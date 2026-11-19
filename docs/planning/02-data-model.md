# Planning v1 — 02 Data model

Tables for the planner. Behavior is in `03-engine.md`; functions in `04-api.md`; the version
registry table is in `01-version-registry.md`.

## Conventions used below

- New schemas: `planning` and `ledger`. One new table in `reservations`.
- The DDL below is shorthand for column lists and constraints. Write the real scripts in the
  repo's style (`database/README.md`, and `updates/20261105-01-*.sql` as the model): upper-case
  keywords, `TEXT COLLATE pg_catalog."default"`, named constraints (`<table>_pkey`,
  `<table>_<col>_fkey`, `<table>_<col>_check`, `<table>_<cols>_unique`, `<table>_<purpose>_uq`,
  `<table>_<purpose>_idx`, `fki_<table>_<col>`), guarded foreign keys, a comment on every table,
  column, constraint and index, and the grant lines at the end of each table block.
- Surrogate key first, named `<table>_id`, `UUID DEFAULT gen_random_uuid() NOT NULL`. This departs
  from the README's `uuid_generate_v4()` on purpose: planner rows are inserted by triggers and by
  the queue worker under whatever role fired them, and `sp_object_owner` cannot execute
  `uuid_generate_v4()` on prod. Seeds still go after `RESET ROLE`.
- `-- audit` stands for the four standard columns, last in the table, in the repo's order:
  `created_by UUID`, `created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL`,
  `updated_by UUID`, `updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL`, with triggers
  `<table>_created BEFORE INSERT ... utility.set_created()` and
  `<table>_updated BEFORE UPDATE ... utility.set_updated()`. They hold `auth.user_list.id`; null
  for system writes.
- Enumerations are `TEXT` with a `CHECK`, not Postgres enums.
- Partitioned tables are new to this repo (`planning.result_*`, `ledger.transaction`). Create the
  parent and its partitions in the same script and keep one canonical file per parent that also
  lists its partitions.
- A month is identified by its **month key**: the 2nd of the month as a `DATE`, the convention of
  `cleaned.account_values`, `financial_cube.rooms_available` and the status tables.
  `planning.month_key(date)` returns it for any date, and every function that takes a month applies
  it, so nothing depends on a caller sending the right day. A `date` column below holds month keys
  unless its comment says "day". Days are real dates. Month bounds (`enabled_from`,
  `effective_to`, …) are compared against a daily period's month key.
- Every table gets `COMMENT ON TABLE` and comments on non-obvious columns.
- No table here is tracked in Hasura for insert, update or delete. Reads and writes go through
  the functions in `04-api.md`, tracked on the app's Hasura API with a permission on each
  function. `planning.method` and the `_rt` return tables are tracked for select.
- Who may do what is **not** stored in this schema. Permissions come from the app-wide model
  (`docs/workbench/permissions-unification-rbac-response.md`) through `planning.can`
  (`04-api.md` §1.1). Do not add role, grant or membership tables under `planning`.
- Follow the ownership, grant and script rules in `README.md` §7 (DDL under `sp_object_owner`,
  seeds after `RESET ROLE`).

Columns marked `-- FK` reference the named table with `ON DELETE RESTRICT` unless stated.

## 1. Setup

