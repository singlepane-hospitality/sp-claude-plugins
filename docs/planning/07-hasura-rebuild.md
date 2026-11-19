# Planning v1 — 07 One app API: a new Hasura with function permissions

Decision D25 (Austin, 2026-11-18): stand up a new Hasura with function-permission inference
turned off, rebuild the entire existing metadata under it, and replace the API endpoint for the
whole app. It supersedes D24 (a Hasura API for the planner only). This document is the scope, the
method and the work packages for that move. It is not planner work, but it is part of this plan.

Packages are `H1`–`H5` (§9). Everything about Hasura that an agent must not do is in §10.

## 1. What changes and what does not

| | Today | After |
|---|---|---|
| Hasura instance | One Hasura Cloud project, `HASURA_GRAPHQL_INFER_FUNCTION_PERMISSIONS=true` | A new project with the setting `false` |
| Who can call a function | Any role that can select the function's return table (inferred) | Only roles named on the function |
| Endpoint | The project's `hasura.app` host, written into five repos | One new endpoint, ideally a domain we own (§7.2) |
| Metadata | `database/hasura/hasura_metadata.json`, edited by script | The same content, generated, plus a permission list on every function |
| Databases, logins, JWT, roles, row permissions | — | Unchanged |
| Who can reach what | — | Unchanged on cutover day (§4.3). Tightening comes after |

Both projects read and write the same two databases, so there is no data to move. Clients can
switch one at a time, and a client that misbehaves can be pointed back.

## 2. Checked: the current API already runs volatile functions for `user`

Confirmed by Austin on 2026-11-18. It bears on how much of this plan depends on the move.

`database/README.md` says that with inferred permissions "mutations cannot be exposed to non-Admin
roles", and the notetaker routines were dropped for that reason (`20260730-02`). The Hasura
documentation reads the same way. That is not how the current API behaves:

- Source `rdsProd` has ten functions with `exposed_as: mutation`. Seven of them carry an explicit
  permission for role `user`: `acquisitions.upsert_deal_model_scenario`, `set_deal_model_current`,
  `archive_deal_model_scenario`, `accept_listing_diff_item`, `materialize_listing`,
  `transition_listing_access`, and `labor.delete_location_labor_data_for_range`.
- **Introspection:** `acquisitions_upsert_deal_model_scenario` is in `mutation_root` for role
  `user` and for `demo`.
- **Execution:** a scenario push through that mutation with a non-admin session returned its row,
  and the archive mutation cleaned it up.
- The billing project (`database/hasura/billing/`) works the same way: 24 functions exposed as
  mutations to `billing-admin`, with no inference variable set.

What is true, then: with inference on, Hasura never *infers* access to a volatile function, and
its console offers no control to grant it, but a permission written in the metadata JSON is
honored. A role still needs select on the function's return table.

Consequences:

- **Planner writes work on the current API** exactly as specified in `04-api.md`, with the same
  metadata entries the new API would need. No planner package depends on this move, and the
  command table that an earlier pass kept as a fallback is removed from the plan.
- **The move no longer has to happen for functions to be writable by users.** What it still buys
  is a permission stated on every one of the 191 functions instead of inferred from return tables,
  which is the only way to keep a query function from a role that can select its return table.
  Whether that is worth doing now is Austin's decision (§10). D25 stands until he changes it.
- `database/README.md`, "Functions", is corrected in the same PR as this document.

## 3. What exists today

Counted from `database/hasura/hasura_metadata.json` on 2026-11-18 (metadata version 3).

| | `aveStarDb` (legacy) | `rdsProd` (SPH) |
|---|---|---|
| Tracked tables and views | 187 | 198 |
| Relationships | 251 | 154 |
| Computed fields | 29 | 5 |
| Tracked functions | 87 | 104 |
| … exposed as mutations | 0 | 10 |
| … with an explicit permission | 0 | 13 |
| … with a session argument | 59 | 90 |
| Event triggers | 13 | 5 |
| Connection | read replicas | `connection_set` chosen by the `x-hasura-sp-stack` header |

Also in the metadata: 7 actions with their custom types, 2 remote schemas, 1 query collection with
an allow list, 3 inherited roles (`demo`, `hotelave-admin`, `management-user`, each inheriting
`user`), OpenTelemetry and metrics settings. No cron triggers, REST endpoints or API limits.
Roles holding table permissions: `user` (670), `demo` (121), `hotelave-admin` (83), `staff` (45),
`management-user` (3).

