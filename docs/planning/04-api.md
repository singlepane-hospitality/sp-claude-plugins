# Planning v1 — 04 Functions and Hasura

The contract between sp-core and its callers (the UI, the agent service, later Excel and MCP).
Reads and writes are tracked functions on a Hasura API of the planner's own (§1.3).
Build both sides against this file. Deviate only when something here is impossible, and record the
deviation in the PR description.

## 1. Conventions

- Schema `planning` unless stated. Hasura root field = `<schema>_<name>` (for example
  `planning_get_workspace`).
- **Everyone is Hasura role `user`.** What a person may do is decided by the module entitlement
  and the app-wide permission model (§1.1), never by a Hasura role and never by anything stored
  under `planning`.
- **Reads are `STABLE` functions**, tracked as queries, returning `SETOF planning.<name>_rt`.
  `hasura_session json` is the first argument and the Hasura `session_argument`; never trust a
  company or user id passed as an ordinary argument. Each function carries a permission for role
  `user`, and its `_rt` table is tracked select-only for role `user` with all columns and
  `filter: {}`; the function authorizes. `_rt` tables live in `tables/` and have no keys, constraints or audit
  columns. A STABLE function cannot create temp tables or write, so every read is plain SQL.
- **Writes are `VOLATILE` functions exposed as mutations**, each tracked with `exposed_as: mutation`
  and an explicit permission for role `user`, the way `acquisitions.upsert_deal_model_scenario`
  is tracked today. The app is moving to a new Hasura where every function carries its
  permissions explicitly (decision D25, `07-hasura-rebuild.md`); the planner's entries are the
  same on the current API and the new one, so they are written once (§1.3). The current API
  exposes a volatile function to `user` when the permission is explicit in the metadata;
  confirmed by test on 2026-11-18 (`07-hasura-rebuild.md` §2).
- A signature below marked `-- mutation` is a VOLATILE function tracked with
  `exposed_as: mutation`, returning `SETOF` its `_rt` table. The text after the semicolon is the
  action it checks with `planning.can`.
- One signature per function name. Hasura rejects overloads; each script ends with a `DO` block
  that checks it.
- Array arguments arrive as Postgres array literals (`'{A,B}'`); structured arguments are `jsonb`.
- Argument names are bare (`property_code`, `scenario_id`); function bodies use
  `#variable_conflict use_column` and `v_` locals, as in `acquisitions.upsert_deal_model_scenario`.
- **Months are month keys:** the 2nd of the month as a `date`, the convention of
  `cleaned.account_values`, `financial_cube.rooms_available` and the status tables. Every function
  and command that takes a month normalizes it with `planning.month_key(date)`, so a caller may
  send any day of the month. Everything returned uses month keys. Days are real dates.
- Errors.
  - A read returns no rows when the caller may not see the hotel (the `auth.get_allowed_hotels` pattern).
  - A mutation raises with `ERRCODE = 'check_violation'` for **every** failure a person can cause:
    not allowed, bad or missing input, a broken planner rule (invalid component, cycle, limit
    reached, stale row version, locked scenario). That is the error class Hasura passes through to
    role `user`; the Plans & Actions triggers rely on the same thing. Messages are lower-case,
    user-readable and shown verbatim.

### 1.1 Access

Permissions are being rebuilt for the whole app
(`docs/workbench/permissions-unification-rbac-response.md`): one role per user, hotel and module,
resolved through evaluator views (`auth.effective_hotel_action`, `auth.effective_company_action`)
that every Hasura block and SQL function reads, with `module_entitlement` saying which hotels a
company may grant per module. The planner adds a module and a list of actions to that model. It
does not store roles, grants or memberships of its own.

Module key: `planning`. Register it in the first planner script and in `loading/0001-modules.sql`
(`INSERT INTO auth.module (module, description, is_active) VALUES ('planning', 'Driver-based budgeting and forecasting', TRUE) ON CONFLICT …`).

Actions to register in the central catalog (seeded by its migration when it exists; names follow
its `module.resource.action` form):

| Action key | Scope | Allows |
|---|---|---|
| `planning.forecast.read` | hotel | Open the planner for a hotel: workspace, line detail, top line, scenarios, change log, driver fit, suggestions, hotel chart; preview a patch |
| `planning.forecast.update` | hotel | Change drivers and top-line values; resolve suggestions; ask the agent |
| `planning.scenario.create` | hotel | Make, detach and archive custom scenarios and budget drafts |
| `planning.scenario.lock` | hotel | Official locks (`forecastN`, `forecastN.M`, `budget`) and archiving them |
| `planning.chart.update` | hotel | Enable and turn off accounts |
| `planning.model.update` | hotel | Create the model; settings; top-line segments; re-apply the standard; hotel-level agent policy |
| `planning.ledger.read` | hotel | Transaction detail (vendors, invoices, payroll journals) |
| `planning.standard.read` | company | See the operator chart and standard |
| `planning.standard.update` | company | Edit the operator standard; company-level agent policy; attach a scenario to more hotels |

