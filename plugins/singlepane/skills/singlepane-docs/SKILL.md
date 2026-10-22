---
name: singlepane-docs
description: Build PowerPoint decks and Word documents containing Singlepane hotel data (P&L actuals/budgets/forecasts, STR comp-set data, on-the-books pace, interest rates) — either live/refreshable via the Singlepane Docs add-in ("Singlepane for Office"), which fills double-bracket Variable placeholder tags on demand, or one-time/static with numbers pulled through the Singlepane MCP connector. Use this skill whenever the user wants a PowerPoint or Word deliverable with Singlepane data in it — monthly performance decks, board/owner reports, asset-management summaries, lender updates, ad-hoc analyses — or mentions placeholder tags, the Singlepane Docs add-in, or refreshing a deck/doc with hotel data. Also use it when editing or debugging a document that already contains Singlepane variable tags, or when retrofitting/converting an existing deck or document with hand-typed numbers into a refreshable one driven by tags and variables.
---

# Building PowerPoint & Word documents with the Singlepane Docs add-in

Singlepane is a data platform for hotel owners and asset managers. Its Office add-in
("Singlepane for Office", one add-in for both PowerPoint and Word) fills
`<<Variable Name>>` placeholder tags in slides and documents with live Singlepane
data. Variables are defined once per document in the add-in's task pane, persist
inside the file itself, and refresh on demand — so a monthly deck is rebuilt by
changing one `Month` variable and clicking refresh, not by re-editing every number.

## First decision: live (add-in) or static (MCP)?

There are two ways to get Singlepane numbers into a document — pick one before
doing anything else:

1. **Live / refreshable — the add-in path (the rest of this skill).** Numbers are
   `<<tags>>` backed by variable definitions; the add-in fetches and refreshes
   them. Next month the user changes the `Month` global and clicks refresh — no
   Claude, no re-generation, and the same file re-points to another property by
   editing one variable. Requires the recipient to have the Docs add-in and a
   Singlepane login to refresh.
2. **Static / one-time — the MCP path.** Query the Singlepane MCP connector for the
   actual numbers and write them into the document as plain text (using the pptx/
   docx skills or python-pptx/python-docx as usual — no tags, no variable store, no
   donor file). The result works for any recipient with no add-in, but every update
   means Claude re-running every query and rebuilding — slower, more expensive, and
   easy to drift.

**How to choose** — if the user hasn't made it obvious, ask: *"Is this a one-time
deliverable, or something you'll refresh (e.g. monthly) or re-point later?"*

- Recurring report (monthly performance deck, board pack, owner report), or "same
  deck every month" → **add-in path**.
- One-off analysis, ad-hoc answer, recipients who don't have the add-in, or the
  user has no add-in installed → **MCP path**.
- Charts/graphs can't be tag-filled either way — the add-in only fills text. In a
  live deck, keep charts to a minimum, drive them from an attached Excel workbook
  (see the Excel skill), or accept that charts are static even when text refreshes.

On the MCP path, everything below about USALI selection (`references/usali-layouts.md`
and `references/layouts/`) and ground truth still applies — pick exact account lines
the same way, get values only from MCP query results, and never fabricate or
extrapolate a number. The rest of this skill covers the add-in path.

## The one thing to understand first (add-in path)

**You author tags and variable definitions; the add-in fetches the numbers.** Values
only appear when the user opens the file in PowerPoint/Word with the add-in loaded
and signs in to Singlepane. Never fabricate a number where a tag should go, and
never replace a tag with a guessed value. When you build a file offline, tell the
user: open it, sign in in the Singlepane pane, and refresh.

## Two ways to work (within the add-in path)