```sql
CREATE TABLE planning.template (                 -- an operator's standard driver set
  template_id   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    integer NOT NULL,                -- auth.company.id (the operator)
  mgmt_code     text NOT NULL,                   -- account prefix, e.g. 'MAR'; the operator chart is every account whose first '-' segment equals it
  name          text NOT NULL,
  description   text,
  active_flag   boolean NOT NULL DEFAULT true,
  -- audit
  UNIQUE (company_id, mgmt_code)
);

CREATE TABLE planning.template_line (            -- planning attributes of one operator account
  template_line_id  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id       uuid NOT NULL,               -- FK planning.template ON DELETE CASCADE
  account_id        text NOT NULL,               -- operator account string
  default_enabled   boolean NOT NULL DEFAULT false,
  retired           boolean NOT NULL DEFAULT false,   -- cannot be enabled at any hotel
  method            text,                        -- FK planning.method
  driver_type       text CHECK (driver_type IN ('none','line','set','calendar','rooms_available')),
  driver_account_id text,                        -- when driver_type = 'line': the driver's account string
  driver_usali_node text,                        -- when driver_type = 'set'; may contain {dept}
  driver_key        text,                        -- when driver_type = 'calendar'
  notes             text,
  -- audit
  UNIQUE (template_id, account_id)
);

CREATE TABLE planning.model (                    -- one hotel on the planner
  model_id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code                   text NOT NULL UNIQUE,   -- reference.hotel code
  company_id             integer NOT NULL,       -- the company that owns and edits the model
  template_id            uuid,                   -- FK planning.template
  status                 text NOT NULL DEFAULT 'setup' CHECK (status IN ('setup','active','archived')),
  horizon_months         integer NOT NULL DEFAULT 12 CHECK (horizon_months IN (12,18,24)),
  top_line_grain         text NOT NULL DEFAULT 'month' CHECK (top_line_grain IN ('month','day_total','day_segment')),
  occupied_rooms_set_id  uuid,                   -- FK planning.driver_set, set after the set exists
  closed_through         date,                   -- month key of the last closed month
  closed_through_override date
  -- audit
);

```

## 2. Chart, lines and pairing

```sql
CREATE TABLE planning.line (                     -- one account enabled (now or before) at a hotel
  line_id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id         uuid NOT NULL,                -- FK planning.model ON DELETE CASCADE
  account_id       text NOT NULL,                -- same string as cleaned.account_values.account_id
  kind             text NOT NULL CHECK (kind IN ('amount','stat')),
  grain            text NOT NULL DEFAULT 'month' CHECK (grain IN ('month','day')),
  stat_line_id     uuid,                         -- FK planning.line: where this amount line's statistic is written
  stat_unit        text CHECK (stat_unit IN ('hours','covers','rooms','guests','other')),
  enabled_from     date NOT NULL,                -- month key: first month in the forecast
  disabled_from    date,                         -- month key: first month out of it; null = still enabled
  owner_user_id    uuid,
  template_line_id uuid,                         -- FK planning.template_line ON DELETE SET NULL
  seeded_at        timestamptz,
  -- audit
  UNIQUE (model_id, account_id),
  CHECK (disabled_from IS NULL OR disabled_from > enabled_from),
  CHECK (kind = 'amount' OR stat_line_id IS NULL)
);

CREATE TABLE planning.stat_pair (                -- operator-chart pairing of an amount account with its stat account
  stat_pair_id       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  amount_account_id  text NOT NULL UNIQUE,
  stat_account_id    text NOT NULL,
  unit               text NOT NULL CHECK (unit IN ('hours','covers','rooms','guests','other')),
  source             text NOT NULL CHECK (source IN ('suffix','proposed','created','manual')),
  status             text NOT NULL DEFAULT 'approved' CHECK (status IN ('proposed','approved','rejected'))
  -- audit
);

CREATE TABLE planning.driver_set (               -- a USALI node as a driver, per hotel
  driver_set_id  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id       uuid NOT NULL,                  -- FK planning.model ON DELETE CASCADE
  usali_node     text NOT NULL,                  -- reference.usali.usali
  variant        text NOT NULL DEFAULT '',       -- '' = the plain node; a name when it carries adjustments
  name           text NOT NULL,
  -- audit
  UNIQUE (model_id, usali_node, variant)
);

CREATE TABLE planning.driver_set_adjust (        -- includes and excludes on a set
  driver_set_adjust_id  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_set_id         uuid NOT NULL,           -- FK planning.driver_set ON DELETE CASCADE
  account_id            text NOT NULL,
  action                text NOT NULL CHECK (action IN ('include','exclude')),
  -- audit
  UNIQUE (driver_set_id, account_id)
);

CREATE TABLE planning.spread_profile (           -- month weights for annual amounts
  spread_profile_id  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id           uuid NOT NULL,              -- FK planning.model ON DELETE CASCADE
  name               text NOT NULL,
  source             text NOT NULL CHECK (source IN ('flat','days','last_year','three_year_avg','typed')),
  weights            numeric[] NOT NULL CHECK (array_length(weights, 1) = 12),   -- sums to 1
  -- audit
  UNIQUE (model_id, name)
);

CREATE TABLE planning.top_line_segment (         -- the rows of a hotel's top line
  top_line_segment_id  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id             uuid NOT NULL,            -- FK planning.model ON DELETE CASCADE
  segment_key          text NOT NULL,            -- 'total' or an sp segment key
  label                text NOT NULL,
  rooms_line_id        uuid NOT NULL,            -- FK planning.line (kind stat, unit rooms)
  revenue_line_id      uuid NOT NULL,            -- FK planning.line (kind amount)
  source               text NOT NULL DEFAULT 'manual' CHECK (source IN ('manual','ideas','duetto')),
  source_segments      text[],                   -- feed segment names that roll into this row
  sort_order           integer NOT NULL DEFAULT 0,
  -- audit
  UNIQUE (model_id, segment_key)
);
```

