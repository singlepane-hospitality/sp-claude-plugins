# Singlepane SP.* function reference

Complete argument-level reference for the supported functions in the add-in (v2.1.x).
All functions are async (Excel shows `#BUSY!` briefly) and require the user to be signed
in. Arguments accept literals (`"ACD"`) — but per the skill's conventions, prefer cell
references to input cells for every argument.

**Supported functions — use ONLY these.** Other `SP.*` functions exist in the add-in
(dashboard/spill data functions like `SP.REV_GOP_EBITDA`, `SP.FLOW_THROUGH`,
`SP.STR_INDEX`, `SP.RISK_UPSIDE`, `SP.GUEST_SATISFACTION`, plus scalar helpers like
`SP.GET_HOTEL_ATTRIBUTE`, `SP.GET_STAR_ID`, `SP.PROPERTY_COUNT`) — they are legacy /
undocumented and must not be used in new models. If you see them in an existing
workbook, leave them alone but don't propagate them. Build everything from:

1. `SP.FINANCIALS` / `SP.FINANCIALS_AGG` — financial data
2. `SP.FILTER` — property-code selection
3. `SP.STR` / `SP.STR_COMP_SET` — STR comp-set data & set composition
4. `SP.OTB` — on-the-books / pace
5. `SP.REVIEWS` / `SP.REVIEWS_SUMMARY` / `SP.REVIEWS_COMP_SET` — guest reviews
6. `SP.GET_INTEREST_RATE` — benchmark rates
7. `SP.GET_HOTEL_REFERENCE` / `SP.GET_USALI_REFERENCE` — reference spills

The review functions and comp-set spills require add-in **v2.1.026 or later** — if a
user's workbook errors on them, have them update the add-in first.

---

## 1. SP.FINANCIALS(code, usali, month, year, version)

One P&L / budget / forecast value for one property. Returns a number (0 if no data).

| Arg | Type | Valid values |
|---|---|---|
| code | string | A property code from "My Properties" (e.g. `"ACD"`) |
| usali | string | An exact line from "Usali Reference", e.g. `"Total Revenue - 100"`, including the ` - <number>` suffix. See [usali-layouts.md](usali-layouts.md) for the canonical report layouts and their exact strings |
| month | string | `"Jan"`–`"Dec"` · `"Total Year"` · `"Q1"`/`"Q2"`/`"Q3"`/`"Q4"` · `"<Mon>YTD"` (e.g. `"JulYTD"`) · `"<Mon>TTM"` trailing-12 · `"<Mon>BOY"` balance-of-year — month+suffix has no space |
| year | number | 4-digit year |
| version | string | `"Actual"`, `"Budget"`, `"Budget1"`–`"Budget12"`, `"Forecast1"`–`"Forecast12"`, `"Proforma"`, `"LY_Actual"`, `"Var_Budget"`, `"Var_LY_Actual"`. Case-insensitive. Companies may have additional named versions. |

```excel
=SP.FINANCIALS($B$1,$A6,C$4,$B$2,$B$3)      // all args from input cells — preferred
=SP.FINANCIALS("ACD","Total Revenue - 100","JulYTD",2025,"Actual")   // literal form
```

## 2. SP.FINANCIALS_AGG(codes, usali, month, year, version)

Identical to SP.FINANCIALS but `codes` is a **range or array of property codes** and the
result is aggregated across them. A header cell containing `codes` (as spilled by
SP.FILTER) is ignored automatically, so you can pass a FILTER spill directly.

```excel
=SP.FINANCIALS_AGG(Inputs!$A$2#,$A6,C$4,$B$2,$B$3)   // spill reference from inputs sheet
=SP.FINANCIALS_AGG(SP.FILTER(,"Brand",$B$1),"Total Revenue - 100","Jun",2025,"Actual")
```

Aggregation semantics: values are summed across properties for currency/count accounts.
For ratio-type lines (occupancy %, ADR, margins) compute the ratio from aggregated
components rather than aggregating the ratio line.

## 3. SP.FILTER([codes], [filter1], [value1], … [filter5], [value5]) — spills

Returns a one-column array of property codes (header row `codes`) matching up to five
attribute filters, ANDed together. Each value can be a single string, a comma-separated
list (OR within the filter), or a range of cells.

| Arg | Notes |
|---|---|
| codes (optional) | Range of codes to restrict the search to; omit to search all authorized hotels (leave the slot empty: `SP.FILTER(,"Brand",$B$1)`) |
| filterN | Attribute name — see list below |
| valueN | Matching value(s) for filterN — prefer an input cell |

