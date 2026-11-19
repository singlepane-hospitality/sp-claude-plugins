# Planning v1 — 06 Work packages

The order to build in, what each package delivers, and how to tell it is done.
`C` packages are sp-core; `U` packages are the ui repo; `H` packages are the move to a new Hasura
for the whole app (`07-hasura-rebuild.md`).

## 1. How a package moves

1. The agent builds on a branch and opens a draft PR (sp-core → `main`, merge commit; ui → `stage`, squash).
2. sp-core packages are proven on a **scratch Postgres 17** with the repo's integration pattern
   (§3). The agent never applies anything to prod and has no credentials to.
3. Austin dry-runs the script on prod (`BEGIN … ROLLBACK`), applies it as `sp_admin`, then applies the
   Hasura metadata to the live app API. There is no QA database.
4. Only then can the ui repo regenerate its Zeus client (`npm run pull-latest-zeus`) and build
   against the real types. A UI package whose backend is not applied yet is built against fixtures
   in `planning.testing.ts` and kept in draft.
5. A package is done when its acceptance list passes, canonical files and docs are updated in the
   same PR, and the PR description lists every deviation from these documents.

## 2. Order and dependencies

| WP | Repo | Scope | Depends on |
|---|---|---|---|
| C0 | sp-core | *Prerequisite, not agent work:* PR 114 switch and cleanup applied and merged | — |
| H1 | sp-core | Metadata generator with explicit function permissions, exposure matrix, per-role schema comparison, runbook (`07` §4, §9) | — |
| H2 | Hasura | *Austin:* the check in `07` §2; the new project and its environment; event trigger rehearsal on copies | H1 |
| H3 | Hasura | *Austin, with the scripts:* generated metadata applied to the new project; parity proven (`07` §5) | H2 |
| H4 | every caller | Endpoint cutover, one small PR per repo, in the order of `07` §7.1 | H3 |
| H5 | Hasura | *Austin:* event trigger switch; retire the old project | H4 |
| C1 | sp-core | Version registry (`01-version-registry.md`) | C0 |
| C2 | sp-core | `planning` schema, tables, method catalog, shared resolver, `planning.can`, module registration, the planner's Hasura metadata script | C1 |
| C3a | sp-core | Engine, patch, workspace reads, change log, driver fit | C2 |
| C3b | sp-core | Model setup, seeding, hotel and operator chart, stat pairs, templates | C3a |
| C3c | sp-core | Recalculation queue, enqueue triggers, pg_cron job, closed-through refresh | C3a |
| C4 | sp-core | Scenarios: copy, snapshot, fork, official locks, archive, limit | C3a |
| C5 | sp-core | Top line: functions, daily lines, RMS forecast table, IDeaS load, Duetto landing | C3a |
| C6 | sp-core | Ledger: tables, GL-detail transformer, matching, reconciliation, drill-through read | C3a |
| C7 | sp-core | Agent surfaces: suggestions, policy, findings, agent jobs | C3a, C6 for the ledger detectors |
| U0 | ui | Version catalog service | C1 applied |
| U1 | ui | Module skeleton: gating, routes, shell, home, setup, API service | C3b applied |
| U2 | ui | Workspace grid and line drawer (Drivers, Activity) | U1, C3a applied |
| U3 | ui | Chart of accounts | U1, C3b applied |
| U4 | ui | Scenario switcher, save-as, lock, fork changes, banners | U2, C4 applied |
| U5 | ui | Top line | U1, C5 applied |
| U6 | ui | Driver fit and Transactions tabs | U2; C6 applied for Transactions |
| U7 | ui | Inbox | U2, C7 applied |
| U8 | ui | Version catalog rollout to existing screens | U0 |

C3b, C3c, C4, C5, C6 can proceed in parallel after C3a, in separate branches. They touch different
functions; the shared file is the planner's Hasura script (append-only entries).
H packages run alongside and block no planner package: planner functions are tracked with explicit
permissions that work on the current API and on the new one (README A14). If the check in
`07-hasura-rebuild.md` §2 fails, U1 and every later UI package that writes also depends on H4.
H1 can start immediately.

A usable first release is C1–C4 with U0–U4: monthly expenses and labor, chart of accounts,
scenarios, live everywhere. C5–C7 and U5–U7 complete v1.

## 3. How sp-core packages are tested