Notes:

- The **operator chart** is not a new table. It is the union of `financial_cube.mgr_chart_of_accounts`
  rows for the operator and accounts in `financial_cube.account_map` with the template's
  `mgmt_code` prefix, left-joined to `planning.template_line`. Descriptions and departments stay in
  `mgr_chart_of_accounts`.
- A line's **USALI leaf, department and category are not stored**. They are resolved on read with
  `financial_cube.resolve_account_lines` and `reference.usali`.
- `stat_pair` is global, like `account_map`: one pairing serves every hotel on that chart. When a
  hotel line is created for an amount account that has an approved pair, the stat account becomes
  a `kind = 'stat'` line of the same model (created if missing) and `stat_line_id` points at it.

## 3. Scenarios and inputs

```sql
CREATE TABLE planning.method (                   -- catalog of driver methods
  method            text PRIMARY KEY,            -- 'fixed','per_unit','stat_chain','pct_of','headcount','flex','schedule','manual','feed'
  label             text NOT NULL,               -- what the method picker shows
  description       text NOT NULL,
  driver_rule       text NOT NULL CHECK (driver_rule IN ('required','forbidden')),
  driver_types      text[],                      -- allowed driver_type values when required
  required_params   text[] NOT NULL,             -- e.g. {p_ratio,p_rate}
  optional_params   text[] NOT NULL DEFAULT '{}',
  produces_stat     boolean NOT NULL DEFAULT false,
  user_selectable   boolean NOT NULL DEFAULT true,   -- false for 'feed'
  sort_order        integer NOT NULL DEFAULT 0,
  active_flag       boolean NOT NULL DEFAULT true
  -- audit
);

CREATE TABLE planning.scenario (                 -- a named version of the plan, per company
  scenario_id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          integer NOT NULL,
  name                text NOT NULL,
  kind                text NOT NULL CHECK (kind IN ('working','budget','custom','official')),
  made_as             text NOT NULL CHECK (made_as IN ('root','fork','copy','snapshot')),
  source_scenario_id  uuid,                      -- FK planning.scenario
  version_key         text NOT NULL,             -- financial_cube.version_registry.version_key
  plan_year           integer,                   -- budget and official scenarios
  takes_actuals       boolean NOT NULL,
  published           boolean NOT NULL DEFAULT true,
  archived_at         timestamptz
  -- audit
);
CREATE UNIQUE INDEX scenario_company_name_uq ON planning.scenario (company_id, lower(name)) WHERE archived_at IS NULL;
CREATE UNIQUE INDEX scenario_one_working_uq  ON planning.scenario (company_id) WHERE kind = 'working' AND archived_at IS NULL;

CREATE TABLE planning.scenario_hotel (           -- a scenario's state at one hotel
  scenario_hotel_id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id            uuid NOT NULL,          -- FK planning.scenario ON DELETE CASCADE
  model_id               uuid NOT NULL,          -- FK planning.model ON DELETE CASCADE
  period_start           date NOT NULL,
  period_end             date NOT NULL,
  state                  text NOT NULL DEFAULT 'live' CHECK (state IN ('live','locked')),
  locked_at              timestamptz,
  locked_by              uuid,
  frozen_closed_through  date,                   -- closed_through at the moment a snapshot was taken
  last_calc_at           timestamptz,
  last_calc_run_id       uuid,
  -- audit
  UNIQUE (scenario_id, model_id)
);

CREATE TABLE planning.component (                -- one building block of a line in one scenario
  component_id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id          uuid NOT NULL,            -- FK planning.scenario ON DELETE CASCADE
  line_id              uuid NOT NULL,            -- FK planning.line ON DELETE CASCADE
  label                text NOT NULL,
  method               text NOT NULL,            -- FK planning.method
  driver_type          text NOT NULL DEFAULT 'none' CHECK (driver_type IN ('none','line','set','calendar','rooms_available')),
  driver_line_id       uuid,                     -- FK planning.line
  driver_set_id        uuid,                     -- FK planning.driver_set
  driver_key           text CHECK (driver_key IN ('days','weekdays','weekend_days','one')),
  p_ratio              numeric,
  p_rate               numeric,
  p_amount             numeric,
  p_pct                numeric,
  p_fte                numeric,
  p_hours              numeric,
  p_base_driver        numeric,
  p_escalator_pct      numeric,
  p_escalator_month    integer CHECK (p_escalator_month BETWEEN 1 AND 12),
  spread_profile_id    uuid,                     -- FK planning.spread_profile
  contributes_stat     boolean NOT NULL DEFAULT true,
  effective_from       date,
  effective_to         date,
  vendor_key           text,                     -- normalized vendor, for matching ledger transactions
  origin               text NOT NULL DEFAULT 'user' CHECK (origin IN ('user','template','seed','agent','import','copy')),
  source_component_id  uuid,                     -- the component this one was copied from (lineage; fork changes match on it)
  sort_order           integer NOT NULL DEFAULT 0,
  notes                text,
  row_version          integer NOT NULL DEFAULT 1,   -- incremented on every update; optimistic concurrency
  -- audit
  CHECK (effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from),
  CHECK ((driver_type = 'line') = (driver_line_id IS NOT NULL)),
  CHECK ((driver_type = 'set')  = (driver_set_id  IS NOT NULL)),
  CHECK ((driver_type = 'calendar') = (driver_key IS NOT NULL))
);
CREATE INDEX component_scenario_line_idx ON planning.component (scenario_id, line_id);

CREATE TABLE planning.component_period (         -- sparse per-period overrides, and scheduled / typed / daily values
  component_period_id  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  component_id         uuid NOT NULL,            -- FK planning.component ON DELETE CASCADE
  period               date NOT NULL,            -- month key, or the day for daily lines
  field                text NOT NULL CHECK (field IN ('ratio','rate','amount','pct','stat')),
  value                numeric NOT NULL,
  -- audit
  UNIQUE (component_id, period, field)
);

CREATE TABLE planning.scenario_change (          -- what a fork changes relative to its source
  scenario_change_id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id             uuid NOT NULL,         -- the fork; FK planning.scenario ON DELETE CASCADE
  model_id                uuid NOT NULL,         -- FK planning.model ON DELETE CASCADE
  target_type             text NOT NULL CHECK (target_type IN ('component_param','component_remove','line_value')),
  source_component_id     uuid,                  -- the source scenario's component (by its lineage id)
  line_id                 uuid,                  -- for line_value
  field                   text CHECK (field IN ('ratio','rate','amount','pct','fte','hours','base_driver','value')),
  op                      text CHECK (op IN ('replace','adjust_pct','adjust_amount')),
  value                   numeric,
  period_from             date,                  -- null = all periods
  period_to               date,
  source_value_at_change  numeric,               -- to flag when the source has since moved
  note                    text
  -- audit
);
```

