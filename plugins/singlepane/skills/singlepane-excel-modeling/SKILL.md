---
name: singlepane-excel-modeling
description: Build Excel financial models, reports, and dashboards for hotel portfolios using the Singlepane Excel add-in's SP.* custom functions (SP.FINANCIALS, SP.FINANCIALS_AGG, SP.STR, SP.OTB, SP.FILTER, and more). Use this skill whenever the user mentions Singlepane, SP. functions, hotel P&L / USALI accounts, budgets/forecasts/reforecasts, STR or comp-set index data, on-the-books/pace data, guest review scores/counts or review comp sets, flow-through, or wants to build or modify an Excel workbook that pulls hotel portfolio data — even if they don't name the add-in explicitly, and whether the workbook should be live/refreshable (SP.* formulas) or a one-time static export (values via the Singlepane MCP connector). Also use it when reviewing or debugging a workbook that already contains SP.* formulas, or when retrofitting/converting an existing model or report — one built on pasted exports, hardcoded values, or data-tab lookups — to live Singlepane formulas.
---

# Building Excel models with the Singlepane add-in

Singlepane is a data platform for hotel owners and asset managers. Its Excel add-in
exposes custom functions under the `SP.` namespace (e.g. `=SP.FINANCIALS(...)`) that pull
live data — P&L actuals/budgets/forecasts, STR comp-set performance, on-the-books pace,
guest sentiment, interest rates — straight into cells.

## First decision: live formulas or static values?

There are two ways to get Singlepane numbers into a workbook — pick one before
building:

1. **Live / refreshable — SP.* formulas (the rest of this skill).** The workbook
   recalculates against Singlepane whenever the user refreshes: next month's close,
   a re-pointed property code, a different version — all without Claude re-running
   anything. This is the default for any model, report, or dashboard the user will
   keep using.
2. **Static / one-time — the MCP path.** Query the Singlepane MCP connector for the
   actual numbers and write plain values into the cells (normal xlsx tooling, no
   SP.* formulas, no fix-up script). The file works for anyone with no add-in or
   login — but every update means Claude re-running every query, which is slower,
   more expensive, and easy to drift from the platform.

