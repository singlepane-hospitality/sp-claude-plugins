# F&B Outlets (per-outlet template) — Singlepane detailed-financials layout

Read [../usali-layouts.md](../usali-layouts.md) first for how to read this table,
exact-string traps, and KPI-row recipes. USALI strings must be copied verbatim into
SP.FINANCIALS.

The UI generates this tab dynamically, one outlet department at a time, from a single
template: every account is the same line item with the outlet's department number as the
suffix. In the table below `{dept}` is the outlet department number — substitute `201`,
`202`, etc. to get the exact string (e.g. `Total Revenue - {dept}` → `Total Revenue - 201`).

**Outlets are positional, not concepts.** Operators book their outlets to these departments
by position, so most of them are generic "Outlet N" slots whose meaning differs by hotel —
one hotel's Outlet 1 (201) is its lobby bar, another's is a steakhouse. A hotel's real outlet
names and aliases come from the `get_fb_outlets` tool: when the user names an outlet ("the
lobby bar", "Bourbon Steak", "Outlet 3"), call it first and take the dept number from its
result — never infer the dept from what the outlet is. Generic outlet departments:

| Dept | Outlet | Dept | Outlet |
|---|---|---|---|
| 201 | Outlet 1 | 202 | Outlet 2 |
| 203 | Outlet 3 | 204 | Outlet 4 |
| 205 | Outlet 5 | 206 | Outlet 6 |
| 207 | Outlet 7 | 208 | Outlet 8 |
| 209 | Outlet 9 | 210 | Outlet 10 |
| 217 | Outlet 11 | 218 | Outlet 12 |
| 219 | Outlet 13 | 221 | Outlet 14 |
| 222 | Outlet 15 | 223 | Outlet 16 |
| 224 | Outlet 17 | 225 | Outlet 18 |

The fixed-meaning departments keep their names at every hotel: 211 Room Service,
213 Banquets, 214 Catering, 215 Convention Services, 216 F&B Overhead.

(212 = Minibar also exists but is reported on the Other Operated Dpt. tab; 200 is
consolidated F&B and 220 a rollup — neither is an outlet. Not every account exists for every
outlet — rows below note the exceptions. A missing account for a given outlet simply returns
no data.)

| Row label | USALI string (exact) | Notes |
|---|---|---|
| **{Outlet name}** | — | SECTION HEADER |
| Food - Breakfast Revenue | `Food - Breakfast Revenue - {dept}` |  |
| Food - Brunch Revenue | `Food - Brunch Revenue - {dept}` |  |
| Food - Lunch Revenue | `Food - Lunch Revenue - {dept}` |  |
| Food - Dinner Revenue | `Food - Dinner Revenue - {dept}` |  |
| Food - Late Night Revenue | `Food - Late Night Revenue - {dept}` |  |
| Food - Reception Revenue | `Food - Reception Revenue - {dept}` | only defined for depts 213, 214, 216 |
| Food - Coffee Break Revenue | `Food - Coffee Break Revenue - {dept}` | only defined for depts 209, 213, 214, 216 |
| Food - Allowances | `Food - Allowances - {dept}` |  |
| Food - Other Revenue | `Food - Other Revenue - {dept}` | not defined for dept 225 |
| Food - Special Event | `Food - Special Event - {dept}` | not defined for depts 202, 203, 204, 207, 208, 209, 210, 211, 213, 214, 216 |
| Food - All Meal Periods | `Food - All Meal Periods - {dept}` | not defined for depts 203, 205, 209, 216 |
| Food Revenue | `Food Revenue - {dept}` | bold/subtotal |
| Beverage - Breakfast Revenue | `Beverage - Breakfast Revenue - {dept}` |  |
| Beverage - Brunch Revenue | `Beverage - Brunch Revenue - {dept}` |  |
| Beverage - Lunch Revenue | `Beverage - Lunch Revenue - {dept}` |  |
| Beverage - Dinner Revenue | `Beverage - Dinner Revenue - {dept}` |  |
| Beverage - Late Night Revenue | `Beverage - Late Night Revenue - {dept}` |  |
| Beverage - Reception | `Beverage - Reception - {dept}` | only defined for depts 213, 214, 216 (note: no "Revenue" in the account name) |
| Beverage - Coffee Break Revenue | `Beverage - Coffee Break Revenue - {dept}` | only defined for depts 213, 214, 216 |
| Beverage - Allowances | `Beverage - Allowances - {dept}` |  |
| Beverage - Beer Revenue | `Beverage - Beer Revenue - {dept}` |  |
| Beverage - Wine Revenue | `Beverage - Wine Revenue - {dept}` |  |
| Beverage - Liquor Revenue | `Beverage - Liquor Revenue - {dept}` |  |
| Beverage - Other Revenue | `Beverage - Other Revenue - {dept}` | not defined for depts 205, 209, 214 |
| Beverage - Special Event | `Beverage - Special Event - {dept}` | not defined for depts 202, 203, 204, 207, 208, 209, 210, 211, 213, 214, 216 |
| Beverage Revenue | `Beverage Revenue - {dept}` | bold/subtotal |
| Other - Audiovisual Revenue | `Other - Audiovisual Revenue - {dept}` | only defined for depts 213, 214, 216, 219 |
| Other - Function Room Rental & Setup Charges | `Other - Function Room Rental & Setup Charges - {dept}` | only defined for depts 213, 214, 216, 219 |
| Other - Other Revenue | `Other - Other Revenue - {dept}` |  |
| Other - Special Event | `Other - Special Event - {dept}` | not defined for depts 202, 203, 204, 207, 208, 209, 210, 211, 213, 214, 216 |
| Other - Surcharges & Service Charges | `Other - Surcharges & Service Charges - {dept}` |  |
| Other - Allowances | `Other - Allowances - {dept}` |  |
| Other Revenue | `Other Revenue - {dept}` | bold/subtotal |
| Total Revenue | `Total Revenue - {dept}` | bold/subtotal |
| **FOOD & BEVERAGE EXPENSES** | — | SECTION HEADER |
| **COST OF SALES** | — | SECTION HEADER |
| Cost of Food | `Cost of Food Sales - {dept}` |  |
| Cost of Beverage | `Cost of Beverage Sales - {dept}` |  |
| Total Cost Of F&B Sales | `Total Cost of F&B Sales - {dept}` | bold/subtotal |
| Cost of Other Revenue | `Total Cost of Other Revenue - {dept}` |  |
| Total Cost Of Sales | `Total Cost of Sales & Other Revenue - {dept}` | bold/subtotal |
| **SALARIES, WAGES AND BONUSES** | — | SECTION HEADER |
| Management | `S&W Management - {dept}` |  |
| Non-Management | `S&W Non-Management - {dept}` |  |
| Other | `S&W Other - {dept}` |  |
| Total Salaries and Wages | `Total Salaries & Wages - {dept}` | bold/subtotal |
| Contract Labor | `Total Contracted Leased & Outsourced Labor - {dept}` |  |
| Service Charge Distribution | `Total Service Charge Distribution - {dept}` |  |
| Bonus and Incentive Pay | `Total Bonuses & Incentives - {dept}` |  |
| Total Salaries, Wages And Bonuses | `Total Salaries Wages & Bonuses - {dept}` | bold/subtotal |
| **PAYROLL RELATED EXPENSES** | — | SECTION HEADER |
| Personal Days | `Personal Days - {dept}` |  |
| Sick Pays | `Sick Pay - {dept}` |  |
| Holiday Pay | `Holiday Pay - {dept}` |  |
| Vacation/ Paid Time Off | `Vacation - {dept}` |  |
| Severance Pay | `Severance Pay - {dept}` |  |
| Parental Leave | `Parental Leave - {dept}` | exists in USALI for each outlet, but the UI row never resolves it (UI lookup bug) — safe to use directly |
| Other Pay | `Other Pay - {dept}` |  |
| Supplemental Pay | `Total Supplemental Pay - {dept}` | bold/subtotal |
| Automobile Allowance | `Automobile Allowance - {dept}` |  |
| Child Care | `Child Care - {dept}` |  |
| Contributory Savings Plan | `Contributory Savings Plan - {dept}` |  |
| Dental Insurance | `Dental Insurance - {dept}` |  |
| Disability Insurance | `Disability Insurance - {dept}` |  |
| Expat Benefits | `Expat Benefits - {dept}` |  |
| Group Life Insurance | `Group Life Insurance - {dept}` |  |
| Health Insurance | `Health Insurance - {dept}` |  |
| Housing and Educational | `Housing and Educational - {dept}` |  |
| Meals | `Meals - {dept}` |  |
| Miscellaneous Benefits | `Miscellaneous Benefits - {dept}` |  |
| Nonunion Insurance | `Nonunion Insurance - {dept}` |  |
| Nonunion Pension | `Nonunion Pension - {dept}` |  |
| Profit Sharing | `Profit Sharing - {dept}` |  |
| Public Subsidized Transportation | `Public Subsidized Transportation - {dept}` |  |
| Stock Benefits | `Stock Benefits - {dept}` |  |
| Stock Options | `Stock Options - {dept}` |  |
| Union Insurance | `Union Insurance - {dept}` |  |
| Union Other | `Union Other - {dept}` |  |
| Union Pension | `Union Pension - {dept}` |  |
| Workers’ Compensation Insurance | `Workers Compensation Insurance - {dept}` |  |
| Employee Benefits | `Total Employee Benefits - {dept}` | bold/subtotal |
| Taxes | `Total Payroll Taxes - {dept}` |  |
| Total Payroll Related Expenses | `Total Payroll-Related Expenses - {dept}` | bold/subtotal |
| Total Labor | `Total Labor Costs & Related Expenses - {dept}` | bold/subtotal |
| **OTHER EXPENSES** | — | SECTION HEADER |
| Banquet Expenses | `Banquet Expenses - {dept}` |  |
| China | `China - {dept}` |  |
| Cleaning Supplies | `Cleaning Supplies - {dept}` |  |
| Cluster Services | `Cluster Services - {dept}` |  |
| Commissions | `Commissions - {dept}` |  |
| Complimentary Services & Gifts | `Complimentary Services & Gifts - {dept}` |  |
| Contract Services | `Contract Services - {dept}` |  |
| Corporate Office Reimbursables | `Corporate Office Reimbursables - {dept}` |  |
| Decorations | `Decorations - {dept}` |  |
| Dishwashing Supplies | `Dishwashing Supplies - {dept}` |  |
| Dues & Subscriptions | `Dues & Subscriptions - {dept}` |  |
| Entertainment- In-House | `Entertainment- In-House - {dept}` |  |
| Equipment Expense | `Equipment Expense - {dept}` |  |
| Flatware | `Flatware - {dept}` |  |
| Glassware | `Glassware - {dept}` |  |
| Ice | `Ice - {dept}` |  |
| Kitchen Allocation | `Kitchen Allocation - {dept}` |  |
| Kitchen Fuel | `Kitchen Fuel - {dept}` |  |
| Kitchen Smallwares | `Kitchen Smallwares - {dept}` |  |
| Laundry & Dry Cleaning | `Laundry & Dry Cleaning - {dept}` |  |
| Licenses & Permits | `Licenses & Permits - {dept}` |  |
| Linen | `Linen - {dept}` |  |
| Management Fees | `Management Fees - {dept}` |  |
| Menus & Beverage Lists | `Menus & Beverage Lists - {dept}` |  |
| Miscellaneous | `Miscellaneous - {dept}` |  |
| Music & Entertainment | `Music & Entertainment - {dept}` |  |
| Operating Supplies | `Operating Supplies - {dept}` |  |
| Paper & Plastics | `Paper & Plastics - {dept}` |  |
| Postage & Overnight Delivery | `Postage & Overnight Delivery - {dept}` |  |
| Printing & Stationary | `Printing & Stationary - {dept}` |  |
| Reservations | `Reservations - {dept}` |  |
| Royalty Fees | `Royalty Fees - {dept}` |  |
| Training | `Training - {dept}` |  |
| Travel - Meals & Entertainment | `Travel - Meals & Entertainment - {dept}` |  |
| Travel - Other | `Travel - Other - {dept}` |  |
| Uniform Costs | `Uniform Costs - {dept}` |  |
| Uniform Laundry | `Uniform Laundry - {dept}` |  |
| Utensils | `Utensils - {dept}` |  |
| Total Other Expenses | `Total Other Expenses - {dept}` | bold/subtotal |
| Undistributed Expenses | `Undistributed Expenses - {dept}` |  |
| Fees | `Fees - {dept}` |  |
| Non-Opearing Income/Expense | `Non-Operating - {dept}` |  |
| Total Departmental Expenses | `Total Departmental Expenses - {dept}` | bold/subtotal |
| **COVERS** | — | SECTION HEADER |
| Breakfast Covers | `Breakfast Customers - {dept}` | not defined for dept 215 |
| Brunch Covers | `Brunch Customers - {dept}` | not defined for dept 216 |
| Lunch Covers | `Lunch Customers - {dept}` | not defined for dept 215 |
| Coffee Break Covers | `Coffee Break Customers - {dept}` | only defined for depts 213, 214, 216, 217, 218, 219 |
| Reception Covers | `Reception Customers - {dept}` | only defined for depts 213, 214, 216, 217, 218, 219 |
| Dinner Covers | `Dinner Customers - {dept}` | not defined for dept 215 |
| Late Night Covers | `Late Night Customers - {dept}` | not defined for depts 213, 214, 215, 216 |
| Complimentary Covers | `Complimentary Customers - {dept}` | not defined for depts 215, 216 |
| Other Covers | `Other Customers - {dept}` | not defined for dept 215 |
| Total Covers | `Total Customers - {dept}` | bold/subtotal; not defined for dept 215 |
| **HOURS WORKED - STATS** | — | SECTION HEADER |
| Mgmt Regular Hours Worked | `Mgmt Regular Hours Worked - {dept}` |  |
| Mgmt OT & DT Hours Worked | `Mgmt OT & DT Hours Worked - {dept}` |  |
| Mgmt Hours Worked | `Mgmt Hours Worked - {dept}` | bold/subtotal |
| Non Mgmt Regular Hours Worked | `Non Mgmt Regular Hours Worked - {dept}` |  |
| Non Mgmt OT & DT Hours Worked | `Non Mgmt OT & DT Hours Worked - {dept}` |  |
| Non-Mgmt Hours Worked | `Non-Mgmt Hours Worked - {dept}` | bold/subtotal |
| Outside Labor Hours Worked | `Outside Labor Hours Worked - {dept}` |  |
| Total Hours Worked | `Total Hours Worked - {dept}` | bold/subtotal |