`planning.method` is seeded with the nine methods (seed after `RESET ROLE`; source in
`seeds/planning-methods/01-seed.sql`). It gives the UI its picker and gives
`planning.validate_component` its rules, so labels and parameter rules are data. A new method
still needs a formula in the engine (`03-engine.md` §3); the table does not make methods
configurable. Driver types, grains and the other small enumerations stay `CHECK` constraints,
because each value is tied to its own column or code path.

Method and parameter requirements, as seeded (enforced by `planning.validate_component`, called by every write path):

| Method | Requires | Forbids |
|---|---|---|
| `fixed` | `p_amount` | driver |
| `per_unit` | driver, `p_rate` | |
| `stat_chain` | driver, `p_ratio`, `p_rate` | |
| `pct_of` | driver (`line` on an amount line, or `set`), `p_pct` | |
| `headcount` | `p_fte`, and either (`p_hours`, `p_rate`) or `p_amount` | driver |
| `flex` | driver, `p_amount`, `p_pct` between 0 and 100, `p_base_driver` > 0 | |
| `schedule` | at least one `amount` period row | driver, `p_*` |
| `manual` | nothing | driver |
| `feed` | the line is in `top_line_segment` with a feed source | driver |

## 4. Results and logs

```sql
CREATE TABLE planning.result_line (              -- one cell per line and period
  model_id     uuid NOT NULL,
  scenario_id  uuid NOT NULL,
  line_id      uuid NOT NULL,
  grain        char(1) NOT NULL CHECK (grain IN ('M','D')),
  period       date NOT NULL,
  amount       numeric(18,2),
  stat         numeric(18,4),
  source       text NOT NULL CHECK (source IN ('actual','calc','manual','feed')),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (model_id, scenario_id, line_id, grain, period)
) PARTITION BY HASH (model_id);                  -- 16 partitions, created in the same script

CREATE TABLE planning.result_component (         -- how each component arrived at its number
  model_id      uuid NOT NULL,
  scenario_id   uuid NOT NULL,
  component_id  uuid NOT NULL,
  period        date NOT NULL,
  driver_value  numeric,
  ratio         numeric,
  stat          numeric(18,4),
  rate          numeric,
  amount        numeric(18,2),
  PRIMARY KEY (model_id, scenario_id, component_id, period)
) PARTITION BY HASH (model_id);                  -- 16 partitions

CREATE TABLE planning.calc_run (
  calc_run_id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id       uuid NOT NULL,
  scenario_id    uuid NOT NULL,
  trigger        text NOT NULL,                  -- 'patch','queue:<reason>','lock','setup','manual'
  started_at     timestamptz NOT NULL DEFAULT now(),
  duration_ms    integer,
  line_count     integer,
  changed_cells  integer,
  written_cells  integer,
  status         text NOT NULL DEFAULT 'ok' CHECK (status IN ('ok','error')),
  error          text
);
CREATE INDEX calc_run_model_idx ON planning.calc_run (model_id, started_at DESC);

CREATE TABLE planning.change_log (               -- append-only; one row per applied patch or system change
  change_id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id       uuid NOT NULL,
  scenario_id    uuid,
  line_id        uuid,
  component_id   uuid,
  actor_type     text NOT NULL CHECK (actor_type IN ('user','agent','autopilot','template','seed','system')),
  actor_user_id  uuid,                           -- the person who made or approved it
  action         text NOT NULL,                  -- 'patch','enable_account','disable_account','create_scenario','lock','archive','seed', ...
  patch          jsonb,                          -- the ops applied
  before         jsonb,
  after          jsonb,
  reason         text,
  evidence       jsonb,                          -- transaction ids, contract reference, suggestion id
  impact         jsonb,                          -- {"year_total_delta": n, "by_month": {...}}
  created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX change_log_model_idx ON planning.change_log (model_id, created_at DESC);
CREATE INDEX change_log_line_idx  ON planning.change_log (line_id, created_at DESC);

CREATE TABLE planning.recalc_request (           -- the recalculation queue
  recalc_request_id  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id           uuid NOT NULL,
  scenario_id        uuid,                       -- null = every live scenario of the hotel
  scenario_key       uuid GENERATED ALWAYS AS (coalesce(scenario_id, '00000000-0000-0000-0000-000000000000'::uuid)) STORED,
  reason             text NOT NULL,
  status             text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued','running','done','error')),
  not_before         timestamptz NOT NULL DEFAULT now(),
  requested_at       timestamptz NOT NULL DEFAULT now(),
  started_at         timestamptz,
  finished_at        timestamptz,
  attempts           integer NOT NULL DEFAULT 0,
  error              text
);
CREATE UNIQUE INDEX recalc_request_queued_uq ON planning.recalc_request (model_id, scenario_key) WHERE status = 'queued';
CREATE INDEX recalc_request_due_idx ON planning.recalc_request (not_before) WHERE status = 'queued';
```

