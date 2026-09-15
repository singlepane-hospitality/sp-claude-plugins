# Singlepane detailed-financials layouts (USALI account reference)

These are the canonical report layouts from Singlepane's own **Detailed Financials** UI,
extracted directly from the application source. Use them as the default row structure when a
user asks for a "summary P&L", "rooms schedule", "F&B schedule", "labor report", etc. —
they are what Singlepane users already see in the product, so a workbook built this way will
look familiar.

Every string in the **USALI string (exact)** column is the literal account line to pass to
`SP.FINANCIALS` / `SP.FINANCIALS_AGG` (e.g. `=SP.FINANCIALS("ACD", "Total Revenue - 100", ...)`).
**Copy them verbatim** — the ` - NNN` department suffix is part of the string, and several
strings contain irregularities that must be preserved exactly:

- `Total Banquets Beverage- 200` — no space before the dash.
- `Mgmt Hours Worked  - 000` and `Non Mgmt Hours Worked  - 000` — **two** spaces before the dash.
- `Workers’ Compensation Insurance - 100` — curly apostrophe (but the 000-level `Workers Compensation Insurance - 000` has none).
- `ELECTRIC (KWH)`, `GAS (THERMS)`, `WATER (GALLONS)` — utility consumption stats with no department suffix.

### How to read the tables

- **SECTION HEADER** rows are display-only headings (no account behind them) — render them as bold text rows in Excel.
- **bold/subtotal** marks rows the UI renders bold — totals/subtotals. The subtotal accounts are real USALI lines (the platform computes them), so pull them with SP.FINANCIALS rather than SUMming detail rows — details may not tie exactly to the platform total.
- **KPI** rows (Occupancy, ADR, RevPAR, per-segment ADR, …) are *derived*: the UI requests a server-side metric ("PAR" = per available room, "POR" = per occupied room, "DM" = daily metric / ADR-style) against the base account shown. In Excel, compute them as the division given in the Notes column (e.g. Occupancy = `Total Rooms Sold - 100` ÷ `Total Rooms Available - 100`; ADR = `Total Revenue - 100` ÷ `Total Rooms Occupied - 100`; RevPAR = `Total Revenue - 100` ÷ `Total Rooms Available - 100`). These recipes reproduce the UI's server-side math from base accounts; spot-check against the Singlepane UI if exactness matters.
- Blank spacer rows in the UI are omitted here; add blank rows between sections in Excel for readability.
- The same account can appear more than once (e.g. `Total Revenue - 100` appears as ADR, RevPAR and as the Rooms revenue line) — the row label and KPI math distinguish them.

### Department suffix decoder

The ` - NNN` suffix encodes the USALI department:

| Suffix | Department |
|---|---|
| 100 | Rooms |
| 200 | Food & Beverage (all outlets consolidated) |
| 201–225 | Individual F&B outlets (see the F&B Outlets section; 212 = Minibar, reported under Other Operated; 220 is unused) |
| 300 | Other Operated Departments (total) |
| 305 | Casino |
| 310 | Health Club/Spa |
| 320 | Parking |
| 330 | Recreation |
| 340 | Retail |
| 350 | Guest Communications |
| 360 | Laundry & Dry Cleaning |
| 370 | Minor Operated Department-3 ("Other Operated Department") |
| 380 | Minor Operated Department-4 ("Misc. Minor Operated Department") |
| 390 | Golf Course & Pro Shop |
| 400 | Miscellaneous Income |
| 500 | Administrative & General |
| 600 | Information & Telecom Systems |
| 700 | Sales & Marketing (incl. Franchise Fees) |
| 800 | Repairs & Maintenance (Property Operations) |
| 810 | Utilities |
| 900 | Non-Operating income & expenses (rent, taxes, insurance, FX, other) |
| 910 | Interest, Depreciation & Amortization |
| 920 | Management Fees |
| 930 | FF&E Replacement Reserve |
| 940 | House Laundry (labor) |
| 950 | Staff Dining (labor) |
| 000 | Property-level totals & KPIs (Total Revenue, GOP, EBITDA, NOI, total labor, …) |

## Layout files — read ONLY the one(s) you need

Each report layout lives in its own file under `layouts/`. To keep responses fast,
read just the file(s) for the view being built — never all of them.

| View | File | ~rows |
|---|---|---|
| Summary | [layouts/summary.md](layouts/summary.md) | 62 |
| Rooms | [layouts/rooms.md](layouts/rooms.md) | 186 |
| Consolidated F&B | [layouts/consolidated-fb.md](layouts/consolidated-fb.md) | 133 |
| F&B Outlets (per-outlet template) | [layouts/fb-outlets.md](layouts/fb-outlets.md) | 163 |
| F&B Revenue Details | [layouts/fb-revenue-details.md](layouts/fb-revenue-details.md) | 560 |
| Other Operated Dpt. | [layouts/other-op-dpt.md](layouts/other-op-dpt.md) | 102 |
| Misc. Income | [layouts/misc-income.md](layouts/misc-income.md) | 18 |
| A&G | [layouts/a-g.md](layouts/a-g.md) | 93 |
| I&T | [layouts/i-t.md](layouts/i-t.md) | 96 |
| S&M | [layouts/s-m.md](layouts/s-m.md) | 93 |
| R&M | [layouts/r-m.md](layouts/r-m.md) | 90 |
| Utilities | [layouts/utilities.md](layouts/utilities.md) | 28 |
| Non-Operating | [layouts/non-operating.md](layouts/non-operating.md) | 33 |
| Labor | [layouts/labor.md](layouts/labor.md) | 102 |

## Choosing the right view

- **Summary** is the default for an owner/executive P&L — one page from KPIs down to net income, all at department-total level.
- The **department tabs** (Rooms, Consolidated F&B, Other Operated Dpt., Misc. Income, A&G, I&T, S&M, R&M, Utilities, Non-Operating) are the detailed schedules behind each Summary line — use them when the user wants a full departmental schedule or a specific expense line.
- **F&B Outlets** (template, depts 201+) gives a full P&L for one outlet; **F&B Revenue Details** lists revenue lines for all outlets at once.
- **Labor** is the property-wide labor cost and hours view (000-level totals with per-department breakdown, including 940 House Laundry and 950 Staff Dining).
- When you only need a top-line number (Total Revenue, GOP, EBITDA, NOI), use the 000-suffix account from the Summary layout rather than summing departments.
