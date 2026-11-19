# Planning v1 — 01 Version registry

Replace the hard-coded lists of financial version names with one table, add the planner's
versions to it, and give every dropdown one function to read.

**Prerequisite:** PR 114 (single-pass cube) has had its switch (`20261111-02`) and cleanup
(`20261111-03`) applied and is merged to `main`. Build this on those functions. Paths below are
relative to `database/sph/singlepane/schemas/` on that branch; line numbers are from the PR 114
branch at `d3666606` and will drift.

## 1. Why this is its own work package

- The planner needs versions the code does not know: `working`, and one key per custom scenario.
- Version knowledge is spread over a whitelist, a second whitelist that disagrees with it, a
  hand-written precedence ladder, regex parsing in the future insights resolver, and a `LIKE`
  gate repeated in about a dozen functions.
- It touches the cube, so it ships alone, with parity tests, before any planner table exists.

## 2. Table

```sql
CREATE TABLE financial_cube.version_registry (
  version_registry_id  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  version_key          text NOT NULL,            -- the value stored in cleaned.account_values.version; lower case
  label                text NOT NULL,            -- what dropdowns show
  family               text NOT NULL CHECK (family IN ('actual','budget','forecast','proforma','custom')),
  kind                 text NOT NULL CHECK (kind IN ('stored','synthetic')),
  author               text NOT NULL DEFAULT 'primary' CHECK (author IN ('primary','owner')),
  forecast_month       integer CHECK (forecast_month BETWEEN 1 AND 12),   -- forecastN and forecastN.M
  revision             integer CHECK (revision BETWEEN 0 AND 5),          -- 0 for forecastN, M for forecastN.M
  latest_rank          integer,                  -- position in the "latest forecast" ladder; null = not on it
  bypass_validation    boolean NOT NULL DEFAULT false,  -- passes the validation gate without a validation row
  is_live              boolean NOT NULL DEFAULT false,  -- moves between locks (working, live custom scenarios)
  is_selectable        boolean NOT NULL DEFAULT true,   -- appears in dropdowns
  sort_order           integer NOT NULL DEFAULT 0,
  company_id           integer,                  -- null = system version, visible to everyone; else only this company
  scenario_id          uuid,                     -- planning.scenario, for planner versions (no FK: planning may not exist yet)
  aliases              text[],                   -- accepted spellings that normalize to version_key
  active_flag          boolean NOT NULL DEFAULT true,
  -- audit
  CONSTRAINT version_registry_version_key_unique UNIQUE (version_key),
  CONSTRAINT version_registry_key_lower_check CHECK (version_key = lower(version_key))
);
```

Owned by whichever role owns the other `financial_cube` tables on prod (check
`pg_tables.tableowner`; most are `postgres`, so this block runs after `RESET ROLE`, not under
`sp_object_owner`). Grant `SELECT` to `sp_user_readonly`; writes only through functions.

### 2.1 Seed

One row per version the code accepts today, so behavior is unchanged on day one:

| Keys | family | kind | forecast_month / revision | latest_rank | bypass_validation |
|---|---|---|---|---|---|
| `actual` | actual | stored | | 10 | false |
| `forecast1` … `forecast12` | forecast | stored | N / 0 | per §2.2 | false |
| `forecastN.M` exactly as `get_valid_version` accepts them (M = 1–5; 1–4 for N = 2, 4, 6, 9, 11) | forecast | stored | N / M | per §2.2 | **true** |
| `forecast` (bare) | forecast | stored | | per §2.2 | false; `is_selectable = false` |
| `budgetfinal`, `budget`, `budget12` … `budget1` | budget | stored | | per §2.2 | false |
| `proforma_update`, `proforma`, `proforma_mgr` | proforma | stored | | per §2.2 | **true** |
| `proforma_have` | proforma | stored | | null | **true** |
| `latest_forecast`, `ly_actual`, `var_ly_actual`, `var_budget` | by meaning | synthetic | | null | false |
| `actforec1` … `actforec12` | forecast | synthetic | N / 0 | null | false |