Retention: delete `done` queue rows older than 7 days and `calc_run` rows older than 90 days in
the queue worker. `change_log` is kept.

## 5. Feeds

```sql
CREATE TABLE reservations.rms_forecast_segment ( -- RMS forecast by stay date and segment
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_code    text NOT NULL,
  data_source      text NOT NULL,                -- 'ideas','duetto'
  as_of_date       date NOT NULL,
  stay_date        date NOT NULL,
  source_segment   text NOT NULL,                -- as the RMS names it
  rooms_forecast   numeric,
  revenue_forecast numeric,
  adr_forecast     numeric,
  source_file      text,
  loaded_at        timestamptz NOT NULL DEFAULT now(),
  UNIQUE (property_code, data_source, as_of_date, stay_date, source_segment)
);
CREATE INDEX rms_forecast_segment_read_idx
  ON reservations.rms_forecast_segment (property_code, data_source, stay_date, as_of_date DESC);
```

It mirrors `reservations.otb_segment` so the existing segment maps apply. It lives in
`reservations`, not `planning`, because pace screens can use it later.

## 6. Ledger

```sql
CREATE TABLE ledger.transaction (                -- one posting line from an accounting system
  transaction_id   uuid NOT NULL DEFAULT gen_random_uuid(),
  code             text NOT NULL,
  account_id       text NOT NULL,                -- built exactly as the trial balance loader builds it for this operator
  posting_date     date NOT NULL,
  period           date NOT NULL,                -- month key of the accounting month
  amount           numeric(18,2) NOT NULL,       -- same sign convention as cleaned.account_values
  stat_amount      numeric(18,4),
  journal_type     text,                         -- AP, JE, PR, accrual, reversal ... as the source labels it
  source_system    text NOT NULL,                -- 'm3','intacct','peoplesoft', ...
  source_txn_id    text NOT NULL,
  line_no          integer NOT NULL DEFAULT 1,
  vendor_id        text,
  vendor_name      text,
  vendor_key       text,                         -- normalized: lower, alphanumeric only
  invoice_no       text,
  invoice_date     date,
  po_no            text,
  description      text,
  memo             text,
  fileid           text,
  loaded_at        timestamptz NOT NULL DEFAULT now(),
  component_id     uuid,                         -- the planner component it was matched to (working scenario)
  match_source     text CHECK (match_source IN ('rule','agent','user')),
  PRIMARY KEY (posting_date, transaction_id),
  UNIQUE (posting_date, code, source_system, source_txn_id, line_no)
) PARTITION BY RANGE (posting_date);             -- yearly partitions 2024 through 2028 created in the script
CREATE INDEX transaction_account_idx ON ledger.transaction (code, account_id, period);
CREATE INDEX transaction_vendor_idx  ON ledger.transaction (code, vendor_key, period);

CREATE TABLE ledger.gl_detail_config (           -- column pointers for a GL-detail report type
  report_type       text PRIMARY KEY,            -- config.report_type_config.report_type
  source_system     text NOT NULL,
  posting_date_col  text NOT NULL,
  date_format       text,
  txn_id_col        text,                        -- null: hash of the row's identifying columns
  line_no_col       text,
  journal_type_col  text,
  vendor_id_col     text,
  vendor_name_col   text,
  invoice_no_col    text,
  invoice_date_col  text,
  po_col            text,
  description_col   text,
  memo_col          text,
  stat_amount_col   text
  -- audit
);

CREATE TABLE ledger.reconciliation (             -- transactions summed against the trial balance
  reconciliation_id  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code               text NOT NULL,
  period             date NOT NULL,
  account_id         text NOT NULL,
  ledger_amount      numeric(18,2) NOT NULL,
  tb_amount          numeric(18,2),
  difference         numeric(18,2) GENERATED ALWAYS AS (ledger_amount - coalesce(tb_amount, 0)) STORED,
  checked_at         timestamptz NOT NULL DEFAULT now(),
  UNIQUE (code, period, account_id)
);
```