Follow `tests/deal_model_scenarios_integration.sql` and `tests/settings_checks.sql`:

- `tests/planning_<wp>_integration.sql`: run with `psql -v ON_ERROR_STOP=1` against an **empty**
  scratch database. It creates roles and minimal shapes of referenced tables under
  `SET ROLE sp_object_owner`, includes `prod_like_security.sql`, applies the package's update
  script(s) **twice** as `sp_admin` (re-runnable), then runs the checks as `sp_test_app`.
- `tests/planning_<wp>_checks.sql`: `BEGIN; … ROLLBACK;` with `DO $test$` blocks that
  `RAISE EXCEPTION` on failure and end with `RAISE NOTICE 'planning <wp>: all checks passed'`.
  Fake the session with `set_config('hasura.user', …, true)` and by passing a session JSON.
- Shared fixture: `tests/fixtures/planning_golden_hotel.sql` (new). One hotel, `GOLD`, 312 rooms,
  company 9001, `requires_validation = true`:
  - about 40 accounts under one operator prefix covering: room revenue by three segments with
    rooms-sold stat accounts, a food revenue account with a covers stat (`-STAT`), wage accounts with
    hours stats (`-STAT`), payroll-related, supplies, a contract-services account, utilities, one
    unmapped account, one balance-sheet account, one account split across two USALIs;
  - the matching slice of `reference.usali`, `account_map`, `account_hierarchy` /
    `account_ancestor_map` (enough nodes for `Total Rooms Occupied - 100`,
    `Total Salaries Wages & Bonuses - 100`, department revenue and total revenue);
  - 24 months of `actual` rows generated by formula (so expected seeds are known), validated;
    `financial_cube.rooms_available`; a stand-in for `financial_data_status_mv`;
  - one more company (9002) that can see the hotel but does not own its model, for permission checks.
- Scale check: a script that clones `GOLD` to 3,000 lines × 18 months and times `planning.calc`.
  Report the timing in the PR; the target is under 500 ms.

C1 additionally has the parity test described in `01-version-registry.md` §5.

**Real-hotel check (C3b, once):** on a scratch database loaded with one real hotel's rows
(`\copy` through the read-only `SPH_DATABASE_URL`; Austin names the hotel), run `create_model` and
compare the seeded working forecast for the remaining months of the year with the operator's latest
loaded `forecastN` at summary lines (total revenue, departmental expenses by department, GOP).
Report the differences in the PR. There is no pass threshold; the point is to see how close history
seeding gets before anyone edits a driver.

## 4. Acceptance by package

### C1 Version registry

- Parity test reports 0 differences except the two asserted `is_version_valid` changes.
- `working` rows for a scratch hotel are returned by the cube with no validation row when asked
  for by name. `get_code_latest_forecast` and the future insights resolver never return `working`;
  they still return the latest `forecastN` / `forecastN.M`.
- `insert_provisional_validations` writes nothing for a bypass version and still writes for `budget`.
- `get_available_versions`: a company sees system versions plus its own custom rows, never another
  company's; `has_data` matches the status MV; no allowed hotels → no rows.
- Script re-runs cleanly; one overload per function; `sp_user_readonly` can execute and select.

### C2 Foundation

- Schemas, tables, partitions, comments, grants and default privileges exist; a second run changes nothing.
- `sp_test_app` can select `_rt` tables and execute the planner's functions; no planner base table
  is written except through them.
- The planner metadata script produces a permission for role `user` on every function in
  `04-api.md`, marks every `-- mutation` as a mutation, and tracks no base table.
- A failed permission raises `check_violation` and changes nothing.
- `planning.month_key` returns the 2nd for any day of a month; a command sent with the 1st, the 2nd
  and the 31st of a month behaves identically.
- `financial_cube.resolve_account_lines` returns the same leaf and ancestors as the cube for every
  `GOLD` account, including the override and the split account.
- `planning.can` under the interim rule: Hasura role `admin` passes; a company 9001 user passes
  every hotel action for `GOLD`; a company 9002 user fails all of them; an unentitled hotel fails.
  No planner table stores a role or grant.

### C3a Engine, patch, reads

Each on `GOLD`, with expected numbers computed by hand in the test:

