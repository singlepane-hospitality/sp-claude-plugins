# Singlepane Planning v1 — build spec

**Status:** Spec, written 2026-11-18. Nothing is built. Decisions in §4 are Austin's; assumptions in
§5 are the author's defaults and are flagged for him. **Repos:** `sp-core` (this repo, database) and
`ui` (GitHub `sp-ui`, Angular). Contracts for other repos are in §8. The move to a new Hasura
(`07-hasura-rebuild.md`) touches every repo that calls the API.

The plan explains *why* in the brainstorm page (private artifact, "Singlepane Planning
Brainstorm") and in `mockup.html` here. These documents pin *what*, so the database and the UI can
be built in parallel by agents. Deviate only when something is impossible, and record the deviation
in the PR description.

## 1. Files

| File | Contents | Read it if you are building |
|---|---|---|
| `README.md` | Scope, decisions, assumptions, rules, other repos, open items | anything |
| `00-this-repo.md` | What the repo holding this copy builds from the plan (differs per repo) | anything, first |
| `01-version-registry.md` | Replacing hard-coded version lists; the one version list for dropdowns | C1, U0, U8 |
| `02-data-model.md` | Every new table | any sp-core package |
| `03-engine.md` | Methods, drivers, sets, calculation, write-through, scenarios, queue, seeding, driver fit | C3–C5, C7 |
| `04-api.md` | Function contracts, patch grammar, return types, Hasura | every package, both repos |
| `05-ui.md` | The Angular module: routes, screens, states, tests | U packages |
| `06-work-packages.md` | Build order, dependencies, acceptance, test method | planning the work |
| `07-hasura-rebuild.md` | The new Hasura for the whole app: what exists, the rebuilt metadata, proof, cutover, packages H1–H5 | H packages; anything that touches Hasura |
| `mockup.html` | Interactive mockup with mock data (four screens) and the design write-up | U packages, for behavior |

## 2. What is being built

A driver-based budgeting and forecasting module. An operator's finance team maintains a hotel's
forecast by setting **drivers** on GL accounts (a rate per occupied room, a percent of wages, a
headcount, an itemized schedule) instead of typing or loading numbers. The system calculates the
forecast from those drivers and from actuals, keeps it current as actuals and feeds arrive, shows
it live everywhere the product shows a forecast, and lets people save named scenarios.

Shape of the solution:

- **Postgres does the calculation.** A new `planning` schema holds drivers, scenarios and results.
  A set-based PL/pgSQL engine recalculates one hotel in one scenario per call.
- **It plans at the grain the fact table already uses:** hotel × operator GL account × period,
  the same `account_id` strings as `cleaned.account_values`. USALI rollups come from the existing mapping.
- **Results are written through to the fact tables** under a version key, so the cube, every
  screen, Excel and MCP read planner numbers with no new read path. The working forecast is the
  version `working`.
- **A version registry** replaces the hard-coded version lists, so `working` and custom scenarios
  are first-class and every dropdown reads one list.
- **One write path.** The grid, the agent and later MCP tools all change the forecast through the
  same patch logic. Nothing writes result cells directly. Writes are database functions exposed
  as mutations, each with its own permission (`04-api.md` §1).
- **One API for the whole app, rebuilt.** A new Hasura with function-permission inference off
  replaces the current endpoint. All existing metadata is rebuilt under it with a permission on
  every function, and every client moves to it (`07-hasura-rebuild.md`). The planner is one more
  module on that API.
- **The UI is one workspace:** the P&L as an editable tree grid with a line drawer, plus a top-line
  grid, a chart-of-accounts screen and a suggestions inbox.

## 3. Where things stand in the codebase (verified 2026-11-18)

- `cleaned.account_values`: 88M rows, key `(code, time, version, account_id)`, version is free text,
  loads overwrite, no history.
- PR 114 (single-pass cube) is a draft, not applied. It resolves account → line at read time from
  `mapping_override` / `account_map` and `account_ancestor_map`. `account_map_cache` is being
  retired; **nothing in the planner may read it.**
- Version names are hard-coded in two whitelists, a precedence ladder, the future insights
  resolver and a validation gate repeated in about a dozen functions (inventory in `01`).
- `reference.usali` has `dept`, `category`, `cashflow_type`, and a `default_metric` +
  `default_metric_denominator` for almost every line. The planner uses these for grouping, sets and seeding.
- Stat accounts: some operators have their own; for stat ledgers the loader appends `-STAT` or
  `-STAT-ACCT` to the amount account.
- `financial_cube.mgr_chart_of_accounts`: 52,031 accounts for 41 management companies;
  `parent_account` is empty.
- `raw.ideas_busview` already lands IDeaS forecast columns that nothing reads.
- No transaction table exists. No partitioned table exists in SPH.
- The ui repo is Angular 19 with PrimeNG, `ave-*` atoms, AG Grid Enterprise 35 and a Zeus GraphQL
  client. Version pickers are hard-coded in `src/domain/`.
- Hasura runs with inferred function permissions. `database/README.md` says that keeps volatile
  functions from non-admin roles; the live metadata nevertheless exposes seven of them to `user`
  by explicit permission, and one was tested live (`07-hasura-rebuild.md` §2). The endpoint is
  written into five repos. App-wide permissions are being rebuilt as module-based
  roles (`docs/workbench/permissions-unification-rbac-response.md`); they are not live yet.

## 4. Decisions (Austin, 2026-11-18)

| # | Topic | Decision |
|---|---|---|
| D1 | First user | An operator, replacing ProfitSword or with no tool today. No approval workflow in v1. |
| D2 | Owner and operator forecasts for the same hotel and month | Potentially. The registry carries an author from day one; owner screens are not in v1. |
| D3 | Live forecast | The working forecast shows everywhere (dashboards, Excel, MCP), as ProfitSword's does. |
| D4 | Labor | GL-account level, built from components (1 FTE supervisor + 0.5 hours per occupied room at $20). No positions, schedules or payroll feed. |
| D5 | Accounting systems | Assume M3, Sage, PeopleSoft. When the owner is the customer, GL extract reports. |
| D6 | Top line | IDeaS and Duetto to start. Monthly-grain top line must be an option. |
| D7 | Group definites and tentatives | Eventually; not v1. |
| D8 | Autopilot | Set by threshold and by account. |
| D9 | Calendar | Calendar year; rolling 12, 18 or 24 months; trailing-12 lookback; no 13-period calendars. |
| D10 | Below GOP from contract and loan data | Not in v1. |
| D11 | Migration | A ProfitSword setup may be a starting point; the goal is better drivers than they have. |
| D12 | Multi-property allocations, multi-currency | Not in v1. |
| D13 | Sets and grouping without operator hierarchies | Sets of GLs must drive other accounts; GLs are grouped by type. Use the USALI mapping. |
| D14 | Stat accounts | Stat chains write both the stat GL and the amount GL. |
| D15 | Chart of accounts | Review and edit the full chart; enable and deactivate accounts for forecast and budget; a hotel can start using a new GL. |
| D16 | Mapping cache | `account_map_cache` is going away; assume every cube reader comes off it; the planner does not wait. |
| D17 | Driver fit | A drawer tab showing driver accuracy over the last 12 months, with average error. Suggestions are AI-driven, like the agent's others. |
| D18 | Scenarios | Custom scenarios can be saved, locked and snapshotted; dropdowns list whatever exists. |
| D19 | Scenario scope and limit | Defined per company. Five custom scenarios per hotel for now. |
| D20 | Making a scenario | Three options from any scenario. **Copy:** full copy, does not follow its original, still updates with actuals. **Fork:** follows its original. **Snapshot:** fully locked, does not update with actuals. |
| D21 | Latest forecast | The working forecast is its own version. `latest_forecast` keeps resolving to the latest locked forecast (`forecastN`, `forecastN.M`), with no change to the ladder. |
| D22 | Permissions | Everyone is Hasura role `user`. Reading and editing the planner is a module entitlement plus a per-user permission assignment in the app-wide model being built. No planner-specific role table. |
| D23 | Writes | Hasura infers function permissions, so volatile functions are unusable by non-admins. The UI cannot write through tracked functions on the main API. *The premise is under check: see `07-hasura-rebuild.md` §2.* |
| D24 | Planner API | *Superseded by D25.* Create a new Hasura API specific to the planner, with function-level permissions, so its volatile functions can be mutations for ordinary users. |
| D25 | One app API | Make a new Hasura with function-permission inference off, rebuild the entire existing metadata under it so function permissions can be used, and replace the API endpoint for the whole app. In scope. |

## 5. Assumptions (the author's defaults; flag if wrong)

| # | Assumption | Where it bites | To flip it |
|---|---|---|---|
| A1 | Planner month keys are the 2nd of the month, the fact tables' convention, normalized by `planning.month_key` | `02` conventions | Change the helper; nothing else stores a literal day |
| A2 | Owner-authored versions are private to the owner; not built in v1 | `01` §2 | — |
| A3 | Until the app-wide permission model ships, every entitled user of the company that owns a model may read and edit it, and the UI flag hides the module (the Plans & Actions approach) | `04` §1.1 | Nothing to flip: `planning.can` reads the evaluator views once they exist |
| A4 | Stat pairings for operators with their own stat GLs are approved by Singlepane staff at onboarding | `04` §1.1, `05` §12 | Put `set_stat_pair` under `planning.standard.update` |
| A5 | In a copy, feed-driven lines freeze at their values when copied | `03` §10 | Copy `feed` components unchanged |
| A6 | Driver methods are a catalog table (`planning.method`) carrying labels and parameter rules; driver types and the other small enumerations stay `CHECK` constraints | `02` §3 | Replace the catalog with a `CHECK` |
| A13 | The command table is built only if the check in `07` §2 fails and the new API is not live when the first write ships | `04` §1.4, `02` §9 | Build the two fallback tables; in the UI only `run()` changes |
| A7 | Budget drafts are copies that do not take actuals; one official `budget` per hotel and year | `03` §10, `04` §4 | — |
| A8 | New tables use `gen_random_uuid()`, not the README's `uuid_generate_v4()` | `02` conventions | Change the default; keep seeds after `RESET ROLE` either way |
| A9 | Operator standards carry method and driver, not values; values come from the hotel's history; no automatic propagation to hotels | `02` §1, `04` §2 | — |
| A10 | The engine recalculates a hotel's open periods in full on every patch | `03` §6 | Implement the dirty-set path behind `p_line_ids` |
| A11 | Subtotals and KPIs in the workspace come from the existing data layer by version key, not from a new rollup | `04` §3, `05` §6.1 | — |
| A12 | The first usable release is C1–C4 + U0–U4; top line beyond monthly entry, ledger and agent follow | `06` §2 | Reorder |
| A14 | Planner packages do not wait for the new API: a volatile function with an explicit permission already runs for `user` on the current one, and the metadata entries are the same on both | `07` §2, `06` §2 | If Austin's check fails, U1 and later UI packages depend on H4, or use A13 |
| A15 | The new API gives every role exactly the functions it reaches today; trimming comes after the move | `07` §4.3 | Edit the exposure matrix before H3 |
| A16 | The new project keeps the current database logins, JWT configuration and engine version | `07` §4.1 | Separate changes, after cutover |

## 6. Scope

**In v1**

- Version registry; `working`; one version list for dropdowns.
- One app API: a new Hasura with explicit function permissions, the existing metadata rebuilt
  under it, and every client moved to its endpoint (`07-hasura-rebuild.md`, packages H1–H5).
- Chart of accounts: operator chart, per-hotel enable and deactivate with dates, stat pairing.
- Drivers: `fixed`, `per_unit`, `stat_chain`, `pct_of`, `headcount`, `flex`, `schedule`, `manual`,
  `feed`; several dated components per line; month overrides; sets from USALI nodes with includes
  and excludes; monthly spread profiles.
- History seeding from each hotel's own actuals, guided by `reference.usali` default metrics and
  the operator standard.
- Engine with actualization, write-through and a recalculation queue.
- Scenarios: working, fork, copy, snapshot, budget drafts, official locks to `forecastN`,
  `forecastN.M` and `budget`; archive; five custom per hotel.
- Top line by month, by day, and by day and segment; IDeaS feed; Duetto landing.
- Ledger: GL-detail files into `ledger.transaction`, matching to components, drill-through.
- Driver fit figures; suggestions, policies and findings as database surfaces; the inbox.
- UI: workspace with line drawer, top line, chart of accounts, inbox, scenario dialogs, setup.

**Not in v1**

- Approval workflow. Planner-specific roles or grants (permissions come from the app-wide model). Owner screens.
- During the API move: changing who can reach which function or table, the database logins Hasura
  uses, or the Hasura engine version. The move is like-for-like.
- Delphi definites and tentatives. Below-GOP lines seeded from contracts and loans (they are
  ordinary typed lines). Shared-service allocations. Multi-currency. Operator presentation hierarchies.
- API connectors to accounting systems (files first). Positions, schedules, payroll feeds.
- ProfitSword driver import (needs a sample export; design after C3b).
- The agent service itself (sp-ai-backend, §8). Policy editing UI. A chat transcript UI.
- Daily storage of monthly lines; pickup-based top-line baseline; flex budget screen.
- Portfolio views of planner scenarios beyond what the existing screens show by version key.

## 7. Rules for whoever builds this

### 7.1 sp-core

- **Never apply anything to prod.** The URLs in `.env` are read-only. Austin applies scripts as
  `sp_admin` and applies Hasura metadata. Prove work on a scratch Postgres 17 (`06` §3).
- Read-only prod queries for sizing are fine with a `statement_timeout`. Never read
  `financial_cube.financial_data_status` (the base table); read `financial_data_status_mv`.
- Update scripts: `database/sph/singlepane/updates/YYYYMMDD-NN-<kebab>.sql`; header box as in
  `20261105-04-generic-settings.sql`; one transaction; DDL under `SET ROLE sp_object_owner`;
  **`RESET ROLE` before any statement that inserts rows**; every function body ends `$function$;`
  (many canonical files end with a bare `$function$`; do not copy that); comments on every object;
  idempotent (`IF NOT EXISTS`, `OR REPLACE`, guarded constraints); a commented rollback block; a
  final `DO` block that verifies overloads and privileges.
- Check who owns an existing object before changing it (`pg_get_userbyid(proowner)`,
  `pg_tables.tableowner`). Most `financial_cube` objects are owned by `postgres`: replace them
  after `RESET ROLE`, and never `ALTER FUNCTION … RENAME` or `OWNER TO` them.
- New schema (`planning`, `ledger`): `CREATE SCHEMA`, `ALTER SCHEMA … OWNER TO sp_object_owner`,
  `GRANT USAGE … TO sp_user_readonly`, `GRANT ALL PRIVILEGES ON SCHEMA … TO sp_developer`, and
  `ALTER DEFAULT PRIVILEGES FOR ROLE sp_object_owner IN SCHEMA … GRANT EXECUTE ON ROUTINES TO sp_user_readonly`
  (new schemas fail closed for EXECUTE since 20261005). Add the schema bootstrap file
  `schemas/<schema>/<schema>.sql`.
- Canonical files under `schemas/` change in the same PR as the update script. `_rt` tables go in
  `tables/` and carry no keys, constraints or audit columns.
- Hasura metadata is edited by a script in `database/hasura/scripts/`, never by hand; the diff must
  be pure additions. Do not copy webhook URLs or keys into scripts.
- Planner objects are tracked on the app's Hasura API like any module's, by a script. Every
  tracked function gets an explicit permission for role `user`, queries included: the new API
  requires it (`07-hasura-rebuild.md` §4.3) and the current one accepts it.
- Agents never hold an admin secret, apply metadata, or copy a webhook URL or key
  (`07-hasura-rebuild.md` §10).
- A STABLE function cannot create temp tables or write. Anything that does is VOLATILE and a mutation.
- Permissions are not the planner's to define. Do not add role, grant or membership tables under
  `planning`; ask the one function `planning.can` (`04-api.md` §1.1).
- pg_cron changes are scripts under `database/sph/postgres/updates/`; jobs run as `postgres` in
  database `singlepane`.
- A function that calls the financial cube sets its own planner settings and passes the
  `db-work-mem` skip, as the existing `app.*` callers do. Planner functions read
  `cleaned.account_values` directly and should not need to.
- Fixtures are synthetic. No client data, hotel names or account values in the repo.
- Git: branch from `main` (`feat/planning-<wp>`), draft PR to `main`, merged with a merge commit.
  Do not commit to `main`.

### 7.2 ui

`05-ui.md` §1. In short: Angular 19 standalone components, `ave-*` atoms, `ZeusService`, npm only,
no new dependencies, gate with the flag and the entitlement and a route guard, phone-friendly,
Jest specs, PR to `stage` with a Conventional Commit title, and follow that repo's `CLAUDE.md`.

## 8. Other repos

Not specified here in full; these are the contracts they build against.

**sp-ai-backend — forecast agent service**

- Trigger: Hasura event on `planning.agent_job` insert (`04` §9). Job types: `review_findings`
  (after a month closes or a ledger load, enqueued by the database), `chat_patch` (a person's
  request from the inbox), `answer_followup`.
- Reads: `planning.agent_get_findings`, `planning.agent_explain_line`; contracts, comments and
  transactions through its existing tools.
- Writes: only `planning.agent_upsert_suggestion` and `planning.agent_finish_job`. It never writes
  planner tables or result cells, and it never calls `apply_patch` itself; autopilot is applied by
  `agent_upsert_suggestion` under the account's policy.
- The engine supplies every number the agent quotes (`agent_preview_patch` for impact, the fit score
  for kind `fit`). The agent supplies the judgment: what the miss is, what to propose, what to ask.
- Questions to people go through Scout's commentary thread; the answer comes back as
  `planning.resolve_suggestion(action => 'answer')`.
- Model calls go through that repo's LLM helper, not a provider SDK.
- MCP tools for customers (`explain_line`, `preview_patch`, `apply_patch`, `list_suggestions`,
  `compare_scenarios`) wrap the same functions later.

**Hasura — one app API (D25)**

- A new Hasura with function-permission inference off replaces the current endpoint for every
  client. Scope, method and packages: `07-hasura-rebuild.md`. The planner needs no API of its own.
- Per repo, the move is a change of endpoint and secret (`07` §7.3): `ui`, `ave-serverless`,
  `sp-ai-backend`, `singlepane-excel`, `sp-office-addins`, and `sp-api` once its question is
  answered. `sp-core` holds the generator, the comparison script and the runbook.

**ave-serverless — loaders, event receivers, sign-in**

- GL-detail and RMS files arrive through the existing report-type pipeline (`02` §5–§6, `03` §9);
  new report types are configuration plus the transformers in sp-core.
- It receives Hasura event triggers and actions, issues the token claims and hosts the
  impersonation authorizer, so it moves first in the cutover (`07` §7.1).

**singlepane-excel — add-in**

- Version arguments must accept any registry key. Version pickers call
  `financial_cube_get_available_versions`. No function output changes.
- The API host is a constant in two source files; it changes once, in H4.

**sp-office-addins — Word and PowerPoint add-in**

- The same two changes: version lists from the registry function, and the API host in H4.

**sp-internal-ops — staff MCP**

- Tools that validate or list versions read the registry. Report types for GL-detail and Duetto
  files are set up with the existing report-type tools. It does not call the app API.

**sp-ai-backend / sp-claude-plugins — existing MCP tools and skills**

- Wherever a tool validates or lists versions, read the registry function. `get_data_availability`
  keeps its own list in v1 (noted in `01` §3.2).

**Legacy database**

- No change. Planner versions arrive in the nightly copy and are ignored until legacy's own version
  lists learn the keys.

## 9. Open items for Austin

Blocking a specific package:

| Item | Blocks |
|---|---|
| PR 114 applied and merged (its scripts need renumbering against `main`) | C1 and everything after |
| Name the hotel for the real-hotel seeding check | C3b sign-off |
| A sample Duetto forecast export | The Duetto part of C5 |
| A sample GL-detail export from M3, Sage and PeopleSoft, one each | Real report types in C6 (the generic transformer does not wait) |
| Run the check in `07` §2 (does the current API already run a volatile function for `user`?) and decide whether the API move goes ahead now | Whether UI packages that write depend on H4 (A14) |
| The new Hasura project (D25): who creates it, its plan and domain, the current project's environment for comparison, where the new metadata lives, the event trigger rehearsal, the public API's Hasura (`07` §10) | H2 and everything after it |
| The app-wide permission model: register the planner's actions (`04` §1.1) and switch `planning.can` when it ships | Real per-user permissions; until then the interim rule (A3) applies |
| Agent service spec and its webhook | C7 end to end, U7 "Ask the agent" |

Not blocking (defaults in §5): A1–A16.

## 10. Revisions

Append dated subsections here; do not rewrite decisions in place.

### 2026-11-18, second pass (Austin's review)

- **Latest forecast (D21).** `working` is off the ladder; the future insights resolver is
  unchanged. Was assumption A1.
- **Permissions (D22).** `planning.user_role` removed. Access is the module entitlement plus the
  app-wide permission model, asked through `planning.can`, with an interim rule until that model
  ships. The planner lists the action keys it needs. Capability booleans replace roles in the API
  and UI.
- **Writes (D23).** Tracked volatile functions replaced by `planning.command`: the UI inserts a
  row and a trigger runs the command. `preview_patch` is a command too. Errors a person can cause
  all use `check_violation`.
- **Month keys.** Planner months are now the 2nd of the month, matching the fact tables, with one
  normalizing helper.
- **Methods.** `planning.method` catalog table added; driver types stay a `CHECK`.

### 2026-11-18, third pass

- **Planner API (D24).** Austin: create a new Hasura API specific to the planner with
  function-level permissions. Writes are volatile functions exposed as mutations there, and reads
  move there too. The command table from the second pass is kept only as a fallback (A13,
  `04` §1.4, `02` §9). New prerequisite H0 and open items in §9. The UI gains a second endpoint
  and a second generated client.

### 2026-11-18, fourth pass

- **One app API (D25).** Austin: instead of a Hasura API for the planner only, make a new Hasura
  with function-permission inference off, rebuild the entire existing metadata under it, and
  replace the endpoint for the whole app; part of this scope. New document `07-hasura-rebuild.md`
  and packages H1–H5 replace H0. D24 is superseded. The planner goes back to one endpoint and the
  app's generated client; its own database login is dropped.
- **Finding recorded with it (`07` §2).** The current API already exposes seven volatile functions
  to `user` by explicit permission, and the deal model scenario push was tested live through one
  of them. If Austin's check confirms it, planner writes do not need the new API (A14) and the
  move rests on its own reasons. The check's result goes here when it is run.
