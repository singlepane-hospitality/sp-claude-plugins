# Planning v1 — 03 Engine

How a forecast is calculated, kept in step with actuals, and written to the fact tables.
Table and column names are defined in `02-data-model.md`; function signatures in `04-api.md`.

Everything in this file runs inside Postgres as set-based PL/pgSQL. The functions named here
(`planning.apply_patch`, `planning.calc`, …) are plain
Postgres functions; the UI reaches them through the planner's Hasura API (`04-api.md` §1.3). There is no application-tier
calculation. The UI may compute the edited row locally for instant feedback, and must reconcile
with what the patch call returns.

## 1. Vocabulary

| Term | Meaning |
|---|---|
| Model | One hotel's planning setup (`planning.model`). One per hotel code. |
| Line | One forecastable account at a hotel (`planning.line`): an amount account or a stat account. Keyed on the same `account_id` string as `cleaned.account_values`. |
| Component | One building block of a line in one scenario (`planning.component`). A line's value is the sum of its components. |
| Driver | What a component multiplies: another line, a set of lines, the calendar, or rooms available. |
| Set | A USALI node resolved to this hotel's accounts, plus includes and excludes (`planning.driver_set`). |
| Scenario | A named version of the plan (`planning.scenario`), per company, attached to hotels through `planning.scenario_hotel`. |
| Period | A month key (the 2nd of the month, as in the fact tables) for monthly lines, or a day for daily lines. |
| Closed period | A month on or before the hotel's `closed_through`. |

## 2. Periods

- A scenario covers `period_start .. period_end` for each hotel (`planning.scenario_hotel`), both
  month keys, inclusive. A month key is the 2nd of the month; `planning.month_key(date)` returns it
  for any date and every function that takes a month applies it.
  - Working forecast: `period_start` = January of the year containing the first open month.
    `period_end` = first open month + `model.horizon_months` − 1, and never earlier than December
    of that year.
  - Budget scenario: January to December of `scenario.plan_year`.
  - Fork, copy, snapshot: inherited from the source when created.
- `model.closed_through` is the month key of the last closed month. `planning.refresh_closed_through(model_id)`
  sets it to the last month M such that every month from January of that year through M has a
  displayable `actual` row for the hotel in `financial_cube.financial_data_status_mv`
  (read the MV, never the base table). A planner admin may set `closed_through_override`; when set it wins.
- For a scenario with `takes_actuals = true`, periods on or before `closed_through` are **closed**
  and everything after is **open**. For `takes_actuals = false` (budgets, snapshots) every period is
  open for calculation purposes; snapshots are never recalculated at all.

## 3. Methods

A component produces, per period, an **amount** and optionally a **stat**. `D` is the driver value
for the period. Parameters are the `p_*` columns on the component; each can be overridden per
period by a `planning.component_period` row (`field` names in brackets).

| Method | Driver | Stat | Amount | Notes |
|---|---|---|---|---|
| `fixed` | none | none | `p_amount` [amount] | If `spread_profile_id` is set, `p_amount` is an annual figure and the period amount is `p_amount × weight(month)`. If `p_escalator_pct` is set, amounts from `p_escalator_month` each year are multiplied by `(1 + pct/100)` compounding yearly. |
| `per_unit` | required | none | `D × p_rate` [rate] | Guest supplies, $4.85 per occupied room. |
| `stat_chain` | required | `D × p_ratio` [ratio] | `stat × p_rate` [rate] | Covers = occupied rooms × capture; revenue = covers × check. Hours = occupied rooms × hours per room; wages = hours × wage. |
| `pct_of` | required (amount driver) | none | `D × p_pct / 100` [pct] | Payroll taxes, 31.5% of rooms S&W. |
| `headcount` | none | `p_fte × p_hours` | `stat × p_rate`; when `p_hours` is null, `p_fte × p_amount` | One supervisor: 1 FTE × 173 hours × $26. Salaried: FTE × monthly salary, no stat. |
| `flex` | required | none | `p_amount × (p_pct/100 + (1 − p_pct/100) × D / p_base_driver)` | `p_pct` is the fixed share. Utilities, 70% fixed. |
| `schedule` | none | none | the period's [amount] override, else 0 | Itemized plan lines: window cleaning in April and October. |
| `manual` | none | period [stat] override or `p_amount` for stat lines | period [amount] override, else `p_amount` | Typed values. Used for typed top-line rooms and for one-off entries. |
| `feed` | none | from the feed | from the feed | See §9. A period override beats the feed for that period. |