Valid filter attribute names: `Ownership`, `ManagementCompany`, `HotelCompany`,
`Brand`, `ManagedOrFranchised`, `Market`, `STRMarketClass`, `RoomRange`, `Union`,
`Rooms`, `AssetManager`, `Fund`, `Lender`, `ServiceLevel`, `ProductType`,
`InvestmentStage`, `MeetingSpaceSqft`, `UDF1`–`UDF20`.

Values are exact strings from the user's data (check the "My Properties" sheet — e.g.
"Marriott" may live in `HotelCompany` while `Brand` holds the flag like "Courtyard").

```excel
=SP.FILTER(,"ProductType","Resort,Urban")                       // OR within one filter
=SP.FILTER(,"Brand",$B$1,"Market",$B$2)                         // AND across filters
```

Returns `No data` if nothing matches. Primarily designed to feed SP.FINANCIALS_AGG.

## 4. SP.STR(code, date, aggregateType, metric, [subject_comp_market], [segment])

STR (Smith Travel Research) performance for the subject hotel and its comp sets.
Returns a scalar.

| Arg | Valid values |
|---|---|
| code | Property code |
| date | `"YYYY-MM-DD"` or Excel date. Report date — e.g. month-end for monthly data |
| aggregateType | **Case-sensitive:** `day`, `month`, `monthToDate`, `currentWeek`, `running28Days`, `yearToDate`, `running3Month`, `running12Month` |
| metric | `Occ`, `ADR`, `RevPAR` · `% Chg` variants: `Occ % Chg`, `ADR % Chg`, `RevPAR % Chg` · indexes: `MPI`, `ARI`, `RGI` (+ `% Chg` variants) · ranks: `Occ Rank`, `ADR Rank`, `RevPAR Rank`, `Occ % Chg Rank`, `ADR % Chg Rank`, `RevPAR % Chg Rank` (case-insensitive) |
| subject_comp_market (optional, default `Subject`) | `Subject`, `CS1`–`CS5` (comp sets), `Market Scale` |
| segment (optional, default `Total`) | `Total`, `Group`, `Contract`, `Transient` |

```excel
=SP.STR($B$1,$A6,"month",C$5,C$4,"Total")                 // grid form off input cells
=SP.STR("ACD","2025-06-30","month","RGI","CS2","Total")   // June RGI vs comp set 2
```

**Which date to pass for each aggregate type** — getting this wrong returns no/wrong
data:

| Aggregate type | Date to pass | Excel helper |
|---|---|---|
| `month`, `yearToDate`, `running3Month`, `running12Month` | **Month-end date** (28th/30th/31st) of the period's last month | `=EOMONTH(date,0)` |
| `currentWeek`, `running28Days` | **A Saturday** — STR weeks end Saturday | most recent Saturday on/before d: `=d-WEEKDAY(d,16)+1` |
| `day`, `monthToDate` | The actual day you want (for `monthToDate`, the as-of day) | — |

When building a monthly STR grid, generate the date column with
`=EOMONTH(DATE($B$2,ROW()-5,1),0)`-style formulas so every row is guaranteed to be a
month-end; for weekly grids, step `=A6+7` from a known Saturday.

Note on indexes: MPI/ARI/RGI are already subject-vs-compset ratios, so requesting an
index for `CS1`–`CS5` returns the index computed against that comp set. Occ/ADR/RevPAR
with `CS1`–`CS5` return the comp set's own performance.

## 5. SP.STR_COMP_SET(code, [as_of_date], [compset]) — spills

The membership of one STR competitive set: one row per member hotel, two columns
(hotel name, rooms), **no header row** — write your own labels in the row above the
spill. The subject property appears as a member of its own set (that's how it's
reported in the STR file).

| Arg | Valid values |
|---|---|
| code | Property code |
| as_of_date (optional) | Blank/omitted = latest composition. A date returns the composition in effect as of that date (most recent STR report on or before it) — useful next to a historical SP.STR grid, since set membership changes over time |
| compset (optional) | `CS1`–`CS5` (or a bare group number). Blank/omitted = CS1 |

```excel
=SP.STR_COMP_SET($B$1)                    // current primary comp set
=SP.STR_COMP_SET($B$1,$B$2,"CS2")         // CS2 as of the report date in B2
```

Errors with `No STR comp set found` (`#N/A`) when the property has no set with that
number. Not batched (one backend call per spill), cached like the scalar functions.

