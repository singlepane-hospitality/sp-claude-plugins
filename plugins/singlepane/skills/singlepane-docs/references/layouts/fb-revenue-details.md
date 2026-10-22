# F&B Revenue Details — Singlepane detailed-financials layout

Read [../usali-layouts.md](../usali-layouts.md) first for how to read this table,
exact-string traps, and KPI-row recipes. USALI strings must be copied verbatim into
SP.FINANCIALS.

Revenue-line detail for every F&B outlet, one block per outlet (departments 201–225). Revenue lines only — the full per-outlet P&L is the F&B Outlets template above.

Outlet blocks are positional: OUTLET 1–18 are generic slots whose meaning differs by hotel (201–210 = Outlet 1–10,
217–219 = Outlet 11–13, 221–225 = Outlet 14–18). Resolve a named outlet ("the lobby bar") to its dept with the
`get_fb_outlets` tool — never by concept. Room Service, Banquets, Catering, Convention Services and F&B Overhead
keep their names at every hotel.

| Row label | USALI string (exact) | Notes |
|---|---|---|
| **OUTLET 1** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 201` |  |
| Food - Brunch Revenue | `Food - Brunch Revenue - 201` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 201` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 201` |  |
| Food - Late Night Revenue | `Food - Late Night Revenue - 201` |  |
| Food - Allowances | `Food - Allowances - 201` |  |
| Food - Special Event | `Food - Special Event - 201` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 201` |  |
| Food - Other Revenue | `Food - Other Revenue - 201` |  |
| Food Revenue | `Food Revenue - 201` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 201` |  |
| Beverage - Brunch Revenue | `Beverage - Brunch Revenue - 201` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 201` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 201` |  |
| Beverage - Late Night Revenue | `Beverage - Late Night Revenue - 201` |  |
| Beverage - Allowances | `Beverage - Allowances - 201` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 201` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 201` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 201` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 201` |  |
| Beverage - Special Event | `Beverage - Special Event - 201` |  |
| Beverage Revenue | `Beverage Revenue - 201` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 201` |  |
| Other - Special Event | `Other - Special Event - 201` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 201` |  |
| Other - Allowances | `Other - Allowances - 201` |  |
| Other Revenue | `Other Revenue - 201` | bold/subtotal |
| Outlet 1 - Total Revenue | `Total Revenue - 201` | bold/subtotal |
| **OUTLET 2** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 202` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 202` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 202` |  |
| Food - Allowances | `Food - Allowances - 202` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 202` |  |
| Food - Other Revenue | `Food - Other Revenue - 202` |  |
| Food Revenue | `Food Revenue - 202` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 202` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 202` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 202` |  |
| Beverage - Allowances | `Beverage - Allowances - 202` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 202` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 202` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 202` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 202` |  |
| Beverage Revenue | `Beverage Revenue - 202` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 202` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 202` |  |
| Other - Allowances | `Other - Allowances - 202` |  |
| Other Revenue | `Other Revenue - 202` | bold/subtotal |
| Outlet 2 - Total Revenue | `Total Revenue - 202` | bold/subtotal |
| **OUTLET 3** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 203` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 203` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 203` |  |
| Food - Allowances | `Food - Allowances - 203` |  |
| Food - Other Revenue | `Food - Other Revenue - 203` |  |
| Food Revenue | `Food Revenue - 203` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 203` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 203` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 203` |  |
| Beverage - Allowances | `Beverage - Allowances - 203` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 203` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 203` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 203` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 203` |  |
| Beverage Revenue | `Beverage Revenue - 203` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 203` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 203` |  |
| Other - Allowances | `Other - Allowances - 203` |  |
| Other Revenue | `Other Revenue - 203` | bold/subtotal |
| Outlet 3 - Total Revenue | `Total Revenue - 203` | bold/subtotal |
| **OUTLET 4** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 204` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 204` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 204` |  |
| Food - Allowances | `Food - Allowances - 204` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 204` |  |
| Food - Other Revenue | `Food - Other Revenue - 204` |  |
| Food Revenue | `Food Revenue - 204` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 204` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 204` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 204` |  |
| Beverage - Allowances | `Beverage - Allowances - 204` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 204` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 204` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 204` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 204` |  |
| Beverage Revenue | `Beverage Revenue - 204` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 204` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 204` |  |
| Other - Allowances | `Other - Allowances - 204` |  |
| Other Revenue | `Other Revenue - 204` | bold/subtotal |
| Outlet 4 - Total Revenue | `Total Revenue - 204` | bold/subtotal |
| **OUTLET 5** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 205` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 205` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 205` |  |
| Food - Allowances | `Food - Allowances - 205` |  |
| Food - Special Event | `Food - Special Event - 205` |  |
| Food - Other Revenue | `Food - Other Revenue - 205` |  |
| Food Revenue | `Food Revenue - 205` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 205` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 205` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 205` |  |
| Beverage - Allowances | `Beverage - Allowances - 205` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 205` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 205` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 205` |  |
| Beverage - Special Event | `Beverage - Special Event - 205` |  |
| Beverage Revenue | `Beverage Revenue - 205` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 205` |  |
| Other - Special Event | `Other - Special Event - 205` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 205` |  |
| Other - Allowances | `Other - Allowances - 205` |  |
| Other Revenue | `Other Revenue - 205` | bold/subtotal |
| Outlet 5 - Total Revenue | `Total Revenue - 205` | bold/subtotal |
| **OUTLET 6** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 206` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 206` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 206` |  |
| Food - Allowances | `Food - Allowances - 206` |  |
| Food - Special Event | `Food - Special Event - 206` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 206` |  |
| Food - Other Revenue | `Food - Other Revenue - 206` |  |
| Food Revenue | `Food Revenue - 206` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 206` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 206` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 206` |  |
| Beverage - Allowances | `Beverage - Allowances - 206` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 206` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 206` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 206` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 206` |  |
| Beverage - Special Event | `Beverage - Special Event - 206` |  |
| Beverage Revenue | `Beverage Revenue - 206` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 206` |  |
| Other - Special Event | `Other - Special Event - 206` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 206` |  |
| Other - Allowances | `Other - Allowances - 206` |  |
| Other Revenue | `Other Revenue - 206` | bold/subtotal |
| Outlet 6 - Total Revenue | `Total Revenue - 206` | bold/subtotal |
| **OUTLET 7** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 207` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 207` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 207` |  |
| Food - Allowances | `Food - Allowances - 207` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 207` |  |
| Food - Other Revenue | `Food - Other Revenue - 207` |  |
| Food Revenue | `Food Revenue - 207` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 207` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 207` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 207` |  |
| Beverage - Allowances | `Beverage - Allowances - 207` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 207` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 207` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 207` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 207` |  |
| Beverage Revenue | `Beverage Revenue - 207` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 207` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 207` |  |
| Other - Allowances | `Other - Allowances - 207` |  |
| Other Revenue | `Other Revenue - 207` | bold/subtotal |
| Outlet 7 - Total Revenue | `Total Revenue - 207` | bold/subtotal |
| **OUTLET 8** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 208` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 208` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 208` |  |
| Food - Allowances | `Food - Allowances - 208` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 208` |  |
| Food - Other Revenue | `Food - Other Revenue - 208` |  |
| Food Revenue | `Food Revenue - 208` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 208` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 208` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 208` |  |
| Beverage - Allowances | `Beverage - Allowances - 208` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 208` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 208` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 208` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 208` |  |
| Beverage Revenue | `Beverage Revenue - 208` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 208` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 208` |  |
| Other - Allowances | `Other - Allowances - 208` |  |
| Other Revenue | `Other Revenue - 208` | bold/subtotal |
| Outlet 8 - Total Revenue | `Total Revenue - 208` | bold/subtotal |
| **OUTLET 9** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 209` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 209` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 209` |  |
| Food - Coffee Break Revenue | `Food - Coffee Break Revenue - 209` |  |
| Food - Allowances | `Food - Allowances - 209` |  |
| Food - Other Revenue | `Food - Other Revenue - 209` |  |
| Food Revenue | `Food Revenue - 209` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 209` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 209` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 209` |  |
| Beverage - Allowances | `Beverage - Allowances - 209` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 209` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 209` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 209` |  |
| Beverage Revenue | `Beverage Revenue - 209` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 209` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 209` |  |
| Other - Allowances | `Other - Allowances - 209` |  |
| Other Revenue | `Other Revenue - 209` | bold/subtotal |
| Outlet 9 - Total Revenue | `Total Revenue - 209` | bold/subtotal |
| **OUTLET 10** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 210` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 210` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 210` |  |
| Food - Allowances | `Food - Allowances - 210` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 210` |  |
| Food - Other | `Food - Other Revenue - 210` |  |
| Food Revenue | `Food Revenue - 210` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 210` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 210` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 210` |  |
| Beverage - Allowances | `Beverage - Allowances - 210` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 210` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 210` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 210` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 210` |  |
| Beverage Revenue | `Beverage Revenue - 210` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 210` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 210` |  |
| Other - Allowances | `Other - Allowances - 210` |  |
| Other Revenue | `Other Revenue - 210` | bold/subtotal |
| Outlet 10 - Total Revenue | `Total Revenue - 210` | bold/subtotal |
| **ROOM SERVICE** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 211` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 211` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 211` |  |
| Food - Allowances | `Food - Allowances - 211` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 211` |  |
| Food - Other Revenue | `Food - Other Revenue - 211` |  |
| Food Revenue | `Food Revenue - 211` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 211` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 211` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 211` |  |
| Beverage - Allowances | `Beverage - Allowances - 211` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 211` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 211` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 211` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 211` |  |
| Beverage Revenue | `Beverage Revenue - 211` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 211` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 211` |  |
| Other - Allowances | `Other - Allowances - 211` |  |
| Other Revenue | `Other Revenue - 211` | bold/subtotal |
| Room Service - Total Revenue | `Total Revenue - 211` | bold/subtotal |
| **BANQUETS** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 213` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 213` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 213` |  |
| Food - Reception Revenue | `Food - Reception Revenue - 213` |  |
| Food - Coffee Break Revenue | `Food - Coffee Break Revenue - 213` |  |
| Food - Allowances | `Food - Allowances - 213` |  |
| Food - Other Revenue | `Food - Other Food Revenue - 213` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 213` |  |
| Food - Other Revenue | `Food - Other Revenue - 213` |  |
| Food Revenue | `Food Revenue - 213` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 213` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 213` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 213` |  |
| Beverage - Coffee Break Revenue | `Beverage - Coffee Break Revenue - 213` |  |
| Beverage - Reception | `Beverage - Reception - 213` |  |
| Beverage - Allowances | `Beverage - Allowances - 213` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 213` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 213` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 213` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 213` |  |
| Beverage Revenue | `Beverage Revenue - 213` | bold/subtotal |
| Other - Audiovisual Revenue | `Other - Audiovisual Revenue - 213` |  |
| Other - Room Rental & Setup Charges | `Other - Function Room Rental & Setup Charges - 213` |  |
| Other - Other Revenue | `Other - Other Revenue - 213` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 213` |  |
| Other - Allowances | `Other - Allowances - 213` |  |
| Other Revenue | `Other Revenue - 213` | bold/subtotal |
| Banquets - Total Revenue | `Total Revenue - 213` | bold/subtotal |
| **CATERING** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 214` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 214` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 214` |  |
| Food - Reception Revenue | `Food - Reception Revenue - 214` |  |
| Food - Coffee Break Revenue | `Food - Coffee Break Revenue - 214` |  |
| Food - Allowances | `Food - Allowances - 214` |  |
| Food - Other Revenue | `Food - Other Food Revenue - 214` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 214` |  |
| Food - Other Revenue | `Food - Other Revenue - 214` |  |
| Food Revenue | `Food Revenue - 214` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 214` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 214` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 214` |  |
| Beverage - Reception Revenue | `Beverage - Reception - 214` |  |
| Beverage - Coffee Break Revenue | `Beverage - Coffee Break Revenue - 214` |  |
| Beverage - Allowances | `Beverage - Allowances - 214` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 214` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 214` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 214` |  |
| Beverage Revenue | `Beverage Revenue - 214` | bold/subtotal |
| Other - Audiovisual Revenue | `Other - Audiovisual Revenue - 214` |  |
| Other - Room Rental & Setup Charges | `Other - Function Room Rental & Setup Charges - 214` |  |
| Other - Other Revenue | `Other - Other Revenue - 214` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 214` |  |
| Other - Allowances | `Other - Allowances - 214` |  |
| Other Revenue | `Other Revenue - 214` | bold/subtotal |
| Catering - Total Revenue | `Total Revenue - 214` | bold/subtotal |
| **CONVENTION SERVICES** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 215` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 215` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 215` |  |
| Food - Allowances | `Food - Allowances - 215` |  |
| Food - Special Event | `Food - Special Event - 215` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 215` |  |
| Food - Other Revenue | `Food - Other Revenue - 215` |  |
| Food Revenue | `Food Revenue - 215` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 215` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 215` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 215` |  |
| Beverage - Allowances | `Beverage - Allowances - 215` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 215` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 215` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 215` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 215` |  |
| Beverage - Special Event | `Beverage - Special Event - 215` |  |
| Beverage Revenue | `Beverage Revenue - 215` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 215` |  |
| Other - Special Event | `Other - Special Event - 215` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 215` |  |
| Other - Allowances | `Other - Allowances - 215` |  |
| Other Revenue | `Other Revenue - 215` | bold/subtotal |
| Convention Services - Total Revenue | `Total Revenue - 215` | bold/subtotal |
| **F&B OVERHEAD** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 216` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 216` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 216` |  |
| Food - Reception Revenue | `Food - Reception Revenue - 216` |  |
| Food - Coffee Break Revenue | `Food - Coffee Break Revenue - 216` |  |
| Food - Allowances | `Food - Allowances - 216` |  |
| Food - Other Revenue | `Food - Other Revenue - 216` |  |
| Food Revenue | `Food Revenue - 216` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 216` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 216` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 216` |  |
| Beverage - Reception Revenue | `Beverage - Reception - 216` |  |
| Beverage - Coffee Break Revenue | `Beverage - Coffee Break Revenue - 216` |  |
| Beverage - Allowances | `Beverage - Allowances - 216` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 216` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 216` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 216` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 216` |  |
| Beverage Revenue | `Beverage Revenue - 216` | bold/subtotal |
| Other - Audiovisual Revenue | `Other - Audiovisual Revenue - 216` |  |
| Other - Room Rental & Setup Charges | `Other - Function Room Rental & Setup Charges - 216` |  |
| Other - Other Revenue | `Other - Other Revenue - 216` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 216` |  |
| Other - Allowances | `Other - Allowances - 216` |  |
| Other Revenue | `Other Revenue - 216` | bold/subtotal |
| F&B Overhead - Total Revenue | `Total Revenue - 216` | bold/subtotal |
| **OUTLET 11** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 217` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 217` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 217` |  |
| Food - Allowances | `Food - Allowances - 217` |  |
| Food - Special Event | `Food - Special Event - 217` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 217` |  |
| Food - Other Revenue | `Food - Other Revenue - 217` |  |
| Food Revenue | `Food Revenue - 217` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 217` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 217` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 217` |  |
| Beverage - Allowances | `Beverage - Allowances - 217` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 217` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 217` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 217` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 217` |  |
| Beverage - Special Event | `Beverage - Special Event - 217` |  |
| Beverage Revenue | `Beverage Revenue - 217` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 217` |  |
| Other - Special Event | `Other - Special Event - 217` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 217` |  |
| Other - Allowances | `Other - Allowances - 217` |  |
| Other Revenue | `Other Revenue - 217` | bold/subtotal |
| Outlet 11 - Total Revenue | `Total Revenue - 217` | bold/subtotal |
| **OUTLET 12** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 218` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 218` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 218` |  |
| Food - Allowances | `Food - Allowances - 218` |  |
| Food - Special Event | `Food - Special Event - 218` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 218` |  |
| Food - Other Revenue | `Food - Other Revenue - 218` |  |
| Food Revenue | `Food Revenue - 218` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 218` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 218` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 218` |  |
| Beverage - Allowances | `Beverage - Allowances - 218` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 218` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 218` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 218` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 218` |  |
| Beverage - Special Event | `Beverage - Special Event - 218` |  |
| Beverage Revenue | `Beverage Revenue - 218` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 218` |  |
| Other - Special Event | `Other - Special Event - 218` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 218` |  |
| Other - Allowances | `Other - Allowances - 218` |  |
| Other Revenue | `Other Revenue - 218` | bold/subtotal |
| Outlet 12 - Total Revenue | `Total Revenue - 218` | bold/subtotal |
| **OUTLET 13** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 219` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 219` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 219` |  |
| Food - Allowances | `Food - Allowances - 219` |  |
| Food - Special Event | `Food - Special Event - 219` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 219` |  |
| Food - Other Revenue | `Food - Other Revenue - 219` |  |
| Food Revenue | `Food Revenue - 219` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 219` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 219` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 219` |  |
| Beverage - Allowances | `Beverage - Allowances - 219` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 219` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 219` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 219` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 219` |  |
| Beverage - Special Event | `Beverage - Special Event - 219` |  |
| Beverage Revenue | `Beverage Revenue - 219` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 219` |  |
| Other - Special Event | `Other - Special Event - 219` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 219` |  |
| Other - Allowances | `Other - Allowances - 219` |  |
| Other Revenue | `Other Revenue - 219` | bold/subtotal |
| Outlet 13 - Total Revenue | `Total Revenue - 219` | bold/subtotal |
| **OUTLET 14** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 221` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 221` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 221` |  |
| Food - Allowances | `Food - Allowances - 221` |  |
| Food - Special Event | `Food - Special Event - 221` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 221` |  |
| Food - Other Revenue | `Food - Other Revenue - 221` |  |
| Food Revenue | `Food Revenue - 221` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 221` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 221` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 221` |  |
| Beverage - Allowances | `Beverage - Allowances - 221` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 221` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 221` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 221` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 221` |  |
| Beverage - Special Event | `Beverage - Special Event - 221` |  |
| Beverage Revenue | `Beverage Revenue - 221` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 221` |  |
| Other - Special Event | `Other - Special Event - 221` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 221` |  |
| Other - Allowances | `Other - Allowances - 221` |  |
| Other Revenue | `Other Revenue - 221` | bold/subtotal |
| Outlet 14 - Total Revenue | `Total Revenue - 221` | bold/subtotal |
| **OUTLET 15** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 222` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 222` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 222` |  |
| Food - Allowances | `Food - Allowances - 222` |  |
| Food - Special Event | `Food - Special Event - 222` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 222` |  |
| Food - Other Revenue | `Food - Other Revenue - 222` |  |
| Food Revenue | `Food Revenue - 222` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 222` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 222` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 222` |  |
| Beverage - Allowances | `Beverage - Allowances - 222` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 222` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 222` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 222` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 222` |  |
| Beverage - Special Event | `Beverage - Special Event - 222` |  |
| Beverage Revenue | `Beverage Revenue - 222` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 222` |  |
| Other - Special Event | `Other - Special Event - 222` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 222` |  |
| Other - Allowances | `Other - Allowances - 222` |  |
| Other Revenue | `Other Revenue - 222` | bold/subtotal |
| Outlet 15 - Total Revenue | `Total Revenue - 222` | bold/subtotal |
| **OUTLET 16** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 223` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 223` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 223` |  |
| Food - Allowances | `Food - Allowances - 223` |  |
| Food - Special Event | `Food - Special Event - 223` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 223` |  |
| Food - Other Revenue | `Food - Other Revenue - 223` |  |
| Food Revenue | `Food Revenue - 223` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 223` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 223` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 223` |  |
| Beverage - Allowances | `Beverage - Allowances - 223` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 223` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 223` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 223` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 223` |  |
| Beverage - Special Event | `Beverage - Special Event - 223` |  |
| Beverage Revenue | `Beverage Revenue - 223` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 223` |  |
| Other - Special Event | `Other - Special Event - 223` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 223` |  |
| Other - Allowances | `Other - Allowances - 223` |  |
| Other Revenue | `Other Revenue - 223` | bold/subtotal |
| Outlet 16 - Total Revenue | `Total Revenue - 223` | bold/subtotal |
| **OUTLET 17** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 224` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 224` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 224` |  |
| Food - Allowances | `Food - Allowances - 224` |  |
| Food - Special Event | `Food - Special Event - 224` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 224` |  |
| Food - Other Revenue | `Food - Other Revenue - 224` |  |
| Food Revenue | `Food Revenue - 224` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 224` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 224` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 224` |  |
| Beverage - Allowances | `Beverage - Allowances - 224` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 224` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 224` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 224` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 224` |  |
| Beverage - Special Event | `Beverage - Special Event - 224` |  |
| Beverage Revenue | `Beverage Revenue - 224` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 224` |  |
| Other - Special Event | `Other - Special Event - 224` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 224` |  |
| Other - Allowances | `Other - Allowances - 224` |  |
| Other Revenue | `Other Revenue - 224` | bold/subtotal |
| Outlet 17 - Total Revenue | `Total Revenue - 224` | bold/subtotal |
| **OUTLET 18** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - 225` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - 225` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - 225` |  |
| Food - Allowances | `Food - Allowances - 225` |  |
| Food - Special Event | `Food - Special Event - 225` |  |
| Food - All Meal Periods | `Food - All Meal Periods - 225` |  |
| Food Revenue | `Food Revenue - 225` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - 225` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - 225` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - 225` |  |
| Beverage - Allowances | `Beverage - Allowances - 225` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - 225` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - 225` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - 225` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - 225` |  |
| Beverage - Special Event | `Beverage - Special Event - 225` |  |
| Beverage Revenue | `Beverage Revenue - 225` | bold/subtotal |
| Other - Other Revenue | `Other - Other Revenue - 225` |  |
| Other - Special Event | `Other - Special Event - 225` |  |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - 225` |  |
| Other - Allowances | `Other - Allowances - 225` |  |
| Other Revenue | `Other Revenue - 225` | bold/subtotal |
| Outlet 18 - Total Revenue | `Total Revenue - 225` | bold/subtotal |
| Total F&B Revenue | `Total Revenue - 200` | bold/subtotal |