Rules that apply to all methods:

- A component is active in a period when the line is enabled for that period
  (`enabled_from <= period` and `disabled_from` is null or `> period`) and the period is within
  `effective_from .. effective_to` (nulls are open-ended). These bounds are month keys; a daily
  period is tested by its month key. Inactive means it contributes nothing.
- A null parameter that the method needs makes the component invalid. `planning.apply_patch`
  rejects the patch; it never stores an invalid component.
- Amounts are rounded to 2 decimals and stats to 4 decimals when stored in results.
- Amount sign follows `cleaned.account_values` for that account: revenue positive, expenses positive
  (the loaders already flip revenue). The engine never flips signs.

### 3.1 Which stat a line carries

- An amount line may point at a paired stat line (`line.stat_line_id`). The stats of its components
  with `contributes_stat = true` are summed and added to that stat line for the period. Several
  amount lines may point at the same stat line.
- A stat line is either **collected** (at least one amount line points at it; it has no components
  of its own and `apply_patch` rejects adding one) or **driven** (it has its own components,
  usually `manual`, `feed` or `stat_chain`).
- A stat line's value lives in `result_line.stat`; its `amount` is null.

## 4. Drivers

| `driver_type` | Value for a period |
|---|---|
| `line` | The driver line's `stat` if it is a stat line, else its `amount`. Monthly value. For a daily line the monthly value is the sum of its days. |
| `set` | Sum over the set's members of member value × weight. See §4.1. |
| `calendar` | `driver_key` one of `days` (days in month), `weekdays` (Mon–Thu), `weekend_days` (Fri–Sun), `one` (1). |
| `rooms_available` | Rooms available for the month from `financial_cube.rooms_available` using the same resolution the cube uses (version `'*'` and the `1900-01-02` default included) × days in month, unless the hotel has a GL value for Total Rooms Available, in which case the set of that node is used instead. |

### 4.1 Sets

A set is `(model_id, usali_node)` plus rows in `planning.driver_set_adjust` that include or exclude
specific accounts.

Members are resolved at calculation time, never stored:

1. For each enabled line of the model, find its leaf line(s): the hotel's rows in
   `financial_cube.mapping_override` for `(code, account_id)` if any exist, otherwise the rows in
   `financial_cube.account_map` for the account. Each gives `(sp_account_id, weight)`.
2. Join each leaf to `financial_cube.account_ancestor_map` on `leaf_account_id`, keep rows whose
   `ancestor_account_id = usali_node`. Member weight = map weight × ancestor weight.
3. Apply adjustments: an `exclude` row removes the account; an `include` row adds it with weight 1.

This is the same lookup PR 114's `get_financial_cube_cells` performs (`account_leaf` and `line_edge`
CTEs). Lift it into one shared function, `financial_cube.resolve_account_lines(p_code text,
p_account_ids text[])` returning `(account_id, leaf, usali, weight)`, and have the planner call it.
Do not read `financial_cube.account_map_cache` anywhere in the planner; it is being removed.

Value of a set for a period:

- **Open period:** sum over enabled member lines of the scenario's `result_line` value (stat for
  stat lines, amount otherwise) × weight.
- **Closed period:** sum of `cleaned.account_values` `actual` for every account of the hotel that
  resolves to the node, enabled or not, × weight. Actuals always count in full.

A set must not contain the line that the component belongs to. `apply_patch` rejects it.

