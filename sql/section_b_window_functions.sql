--==================================
--## Section B — Window functions 
--==================================

--====================================
--### Question 6 — County leaderboards
--====================================
with customer_stats as (
	select c.county,c.customer_id,
			c.first_name || ' ' || c.last_name as full_name,
			sum((oi.quantity * oi.unit_price) * (1 - coalesce(oi.discount_percentage, 0) / 100.0)) as total_expenditure
	from customers c
	join orders o on c.customer_id = o.customer_id
	join order_items oi on o.order_id = oi.order_id
	where o.order_status = 'completed'
	group by c.county,c.customer_id,full_name
),
ranked_customers AS (
    SELECT 
        county,
        DENSE_RANK() OVER (PARTITION BY county ORDER BY total_expenditure DESC) AS county_rank,
        customer_id, 
        full_name,
        ROUND(total_expenditure, 2) AS total_spent
    FROM customer_stats
)
SELECT 
    county,
    county_rank,
    customer_id,
    full_name,
    total_spent
FROM ranked_customers
WHERE county_rank <= 3
ORDER BY county ASC, county_rank ASC;

--=================================================
-- ### Question 7 — Best sellers per category, 2025
--=================================================
with product_stats as (
	select p.category,
		p.product_id,p.product_name, 
		sum(oi.line_total) as revenue,
		sum(oi.quantity) as units_sold
	from products p
	join order_items oi using (product_id)
	join orders o on o.order_id = oi.order_id
	where order_status = 'completed'
		and order_date >= '2025-01-01'
		and order_date < '2026-01-01'
	group by product_id
),
ranked_categories as (
	select category,product_id,product_name,revenue, units_sold,
		row_number() over(partition by category order by revenue desc,product_id asc) as rank_in_category
	from product_stats
)
select category,rank_in_category, product_id,product_name,revenue,units_sold
from ranked_categories
where rank_in_category <= 3;

--=================================================
-- ### Question 8 — Month-over-month growth 
--=================================================
with monthly_revenue as (
	select to_char(order_date,'YYYY-MM') as month,
			sum(oi.line_total) as revenue
	from orders o
	join order_items oi using(order_id)
	where o.order_status = 'completed'
	group by month
),
	revenue_with_lag as ( 
		select month,revenue,
		 	lag(revenue) over(order by month asc) as prev_month_revenue
		from monthly_revenue
)
select month,revenue, prev_month_revenue,
	round((revenue-prev_month_revenue)/nullif(revenue,0),2) as growth_pct
from revenue_with_lag;

--====================================================
--### Question 9 — Is each order bigger than the last?
--====================================================
with nyeri_customers as(
	select o.customer_id, o.order_id, o.order_date, o.total_amount, 
		lag(total_amount) over(partition by customer_id order by o.order_date) previous_order_amount
	from orders o
	join customers c using(customer_id)
	where c.county = 'Nyeri'
		and o.order_status = 'completed'
		and o.order_date >= '2026-01-01'
		and o.order_date < '2027-01-01'
), 
	nyeri_customers_with_direction as (
		select customer_id,order_id,order_date,total_amount,previous_order_amount,
					(total_amount - previous_order_amount) as change_amount,
				case
					when previous_order_amount is null then 'first order'
					when total_amount > previous_order_amount then 'up'
					when total_amount < previous_order_amount then 'down'
					else 'same'
				end as direction	
		from nyeri_customers 
)
-- 1st query: 
select 
    customer_id,
    order_id,
    order_date,
    total_amount,
    previous_order_amount,
    change_amount,
    direction
from nyeri_customers_with_direction;
-- 2nd query: 
select 
    count(*) as total_rows,
    count(distinct customer_id) as distinct_customers,
    sum(case when direction = 'first order' then 1 else 0 end) as first_orders,
    sum(case when direction = 'up' then 1 else 0 end) as orders_bigger,
    sum(case when direction = 'down' then 1 else 0 end) as orders_smaller,
    sum(case when direction = 'same' then 1 else 0 end) as orders_same
from nyeri_customers_with_direction;

--========================================
--### Question 10 — Year-to-date revenue 
--========================================
with monthly_revenue as(
	select 
		to_char(o.order_date,'YYYY') as year,
		to_char(o.order_date,'YYYY-MM') as month,
		sum(oi.line_total) as monthly_revenue
	from orders o
	join order_items oi using(order_id)
	where o.order_status = 'completed'
	group by month,year
			
)
select
	year,month,monthly_revenue,
	sum(monthly_revenue) over(partition by year order by month asc 
					ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_revenue_ytd,
	sum(monthly_revenue) over(order by month asc 
					ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_revenue_all_time
from monthly_revenue
order by month asc;


