Not in the repo, and needed (§10 says who gets them): the project's environment variables (JWT
configuration for the Cognito pool, unauthorized role, CORS, allow-list switch, the engine
version), the database connection strings, the Hasura Cloud IP allowed on the database security
group, and the plan the project is on.

**Callers of the endpoint** (found by searching each repo on 2026-11-18):

| Repo | How it calls | Where the endpoint is set |
|---|---|---|
| `ui` (sp-ui) | User token; impersonation through a gateway endpoint | `src/environments/environment*.ts` (`graphql_uri`), `zeus-service.service.ts`, `codegen.yml`, `package.json` scripts, `.mcp.json` |
| `ave-serverless` (CodeCommit) | Admin secret from Lambdas; receives event triggers and actions; issues the token claims; hosts the impersonation authorizer | `serverless.yml`, `serverless-singlepane-scheduler.yml`, `singlepane-user-authentication/serverless.yml` (`hasura_url` parameter), `HASURA_GRAPHQL_URI` |
| `sp-ai-backend` | Admin secret with user headers; receives event triggers | `HASURA_GRAPHQL_ENDPOINT`, `HASURA_ADMIN_SECRET`, `HASURA_WEBHOOK_SECRET` (SST secrets, `.env*` files) |
| `singlepane-excel` (CodeCommit) | User token | Host written in `src/functions/functions.ts` and `authentication/amplify.service.ts` |
| `sp-office-addins` | User token | Host written in `src/core/data/hasura.client.ts` |
| `sp-api` | Authorization webhook for the public API | Not in the repo; confirm which Hasura it fronts (§10) |

`sp-internal-ops` and `sp-billing-admin` do not call this endpoint (the first uses the database
directly; the second has its own Hasura project, which stays as it is).

## 4. Target

### 4.1 The project

- A new Hasura Cloud project, same region and plan as the current one, same engine version to
  begin with. Record both versions in the runbook; an engine upgrade is a separate change.
- Environment:
  - `HASURA_GRAPHQL_INFER_FUNCTION_PERMISSIONS=false`.
  - JWT configuration, unauthorized role, CORS and allow-list switch copied from the current
    project. The same Cognito pool and claims mean a token is valid on both projects.
  - A new admin secret. It is never written into a repo, a script or a PR.
  - Database connection strings, webhook URLs and webhook keys as environment variables. The new
    metadata refers to them with `from_env`; it contains no literal URL or key (§4.2).
- The same database logins the current project uses. Changing them is a different project.
- The Hasura Cloud IP of the new project added to the database security groups.

### 4.2 The metadata

Generated, never hand-edited, by `database/hasura/scripts/rebuild_metadata.py` from a fresh export
of the live metadata. Output: `database/hasura/app/hasura_metadata.json`. The current file stays
where it is until the old project is retired (H5), then the new file replaces it.

The generator:

1. Copies every source, table, permission, relationship, computed field, remote schema, action,
   custom type, inherited role, query collection and allow-list entry unchanged. Source names stay
   `aveStarDb` and `rdsProd`.
2. Replaces every literal webhook URL, header value and connection string with a `from_env`
   reference and prints the list of variables the project needs. The literals now in git are a
   reason to rotate those keys after cutover (§10).
3. Leaves event triggers out of the output by default and writes them to a separate file
   (`event_triggers.json`), so they are applied on purpose (§6).
4. Writes a `permissions` list on **every** tracked function (§4.3).
5. Keeps the round-trip rules of the current file: `json.dumps(indent=2, ensure_ascii=False)`,
   tables and functions sorted, and the file's trailing-newline state.
6. Is deterministic: a second run on the same export produces the same bytes.

Until cutover every metadata change still goes to the current project by its usual script, and
the generator is re-run from a new export. Nothing is edited in both places by hand.

### 4.3 Function permissions: same access as today

With inference off, a function is exposed to a role only if the role is named on the function
*and* can select the function's return table. The baseline reproduces today's access exactly, so
that nobody gains or loses anything on cutover day:

- **A function exposed as a query:** name every role that has a select permission on its return
  table today. That is the set inference gives now.
- **A function exposed as a mutation:** keep the permissions it has today. The three with none
  (`create_listing_version`, `set_listing_status`, `unlock_listing_deal`) stay admin-only.