Templates express sets relative to the line: `usali_node` may contain the token `{dept}`, replaced
by the department suffix of the line's own leaf USALI when the template is applied (for example
`Total Salaries Wages & Bonuses - {dept}`).

## 5. Dependency levels

Build a directed graph over the model's lines for the scenario:

- component with `driver_type = 'line'`: edge driver line → component's line;
- component with `driver_type = 'set'`: edge from every member line → component's line;
- amount line with `stat_line_id`: edge amount line → stat line.

`level(line)` = 0 if it has no incoming edges, else 1 + max level of its sources. A cycle is an
error: `apply_patch` rejects the patch that would create it, and a full recalculation that finds
one (for example after a mapping change) marks the calc run failed, leaves stored results
untouched, and records the cycle's accounts in `planning.calc_run.error`.

Levels are recomputed at the start of every calculation. They are not stored.

## 6. Calculation: `planning.calc`

Signature and options are in `04-api.md`. One call calculates one hotel in one scenario.

1. **Lock.** `pg_advisory_xact_lock` on the model id (use the two-int form with a planning class
   id) so two calculations of the same hotel never interleave.
2. **Guard.** If `scenario_hotel.state = 'locked'`, return without doing anything.
3. **Effective inputs.** Build temp tables (`ON COMMIT DROP`):
   - `eff_component`: the components that apply to this scenario and hotel;
   - `eff_param`: one row per component × period × field with the resolved value
     (default, then period override).
   For a root, copy or budget scenario these come straight from `planning.component` and
   `planning.component_period`. For a fork, start from the source scenario's effective inputs
   (recursively; maximum depth 3) and apply the fork's `planning.scenario_change` rows, then add
   the fork's own components. For preview mode, apply the overlay patch to the temp tables only.
