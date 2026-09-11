# Proven model patterns

Layouts that work well with the add-in's functions. Adapt freely — these are shapes,
not templates. In every pattern, the assumptions block (property code, year, version)
lives in labeled cells at the top so the user can repoint the model without editing
formulas.

## 1. Monthly P&L for one property

Rows = USALI lines, columns = Jan…Dec + Total Year.

```
      A                        B      C     D    ...  N
1  Property code:            ACD
2  Year:                     2025
3  Version:                  Actual
4  USALI line                Jan    Feb   Mar   ...  Total Year
5  Total Revenue - 100       =SP.FINANCIALS($B$1,$A5,B$4,$B$2,$B$3)   → fill right/down
6  Rooms Revenue - 110       ...
```

One formula, filled across the whole grid. Add a second grid (or interleaved columns)
with version `Budget` and difference/percent columns computed in Excel for a variance
view. For the row structure, use the canonical layouts in
[usali-layouts.md](usali-layouts.md) — Summary for an executive P&L, the department
tabs for detailed schedules — and validate any other line against the "Usali
Reference" sheet. For a clean printable report, the USALI strings can sit in a hidden/
grouped helper column next to the display labels, with the print area excluding it.

## 2. Actual vs Budget vs LY variance report

Columns: Actual, Budget, Var $ (=Actual−Budget), Var %, LY (`"LY_Actual"` version or
prior-year Actual), Var to LY. Either compute variances in Excel (transparent,
auditable) or use the `"Var_Budget"` / `"Var_LY_Actual"` versions to fetch them
directly. Use month `"<Mon>YTD"` for a month + YTD side-by-side report — the classic
month-end package is two such blocks.

## 3. Portfolio rollup with FILTER + FINANCIALS_AGG

```
1  Brand filter:        Marriott          (cell B1)
2  Codes:               =SP.FILTER(,"Brand",B1)        → spills codes + header at A4
3
4  Metric               2024                            2025
5  Total Revenue        =SP.FINANCIALS_AGG($A$4#,$A5,"Total Year",B$4,"Actual")
6  GOP                  ...
```

Nest the FILTER directly inside FINANCIALS_AGG when the code list doesn't need to be
visible (or park the spill in a hidden/grouped helper column). For per-hotel detail +
portfolio total: rows = codes (from the FILTER spill), columns = metrics via
SP.FINANCIALS, with an AGG row at the bottom.

Ratios across a portfolio: aggregate the components, not the ratio — e.g. portfolio
GOP margin = AGG(GOP)/AGG(Total Revenue), never AGG(GOP margin).

## 4. STR comp-set dashboard

Rows = months (as month-end dates — build them with `=EOMONTH(...)` so the 28/30/31
is always right), columns = Occ/ADR/RevPAR for Subject, then MPI / ARI / RGI. Use
`aggregateType "month"` with a month-end date per row, or a single `running12Month` /
`yearToDate` summary row (also month-end dated). For weekly views (`currentWeek`,
`running28Days`) the date must be a Saturday — STR weeks end Saturday; step rows
`=A6+7` from a known Saturday. Add `"CS1"` columns to show the comp set's own
Occ/ADR/RevPAR next to the subject.

```
=SP.STR($B$1, $A6, "month", C$5, C$4, "Total")
```

where row 4 holds Subject/CS1 and row 5 holds the metric name. Index metrics (MPI, ARI,
RGI) hover around 100; format them as numbers, not percents.

## 5. Pace / OTB report

Rows = future months (first-of-month dates, `"monthly"`), columns = OTB this year, OTB
same time last year, and pace:

```
OTB rev:    =SP.OTB($B$1,"monthly",$A6,"subject","ty","revenue","total",$B$2)
STLY rev:   =SP.OTB($B$1,"monthly",$A6,"subject","ly","revenue","total",$B$2)
Pace:       =B6-C6      (and % = B6/C6-1, wrapped in IFERROR)
```

`$B$2` = as-of date in the assumptions block. Add rn/adr columns the same way. For a
daily view use `"daily"` with one row per stay date.

## 6. Debt service schedule

Monthly rows with `=SP.GET_INTEREST_RATE("SOFR", $A6)` (+ spread) per period; future
dates return forward-curve values. Remember the function returns percent units — divide
by 100. Pin scenario dates with the `as_of_date` argument so the model doesn't shift
when curves update.

## 7. Per-key / per-room metrics

Land the room count once in the assumptions block via a lookup against "My
Properties" — `=XLOOKUP($B$1,'My Properties'!A:A,'My Properties'!M:M)` (column M =
Rooms) — and divide by that cell. KPI recipes (Occ %, ADR, RevPAR, PAR/POR stats) are
in [usali-layouts.md](usali-layouts.md).

## 8. Guest review scorecard

Two blocks. Top: the comp set comparison — one spill, subject first, members
alphabetical, with your own header row typed above it:

```
A5:  =SP.REVIEWS_COMP_SET($B$1,$B$2,$B$3)     // B2 source (blank = all), B3 as-of
```

(columns spill as name · review count · avg rating · TA rank · rank of · market —
missing metrics are blank, ranks populate only when source is blank/tripadvisor.com).

Below: monthly trend rows (month-start dates) for the subject —

```
Reviews:   =SP.REVIEWS($B$1,$A20,EOMONTH($A20,0),$B$2,"subject","review_count")
Rating:    =SP.REVIEWS($B$1,$A20,EOMONTH($A20,0),$B$2,"subject","avg_rating")
Response:  =SP.REVIEWS($B$1,$A20,EOMONTH($A20,0),$B$2,"subject","response_rate")
```

Add a `"cs"` twin column per metric to compare against the pooled comp set. For
lifetime totals as of month-end (review growth month over month), use
`=SP.REVIEWS_SUMMARY($B$1,$B$2,EOMONTH($A20,0),"subject","review_count")` and
difference consecutive rows. Ratings are on a 5-point scale; format `response_rate`
as a percent.

## Finishing touches

- Number formats: currency with no decimals for revenue/GOP/EBITDA, one decimal for
  occupancy %, two for ADR/RevPAR, plain numbers for STR indexes.
- Wrap ratio math in `IFERROR(...,"")` — missing data comes back as 0.
- Freeze panes below the header row; bold the assumptions block.
- Tell the user how to refresh (Login → Recalculate All Functions) and, if sharing
  outside the company, to save a copy and use Convert To Values.