`aliases`: for each `forecastN.M`, the underscore form `forecastN_M` (today's rewrite). Labels:
take them from the UI (`src/domain/forecast.ts`, `versions.ts`, `constant.enum.ts` in the ui repo)
so nothing is renamed.

New rows added by this work package:

| Key | family | kind | latest_rank | bypass_validation | is_live |
|---|---|---|---|---|---|
| `working` | forecast | stored | null: not on the ladder | true | true |

Custom scenario rows (`cs_<10 hex>`, family `custom`, `company_id` set, `bypass_validation = true`,
`latest_rank` null) are inserted by `planning.create_scenario` later; nothing to seed.

### 2.2 The ladder

`latest_rank` reproduces `get_code_latest_forecast` exactly (`financial_cube/routines/get_code_latest_forecast.sql:45-235`):

1. `actual`
2. `forecast12.5`, `12.4`, … `12.1`, `forecast12`, then the same for 11 down to 1
3. `forecast`
4. `budgetfinal`, `budget`, `budget12` … `budget1`
5. `proforma_update`, `proforma`, `proforma_mgr`

`working` is its own version and is **not** on the ladder. `latest_forecast` keeps resolving to the
latest locked forecast, which for a planner hotel is the `forecastN` or `forecastN.M` its last
official lock wrote. People see the working forecast by choosing it.

Leave gaps of 10 between ranks. The current ladder names `forecast4.5`, `6.5`, `9.5` and `11.5`,
which are not valid versions; do not create rows for them.

## 3. Functions to change

Rewrite each to read the registry. Signatures do not change (Hasura rejects overloads).

| Function | Today | After |
|---|---|---|
| `financial_cube.get_valid_version(text)` | Case-sensitive `IN` list; `actforec` regex; underscore rewrite (`get_valid_version.sql:23-67`) | Return `version_key` where the input equals `version_key` or is in `aliases`, and `active_flag`. Keep it case-sensitive (callers lower-case). Custom keys of another company are still "valid" here; visibility is enforced in §4 and by the data layer's hotel check. |
| `financial_cube.is_version_valid(text)` | A second list that lacks `proforma_have` and `actforecN` | `get_valid_version(x) IS NOT NULL`. This makes `proforma_have` and `actforecN` valid on the screens that call it. Intended; note it in the PR. |
| `financial_cube.get_code_latest_forecast(code, month, year)` | If-ladder over versions present in `financial_data_status_mv` | `SELECT r.version_key FROM status_mv s JOIN version_registry r ON r.version_key = s.version WHERE … AND r.latest_rank IS NOT NULL ORDER BY r.latest_rank LIMIT 1`. Same `'Annual'` → `'Dec'` handling. |
| `financial_cube.get_version_for_future_insights_as_of_date` | Regex parse of `forecastN[.M]`; hard-coded budget priority (`:72-136`) | Read `forecast_month`, `revision` and the budget order from the registry. No change in behavior: `working` and custom versions are never eligible. |
| Validation gate (every copy) | `… OR version LIKE 'forecast%.%' OR version LIKE 'proforma%'` | `… OR <bypass>` where bypass comes from `version_registry.bypass_validation`. See §3.1. |
| `cleaned.insert_provisional_validations()` | Writes a provisional row for every version | Skip versions whose registry row has `bypass_validation`. |
| `controllers.load_s3_file_by_report_type` / `transfer_actuals_to_forecast` | `^Forecast[0-9]+$` regex | Unchanged. File loads keep their own parsing. |
| Transformers | Parse `forecastN` from file arguments | Unchanged. |

### 3.1 The gate, without slowing the cube

The gate sits inside large dynamic statements. Do not call a function per row.

- **`get_financial_cube_cells`** (`:263-267`) and **`get_financial_cube_jit_leaf_range`** (`:624-642`):
  the requested versions are known before the statement is built. Look up the bypass flag once per
  requested version in PL/pgSQL and inject it as a literal per cell leg (cells) or as an array
  literal tested with `= ANY` (leaf range).
- **`update_financial_data_status`** (`:41-45`, `:57-61`) and
  **`update_future_insights_usali_availability`** (`:67-71`, `:84-90`, `:101-126`): join
  `version_registry` (about 130 rows, hash join) and test `r.bypass_validation`.
- The other copies, same treatment by whichever of the two fits:
  `get_financial_gl_cube.sql:164-173`, `get_financial_data_raw.sql:457-461`,
  `get_financial_cube_jit.sql:441-443`, `get_financial_cube_jit_premap.sql:465-479`,
  `get_financial_cube_jit_premap_range_syn.sql:458-472`, `get_financial_cube_daily.sql:436-450`,
  `app/get_gl_explorer.sql:280-289`, `app/get_financial_gl_variance.sql:463-469`.
- A version with no registry row does not bypass.

The rule "validation is keyed by month for `actual` and by `'Total Year'` for everything else"
stays as code. Do not move it into the registry in this work package.

### 3.2 Leave alone

- `app.get_forecast_accuracy*` and `app.get_dashboard__rev_gop_ebitda*`: their `forecast(m-1)` arrays
  mean official monthly forecasts and stay that way.
- `financial_cube.fav_*` and the wide `financials_all_versions` tables: one column per version;
  custom and working versions are not added.
- `app.get_data_availability` (`:83-90`) and `app.list_nonzero_variance_counts` (`:35,43`) hold their
  own copies of the list. Note them in the PR as follow-ups; not required for v1.
- Known bugs the inventory found (`get_financial_rollup.sql:119` tests the wrong variable;
  `get_financial_data.sql:45` prints NULL in its error; `get_financial_data_status.sql:80` parses one
  digit). Fix only if trivial and covered by a test; otherwise list them in the PR.

## 4. One version list for dropdowns

```sql
financial_cube.get_available_versions(
  hasura_session  json,
  property_codes  text[],
  year_input      integer DEFAULT NULL      -- null = any year
) RETURNS SETOF financial_cube.available_version_rt   -- STABLE
```

`financial_cube.available_version_rt`: `version_key`, `label`, `family`, `kind`, `author`,
`is_live boolean`, `is_locked boolean`, `scenario_id uuid`, `made_as text`,
`source_label text`, `has_data boolean`, `hotel_count integer`, `sort_order integer`.

Rules:

- Hotels = `auth.get_allowed_hotels(hasura_session, property_codes)`. No allowed hotels, no rows.
- Return every `is_selectable`, `active_flag` registry row that is a system version
  (`company_id IS NULL`) or belongs to the session's company (`x-hasura-company-id`); admin role
  sees all.
- `has_data` / `hotel_count`: from `financial_cube.financial_data_status_mv` for those hotels (and
  year when given). **Read the MV, never the base status table.** Stored versions with no data for
  any of the hotels are returned with `has_data = false` so pickers can grey them out or hide them;
  custom versions with no data are omitted.
- Synthetic versions are returned with `has_data = true` when their inputs have data
  (`ly_actual` needs `actual`; `var_budget` needs `actual` and `budget`; `latest_forecast` needs any
  ranked version).
- Planner columns (`scenario_id`, `made_as`, `source_label`, `is_locked`) come from
  `planning.scenario` when that table exists; until the planner ships they are null. Guard with
  `to_regclass('planning.scenario')` so this work package can ship first.
- Order by `sort_order`, then `label`.

Management-company users must not see proforma versions (the UI enforces this today with
`withProformaOption`). Keep that filter in the UI; do not move it into this function in v1.

## 5. Tests

`database/sph/singlepane/tests/version_registry_parity.sql`, in the style of PR 114's
`financial_replacement_*_parity.sql` (`BEGIN READ ONLY`, two-way `EXCEPT ALL`, a final
`RAISE WARNING 'version registry parity: N comparisons, 0 with differences'`). Runnable on prod
read-only after the script is applied, and on a scratch database.

The test file defines the **old** bodies as `pg_temp` functions (copied verbatim from the pre-change
files) and compares old and new over:

1. `get_valid_version` and `is_version_valid` for every distinct `version` in
   `cleaned.account_values` and `financial_cube.validation`, every alias form, mixed-case forms,
   and a fixed list of invalid strings (`forecast13`, `forecast2.5`, `budget13`, `''`, NULL).
   Expected differences, asserted explicitly: `is_version_valid` now returns true for
   `proforma_have` and `actforec1..12`.
2. `get_code_latest_forecast` for N random (code, month, year) from the status MV (default 2,000)
   plus every month of the current year for hotels given by `-v codes=`.
3. `get_version_for_future_insights_as_of_date` for a sample of hotels, stay months and as-of dates.
4. `get_financial_cube_cells` and `get_financial_data` on the cells PR 114's cube and data parity
   tests use, old gate versus new gate, for hotels that require validation and hotels that do not.
5. After inserting `working` rows for one scratch hotel (scratch only): the rows are returned by the
   cube without a validation row when `working` is asked for by name; `get_code_latest_forecast`
   and the future insights resolver still return the latest `forecastN` / `forecastN.M` and never
   `working`; `insert_provisional_validations` wrote nothing for `working`.

Plus `version_registry_integration.sql` + `_checks.sql` in the repo's integration style (empty
scratch database, `prod_like_security.sql`, script applied twice, checks as `sp_test_app`).

## 6. Deliverables

- `updates/<date>-NN-version-registry.sql`: table, seed (after `RESET ROLE`), the rewritten
  functions, `available_version_rt`, `get_available_versions`, a final `DO` block that verifies
  one overload per function and `sp_user_readonly` EXECUTE / SELECT.
- Canonical files under `schemas/financial_cube/…`, `schemas/cleaned/…`, `schemas/app/…` updated in
  the same change; seed source in `seeds/version-registry/01-seed.sql` and `loading/`.
- `database/hasura/scripts/version_registry_metadata.py`: track `available_version_rt` (select,
  all columns, `filter: {}`, role `user`) and `get_available_versions` (query,
  `session_argument: hasura_session`).
- `database/docs/financial_cube/version-registry.md`: what the columns mean and how to add a version.
- A note for the follow-on repos (README §8): the UI, the Excel add-in and the MCP tools stop
  listing versions by hand and call `financial_cube_get_available_versions`.

## 7. Rollback

The script's commented rollback block restores the previous function bodies from the canonical
files at the pre-change commit and drops the registry, the return type and the new function.
Nothing reads the registry outside the functions this script replaces.