Account, hotel-code and sign handling for a GL-detail file reuse the report type's existing
`config.report_type_config` settings; `ledger.gl_detail_config` only adds the transaction columns.

## 7. Agent surfaces

```sql
CREATE TABLE planning.autopilot_policy (         -- what the agent may do, by account and threshold
  autopilot_policy_id  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id           integer NOT NULL,
  template_id          uuid,                     -- scope: operator standard
  model_id             uuid,                     -- scope: one hotel
  department           text,                     -- scope: reference.usali.dept
  category             text,                     -- scope: reference.usali.category
  account_id           text,                     -- scope: one account
  mode                 text NOT NULL CHECK (mode IN ('off','ask','suggest','autopilot')),
  max_monthly_amount   numeric,                  -- autopilot only: largest change to any month
  max_pct              numeric,                  -- autopilot only: largest percent change to a parameter
  allowed_kinds        text[],                   -- suggestion kinds this row covers; null = all
  notify_user_id       uuid
  -- audit
);

CREATE TABLE planning.suggestion (               -- a proposal from the agent, or a question
  suggestion_id   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id        uuid NOT NULL,
  scenario_id     uuid NOT NULL,
  line_id         uuid,
  component_id    uuid,
  kind            text NOT NULL CHECK (kind IN ('rate_change','new_recurring','one_time','fit','ratio_drift','missing_invoice','timing_shift','over_forecast','other')),
  title           text NOT NULL,
  body            text NOT NULL,
  evidence        jsonb,                         -- transaction ids, contract reference, fit figures
  patch           jsonb,                         -- ops for planning.apply_patch; null for a pure question
  impact          jsonb,                         -- from planning.preview_patch
  score           jsonb,                         -- engine score, e.g. {"avg_error_before":0.049,"avg_error_after":0.014}
  policy_mode     text NOT NULL CHECK (policy_mode IN ('ask','suggest','autopilot')),
  status          text NOT NULL DEFAULT 'open' CHECK (status IN ('open','needs_answer','accepted','dismissed','auto_applied','reverted','expired')),
  question        text,
  answer_options  jsonb,                         -- [{"key":"one_time","label":"One-time"}, ...]
  answer          jsonb,
  asked_user_id   uuid,
  resolved_by     uuid,
  resolved_at     timestamptz,
  change_id       uuid,                          -- planning.change_log row when applied
  finding_key     text,                          -- stable key from the detector, to avoid duplicates
  -- audit
  UNIQUE (model_id, scenario_id, finding_key)
);

CREATE TABLE planning.agent_job (                -- work handed to the agent service
  agent_job_id  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id      uuid NOT NULL,
  job_type      text NOT NULL CHECK (job_type IN ('review_findings','chat_patch','answer_followup')),
  payload       jsonb NOT NULL,
  status        text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued','running','done','error')),
  result        jsonb,
  error         text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  finished_at   timestamptz
);
```

Policy resolution: the most specific matching row wins, in the order account, category within
department, department, hotel, template, company. No row means `suggest`.

## 8. Sizing notes

- Per hotel: about 2,000 to 3,000 enabled lines, 3,000 to 5,000 components per scenario,
  under 100,000 result cells per scenario.
- A published scenario adds about 36,000 rows per hotel to `cleaned.account_values`
  (lines × months, non-zero only).
- `planning.result_*` and `ledger.transaction` are partitioned from the first script. Do not add
  partitions by hand later; put partition creation in the script and, for the ledger, in a small
  `ledger.ensure_partitions(year)` function called by the loader.
