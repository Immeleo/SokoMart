**Team Member - Leonard Mambo Mwilu, Cohort 9, 11th October 2026**



**How to Run SQL queries**

Assuming that you have the database ready and loaded with the data files. Each my SQL queries should be run alone. Select the entire query and click execute or F5 is you are working on PgAdmin, if using DBeaver, place cursor at the end of the query,i.e after the semicolon(;) and click Ctrl+Enter.

**A results table**
## Practice drills (Monday morning — unmarked)

| D1 | `00_practice_drills.sql ` |  | (screenshots/D1_a.png) and  (screenshots/D1_a.png)|
| D2 | `00_practice_drills.sql ` |  | (screenshots/D2.png) |
| D3 | `00_practice_drills.sql ` |  | (screenshots/D3.png) |
| D4 | `00_practice_drills.sql ` |  | (screenshots/D4.png) |
| D5 | `00_practice_drills.sql ` |  | (screenshots/D5.png) |
| D6 | `00_practice_drills.sql ` |  | (screenshots/D6.png) |
| D7 | `00_practice_drills.sql ` |  | (screenshots/D7.png) |
| D8 | `00_practice_drills.sql ` |  | (screenshots/D8.png) |
| D9 | `00_practice_drills.sql ` |  | (screenshots/D9.png) |
| D10 | `00_practice_drills.sql ` |  | (screenshots/D10.png)|

## Section A — CTEs and subqueries

### Question 1 — Big spenders of 2025.
**Scenario:** Marketing wants to invite 2025's above-average customers to a loyalty launch.
This questions has two querys, to run the script has proven challenging, so to get the results for both queries you run
the main results first. To run the summary statistics you commented out the main query select and then run.

| Question 1 — Big spenders of 2025 | `section_a_ctes_subqueries.sql`  | | screenshots/Big_Spenders_2025_main_query.png and screenshots/Big_Spenders_2025_summary_statistics.png 

### Question 2 — Premium-priced products.
**Scenario:** The pricing team wants every **active** product that is priced above the average
This questions has two querys, to run the script has proven challenging, so to get the results for both queries you run
the main results first. To run the second query you commented out the 1st query select and then run 2nd query select.

| Question 2 — Premium-priced products | `section_a_ctes_subqueries.sql` | | screenshots/Premium_priced_products_1st_query.png and screenshots/Premium_priced_products_2nd_query.png 

### Question 3 — 2026 monthly profit and loss 
**Scenario.** Finance needs a monthly P&L for **January–October 2026**
To run - select entire query and click execute.
| Question 3 — 2026 monthly profit and loss | `section_a_ctes_subqueries.sql` | | screenshots/Premium_priced_products_1st_query.png and screenshots/2026_monthly_profit_and_loss.pn

### Question 4 — Cross-category shoppers in Nakuru
**Scenario:** The Nakuru regional manager wants customers who already shop across several departments, for a bundle campaign.
To get the results for both queries you run the 1st select query. To run the second query you commented out the 1st query select and then run 2nd query select.
| Question 4 — Cross-category shoppers in Nakuru | `section_a_ctes_subqueries.sql` | | screenshots/customers_with_3_or_more_categories.png and Nakuru_qualifying_customers.png|

### Question 5 — Products nobody has ordered
**Scenario.** The warehouse is reviewing shelf space: which products have **never appeared on
any order** (any status)?
To execute select the entire query and click execute.
| Question 5 — Products nobody has ordered | `section_a_ctes_subqueries.sql` | | screenshots/products_nobody_ordered.png

## Section B — Window functions


### Question 6 — County leaderboards 
**Scenario.** Each county manager wants their top 3 customers by lifetime revenue.
To run select entire query and click execute.
| Question 6 — Products nobody has ordered | `section_a_ctes_subqueries.sql` | | screenshots/county_leaderboards.png

### Question 7 — Best sellers per category, 2025 
**Scenario:** Category buyers are planning 2026 stock and want 2025's top 3 products in each category.
To run select entire query and click execute.
| Question 7 — Best sellers per category, 2025 | `section_a_ctes_subqueries.sql` | | screenshots/Best_Sellers_per_Category_in_2025

### Question 8 — Month-over-month growth 
**Scenario.** The CEO's dashboard shows revenue growth versus the previous month.
To run select entire query and click execute.
| Question 8 — Month-over-month growth  | `section_a_ctes_subqueries.sql` | | screenshots/month_over_month_growth.png

### Question 9 — Is each order bigger than the last? 
**Scenario.** Customer success in **Nyeri** wants to see whether customers are spending more or
less per order through 2026.
To 1st query select query upto ';' and click execute. To run the second query comment the 1st query, select entire query and then run.
| Question 9 — Is each order bigger than the last? | `section_a_ctes_subqueries.sql` | | screenshots/is_order_big_than_last.png and screenshots/nyeri_order_size_summary.png

### Question 10 — Year-to-date revenue 
**Scenario.** Finance reports cumulative revenue that **restarts every January**.
To run select entire query and click execute.
| Question 10 — Year-to-date revenue | `section_a_ctes_subqueries.sql` | | screenshots/year_to_date_revenue.png