1. **Tags + Import Variables** — author `<<tags>>` in the text and deliver the
   variable definitions as JSON for the task pane's **Advanced → Import Variables**
   (see [references/variables-and-store.md](references/variables-and-store.md) for
   the accepted format — `id`s optional, they're regenerated on import). Tags
   referencing not-yet-defined variables are fine until the import. **Never hand the
   user a variables JSON without the paste instructions** (handoff step below) —
   JSON without steps is a dead end for them.
2. **Full offline generation (validated end-to-end)** — build the entire .pptx/.docx
   outside Office with variables *pre-defined*, so it opens ready to refresh. This
   requires embedding the add-in's variable store in the file's webextension part —
   done by the bundled graft script, which needs a **donor file** (any document of
   the same type previously saved with the add-in loaded; it supplies the add-in
   reference wiring). If the user can't provide a donor, fall back to mode 1 —
   the only difference for the user is one paste-and-import step on first open.

## Workflow

1. **Clarify scope**: one-time vs refreshable (the path decision above), which
   property/properties, which metrics, which period(s), which versions
   (Actual/Budget/Forecast), PowerPoint or Word, and — for offline generation —
   whether a donor file saved with the add-in is available.
2. **Get ground truth — never invent codes or account names.** Two strings are
   exact-match against the user's database:
   - **Property codes** (usually 3 letters, e.g. `"ACD"`). If the Singlepane MCP
     connector is available, verify with its hotel-list tool; otherwise ask the user
     or read them from an existing document/workbook.
   - **USALI account lines** (e.g. `"Total Revenue - 100"` — the ` - NNN` suffix is
     part of the string). Pick them from the canonical layouts under `references/`
     (see below). Same vocabulary as the Singlepane Excel add-in.
3. **Design the variable set** (see
   [references/variables-and-store.md](references/variables-and-store.md)):
   - **Globals** for everything shared or repeated: `Hotel Code`, `Month`, `Year`,
     `Version`, titles. This is what makes the document re-pointable — change one
     global, every query follows.
   - **Query variables** for each data point, with parameter fields referencing
     globals via `{Month}`, `{Year}`, `{Hotel Code}` instead of literals.
   - **Computed variables** for ratios, variances, and anything derived
     (`([GOP] - [GOP Budget]) / [GOP Budget]`) — keep math in variables, not in tags.
4. **Author the document** with tags as literal text (`<<Total Revenue | abbrev:1,$>>`)
   using whatever tool fits (python-pptx / python-docx, or the pptx/docx skills).
   Tag syntax and all format modifiers:
   [references/tag-syntax.md](references/tag-syntax.md). Placement rules below.
5. **For offline generation**: write the variable store JSON and run
   `python3 scripts/graft_sp_store.py <generated file> <donor file> <store.json> -o <out>`
   (path relative to this skill). It validates the store, embeds it exactly the way
   Office persists it, and wires the task pane to auto-open. Skipping this step
   ships a document whose variables don't exist.
6. **Hand off**: tell the user to open the file, sign in in the Singlepane pane
   (ribbon button if the pane doesn't auto-open), and refresh. Numbers appear then —
   not before. If the variables were **not** embedded (mode 1 / no donor), also
   deliver the variables JSON and spell out what to do with it, e.g.: *"Open the
   file, sign in in the Singlepane pane, then open **Advanced → Import Variables**,
   paste the JSON below, click **Import**, and refresh. Until you do this, the tags
   stay literal text."* Variables whose names already exist in the document are
   skipped on import, so re-importing is safe.

## Where tags can live

- **PowerPoint**: text boxes, placeholders, geometric shapes, callouts, freeforms,
  and table cells on slides. NOT: speaker notes, chart elements, SmartArt, WordArt,
  or master/layout placeholders. Table support needs PowerPoint API 1.8+ (Microsoft
  365); on older hosts only text shapes bind.
- **Word**: body paragraphs and table cells (the add-in wraps the paragraph in a
  content control). Keep tags out of headers, footers, footnotes, and floating text
  boxes.
- A tag must be complete (`<<` … `>>`) within a single text frame / table cell —
  never split one across shapes or cells.
- Tags inherit the formatting of the text they replace, so style the tag text
  (font, size, color) exactly as the final number should look.

## Variable & tag design rules

- Variable names are case-insensitive, whitespace-normalized, and must be unique.
  Use natural display names (`Total Revenue`, `Occ`), not snake_case.
- Prefer simple tags (`<<GOP | abbrev:1,$>>`) over in-tag arithmetic. Expressions in
  tags are supported but hard to maintain on a slide; put math in computed variables.
- In tag expressions, wrap multi-word names in brackets (`[Total Revenue] / [Rooms Sold]`)
  to avoid ambiguous greedy matching.
- Set `defaultModifiers` on a variable when it should always render one way (e.g.
  Occ as `percent:1`) — then plain `<<Occ>>` is enough and slides stay clean. A tag's
  own `| modifiers` override the default.
- **Missing data returns 0, not blank**, for financials/STR/OTB queries — and
  division by zero makes a computed variable/tag render as an error. Design variance
  ratios accordingly (or present variance as an absolute plus a direction word via
  the `updown` modifier).
- Month strings: use 3-letter `"Jan"`–`"Dec"` in query fields and month-type global
  values. SP financials also accept aggregates: `"Total Year"`, `"Q1"`–`"Q4"`,
  `"JunYTD"`, `"JunTTM"`, `"AugBOY"` (month+suffix, no space). A month-type global
  renders long in document text by default (`<<Month>>` → "June") while queries
  receive the short form — use `| monthshort` if you want "Jun" on the page.
- Versions: `"Actual"`, `"Budget"`, `"Budget1"`–`"Budget12"`, `"Forecast1"`–`"Forecast12"`,
  `"Proforma"`, `"LY_Actual"`, `"Var_Budget"`, `"Var_LY_Actual"` (plus
  company-specific names). For a variance you can either query a `Var_*` version or
  compute it from two query variables — the computed route is more transparent and
  reusable for both $ and % renderings.

## Picking USALI lines: use the canonical layouts

USALI selection is the heart of report building. The canonical layouts — reproduced
from Singlepane's own Detailed Financials UI — live under `references/`: read
[references/usali-layouts.md](references/usali-layouts.md) (reading conventions,
exact-string traps, KPI recipes, department-suffix decoder), then read **only** the
per-view file(s) you need from `references/layouts/` (`summary.md` for an
executive P&L; department schedules `rooms.md`, `consolidated-fb.md`, `fb-outlets.md`,
`fb-revenue-details.md`, `other-op-dpt.md`, `misc-income.md`, `a-g.md`, `i-t.md`,
`s-m.md`, `r-m.md`, `utilities.md`, `non-operating.md`, `labor.md`). Never read all
the layout files. For a KPI row (Occupancy, ADR, RevPAR, GOP margin), use the KPI
recipes in the index — in this add-in they become computed variables dividing two
query variables.

Top-line numbers (Total Revenue, GOP, EBITDA, NOI) come from `- 000` accounts —
don't sum departments yourself.

**Named F&B outlets:** outlet depts 201–225 are positional ("Outlet 1" = 201 at every
hotel), not concepts, so a hotel's lobby bar or steakhouse can sit in any of them. When
the user names an outlet, look up its dept with the Singlepane MCP connector's
`get_fb_outlets` tool (hotel code, plus the name as `search`) and append the returned
`usali_suffix` to the `fb-outlets.md` account names (e.g. `Total Revenue - 203`); label it
with the tool's `display_label`. Never infer the dept from the outlet's concept; without
the connector, ask the user.

## Typical deck patterns

- **Monthly performance one-pager / snapshot slide**: globals `Hotel Code`, `Month`,
  `Year`; KPI queries Occ / ADR / RevPAR (per the KPI recipes) + `Total Revenue - 000`,
  `Total Hotel GOP - 000`; a commentary paragraph mixing tags into prose
  (`"Total revenue was <<Total Revenue | abbrev:1,$>>, <<Rev Var | updown>>
  <<Rev Var | abs | abbrev:1,$>> vs budget."`).
- **Variance table**: a PowerPoint/Word table with rows = accounts, columns =
  Actual / Budget / Var $ / Var %; one query variable per Actual and Budget cell,
  computed variables for the Var columns. Name systematically
  (`Rooms Rev`, `Rooms Rev Budget`, `Rooms Rev Var`, `Rooms Rev Var Pct`).
- **Portfolio page**: financials query variables accept multiple codes (values are
  aggregated across them) — list the codes, or keep a per-property section driven by
  a `Hotel Code` global and duplicate the section per property with distinct globals
  only if the properties truly need separate variables.
- **Year-in-review / YTD**: same variables, month field `"{Month}YTD"` — interpolation
  concatenates, so a `Month` global of `Jun` yields `JunYTD`.

## Retrofitting an existing deck or document

When the user already produces a deck or report by hand — numbers retyped into prose,
KPI callouts, and tables every month — and wants it refreshable, follow
[references/retrofit.md](references/retrofit.md): inventory every hardcoded number
(including month/year words in titles and prose — they become `<<Month>>`/`<<Year>>`
tags), recover each one's inputs (property, period, version, account/metric), design
the variable set with shared parameters consolidated into globals, replace text with
tags in place so formatting survives, and validate the refreshed copy against the
untouched original. The non-negotiables:

- **Retrofit a copy, never the original** — the original is the validation baseline.
- **Consolidate into globals.** The test of a good retrofit: next month the user
  edits one or two globals and clicks refresh.
- **Name what stays manual.** Charts, numbers in unsupported locations, and
  non-Singlepane figures can't be tag-filled — list them for the user explicitly so
  nothing silently stops being updated.

## Offline generation mechanics (what the graft script does)

The add-in persists all variables as one JSON blob under the Office settings key
`sp_docs_store`, serialized into the file's webextension part
(`ppt/webextensions/webextension1.xml` or `word/webextensions/webextension1.xml`).
`scripts/graft_sp_store.py` replicates a real add-in save byte-for-byte in
structure: double-JSON-encoded settings value, task-pane wiring, content types,
package relationships, and `Office.AutoShowTaskpaneWithDocument` so the pane opens
with the document. The PowerPoint path is validated end-to-end against a real
add-in save; Word uses the same mechanism via the donor's own part layout — verify
the first Word generation opens with variables present before shipping many.

The donor matters because the webextension part carries the *add-in reference*
(store type/id), which differs between a sideloaded dev add-in and the production
store add-in — the script copies whatever wiring the donor has, so use a donor saved
by the same add-in installation the recipient uses.

## Troubleshooting

- **Tags show as literal text after opening** → user isn't signed in, or hasn't
  refreshed: Singlepane pane → sign in → refresh. Also check the pane's view toggle —
  "tags" mode intentionally shows tag text; "values" mode shows data.
- **Pane opened blank on document open** (sideload/dev only) → known race; click the
  ribbon button to reopen. Expected to be reliable with the production add-in.
- **Pane briefly shows the login form then logs in by itself** → known cosmetic
  issue while the cached session restores; harmless.
- **A tag renders an error chip** → parse/eval problem in that tag: unknown
  variable name (check spelling against the pane), unknown modifier, or division by
  zero in a computed variable.
- **Value is 0 unexpectedly** → the query matched no data: wrong property code,
  USALI string not exactly matching (suffix, spacing), or month/year/version with no
  data. Fix the variable definition in the pane, not the tag.