- One check per method (`fixed` incl. spread profile and escalator, `per_unit`, `stat_chain`,
  `pct_of` on a line and on a set, `headcount` hourly and salaried, `flex`, `schedule`, `manual`).
- Effective dating: a component ended in May and its replacement from June give the right months.
- Period overrides beat defaults for that month only; clearing restores the default.
- Sets: members resolve through the override and the map; an `exclude` removes an account; closed
  months use actuals of all accounts, enabled or not.
- Paired stats: two wage lines writing one hours line sum correctly; adding a component to a
  collected stat line is rejected.
- Levels: a three-level chain (rooms → wages → payroll-related) calculates in one call; a patch
  that creates a cycle is rejected with a message naming the accounts.
- Actualization: closed months equal actuals and carry `source = 'actual'`; moving
  `closed_through` forward flips the next month.
- Write-through: after a patch, `cleaned.account_values` for `working` equals `result_line` for
  every non-zero monthly cell and has no extra rows; a second identical calculation writes 0 rows;
  a cell that becomes zero is deleted; a loaded (non-planner) row for the same key blocks the write.
- `apply_patch`: every op; all-or-nothing on a bad op; stale `row_version` raises `check_violation`;
  a user of another company cannot patch; the change log row has before, after and impact. Run
  these as `sp_test_app` with a session JSON, the way Hasura will call them.
- `preview_patch` returns the same `changed` as `apply_patch` would and stores nothing (row counts
  unchanged in every planner table and in `account_values`).
- `get_workspace` arrays align with `periods`; `primary_values` for closed months equal actual ÷
  driver actual; compare arrays equal `account_values` for the compare key.
- `get_driver_fit`: average error, bias and worst month match hand-computed values for two lines;
  candidates include the fixed-plus-per-room fit.

### C3b Setup, chart, templates

- `create_model` on `GOLD`: lines for every P&L and statistic account with actuals; none for the
  unmapped or balance-sheet account; stat pairs for the `-STAT` accounts; seeds match the table in
  `03-engine.md` §12 (assert method, driver and value for one account of each kind); the
  fallback-to-fixed rule fires for the account built to fit badly.
- `get_hotel_chart` filters and `attention` values; `can_enable` false with the right reason.
- `set_account_enabled`: enabling an account with no history creates a seeded line from the
  template's method; disabling ends contributions from that month and removes its fact rows from
  then on; an effective month in a closed period is rejected.
- `upsert_template_line`, `apply_template`, `get_operator_chart` paging and `total_rows`.
- `propose_stat_pairs` approves suffix pairs and leaves ambiguous ones unproposed.

### C3c Queue

- Enqueue coalesces: ten enqueues for one hotel leave one queued row with the latest `not_before`.
- Loading `actual` rows for `GOLD` enqueues it; loading rows with `fileid` starting `planning:`
  does not; loading rows for a hotel with no model does not.
- `run_recalc_queue` processes due rows only, marks `done`, records errors and stops after 3 attempts.
- Two concurrent workers never process the same row (two sessions, `SKIP LOCKED`).
- The cron script schedules the job as `postgres` in database `singlepane` and verifies it.

### C4 Scenarios

- **Copy:** editing the source afterward does not change the copy; advancing `closed_through`
  does. A `feed` component arrives in the copy as `manual` with the source's values.
- **Snapshot:** nothing changes it: source edits, actuals, mapping changes, queue runs.
- **Fork:** an unchanged parameter follows the source after the queue runs; a replaced parameter
  does not, and its change shows `source_moved` once the source differs; an `adjust_pct` line change
  tracks the source's new value; fork of a fork resolves; depth 4 is rejected.
- Fork of a snapshot is live (takes actuals).
- `detach_fork` leaves numbers unchanged and stops following.
- Limit: the sixth custom scenario for a hotel is rejected; archiving one frees a slot; budget and
  official scenarios do not count.
- Registry: `create_scenario` inserts the `cs_` row for the company; `get_available_versions`
  shows it to that company only; archive removes the fact rows and hides the row.
- `lock_official`: key resolution for monthly and weekly locks (assert three dates around a month
  boundary); budget lock for a year; the loaded-rows guard and `replace_loaded`; the validation row
  ends at `display_in_app = 1`.

### C5 Top line

- Monthly grain: typing rooms and ADR for a month changes revenue and every dependent expense.
- Daily grain: day cells sum to the month; days with daily actuals are not editable; rooms over
  capacity are rejected.
