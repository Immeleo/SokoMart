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
| Question 6 — Products nobody has ordered | `section_b_window_functions.sql` | | screenshots/county_leaderboards.png

### Question 7 — Best sellers per category, 2025 
**Scenario:** Category buyers are planning 2026 stock and want 2025's top 3 products in each category.
To run select entire query and click execute.
| Question 7 — Best sellers per category, 2025 | `section_b_window_functions.sql` | | screenshots/Best_Sellers_per_Category_in_2025

### Question 8 — Month-over-month growth 
**Scenario.** The CEO's dashboard shows revenue growth versus the previous month.
To run select entire query and click execute.
| Question 8 — Month-over-month growth  | `section_b_window_functions.sql` | | screenshots/month_over_month_growth.png

### Question 9 — Is each order bigger than the last? 
**Scenario.** Customer success in **Nyeri** wants to see whether customers are spending more or
less per order through 2026.
To 1st query select query upto ';' and click execute. To run the second query comment the 1st query, select entire query and then run.
| Question 9 — Is each order bigger than the last? | `section_b_window_functions.sql` | | screenshots/is_order_big_than_last.png and screenshots/nyeri_order_size_summary.png

### Question 10 — Year-to-date revenue 
**Scenario.** Finance reports cumulative revenue that **restarts every January**.
To run select entire query and click execute.
| Question 10 — Year-to-date revenue | `section_b_window_functions.sql` | | screenshots/year_to_date_revenue.png

## Section C — Advanced aggregation with subqueries

### Question 11 — Customer tiers
**Scenario.** The loyalty programme has four tiers by **lifetime revenue**:
Platinum ≥ KES 1,000,000; Gold ≥ 500,000; Silver ≥ 100,000; Bronze below 100,000.
To run select entire query and click execute or F5(in PgAdmin).
| Question 11 — Customer tiers | `section_c_advanced_aggregation.sql` | | screenshots/customer_tiers.png

### Question 12 — What did Mombasa buy in October?
**Scenario.** The Mombasa team wants a one-line shopping list per customer for October 2026.
To run select and execute each of the two queries separate.
| Question 12 — What did Mombasa buy in October? | `section_c_advanced_aggregation.sql` | | screenshots/what_Mombasa_bought_in_October.png and
screenshots/qualifying_customers.png

### Question 13 — Payment health by method, 2026 
**Scenario.** The payments team suspects one channel fails more often than the others.
To run select entire query and click execute.
| Question 13 — Payment health by method, 2026  | `section_c_advanced_aggregation.sql` | | screenshots/Payment_health_by_method_2026.png

### Question 14 — Which departments carry the profit? 
**Scenario.** The board asks which categories earned **more gross profit than the average category** in 2025.
To run select entire query and click execute or F5(in PgAdmin).
| Question 14 — Which departments carry the profit?  | `section_c_advanced_aggregation.sql` | | screenshots/which_departments_carry_the_profit.png

### Question 15 — One sales table with subtotals
**Scenario.** Regional heads want 2026 revenue for **Nairobi, Mombasa, Kisumu, Nakuru and Uasin Gishu**
by category, with county subtotals, category subtotals and a grand total — in **one** query.
To run select entire query and click execute or F5(in PgAdmin).
| Question 15 — One sales table with subtotals | `section_c_advanced_aggregation.sql` | | screenshots/one_sales_table_with_subtotals.png

## Section D — Views, functions, stored procedures and triggers

All objects go in schema `sokomart`. Use `CREATE OR REPLACE` so your file can be re-run.
After every `CALL`, **run a SELECT that proves what changed** and screenshot it.

### Question 16 — Customer summary view and monthly category materialized view 
**Scenario.** Analysts keep rewriting the same customer and category queries.
To run select each query alone and click execute or F5(in PgAdmin).
| Question 16 — Customer summary view and monthly category materialized view | `section_d_views_functions_procedures.sql` | | screenshots/top_10_customers_living_in_kiambu_by_lifetime_spent.png, screenshots/total_customers_&_count_of_customers_with_zero_completed.png, screenshots/december_2025_rows_ordered_by_revenue.png

### Question 17 — Function: customer spend for a date range 
**Scenario.** Customer care needs "how much has this customer spent between these dates?" on demand.
To run select each query separately and run.
| Question 17 — Function: customer spend for a date range | `section_d_views_functions_procedures.sql` | screenshots/calling_fn_for_customer_4000&_-1.png, screenshots/all_time_value_equals.png, screenshots/top_5_Nairobi_spenders_in_2025.png, screenshots/start_&_end_date_exception.png

### Question 18 — Procedure: change a price and keep its history
**Scenario.** The supplier of **Pwani Golden Cooking Oil 3L (product 71)** has raised prices.
Every price change must be recorded.
To run select each query section alone and click execute or F5 in Pgadmin.
| Question 18 — Procedure: change a price and keep its history | `section_d_views_functions_procedures.sql` |screenshots/product_71_before_Update.png, screenshots/product_71_After_Update.png, screenshots/product_71_price_change_history.png, screenshots/product_71_price_change_audit_logs.png, screenshots/product_71_new_price_exception.png, screenshots/price_history_after_exception_was_thrown.png

### Question 19 — Trigger + procedure: order status changes are always logged
**Scenario.** Disputes keep coming up about who changed an order's status and when.
| Question 19 — Trigger + procedure: order status changes are always logged | `section_d_views_functions_procedures.sql` | screenshots/48882_status_after_update.png, screenshots/48882_status_history.png, screenshots/48882_status_change_audit_log.png, screenshots/status_update_exception_caught.png