- **Inherited roles** get nothing of their own. Hasura gives an inherited role a function when any
  role in its set has it, so `demo`, `hotelave-admin` and `management-user` follow `user`.
- The generator writes an **exposure matrix** (`function × role`, before and after) to
  `database/hasura/app/function_exposure.csv` and fails if any cell differs. A function an
  inherited role reaches today only through a select permission of its own is such a difference:
  it is listed for a person to decide, not guessed.

The matrix is also the review list for afterwards. Every function `staff` can reach is in it,
and trimming that list is the first use of explicit permissions. It is not part of the move.

New work (the planner, and anything after it) names its roles on each function in its own
metadata script, queries included. That is harmless on the current project and required on the new
one.

## 5. Proving it before anything moves (H3)

All of these compare the new project with the current one against the production databases, read
only. None needs a client to change.

1. `get_inconsistent_metadata` returns an empty list on the new project.
2. **Per-role schema comparison.** `database/hasura/scripts/compare_role_schemas.py` introspects
   both projects as `user`, `staff`, `demo`, `hotelave-admin`, `management-user` and with no role,
   and prints differences in types, fields and arguments. Expected result: none. The script reads
   endpoints and secrets from the environment and prints no secret.
3. **Allow list.** Every operation in the `allowed-queries` collection validates against the new
   schema for the role that uses it.
4. **Replay.** A sample of real read operations per role (from the project's operation log, or
   captured from the app on stage) run against both; responses must match. Include each of the
   heaviest dashboards and compare timings.
5. **Functions exposed as mutations:** each of the seven that `user` can call today is called once
   on the new project against the demo company's test deal, and the result checked in the database.
6. **Actions and remote schemas:** each of the 7 actions and both remote schemas answers through
   the new project. Their handlers must not depend on which project called them; check that in
   `ave-serverless` and `sp-ai-backend` before the test.
7. **The app.** A build of the ui pointed at the new endpoint, on stage, walked through one screen
   per module with a `user`, a `staff` user, the demo user and an impersonated user. Then the
   Excel add-in and the Office add-in from development builds.
8. `@cached` queries and the `x-hasura-sp-stack` header behave as on the current project.

## 6. Event triggers

The 18 event triggers are the one part two projects cannot safely share without proof. Hasura
keeps their state inside each source database (`hdb_catalog.event_log`,
`hdb_catalog.event_invocation_logs`) and creates Postgres triggers on the tracked tables. What a
second project does to those when it connects, applies metadata or is removed is not documented.

So:

- **Rehearse on copies first (H2).** Restore each database from a snapshot, or use a scratch
  Postgres with the two schemas' trigger tables, and point two throwaway projects at it. Observe
  and write down: what the second project changes in `hdb_catalog` when it connects with no
  event triggers in its metadata; what happens to the table triggers when it applies the same
  event triggers the first one holds; which project delivers an event when both hold the trigger,
  and whether any event is delivered twice; what removing a trigger or a source from one project
  does to the other.