If the user hasn't made it obvious, ask: *"Is this a one-time export, or a workbook
you'll refresh or re-point later?"* Recurring/reusable → SP.* formulas. One-off
snapshot, or recipients without the add-in → MCP static values. (A third option
when the user has the add-in: build with SP.* formulas, refresh in Excel, then use
the task pane's **Convert To Values** on a copy — best of both for share-outs.)
On the MCP path, the ground-truth and USALI-selection guidance below still applies —
values come only from MCP query results, never fabricated.

## The one thing to understand first (SP.* path)

**You author formulas; Excel computes them.** SP.* functions only return values inside
Excel while the user is signed in to the add-in (Home ribbon → singlepane → Login).
When you build a workbook offline (e.g. with openpyxl), write the SP.* formulas as
formula strings and tell the user: open the file in Excel, sign in to Singlepane, and
values will populate (use the task pane's **Recalculate All Functions** if cells show
`#N/A` or stale values). Never fabricate the numbers yourself, and never replace a
formula with a guessed value.

## Ground truth: never invent codes or account names

Two arguments are exact-match strings against the user's database — a typo returns an
error or wrong data:

- **Property codes** (usually 3 letters, e.g. `"ACD"`). The authoritative list is the
  **"My Properties"** sheet the add-in auto-creates (populated by
  `=SP.GET_HOTEL_REFERENCE()`), which also has every attribute per hotel.
- **USALI account lines** (e.g. `"Total Revenue - 100"` — the ` - number` suffix is part
  of the string). The authoritative list is the **"Usali Reference"** sheet
  (`=SP.GET_USALI_REFERENCE()`).

If you're working in a live workbook, read those sheets before writing formulas. If
you're building a file offline and can't see them, verify property codes through the
Singlepane MCP connector when it's available, ask the user for the codes/lines they
want, or build the model so it reads codes from a cell the user fills in — don't guess.
Attribute values used in `SP.FILTER` (brand names, markets, management companies) are
also exact strings from the user's data — pull them from "My Properties" when possible,
and check *which column* actually holds the concept: e.g. "our Marriott hotels" may be
`HotelCompany = "Marriott"` while the `Brand` column holds the flag ("Courtyard",
"Westin", …).

When a model covers a group of hotels ("all our X hotels"), drive it from a
`SP.FILTER` spill rather than a pasted static list of codes, even if you know today's
codes — a live filter keeps the model correct as hotels are bought and sold. Static
lists are fine only when the user names specific properties.

## Workflow

1. **Clarify scope**: which properties (codes or a filter like "all Marriott hotels"),
   which metrics/accounts, which periods, which versions (Actual/Budget/Forecast).
2. **Get ground truth** for codes and USALI lines (see above).
3. **Lay out input cells — every parameter, no exceptions**: property code(s), year,
   month, version, as-of dates, filter values, and each USALI line all live in labeled
   input cells that formulas reference — never as hardcoded literals inside formulas,
   even when there's only one of them. A single-USALI report still gets a USALI input
   cell. Where inputs go:
   - Shared report-wide inputs (code, year, version, as-of date): an assumptions block
     at the top, or a dedicated Inputs sheet for multi-sheet models.
   - Row/column drivers (USALI lines, months, metric names): the row labels and column
     headers themselves are the input cells — one formula then fills the whole grid
     (`=SP.FINANCIALS($B$1,$A6,C$4,$B$2,$B$3)`).
   - Inputs that shouldn't clutter a printable report: place them off the print margin
     (a column to the right of the print area) or in a hidden/grouped column or row,
     and set the print area so they don't print.
   This is what makes a model auditable and repointable — change one cell, the whole
   report follows.
4. **Write the formulas** per the reference below, referencing the input cells.
5. **Leave room for spills**: array functions (SP.FILTER, the comp-set spills, the
   reference spills) spill down/right; SP.FILTER and the reference spills include a
   header row, the comp-set spills don't. Anything in the way causes `#SPILL!`. Put
   each on its own sheet or in a clear region, and reference the spill with `#`
   notation (e.g. `A1#`) or structured formulas.
6. **Hand off**: remind the user to sign in and recalculate. If they'll share the file
   with someone without add-in access, point them to the task pane's **Convert To
   Values** ("zap") — it irreversibly replaces every SP.* formula with its value, so save
   a copy first.

## Function quick reference

Scalar lookups (one value per cell; batched and cached by the add-in, so thousands of
cells are fine):

| Function | Purpose |
|---|---|
| `SP.FINANCIALS(code, usali, month, year, version)` | One P&L value for one property |
| `SP.FINANCIALS_AGG(codes, usali, month, year, version)` | Same, summed over a range/array of codes — accepts a nested `SP.FILTER(...)` |
| `SP.STR(code, date, aggType, metric, [subjCompMkt], [segment])` | STR performance & comp-set indexes |
| `SP.OTB(code, dailyOrMonthly, stayDate, targetSet, periodType, metric, segment, [asOfDate])` | On-the-books / pace |
| `SP.REVIEWS(code, startDate, endDate, source, subjectCs, metric)` | Guest review metrics over a date range (count, avg rating, response rate, star buckets) |
| `SP.REVIEWS_SUMMARY(code, source, asOfDate, subjectCs, metric)` | Site-lifetime review totals & TripAdvisor market rank, as of a scrape date |
| `SP.GET_INTEREST_RATE(benchmark, date, [asOfDate])` | SOFR / SONIA / T10YR benchmark rate (as a percent) |

Array functions (spill; SP.FILTER and the reference spills include a header row — the
comp-set spills don't, so write your own labels above them):

| Function | Purpose |
|---|---|
| `SP.FILTER([codes], filter1, value1, …, [filter5], [value5])` | Property codes matching up to 5 attribute filters |
| `SP.STR_COMP_SET(code, [asOfDate], [compset])` | Member hotels + room counts of an STR comp set |
| `SP.REVIEWS_COMP_SET(code, [source], [asOfDate])` | Review comp set table: name, review count, rating, TripAdvisor rank, market |
| `SP.GET_HOTEL_REFERENCE()` | All authorized hotels × all attributes (the "My Properties" sheet) |
| `SP.GET_USALI_REFERENCE()` | All USALI account lines (the "Usali Reference" sheet) |

**These twelve are the only SP.* functions to use.** The add-in exposes other functions
(dashboard spills like `SP.REV_GOP_EBITDA` or `SP.RISK_UPSIDE`, helpers like
`SP.GET_HOTEL_ATTRIBUTE`) — they are legacy/undocumented and must not appear in new
models. Need a hotel attribute like room count? `XLOOKUP` it from the "My Properties"
sheet instead.

**Before writing any formula, read [references/functions.md](references/functions.md)**
for exact argument order, the full set of valid values for every enum-like argument
(months, versions, STR aggregate types/metrics, OTB period types, attribute names), and
worked examples. Valid values are closed vocabularies — using a value not listed there
fails silently or errors.

## Picking USALI lines: use the canonical layouts

USALI selection is the heart of financial model building. The canonical layouts —
reproduced from Singlepane's own Detailed Financials UI — live under
`references/`: read [references/usali-layouts.md](references/usali-layouts.md) (a
short index: reading conventions, exact-string traps, KPI recipes, department-suffix
decoder), then read **only** the per-view file(s) you need from `references/layouts/`
— `summary.md` for an executive/summary P&L (revenue → departmental expenses →
departmental profit → undistributed → GOP → fees → non-operating → EBITDA → FF&E →
NOI), or the matching department schedule (`rooms.md`, `consolidated-fb.md`,
`fb-outlets.md`, `fb-revenue-details.md`, `other-op-dpt.md`, `misc-income.md`,
`a-g.md`, `i-t.md`, `s-m.md`, `r-m.md`, `utilities.md`, `non-operating.md`,
`labor.md`). Never read all the layout files — some are hundreds of rows, and loading
views you aren't building wastes significant time. When a user asks for a "P&L",
"summary", or a department schedule, start from the matching layout file instead of
inventing a row list.

For complete model shapes (variance reports, portfolio rollups, STR dashboards, pace
reports, debt schedules), see
[references/model-patterns.md](references/model-patterns.md).

## Formula-writing rules

- **Dates**: pass `"YYYY-MM-DD"` strings or reference a cell containing a real Excel
  date; both work. For monthly OTB data use the first of the month.
- **Months** (FINANCIALS/FINANCIALS_AGG): 3-letter abbreviations, `"Jan"`…`"Dec"`.
  SP.FINANCIALS also accepts aggregations: `"Total Year"`, `"Q1"`–`"Q4"`, `"JunYTD"`,
  `"JunTTM"`, `"AugBOY"` (month+suffix, no space).
- **Year**: 4-digit number, unquoted.
- **Versions**: `"Actual"`, `"Budget"`, `"Forecast1"`–`"Forecast12"`, `"Budget1"`–
  `"Budget12"`, `"Proforma"`, `"LY_Actual"`, `"Var_Budget"`, `"Var_LY_Actual"` (plus any
  company-specific reforecast names). Prefer letting the backend compute variances via
  the `Var_*` versions when the user asks for variance columns, but computing variance
  in Excel from two SP.FINANCIALS cells is also fine and more transparent.
- **Missing data returns 0, not blank**, for FINANCIALS/FINANCIALS_AGG/STR/OTB/
  REVIEWS/REVIEWS_SUMMARY. Design accordingly (e.g. guard ratio formulas against
  divide-by-zero with `IFERROR`). Exception: SP.REVIEWS_COMP_SET spills blank cells
  for metrics it doesn't have.
- A cell showing `#N/A` with message **"Not authorized"** means the user isn't signed
  in — not that the formula is wrong. `"No Data"` / `"No data"` from array functions
  means the query matched nothing (the comp-set spills instead error `#N/A` with
  "No STR comp set found" / "No review comp set found" when the set isn't configured).

## Building workbooks programmatically

When creating an .xlsx outside Excel, write formulas as plain strings starting with `=`
(openpyxl preserves them). Notes:

- **Always finish by running the bundled fix-up script on the saved file:**
  `python3 scripts/fix_sp_formulas.py <workbook.xlsx>` (path relative to this skill).
  Why: Excel binds Office.js custom functions through a mangled internal name in the
  file XML — a working cell is stored as `_xldudf_SP_FINANCIALS(...)` marked as a
  dynamic-array formula, not as `SP.FINANCIALS(...)`. A bare `SP.` name written by
  openpyxl never binds to the add-in, so cells show `#NAME?` (or `=@SP...`) until each
  one is manually re-entered. The script rewrites every SP.* cell into Excel's exact
  persisted form (verified against a real Excel save). Skipping this step ships a
  broken workbook. Verify it reports the expected number of cells marked. The
  formula bar still displays clean `=SP.FINANCIALS(...)` — the mangled name lives
  only in the file format.
- If a user reports an existing generated workbook showing `#NAME?` in every SP cell:
  run this script on the file (with it closed in Excel) — that fixes it permanently.
  Re-entering each formula (F2+Enter) also works but is per-cell.
- Set number formats yourself ($, %, thousands separators) — the add-in returns raw
  numbers.
- You cannot compute or verify SP.* results offline; validate structure (argument order,
  valid enum values, cell references) instead, and state clearly in your summary that
  values appear after the user opens the file and signs in.
- Don't pre-place values where a spill will land.

## Retrofitting an existing workbook

When the user already has a model or report fed by pasted data tabs, hardcoded numbers,
or links to other workbooks and wants it live on Singlepane, follow
[references/retrofit.md](references/retrofit.md) — the full survey → map → replace →
validate procedure. The non-negotiables:

- **Retrofit a copy, never the original.** The untouched original is the validation
  baseline.
- **Replace data sources, not model logic.** Only cells where data *enters* the
  workbook (hardcoded actuals, lookups against pasted exports, external links) become
  SP.* formulas; subtotals, variances, ratios, and the user's assumptions stay as they
  are.
- **Validate before cleanup.** Compare the retrofitted copy against the original after
  sign-in and recalculation; delete or hide the old data tabs only after the user
  accepts the comparison.
- If editing the file programmatically, remember openpyxl drops charts, pivot tables,
  and slicers on re-save — check for them first and warn, or do the retrofit inside
  Excel instead.

## Troubleshooting a user's workbook

- Formulas rewritten as `_xludf.SP.FINANCIALS(...)` → Excel's add-in cache is corrupted;
  point the user to singlepaneapp.com → Resources → Excel Add-In Help → "Resetting Excel
  Add-In (xludf error)".
- Everything `#N/A` → sign in via Home ribbon Login button; token refreshes every 45 min
  and sessions can expire.
- Stale numbers → task pane **Clear Cached Data** then **Recalculate All Functions**
  (scalar results are cached up to 12 hours in-session).
- `#SPILL!` → clear the cells below/right of an array function.