- Feed: the latest `as_of_date` per stay date is used; an override beats it; `fill_top_line` `feed`
  clears overrides.
- `transformers.ideas_busview` still loads on-the-books exactly as before (compare its
  `otb_segment` output before and after on a sample file) and now also fills
  `reservations.rms_forecast_segment`.
- Duetto: raw table, report type and transformer exist and load a sample file. **Blocked until a
  sample Duetto forecast export is provided**; ship the rest of C5 without it.

### C6 Ledger

- A GL-detail file for the fixture operator loads into `ledger.transaction` with the same
  `account_id` strings and signs as the trial balance loader produces; re-loading is idempotent;
  `zero_out` replaces the period.
- `ledger.reconcile` ties for accounts that match and reports the difference for one that does not.
- `match_transactions` matches by `vendor_key` when exactly one component fits and leaves the rest.
- `get_line_transactions` returns only the caller's hotels; totals are right; paging limit honored.

### C7 Agent surfaces

- Policy resolution picks the most specific row; no row → `suggest`.
- `agent_upsert_suggestion`: a valid patch gets `impact`; an invalid patch is rejected; under an
  autopilot policy a change inside the limits is applied and logged with `actor_type = 'autopilot'`,
  and one outside the limits is stored as `open`; the same `finding_key` updates, not duplicates.
- `resolve_suggestion`: accept applies and logs the approver; dismiss; answer creates a follow-up
  job; revert restores the previous numbers exactly.
- Each detector fires on a fixture built to trigger it and stays silent on one built not to.
- Agent-only functions are not executable by `sp_test_app`.

### H packages

Acceptance for H1–H5 is in `07-hasura-rebuild.md` §9, with the proof list in its §5. H1 is tested
on a reduced metadata fixture with no real URL or key in it.

### UI packages

Each: Jest specs pass (`npm test -- --ci --run-in-band --force-exit`), `npm run build` passes, and the
listed behavior works against the applied backend (or fixtures while the backend is pending).

| WP | Done when |
|---|---|
| U0 | The service returns grouped options for a hotel set; proforma hidden for management users; planner Compare select uses it |
| U1 | Module hidden without the flag and entitlement, reachable with both; direct URL without access redirects to `/exec`; home lists models; setup creates one and lands on the chart; `pf-anchors.spec.ts` passes |
| U2 | Tree renders departments, subtotals from the data layer, lines and components; the three views; a Rates edit round-trips and flashes changed cells; stale-version error path; drawer Drivers edits each method, add component, "new value from a date", set include/exclude; Activity lists changes; read-only without `can_update`; every write goes through `run()`; list view under 900px |
| U3 | Filters and counts; toggle with effective month; blocked reasons; attention rows; operator chart paging and edit |
| U4 | Switcher groups and labels; save-as with the three types and the limit; lock with the replace confirmation; fork banner, change list, detach; archive; banners per state; queued-recalculation polling |
| U5 | Monthly and daily grids; metric toggle; batched edits; capacity error shown inline; the three fill tools; month navigation in the URL |
| U6 | Fit figures and chart; suggestion card only when a suggestion exists; Transactions month picker, totals and tie-out line; empty state without a ledger |
| U7 | Cards by state; Apply, Edit, Dismiss, answer buttons, Undo; workspace updates after Apply; policy table; agent-unavailable message |
| U8 | Per converted screen: custom scenarios and working forecast appear for hotels that have them; labels of existing versions unchanged; existing specs pass |

## 5. Documentation deliverables (sp-core)

- `database/docs/planning/planning.md`: the module, its tables, how scenarios work, how to add a method.
- `database/docs/planning/runbook.md`: onboarding a hotel (template, stat pairs, create model),
  the queue (how to inspect and retry), locking, archiving, and what to check when numbers look wrong.
- `database/docs/financial_cube/version-registry.md` (C1).
- `database/docs/hasura/planning-metadata-apply.md`, modeled on `plans-actions-metadata-apply.md`.
- `database/docs/hasura/api-rebuild-runbook.md` (H1, completed by H2 and H5), and the "Functions"
  section of `database/README.md` rewritten once the old project is retired.
- Each update script's header names its canonical files, its order relative to the Hasura script
  and the ui Zeus regeneration, and carries a commented rollback block.