- **The production runbook is written from what the rehearsal showed**, not from this document.
- **Rules that hold whatever it shows:**
  - The new project's metadata has no event triggers until the cutover step that adds them.
  - Never remove an event trigger or a source from the old project's metadata while it can still
    reach the production databases. Retire the old project by cutting its database access first
    (security group, then the login's password), then delete it.
  - Before the switch, `hdb_catalog.event_log` has no undelivered rows, and the receiving Lambdas'
    logs are watched through the switch for a missed or doubled delivery.
  - Receivers keep validating the same header secret, supplied to the new project from its
    environment.

## 7. Cutover (H4, H5)

### 7.1 Order

1. **Server-side callers** (`ave-serverless`, `sp-ai-backend`): change the endpoint and admin
   secret in configuration and deploy. They can move as soon as H3 passes; they do not depend on
   where events are delivered from.
2. **Event triggers** in one window, by the runbook from §6.
3. **ui on stage**, then a soak of at least two working days, then **ui on production**.
   Impersonation is switched with it (the gateway authorizer in `ave-serverless`).
4. **Add-ins:** `singlepane-excel`, `sp-office-addins`.
5. **Public API** (`sp-api`), once §10's question about it is answered.
6. **Tooling:** codegen (`pull-latest-zeus`), `.mcp.json`, local env files and READMEs.
7. **Retire the old project** no sooner than two weeks after the last client moves: confirm its
   request count is zero, cut its database access, delete it, replace
   `database/hasura/hasura_metadata.json` with the new file, and update `database/README.md` and
   `database/docs/hasura/`.

Rolling back a client is pointing it at the old endpoint again. Rolling back event triggers is
the reverse of the window's runbook. Nothing in the databases changes either way.

### 7.2 A domain we own

Recommended (the author's, for Austin to decide): put the new API behind a Singlepane domain
instead of the project's `hasura.app` host. Hasura Cloud supports custom domains on its paid
plans. The host is written into five repos and two published add-ins; a domain we own makes this
the last time a move touches them.

### 7.3 What each repo changes

No client code changes shape; each changes where it points. Every repo's change is one small PR,
merged in the order above.

| Repo | Change |
|---|---|
| `ui` | `graphql_uri` in both environment files; codegen and MCP config read the endpoint and secret from the environment (the admin secret now in `package.json` and `.mcp.json` goes away with the old project and must not be replaced by the new one); regenerate Zeus and confirm an empty diff |
| `ave-serverless` | Endpoint and secret parameters in the three stacks; the claims Lambda and impersonation authorizer; confirm the event receivers accept the new project |
| `sp-ai-backend` | The three secrets; fixtures and docs that name the host |
| `singlepane-excel` | The host constant; one release |
| `sp-office-addins` | The host constant; one release |
| `sp-api` | Per §10 |
| `sp-core` | The generator, the comparison script, the runbook, the README; later the retired file |

## 8. What this does to the planner

Nothing structural. The planner is one more module on the app API:

- Its functions are tracked by its own metadata script with an explicit permission for `user`
  on each (`04-api.md` §9), on whichever project is live. The generator carries them across.
- Its UI uses the app's one endpoint and the app's generated client (`05-ui.md` §1). There is no
  planner endpoint, client or database login.
- Its packages do not depend on H packages (§2).

## 9. Work packages

| WP | Who | Scope | Depends on | Done when |
|---|---|---|---|---|
| H1 | sp-core agent | `rebuild_metadata.py`, the exposure matrix, `compare_role_schemas.py`, unit tests on a reduced metadata fixture, `database/docs/hasura/api-rebuild-runbook.md` | — | Run on the committed metadata: output is deterministic; every function has a `permissions` list; the matrix shows no difference or lists each one; no literal URL or key in the output; event triggers are in their own file; the variable list is printed |
| H2 | Austin | The new project, its environment and database access. The event trigger rehearsal on copies (§6) | H1 | The rehearsal's observations and the production runbook for event triggers are written into the runbook |
| H3 | Austin, with the scripts | Apply the generated metadata to the new project; all of §5 | H2 | Every item in §5 passes or has a recorded, accepted difference |
| H4 | one agent per repo, Austin deploys | The client changes in §7.3, in the order of §7.1 steps 1 and 3–6 | H3 | Each client runs on the new endpoint in production; the old project's request count falls to the callers not yet moved |
| H5 | Austin | Event trigger switch (§7.1 step 2, scheduled inside H4); retire the old project (step 7) | H4 | No undelivered or doubled events through the switch; old project deleted after its access was cut; repo files and docs updated |

H1 can start now. It needs nothing from the planner packages and blocks none of them.

## 10. Open items for Austin, and limits on agents

Agents working on H packages never hold or print an admin secret, never apply metadata to either
project, never touch a production database beyond the read-only access they already have, and never
copy a webhook URL or key into a file. Applying metadata, creating the project and every step in a
cutover window are Austin's.

To settle:

| Item | Needed for |
|---|---|
| Decide whether the move still goes ahead now that functions are already writable by users (§2) | Everything in this document |
| Who creates the project; its plan; whether it gets a domain we own (§7.2) | H2 |
| The current project's environment variables and engine version, exported for comparison | H2 |
| Where the new metadata lives: this repo (`database/hasura/app/`, assumed) or the Hasura repository the README anticipates | H1 |
| Which Hasura the public API's authorization webhook (`sp-api`) fronts, and whether it moves | H4 |
| Whether to rotate the webhook keys and the old admin secret that are literals in git today, once the old project is gone | After H5 |
| A snapshot restore, or agreement to rehearse event triggers on a scratch database only | H2 |
