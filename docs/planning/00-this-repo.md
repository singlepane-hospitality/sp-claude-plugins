# Planning v1 — this repo's part

This folder is a copy of the Planning v1 build spec as of 2026-11-18. The copy that gets edited is
in `sp-core` at `docs/workbench/planning/`; change the plan there and re-copy. Paths that start with
`database/` are in `sp-core`.

Start with `README.md`. `mockup.html` is the interactive mockup (open it in a browser). Nothing
in the plan is built yet.

## What this repo builds

- **Skill text that lists versions** (the Excel modeling and Docs skills) describes the version
  list as coming from the registry, including `working` and custom scenarios
  (`01-version-registry.md` §4). A plugin version bump goes with it.
- The MCP tools the plugin exposes are built in `sp-ai-backend`.

This repo does not call the app's Hasura API, so the move in `07-hasura-rebuild.md` changes nothing
here.