## 6. SP.OTB(code, dailyOrMonthly, stayDate, targetSet, periodType, metric, segment, [asOfDate])

Reservation / pace data for stay dates as of a booking snapshot date.

| Arg | Valid values |
|---|---|
| code | Property code |
| dailyOrMonthly | `"daily"` or `"monthly"` |
| stayDate | `"YYYY-MM-DD"` or Excel date. For `monthly`, use the first of the month |
| targetSet | `"subject"` (the hotel) or `"cs"` (comp set) |
| periodType | `"ty"` (this year) or `"ly"` (same time last year, offset dates) |
| metric | `occ`, `rn` (room nights), `adr`, `revenue`, `revpar`, `as_of_date` (returns the snapshot date actually used) |
| segment | `"total"`, `"group"`, `"transient"` |
| asOfDate (optional) | Snapshot date — uses the nearest as-of date **not exceeding** this. Omit for the latest available. Put it in an input cell so the whole report reprices from one cell |

```excel
=SP.OTB($B$1,"monthly",$A6,"subject","ty","revenue","total",$B$2)
=SP.OTB($B$1,"monthly",$A6,"subject","ly","revenue","total",$B$2)   // STLY pair for pace
```

Pace = ty vs ly at the same as-of offset: build both columns and difference them.
Metric availability can vary with the property's data subscriptions.

## 7. SP.REVIEWS(code, start_date, end_date, source, subject_cs, metric)

Guest review metrics computed over the individual reviews **posted in a date range**
(both endpoints inclusive). Returns a scalar (0 if no data). Review data exists only
for properties (and review comp sets) with review scraping configured in Singlepane —
a hotel that's never been set up returns 0, not an error.