Stat pairing (`set_stat_pair`) is Singlepane-internal in v1: Hasura role `admin` only (assumption A4).

```sql
planning.can(hasura_session json, action_key text, property_code text DEFAULT NULL)
  RETURNS boolean        -- STABLE, internal; the only place planner code asks about permission
```

1. Hasura role `admin` → true.
2. Hotel scope: the hotel must have a planner model, be in
   `auth.get_allowed_hotels(hasura_session, ARRAY[property_code])`, and be entitled:
   `(auth.get_module_entitlement_status(hasura_session, 'planning', property_code)).entitlement_status = 1`.
   Company scope: the session's company must own a template or a model.
3. **When the central model is live:** true when the evaluator view has the row
   (`auth.effective_hotel_action` for `(x-hasura-user-id, action_key, property_code)`, or
   `auth.effective_company_action` for company scope). Names are provisional in that plan; use
   whatever it ships.
4. **Until then:** true when `model.company_id` (or the template's company) equals the session's
   `x-hasura-company-id`. Every action is open to those users, and the UI hides the module behind
   the feature flag and entitlement, as Plans & Actions does (assumption A3).

Moving from 4 to 3 is an edit to this one function. Reads call it and return no rows on false.
Mutations call it with their action and raise `you do not have permission to do this` on false. When the central `protected_operation` registry
exists, add the planner's tracked objects to it.

`planning.get_models` returns the caller's capabilities per hotel as booleans (§2), so the UI
shows and hides controls without evaluating permissions itself.

### 1.2 The patch result

Every mutation that can change numbers returns one row of `planning.patch_result_rt`:

| Column | Type | Meaning |
|---|---|---|
| `change_id` | uuid | The `planning.change_log` row; null for a preview |
| `changed` | jsonb | `[{"line_id": …, "period": "2026-07-02", "grain": "M", "amount": 12345.67, "stat": null, "source": "calc"}, …]` — every result cell whose value changed |
| `year_totals` | jsonb | `[{"line_id": …, "year": 2026, "amount": …, "stat": …}]` for the lines in `changed` |
| `warnings` | jsonb | `[{"code": "…", "message": "…"}]`, for example a fork change whose source has moved |
| `calc_ms` | integer | Engine time |
| `queued` | jsonb | Scenarios queued for recalculation as a consequence (forks) |

### 1.3 The app API

The planner has no API of its own. Its objects are tracked on the app's Hasura API like any other
module's (decision D25 supersedes D24), and that API is being rebuilt as a new Hasura with
function-permission inference off (`07-hasura-rebuild.md`).

- **What the planner tracks**, in source `rdsProd`:
  - every `planning.*_rt` table: select, all columns, `filter: {}`, role `user`;
  - `planning.method`: select for role `user`, `filter: {"active_flag": {"_eq": true}}`;
  - every function in §2–§7 marked `-- STABLE` as a query, and every one marked `-- mutation` with
    `exposed_as: mutation`, each with `session_argument: hasura_session` and an explicit
    permission for role `user`;
  - `financial_cube.available_version_rt` and `financial_cube.get_available_versions`
    (`01-version-registry.md`), the same way;
  - the event trigger on `planning.agent_job`.
- **What it does not track:** base planner tables, engine functions and `agent_*` functions.
- **Explicit permissions on every function, queries included.** The new API exposes a function
  only to roles named on it. The current API ignores the entry on a query (it infers from the
  return table) and honors it on a mutation. One set of entries serves both, and the rebuild's
  generator carries them across.
- **Identity** is the app's: the same Cognito token and claims, so `x-hasura-user-id`,
  `x-hasura-company-id` and role `user` arrive as they do for every other module. Everyone is
  `user`; authorization is `planning.can`. Impersonation needs nothing planner-specific.
- **No database login of its own.** Planner functions run under the connection the app API
  already uses, like every tracked function.
- **Which API is live does not matter to the planner.** Its packages ship on the current API if
  the new one is not live yet and move with everything else at cutover (README A14).

## 2. Setup and chart

```sql
planning.get_models(hasura_session json) RETURNS SETOF planning.model_rt                          -- STABLE; hotels the caller holds planning.forecast.read on
```
Hotels on the planner that the caller can open. Columns: `model_id`, `code`, `hotel_name`
(the hotel's `display`-safe name; the UI masks demo names itself), `status`, `closed_through`,
`horizon_months`, `top_line_grain`, `working_scenario_id`, the caller's capabilities as booleans (`can_update`,
`can_create_scenario`, `can_lock`, `can_update_chart`, `can_update_model`, `can_read_ledger`,
`can_read_standard`, `can_update_standard`), `last_calc_at`, `open_suggestions integer`, `needs_attention integer` (chart exceptions).

```sql
planning.create_model(hasura_session json, property_code text, template_id uuid DEFAULT NULL,
                      horizon_months integer DEFAULT 12, top_line_grain text DEFAULT 'month')
  RETURNS SETOF planning.model_rt                                                                  -- mutation; planning.model.update
```
1. Create the model, the company's working scenario if missing, and the `scenario_hotel` row.
2. Propose the chart: a line for every account of the hotel with `actual` rows in the last 24 months
   whose leaf USALI is a P&L or statistic line (`reference.usali.cashflow_type` not `Balance Sheet`,
   mapping not `Unmapped Accounts`), `enabled_from` = January of the first open year. Accounts the
   template marks `default_enabled` are added too; `retired` ones are skipped.
3. Pair stats: suffix pairs (`-STAT`, `-STAT-ACCT`) and approved `planning.stat_pair` rows.
4. Create the standard sets, set `occupied_rooms_set_id`, create one `top_line_segment` row
   (`total`) for monthly grain, or one per mapped segment for daily grains.
5. Seed every line (`03-engine.md` §12), refresh `closed_through`, run `planning.calc`, set status `active`.

```sql
planning.set_model_settings(hasura_session json, property_code text, horizon_months integer DEFAULT NULL,
                            top_line_grain text DEFAULT NULL, closed_through_override date DEFAULT NULL)
  RETURNS SETOF planning.model_rt                                                                  -- mutation; planning.model.update
```

```sql
planning.get_hotel_chart(hasura_session json, property_code text, status_filter text DEFAULT 'all',
                         search text DEFAULT NULL) RETURNS SETOF planning.hotel_chart_rt          -- STABLE; planning.forecast.read
```
`status_filter`: `all | enabled | off | attention`. One row per account in the operator chart that
is either a line of this hotel, has actuals at this hotel, or is `default_enabled` in the template;
when `search` is given, also matching accounts from the rest of the operator chart (limit 200).
Columns: `account_id`, `description`, `usali`, `department`, `category`, `kind` (`amount|stat`),
`line_id`, `enabled boolean`, `enabled_from`, `disabled_from`, `last_actual_month date`,
`trailing_12_actual numeric`, `driver_when_enabled text` (current driver summary, or the template's),
`stat_account_id`, `stat_unit`, `can_enable boolean`, `blocked_reason text`
(`unmapped`, `balance_sheet`, `retired`), `attention text`
(`actuals_while_off`, `unmapped`, null), `note text`.

```sql
planning.set_account_enabled(hasura_session json, property_code text, account_id text,
                             enabled boolean, effective_month date)
  RETURNS SETOF planning.patch_result_rt                                                           -- mutation; planning.chart.update
```
- Enable: fails if `can_enable` is false. Creates the line (and its paired stat line) or clears
  `disabled_from`; seeds it if it has no components in the working scenario; recalculates.
- Disable: sets `disabled_from = effective_month`; the line contributes nothing from then on in
  every live scenario; fact rows from that month are removed by write-through.
- `effective_month` must be the first open month or later.

```sql
planning.get_operator_chart(hasura_session json, template_id uuid, search text DEFAULT NULL,
                            row_limit integer DEFAULT 200, row_offset integer DEFAULT 0)
  RETURNS SETOF planning.operator_chart_rt                                                         -- STABLE; planning.standard.read
planning.upsert_template_line(hasura_session json, template_id uuid, account_id text,
                              default_enabled boolean, retired boolean, method text DEFAULT NULL,
                              driver_type text DEFAULT NULL, driver_account_id text DEFAULT NULL,
                              driver_usali_node text DEFAULT NULL, driver_key text DEFAULT NULL, notes text DEFAULT NULL)
  RETURNS SETOF planning.operator_chart_rt                                                         -- mutation; planning.standard.update
planning.apply_template(hasura_session json, property_code text, account_ids text[] DEFAULT NULL)
  RETURNS SETOF planning.patch_result_rt                                                           -- mutation; planning.model.update
```
`operator_chart_rt`: `account_id`, `description`, `department`, `usali`, `category`, `mapped boolean`,
`default_enabled`, `retired`, `method`, `driver_summary`, `stat_account_id`, `stat_pair_status`,
`hotels_using integer`, `total_rows bigint`. `apply_template` re-seeds the given accounts (or all
non-overridden ones) of one hotel from the template; there is no automatic propagation in v1.

```sql
planning.set_stat_pair(hasura_session json, amount_account_id text, stat_account_id text,
                       unit text, status text DEFAULT 'approved')
  RETURNS SETOF planning.operator_chart_rt                                                         -- mutation; Hasura role admin only
planning.propose_stat_pairs(mgmt_code text) RETURNS integer                                        -- internal; run at onboarding
```
`propose_stat_pairs`: (1) every account ending `-STAT` or `-STAT-ACCT` whose stripped form exists in
`account_map` → `approved`, source `suffix`; (2) for other operators, candidates where the amount
account's leaf USALI has a statistic twin (the `Hours Worked` twin of an `S&W` line by name, or
`reference.usali.default_metric_denominator` when it is a statistic) and exactly one of the
operator's stat accounts maps to that twin within the same department segment of the account string
→ `proposed`, source `proposed`; anything ambiguous is left for a person. Pass `stat_account_id`
= `<amount_account_id>-STAT` to `set_stat_pair` to create a stat account where none exists; the
function then inserts the `account_map` row to the twin USALI.

## 3. Workspace

```sql
planning.get_workspace(hasura_session json, property_code text, scenario_id uuid,
                       compare_version text DEFAULT NULL, plan_year integer DEFAULT NULL)
  RETURNS SETOF planning.workspace_line_rt                                                         -- STABLE; planning.forecast.read
```
One row per line enabled in any month of the year (default: the scenario's first open year).

| Column | Type | Notes |
|---|---|---|
| `line_id`, `account_id`, `description` | | |
| `kind`, `grain` | text | |
| `usali`, `department`, `category`, `sort_key` | text | leaf from the shared resolver (largest weight when split); `sort_key` = the USALI's `sort_order`, then account |
| `split_mapping` | boolean | true when the account maps to more than one leaf |
| `stat_line_id`, `stat_account_id`, `stat_unit` | | paired stat, if any |
| `component_count` | integer | active in the first open month |
| `driver_summary` | text | one line of text, e.g. `Occupied rooms × 0.50 hrs × $20.00`; `3 components` when more than one |
| `primary_field` | text | `rate`, `ratio`, `pct`, `amount` or null: the field a Rates-view cell edits (only for single-component lines) |
| `primary_component_id`, `primary_row_version` | | for patches |
| `periods` | date[] | the 12 month keys of the year |
| `amounts`, `stats` | numeric[] | aligned with `periods`; null where the line is not enabled |
| `primary_values` | numeric[] | the resolved primary parameter per month; for closed months the implied actual value (`amount ÷ driver actual`) |
| `overridden` | boolean[] | month has a period override on the primary field |
| `sources` | text[] | `actual`, `calc`, `manual`, `feed` per month |
| `compare_amounts`, `compare_stats` | numeric[] | from `cleaned.account_values` for `compare_version` (any registry key the caller may see; `ly_actual` = `actual` shifted a year); null array when not requested |
| `year_amount`, `year_stat`, `compare_year_amount` | numeric | |
| `open_suggestions` | integer | |
| `editable` | boolean | caller holds `planning.forecast.update` and the scenario is live at this hotel |

Subtotals and KPIs are **not** in this function. The scenario is written through to the fact
tables, so the UI reads them from the existing data layer with `version = scenario.version_key`
(`app.get_financial_data_twelve_month` and friends). One source of rollup logic.

```sql
planning.get_line(hasura_session json, scenario_id uuid, line_id uuid)
  RETURNS SETOF planning.line_detail_rt                                                            -- STABLE; planning.forecast.read
```
One row: the `workspace_line_rt` columns plus
- `components jsonb`: `[{component_id, row_version, label, method, driver: {type, line_id, set_id, key, label}, p_ratio, p_rate, p_amount, p_pct, p_fte, p_hours, p_base_driver, p_escalator_pct, p_escalator_month, spread_profile_id, contributes_stat, effective_from, effective_to, origin, vendor_key, notes, sort_order, period_overrides: [{period, field, value}], by_period: [{period, driver_value, ratio, stat, rate, amount}], year_amount, share}]`;
- `sets jsonb`: for each set a component uses: `{set_id, usali_node, name, members: [{account_id, description, weight, enabled}], adjustments: [...]}`;
- `fixed_share numeric`: share of the remaining open months' amount that does not move with a driver;
- `fork_changes jsonb`: this fork's changes on the line, each with `source_moved boolean`;
- `inherited_from text`: the template name when `origin` is `template` or `seed`.

```sql
planning.apply_patch(hasura_session json, property_code text, scenario_id uuid, patch jsonb, reason text DEFAULT NULL)
  RETURNS SETOF planning.patch_result_rt                                                           -- mutation; planning.forecast.update
planning.preview_patch(hasura_session json, property_code text, scenario_id uuid, patch jsonb)
  RETURNS SETOF planning.patch_result_rt                                                           -- mutation; planning.forecast.read
```

`patch` is `{"ops": [ … ]}`. All ops apply in one transaction or none do.

| op | Fields | Effect |
|---|---|---|
| `set_param` | `component_id`, `row_version`, `field` (`ratio|rate|amount|pct|fte|hours|base_driver|escalator_pct`), `value` | Change a component's default parameter |
| `set_period` | `component_id`, `row_version`, `field` (`ratio|rate|amount|pct|stat`), `period`, `value` (null clears) | Override one period; the way scheduled, typed and daily values are written |
| `add_component` | `line_id`, `component`: `{label, method, driver_type, driver_line_id|driver_usali_node|driver_key, p_*, effective_from, effective_to, contributes_stat, notes, periods: [{period, field, value}]}` | `driver_usali_node` finds or creates the hotel's set for that node |
| `update_component` | `component_id`, `row_version`, `set`: any of `label, method, driver_*, effective_from, effective_to, contributes_stat, spread_profile_id, vendor_key, notes, sort_order` | |
| `end_component` | `component_id`, `row_version`, `effective_to` | Shorthand used with `add_component` for "new price from June 1" |
| `remove_component` | `component_id`, `row_version` | Only if it has never been in a locked scenario of this hotel; otherwise end it |
| `set_adjust` | `set_id`, `account_id`, `action` (`include|exclude|clear`) | Edit a set's includes and excludes |
| `adjust_line` | `line_id`, `op` (`adjust_pct|adjust_amount`), `value`, `period_from`, `period_to` | Forks only: a line-level adjustment |

Rules:

- `row_version` must match the stored value; otherwise raise `this line was changed by someone else; reload and try again` (`check_violation`). Every update increments it.
- On a **fork**, `set_param` and `set_period` against a source component are stored as
  `planning.scenario_change` rows (`replace`), not as edits to the source; `add_component` creates a
  component owned by the fork; `remove_component` of a source component stores a `component_remove` change.
- On a **locked** scenario every op raises `this scenario is locked`.
- After applying: validate (`planning.validate_component`, cycle check), run `planning.calc`, write the
  `change_log` row (`actor_type = 'user'`; for the agent path see §6), enqueue forks, return the result.
- `preview_patch` applies the ops as an overlay in the engine and stores nothing.

```sql
planning.get_change_log(hasura_session json, property_code text, scenario_id uuid DEFAULT NULL,
                        line_id uuid DEFAULT NULL, row_limit integer DEFAULT 100)
  RETURNS SETOF planning.change_log_rt                                                             -- STABLE; planning.forecast.read
planning.get_driver_fit(hasura_session json, scenario_id uuid, line_id uuid, months integer DEFAULT 12)
  RETURNS SETOF planning.driver_fit_rt                                                             -- STABLE; planning.forecast.read
```
`change_log_rt`: `change_id`, `created_at`, `actor_type`, `actor_name`, `action`, `line_id`,
`account_id`, `summary text` (rendered from the patch), `reason`, `evidence jsonb`, `impact jsonb`.
`driver_fit_rt` (one row): `periods date[]`, `actual numeric[]`, `predicted numeric[]`,
`avg_error numeric`, `bias numeric`, `worst_period date`, `worst_error numeric`,
`months_used integer`, `candidates jsonb` (`[{driver_label, driver_type, driver_ref, fixed_amount, rate, avg_error}]`).
Returns no row for lines fed by the top line.

The method catalog is read straight from the tracked table `planning.method` (`planning_method`
in GraphQL): keys, labels and parameter rules for the method picker.

## 4. Scenarios

```sql
planning.get_scenarios(hasura_session json, property_code text) RETURNS SETOF planning.scenario_rt  -- STABLE; planning.forecast.read
planning.create_scenario(hasura_session json, property_code text, source_scenario_id uuid, made_as text,
                         name text, kind text DEFAULT 'custom', plan_year integer DEFAULT NULL)
  RETURNS SETOF planning.scenario_rt                                                               -- mutation; planning.scenario.create
planning.attach_scenario(hasura_session json, scenario_id uuid, property_codes text[])
  RETURNS SETOF planning.scenario_rt                                                               -- mutation; planning.standard.update
planning.lock_official(hasura_session json, property_code text, lock_type text,
                       source_scenario_id uuid DEFAULT NULL, replace_loaded boolean DEFAULT FALSE)
  RETURNS SETOF planning.scenario_rt                                                               -- mutation; planning.scenario.lock
planning.detach_fork(hasura_session json, scenario_id uuid, property_code text)
  RETURNS SETOF planning.scenario_rt                                                               -- mutation; planning.scenario.create
planning.archive_scenario(hasura_session json, scenario_id uuid, property_code text DEFAULT NULL)
  RETURNS SETOF planning.scenario_rt                                                               -- mutation; planning.scenario.create, or .lock for an official lock
planning.get_fork_changes(hasura_session json, scenario_id uuid, property_code text)
  RETURNS SETOF planning.fork_change_rt                                                            -- STABLE; planning.forecast.read
```

`scenario_rt`: `scenario_id`, `name`, `kind`, `made_as`, `source_scenario_id`, `source_name`,
`version_key`, `plan_year`, `takes_actuals`, `state` (`live|locked`), `locked_at`, `locked_by_name`,
`period_start`, `period_end`, `change_count integer` (forks), `custom_slots_used integer`,
`custom_slots_max integer` (5), `can_edit boolean`, `last_calc_at`.

- `create_scenario`: `made_as` ∈ `fork | copy | snapshot`; `kind` ∈ `custom | budget`.
  - `custom`: fails with `this hotel already has 5 custom scenarios; archive one first` at the limit.
  - `budget`: `made_as` must be `copy`; `plan_year` required; `takes_actuals = false`; period = that year.
  - Inserts the `version_registry` row (`cs_` + first 10 hex of the scenario id, label = name,
    `company_id`, `bypass_validation = true`, `is_live` = not snapshot).
  - Copies or snapshots per `03-engine.md` §10, runs `planning.calc` (not for snapshots, which copy
    results), writes through.
  - If a non-archived scenario of the company already has that name, the hotel is attached to it
    instead (the scenario is company-level); `made_as` and source must match or the call fails.
- `lock_official`: `lock_type` ∈ `forecast_month | forecast_week | budget`. Source defaults to the
  working scenario (`budget` requires a budget draft). Resolves the key (`03-engine.md` §10.1).
  If loaded (non-planner) rows exist for that key and year and `replace_loaded` is false, raise
  `forecast3 for 2026 was loaded from a file; confirm to replace it` so the UI can ask and call again.
- `archive_scenario`: with `property_code`, detaches that hotel only; without, archives the scenario
  for every hotel. The working scenario cannot be archived.

`fork_change_rt`: `scenario_change_id`, `line_id`, `account_id`, `description`, `component_label`,
`target_type`, `field`, `op`, `value`, `period_from`, `period_to`, `source_value_at_change`,
`source_value_now`, `source_moved boolean`, `note`, `created_at`, `created_by_name`.

## 5. Top line

```sql
planning.get_top_line(hasura_session json, property_code text, scenario_id uuid, month date)
  RETURNS SETOF planning.top_line_rt                                                               -- STABLE; planning.forecast.read
planning.set_top_line_cells(hasura_session json, property_code text, scenario_id uuid, cells jsonb, reason text DEFAULT NULL)
  RETURNS SETOF planning.patch_result_rt                                                           -- mutation; planning.forecast.update
planning.fill_top_line(hasura_session json, property_code text, scenario_id uuid, month date, mode text, params jsonb DEFAULT NULL)
  RETURNS SETOF planning.patch_result_rt                                                           -- mutation; planning.forecast.update
planning.set_top_line_segments(hasura_session json, property_code text, segments jsonb)
  RETURNS SETOF planning.top_line_rt                                                               -- mutation; planning.model.update
```

`top_line_rt`, one row per segment (plus one with `segment_key = '__total__'`): `segment_key`,
`label`, `source`, `rooms_line_id`, `revenue_line_id`, `days date[]`, `rooms numeric[]`,
`adr numeric[]`, `revenue numeric[]`, `cell_sources text[]` (`actual|feed|manual|calc`),
`on_books numeric[]` (latest `reservations.otb_segment` snapshot for the mapped segments; null when
none), `feed_rooms numeric[]`, `feed_adr numeric[]`, `month_rooms`, `month_adr`, `month_revenue`,
`rooms_available numeric[]` (total row only), `editable boolean`. For monthly grain `days` holds the
12 month keys of the year and `month` is ignored except for its year.

- `cells`: `[{"segment_key": "retail", "date": "2026-03-18", "rooms": 26, "adr": 322.23}]`; either
  value may be omitted; null clears the override (falls back to the feed or the default). Dates on
  or before `closed_through`, or days that already have daily actuals, are rejected.
- Rooms across segments for a day may not exceed rooms available for that day; raise
  `rooms for Mar 18 exceed the 312 available`.
- `fill_top_line` modes: `feed` (clear overrides so the feed shows through), `last_year_weekday`
  (copy last year's actuals for the same weekday position), `spread` (`params`:
  `{"segment_key", "rooms", "adr"}` month targets spread over days by last year's same-month weekday
  pattern for the segment, or flat when there is no history).

## 6. Agent surfaces

```sql
planning.get_suggestions(hasura_session json, property_code text, status_filter text DEFAULT 'open')
  RETURNS SETOF planning.suggestion_rt                                                             -- STABLE; planning.forecast.read
planning.resolve_suggestion(hasura_session json, suggestion_id uuid, action text, answer jsonb DEFAULT NULL, edited_patch jsonb DEFAULT NULL)
  RETURNS SETOF planning.patch_result_rt                                                           -- mutation; planning.forecast.update
planning.get_policies(hasura_session json, property_code text) RETURNS SETOF planning.policy_rt    -- STABLE; planning.forecast.read
planning.upsert_policy(hasura_session json, policy jsonb) RETURNS SETOF planning.policy_rt         -- mutation; planning.model.update (hotel) or planning.standard.update (company)
planning.request_agent(hasura_session json, property_code text, job_type text, payload jsonb)
  RETURNS SETOF planning.agent_job_rt                                                              -- mutation; planning.forecast.update
```

- `suggestion_rt`: the table's columns plus `account_id`, `line_description`, `created_at`,
  `asked_user_name`, `resolved_by_name`.
- `policy_rt`: `autopilot_policy_id`, `scope_label text` (for example "Utilities", "All wage
  lines", "Everything else"), `scope_level text` (`account|category|department|hotel|template|company`),
  `account_id`, `department`, `category`, `mode`, `max_monthly_amount`, `max_pct`, `allowed_kinds text[]`,
  `set_by_name`, `inherited boolean` (true when the row comes from the template or company, not the hotel).
- `agent_job_rt`: `agent_job_id`, `job_type`, `status`, `created_at`, `finished_at`, `error`.
- `finding_rt` (agent only): `finding_key`, `kind`, `line_id`, `account_id`, `component_id`,
  `period date`, `evidence jsonb` (the figures and transaction ids the rule used),
  `policy_mode text` (resolved for the line), `existing_suggestion_id uuid`.
- `resolve_suggestion` actions: `accept` (apply `patch`, or `edited_patch` when the person changed
  it; `change_log.actor_type = 'agent'`, `actor_user_id` = the approver, `evidence` carries the
  suggestion id), `dismiss`, `answer` (store `answer`, set status `open` again and create an
  `agent_job` of type `answer_followup`), `revert` (for `auto_applied`: apply the inverse patch).
- `request_agent` inserts a `planning.agent_job` row. Chat requests use `job_type = 'chat_patch'`
  with `{"text": "…", "scenario_id": …}`.

For the agent service only (not tracked for role `user`; `GRANT EXECUTE` to `sp_service_backend_rw`):

```sql
planning.agent_get_findings(model_id uuid) RETURNS SETOF planning.finding_rt
planning.agent_explain_line(scenario_id uuid, line_id uuid) RETURNS jsonb     -- line detail + driver fit + recent transactions + open suggestions
planning.agent_preview_patch(scenario_id uuid, model_id uuid, patch jsonb) RETURNS jsonb
planning.agent_upsert_suggestion(suggestion jsonb) RETURNS uuid               -- resolves policy; autopilot applies inside the limits and sets status auto_applied
planning.agent_finish_job(agent_job_id uuid, status text, result jsonb, error text DEFAULT NULL) RETURNS void
```

`agent_get_findings` runs the detectors and returns candidates with a stable `finding_key`
(`<kind>:<account_id>:<vendor_key or period>`):

| Kind | Rule (v1) |
|---|---|
| `ratio_drift` | Driver fit average error ≥ 5% and ≥ $250 a month on average over the last 6 closed months, same sign of bias in at least 4 |
| `rate_change` | A vendor's monthly total on one account changed by ≥ 5% and stayed within ±2% of the new level for 2 consecutive closed months |
| `new_recurring` | A vendor with no postings on the account in the prior 6 months posts in 2 consecutive months |
| `one_time` | One transaction ≥ 3 × the account's median monthly total from that vendor, in the last closed month |
| `over_forecast` | Posted-to-date in the open month already exceeds the month's forecast for the line |

The first needs only actuals; the others need `ledger.transaction` and return nothing until it is loaded.
`agent_upsert_suggestion` must call `planning.preview_patch` logic itself to fill `impact`, and for
kind `fit` must fill `score` from the engine; it rejects a suggestion whose patch fails validation.

## 7. Ledger

```sql
planning.get_line_transactions(hasura_session json, property_code text, account_id text,
                               date_from date, date_to date, row_limit integer DEFAULT 500)
  RETURNS SETOF planning.line_transaction_rt                                                       -- STABLE; planning.ledger.read
transformers.gl_detail(s3_uri text, pcode text, pmonth text, pyear text, pversion text,
                       preporttype text, zero_out boolean, p_date date DEFAULT NULL) RETURNS void
ledger.match_transactions(p_model_id uuid, p_period date) RETURNS integer                          -- internal
ledger.reconcile(p_code text, p_period date) RETURNS integer                                       -- internal
```

- `line_transaction_rt`: `transaction_id`, `posting_date`, `journal_type`, `vendor_name`,
  `invoice_no`, `invoice_date`, `po_no`, `description`, `amount`, `stat_amount`, `component_id`,
  `component_label`, `match_source`, `has_open_suggestion boolean`, `total_amount numeric`,
  `total_rows bigint`.
- `transformers.gl_detail` has the signature `controllers.load_s3_file_by_report_type` requires. It
  builds `account_id`, the hotel code and the sign exactly as the report type's trial balance
  transformer would (reuse the `config.report_type_config` columns: account and department parse
  rules, `amount_col` or `debit_col`/`credit_col`, revenue flip, `hotel_code_parse_pattern`), reads
  the extra columns named in `ledger.gl_detail_config`, and upserts `ledger.transaction` on
  `(posting_date, code, source_system, source_txn_id, line_no)`. With `zero_out`, it first deletes the
  hotel's rows for the periods in the file from that `source_system`. It then calls
  `ledger.ensure_partitions`, `ledger.match_transactions` and `ledger.reconcile` for the periods touched.
- `match_transactions`: for unmatched rows of the period, set `component_id` where exactly one
  active component of the account's line in the working scenario has the same `vendor_key`;
  `match_source = 'rule'`.
- `reconcile`: upsert `ledger.reconciliation` with the ledger sum and the `actual` value per account.

## 8. Engine functions (not tracked)

```sql
planning.calc(p_model_id uuid, p_scenario_id uuid, p_trigger text, p_overlay jsonb DEFAULT NULL,
              p_persist boolean DEFAULT TRUE, p_line_ids uuid[] DEFAULT NULL) RETURNS jsonb   -- the patch-result payload
planning.validate_component(p_component jsonb, p_line_id uuid, p_scenario_id uuid) RETURNS void    -- raises check_violation
planning.resolve_set_members(p_model_id uuid, p_driver_set_id uuid) RETURNS TABLE (account_id text, line_id uuid, weight numeric)
planning.seed_line(p_line_id uuid, p_scenario_id uuid) RETURNS void
planning.refresh_closed_through(p_model_id uuid) RETURNS date
planning.enqueue_recalc(p_model_id uuid, p_scenario_id uuid, p_reason text) RETURNS void
planning.run_recalc_queue(p_max_jobs integer DEFAULT 20) RETURNS integer
financial_cube.resolve_account_lines(p_code text, p_account_ids text[]) RETURNS TABLE (account_id text, leaf text, usali text, weight numeric)
financial_cube.forecast_week_revision(p_date date) RETURNS integer
planning.can(hasura_session json, action_key text, property_code text DEFAULT NULL) RETURNS boolean
planning.month_key(p_date date) RETURNS date                                                       -- IMMUTABLE: the 2nd of p_date's month
```

pg_cron (script under `database/sph/postgres/updates/`, in the style of
`20261019-01-FI005-future-insights-usali-availability-cron.sql`): job `planning_recalc_queue`,
schedule `* * * * *`, command `SELECT planning.run_recalc_queue()`, `database = 'singlepane'`,
`username = 'postgres'`, with the same unschedule-then-schedule and verify blocks.

Triggers that enqueue (all statement-level, all skip rows whose `fileid` starts with `planning:`):
`cleaned.account_values` and `cleaned.account_values_daily` after insert/update/delete for
`version = 'actual'`; `reservations.rms_forecast_segment` after insert; `financial_cube.account_map`,
`mapping_override` and `account_hierarchy` after any change. Check each table's owner first: a
trigger on a `postgres`-owned table is created after `RESET ROLE`.

## 9. Hasura metadata

One API (§1.3). Planner objects are added to `database/hasura/hasura_metadata.json`, source
`rdsProd`, by scripts in `database/hasura/scripts/`: `version_registry_metadata.py` for the
objects in `01-version-registry.md`, and `planning_metadata.py` for everything else in this
document. Each diff must be pure additions.

- Generate the planner's entries from the function list in this file, so a function added here
  cannot be forgotten there.
- Every tracked function gets `permissions: [{"role": "user"}]`, queries included (§1.3), and
  `session_argument: hasura_session`. Every `-- mutation` gets `exposed_as: mutation`.
- Do not write permissions per Hasura role for the planner. Everyone is `user`.
- Declare the event trigger on `planning.agent_job` insert → the agent service like
  `financial_cube.mapping_job_request`'s `new_ai_mapping_job`. Leave the webhook URL and key to
  Austin and keep secrets out of scripts; on the new API they come from its environment.
- While both Hasura projects exist, apply planner metadata to the live one only; the rebuild's
  generator (`07-hasura-rebuild.md` §4.2) carries it to the new one.

Each update script ends with a "Post-deploy (Hasura)" comment naming the metadata script to
apply, and the UI regenerates its Zeus client after the metadata is live.