4. **Closed periods.** For every enabled line and closed period, write the actual:
   monthly lines from `cleaned.account_values` (`version = 'actual'`, the month's row);
   stat lines likewise into `stat`. `source = 'actual'`.
5. **Open periods by level.** For level 0 upward:
   - resolve driver values for the level's components from `result_line` rows already produced
     (lower levels and closed periods), sets (§4.1), calendar and rooms available;
   - compute `stat` and `amount` per component and period into `result_component`;
   - sum components into `result_line.amount`; add contributing stats to the paired stat line;
   - for forks, apply line-level adjustments (`target_type = 'line_value'`) to the line's value
     for the periods in range before the next level reads it.
   `source = 'calc'`, or `'manual'` / `'feed'` when every contributing component is of that method.
6. **Daily lines** (§9) are calculated per day for open periods, then summed into a monthly
   `result_line` row so that monthly drivers read one grain.
7. **Diff and store.** Compare the new results with stored results for the scenario and hotel;
   upsert changed rows, delete rows that no longer exist. Return the changed cells.
8. **Write-through** (§8) for the changed cells, when the scenario is published.
9. **Log.** Insert a `planning.calc_run` row: trigger, duration in ms, lines, changed cells,
   written-through cells, error.

v1 recalculates all open periods of the hotel on every call. Budget: p95 under 500 ms for a
3,000-line hotel over 18 months on prod hardware. `planning.calc` takes an optional
`p_line_ids uuid[]` so a later version can restrict work to a dirty set and its dependents; v1
may ignore it. Record timings so the budget can be checked on real data.

## 7. Actualization

- When `closed_through` advances, the newly closed months switch from calculated to actual on the
  next calculation of every live scenario of the hotel (`takes_actuals = true`).
- The open month for monthly lines keeps the forecast until the month closes.
- Daily lines in an open month use `cleaned.account_values_daily` `actual` for days that have a
  row for the account, and the forecast for the rest.
- Lines that are not enabled are not actualized and not written through. Their actuals still count
  inside sets (§4.1).

## 8. Write-through to the fact tables

A scenario is **published** when it has a registry `version_key` and `scenario.published = true`.
In v1 that is: the working forecast (`working`), budget drafts and custom scenarios (their own
`cs_…` key), and official locks (`forecastN`, `forecastN.M`, `budget`).

For each changed cell of a published scenario:

- Monthly: upsert `cleaned.account_values` with `code`, `account_id`, `version = version_key`,
  `time` = the month key at 00:00 UTC (`make_timestamptz(year, month, 2, 0, 0, 0, 'UTC')`), which is
  what the loaders' `to_timestamp(<year>-<month>-02)` gives on prod, `value`, `fileid = 'planning:' || scenario_id`,
  `source_loaded_at` and `transformed_at` = now, `account_desc` = the account's description.
  Use `ON CONFLICT (code, "time", version, account_id) DO UPDATE ... WHERE value IS DISTINCT FROM EXCLUDED.value`.
- Daily: the same into `cleaned.account_values_daily` with the day's timestamp convention
  (confirm against `transformers.opera_tb`).
- Stat lines write their `stat` as `value` on the stat account.
- A cell whose new value is null or zero is deleted from the fact table if a row exists.
- Closed months are written too (the actual value), so a published version is complete for the year,
  as `forecastN` is today.

Never write to a `(code, version)` the planner does not own. Before the first write for a hotel
and version, if rows exist for that `(code, version)` in the scenario's period range whose `fileid`
does not start with `planning:`, raise unless the caller passed `p_replace_loaded => true`
(only the official-lock functions accept that flag, and only after the UI confirmed).

Official locks additionally upsert `financial_cube.validation` for the hotel, year and version
(`month = 'Total Year'`, `display_in_app = 1`, `status_note = 'Locked in Singlepane Planning'`,
`validated_by` = the user's name) **after** the fact rows are written, with `ON CONFLICT DO UPDATE`.
The insert trigger writes a provisional row first; an upsert afterwards is what makes the real
status land. `working` and `cs_…` versions bypass the validation gate through the registry and
need no validation rows (`01-version-registry.md`).

Write-through happens in the same transaction as the calculation. The cube computes rollups on
read, so the next query from any screen, Excel or MCP sees the new numbers.

## 9. Top line and daily lines

The top line is ordinary lines and components; there is no separate store.

- `planning.top_line_segment` lists a hotel's top-line rows: a segment key, the rooms stat line,
  the revenue amount line, the source, and the display order. A hotel with `top_line_grain = 'month'`
  and no segment split has a single row with segment key `total`.
- **Rooms** live on the stat line as one driven component: method `manual` (typed) or `feed`.
- **Revenue** lives on the amount line as one component: method `per_unit`, driver = the rooms stat
  line, `p_rate` = ADR. Typing ADR for a month is a period override of `rate`.
- `line.grain = 'day'` when `top_line_grain` is `day_segment` or `day_total`. Daily values are
  `component_period` rows whose `period` is the day. A daily `per_unit` component reads its driver
  line's value for the same day.
- **Feed components** read the most recent `reservations.rms_forecast_segment` row per stay date
  for the hotel, source and mapped segment(s): `stat` = rooms forecast, and the revenue line's
  `rate` for the day = ADR forecast. A period override on the component beats the feed for that day.
  Segment mapping uses `reservations.otb_segment_map` (source segment → sp segment) and
  `top_line_segment.segment_key`.
- The hotel's **occupied rooms driver** is the set named by `model.occupied_rooms_set_id`
  (node `Total Rooms Occupied - 100` when the hotel has stat accounts under it, else
  `Total Rooms Sold - 100`). Seeded expense components point at it.

## 10. Scenarios

| Made as | Follows its source | Takes actuals | Stores | Recalculated |
|---|---|---|---|---|
| `root` (working) | n/a | yes | its own components | yes |
| `fork` | yes | yes | only `scenario_change` rows and components it adds | yes, after its source |
| `copy` | no | yes (budget drafts: no) | a full copy of components and period overrides | yes |
| `snapshot` | no | no | a full copy of components, period overrides and results | never |

- **Fork.** Effective inputs = the source's effective inputs with the fork's changes applied.
  A change is a replacement of a parameter (optionally for a period range), an adjustment of the
  source's parameter by a percent or an amount, the removal of a source component, or a line-level
  percent/amount adjustment of a computed value for a period range. A replaced parameter no longer
  follows the source. The fork's change list (API) marks changes whose source value has moved since
  the change was made (`source_value_at_change` differs from the source's current value).
- **Copy.** Components and overrides are copied once. `feed` components are converted to `manual`
  with the source's current results as period values, so a copy moves only with actuals and its own
  edits. (Assumption A5 in the README; flip by copying `feed` components unchanged.)
- **Snapshot.** Copies inputs and results and sets `scenario_hotel.state = 'locked'`. Official
  locks are snapshots with a system version key; custom snapshots get a `cs_…` key.
- **Taking actuals is the scenario's own flag**, not inherited: a fork or copy of a snapshot is live.
- **Detach.** `planning.detach_fork` materializes a fork's effective inputs into its own components
  and makes it a copy.
- **Archive.** Archiving a scenario deletes its fact rows (`fileid = 'planning:' || scenario_id`),
  removes its registry row from dropdowns (`active_flag = false`), keeps its planner rows, and
  detaches its forks first.
- **Limit.** A hotel may be attached to at most 5 non-archived scenarios of kind `custom`.
  Working, budget and official scenarios do not count.
- **Order of recalculation.** After a scenario's results change for a hotel, enqueue its forks for
  that hotel (§11). Never recalculate a fork inline in the source's call.

### 10.1 Official locks

`planning.lock_official` snapshots a hotel's working forecast (or a budget draft) into a system version:

- **Monthly forecast:** `forecastN` where N is the month number of `closed_through` in the plan
  year. Requires N ≥ 1.
- **Weekly revision:** `forecastN.M`. M comes from the existing week rule (week 1 ends on the first
  Sunday after the month's first Thursday; later weeks run Monday to Sunday), evaluated on the lock
  date. The rule is already coded in `financial_cube.get_version_for_future_insights_as_of_date`
  (lines 56–66 on the PR 114 branch) and in the UI's `getWeeklyForecastFromFirstThursday`. Extract
  the SQL into `financial_cube.forecast_week_revision(p_date date)` and use it in both places; do
  not invent a new numbering. The key must exist in the registry or the call fails (months 2, 4, 6,
  9 and 11 only have revisions 1 to 4 today).
- **Budget:** `budget` for `plan_year`.

A lock replaces the hotel's existing rows for that version and year (see the ownership guard in §8),
writes the validation row, and records the snapshot scenario. Locking the same key again replaces it;
the earlier snapshot stays in the planner, unpublished.

## 11. When recalculation runs

| Event | Action | Timing |
|---|---|---|
| `apply_patch` on a scenario | `planning.calc` for that hotel and scenario inside the call; forks enqueued | immediate |
| Account enabled or turned off | lines created or ended; `planning.calc` inline for the working scenario; other live scenarios enqueued | immediate |
| `closed_through` changes | all live scenarios of the hotel enqueued | queue |
| `actual` rows loaded for an enabled hotel (monthly or daily) | all live scenarios enqueued | queue, debounced |
| Feed rows loaded for the hotel | scenarios with feed components enqueued | queue |
| `account_map`, `mapping_override`, `account_hierarchy` change | every model with an affected account (all planner models for a hierarchy change) enqueued | queue |
| Template re-applied | affected models enqueued | queue |
| Source scenario recalculated | its forks enqueued | queue |

Queue mechanics (`planning.recalc_request`):

- Enqueue = upsert on `(model_id, scenario_id)` for a row in `queued` status, pushing `not_before`
  to now + 60 seconds (debounce) and appending the reason. A null `scenario_id` means all live
  scenarios of the hotel.
- `planning.run_recalc_queue(p_max_jobs int default 20)` is called by pg_cron every minute. It
  claims due rows with `FOR UPDATE SKIP LOCKED`, runs `planning.calc`, and marks each `done` or
  `error` (storing the message and incrementing `attempts`; give up after 3).
- Enqueue from data loads through statement-level triggers on `cleaned.account_values` and
  `cleaned.account_values_daily` that look only at `version = 'actual'` rows whose `fileid` does
  not start with `planning:`, and only at codes that have a planner model. The triggers must be
  cheap: one `INSERT ... SELECT DISTINCT code` into the queue.

## 12. History seed

`planning.seed_line` gives a line its first components in the working scenario. Inputs are the
line's leaf USALI row in `reference.usali` and the trailing closed months (12 when available,
at least 6, else fall back to `fixed` 0 and flag the line as unseeded).

| `reference.usali.default_metric` | Seeded component |
|---|---|
| `% of S&W`, `% of Department Revenue`, `% of F&B Revenue`, `% of Hotel Revenue`, `% of Total Revenue`, `% of Rooms Revenue`, other `% of …` | `pct_of`, driver = set on `default_metric_denominator`; `p_pct` = Σ actual ÷ Σ set actual × 100 |
| `POR` | `per_unit`, driver = the model's occupied rooms set; `p_rate` = Σ actual ÷ Σ occupied rooms |
| `PAR` | `per_unit`, driver = `rooms_available` |
| `Per F&B Guest` | `per_unit`, driver = set on `default_metric_denominator` when the hotel has stats under it; otherwise as `POR` |
| `ADR` | `per_unit`, driver = the paired rooms-sold stat line; `p_rate` = Σ revenue ÷ Σ rooms |
| blank, `Nominal`, anything else | `fixed`, `p_amount` = average monthly actual |

Then:

- **Wage lines with a paired hours stat line** are seeded as `stat_chain`: driver = occupied rooms
  set, `p_ratio` = Σ hours ÷ Σ occupied rooms, `p_rate` = Σ wages ÷ Σ hours.
- **Stat lines** that are not collected and not on the top line are seeded `manual` with the
  trailing average.
- **Fallback to fixed.** Run the fit of §13 for the seeded driver and for `fixed`. If `fixed` has
  the lower error, seed `fixed`. Record the choice and both errors in the change log.
- A template line (`planning.template_line`) overrides the method and driver; values still come
  from the hotel's own history.
- Components created by the seed have `origin = 'seed'`.

## 13. Driver fit

`planning.get_driver_fit` backtests a line's current effective components against actuals over the
trailing closed months (default 12):

- For each month, evaluate the components exactly as §3 does, with every driver taken from
  **actuals** (stat actuals, set actuals, calendar, rooms available) and parameters at their
  defaults (period overrides ignored; components active in the first open month are used).
- Return per month: actual, predicted; and overall: average error = Σ|predicted − actual| ÷ Σ|actual|,
  bias = (Σ predicted − Σ actual) ÷ Σ actual, worst month and its error.
- Also return **candidate fits** for the agent: for each candidate driver (the model's occupied
  rooms set, arrivals and guests sets when the hotel has them, the line's department revenue set,
  total revenue, days), the least-squares fixed amount and per-unit rate (intercept clamped at ≥ 0,
  slope at ≥ 0), and the average error of that fit. The engine does not turn candidates into
  suggestions. The agent does (README §8); the UI shows a suggestion only when a
  `planning.suggestion` row exists for the line.

The same evaluation with budget inputs and actual drivers is the flex budget; expose it later
through the same function with a scenario parameter.

## 14. Preview

`planning.preview_patch` runs `planning.calc` in overlay mode: the patch is applied to the temp
effective inputs, results are computed into temp tables, diffed against stored results, and
returned as impact by line and month plus the change in the line's year total. Nothing is stored
and nothing is written through. The agent uses it to score a proposal; the UI uses it for
"what would this do" before applying.