| Arg | Valid values |
|---|---|
| code | Property code |
| start_date / end_date | `"YYYY-MM-DD"` or Excel dates; range includes both days |
| source | `booking.com`, `expedia.com`, `google.com`, `tripadvisor.com` (case-insensitive, the `.com` optional). Blank = all sources combined |
| subject_cs | `"subject"` (the property — the default when blank) or `"cs"` (pooled across the property's review comp set members, subject excluded) |
| metric | `review_count` · `avg_rating` (5-point scale — Booking/Expedia 10-point ratings are normalized) · `response_rate` (fraction 0–1 of reviews with a management reply) · `1_star_count`…`5_star_count` (rating rounded to the nearest whole star) |

```excel
=SP.REVIEWS($B$1,$A6,EOMONTH($A6,0),$B$2,"subject",C$4)      // monthly grid row
=SP.REVIEWS("ACD","2026-08-01","2026-08-31","google.com","subject","avg_rating")
```

All six argument slots must be present — leave `source`/`subject_cs` blank (empty
input cell, or a skipped slot like `,,`) for the defaults. The review comp set is
configured in Singlepane's guest-review module and is **not** the STR comp set.

## 8. SP.REVIEWS_SUMMARY(code, source, as_of_date, subject_cs, metric)

**Site-lifetime** review totals as the review sites themselves display them, captured
by Singlepane's periodic scrapes. Use this for "how many Google reviews / what's our
TripAdvisor rating today (or as of month-end)"; use SP.REVIEWS for "reviews received
in August". Returns a scalar (0 if unavailable).

| Arg | Valid values |
|---|---|
| code | Property code |
| source | Same values as SP.REVIEWS; blank = pooled across sources |
| as_of_date | Blank = latest scrape; a date uses the latest scrape on or before it (per hotel × source). Put it in an input cell for reproducible month-over-month comparisons |
| subject_cs | `"subject"` (default) / `"cs"` (comp set members pooled, subject excluded) |
| metric | `review_count` (summed) · `avg_rating` (count-weighted across sources/members, 5-point scale) · TripAdvisor market-ranking snapshot: `ranking`, `ranking_out_of`, `geo_location_name` (returns text) — these three are subject-only and need source blank or `tripadvisor.com`, otherwise 0 |

```excel
=SP.REVIEWS_SUMMARY($B$1,$B$2,$B$3,"subject","review_count")
=SP.REVIEWS_SUMMARY($B$1,,,"subject","ranking")     // current TA market rank
```

All five argument slots must be present; blanks take the defaults above.

## 9. SP.REVIEWS_COMP_SET(code, [source], [as_of_date]) — spills

The property's review comp set as a ready-made comparison table: the subject hotel
first, then each member alphabetically. Six columns, **no header row** (write your
own labels above the spill): hotel name · review count · avg rating · TripAdvisor
ranking · rank out of · market name.

| Arg | Valid values |
|---|---|
| code | Property code |
| source (optional) | Same values as SP.REVIEWS. Blank/omitted = pooled across all sources |
| as_of_date (optional) | Blank/omitted = latest scrape; else latest scrape on or before the date |

```excel
=SP.REVIEWS_COMP_SET($B$1)
=SP.REVIEWS_COMP_SET($B$1,"tripadvisor.com",$B$2)
```

Values follow SP.REVIEWS_SUMMARY semantics (site-lifetime totals, count-weighted
pooling, 5-point scale). The two ranking columns and the market name are TripAdvisor
data: populated when source is blank or `tripadvisor.com`, blank otherwise. Missing
metrics spill as **blank cells**, not zeros. Only display names are returned — member
property codes are never exposed (demo logins see masked competitor names) — so key
any lookups off this spill by hotel name. Errors with `No review comp set found`
(`#N/A`) when the property has no review comp set configured. Not batched, cached
like the scalar functions.

## 10. SP.GET_INTEREST_RATE(benchmark_rate, date, [as_of_date])

Percent rate for a benchmark on a date (forward-curve values for future dates).

| Arg | Valid values |
|---|---|
| benchmark_rate | `"SOFR"`, `"SONIA"`, `"T10YR"` (case-insensitive) |
| date | Date the rate applies to |
| as_of_date (optional) | Which model-update date's curve to use — pin it in an input cell so the model doesn't shift when curves update |

```excel
=SP.GET_INTEREST_RATE($B$1,$A6,$B$2)
```

Returned as a percent (e.g. `5.33` = 5.33%) — divide by 100 before using in interest
calculations, and verify scale against a known value on first use.

## 11. Reference spills

### SP.GET_HOTEL_REFERENCE() — spills
Every authorized hotel × every attribute. This is what populates the auto-created
"My Properties" sheet. Columns, in order:
`Code, StarId, HotelName, Ownership, ManagementCompany, HotelCompany, Brand,
ManagedOrFranchised, Market, STRMarketClass, RoomRange, Union, Rooms, AssetManager,
OpenDate, AcquisitionDate, SaleDate, Fund, Lender, ServiceLevel, ProductType,
InvestmentStage, MeetingSpaceSqft, UDF1…UDF20, Address, City, State, Country, SuiteMix,
TwoBeddedMix, InteriorMeetingSpaceSqft, OutdoorMeetingSpaceSqft,
LargestMeetingSpaceSqft, NumberOfMeetingSpaces, STRSubClass, LatestRenovationYear,
ResortFee, ResortFeeAmount, HasSpa, SpaManagement, SpaNumberTreatmentRooms,
FitnessCenterSqft, NumberIndoorPools, NumberOutdoorPools, IsMixedUse, HasSki,
HasWaterpark, HasCasino, HasGolf, IsResort, AllInclusive, MaterialFBRevenue,
NumberInHouseFBOutlets, NumberManagedFBOutlets, OffersParking, UnionContractStart,
UnionContractEnd, UnionHousekeeping, UnionFrontDesk, UnionFB, UnionEngineering,
LaundryType, PropertyType`

To use a single attribute in a model (room count, brand, market), `XLOOKUP` the code
against the "My Properties" sheet rather than calling any per-attribute function:
```excel
=XLOOKUP($B$1,'My Properties'!A:A,'My Properties'!M:M)    // Rooms for the input code
```

### SP.GET_USALI_REFERENCE() — spills
All USALI/GL account lines. Columns: `usali, category, dept, sub_dept, default_metric`.
The `usali` column is the exact string SP.FINANCIALS expects. Populates the
auto-created "Usali Reference" sheet. Handy as the source range for a data-validation
dropdown on a USALI input cell.

---

## Caching & batching

- FINANCIALS, FINANCIALS_AGG, STR, OTB, REVIEWS, REVIEWS_SUMMARY, and FILTER batch all
  concurrent cell calls into one backend request (100 ms window) and cache results for
  up to 12 hours — large models recalc fast; a grid of thousands of SP.FINANCIALS
  cells is a normal, supported design.
- The comp-set spills (STR_COMP_SET, REVIEWS_COMP_SET) are not batched — one backend
  call per spill — but cache for 12 hours like the scalars.
- Reference spills cache for the whole session; GET_INTEREST_RATE is never cached.
- The task pane's **Clear Cached Data** + **Recalculate All Functions** force a full
  refresh.
