--=====================================
--### Question 1 — Big spenders of 2025
--=====================================
with customer_stats as (
    select 
        c.customer_id, 
        c.first_name || ' ' || c.last_name as full_name, 
        c.county, 
        sum(o.total_amount) as total_spent_2025
    from customers c
    join orders o using (customer_id)
    where o.order_status = 'completed'
      and o.order_date >= '2025-01-01'
      and o.order_date < '2026-01-01'
    group by c.customer_id, c.first_name, c.last_name, c.county
),
avg_spent as (
    select round(avg(total_spent_2025), 2) as avg_spent_2025
    from customer_stats
),
main_results as (
    select 
        cs.customer_id, 
        cs.full_name, 
        cs.county, 
        cs.total_spent_2025,
        a.avg_spent_2025,
        (cs.total_spent_2025 - a.avg_spent_2025) as amount_above_avg
    from customer_stats cs
    cross join avg_spent a
    where cs.total_spent_2025 > a.avg_spent_2025
)
-- 1. main query: above-average big spenders
select * 
from main_results
order by total_spent_2025 desc;

-- 2. second query: summary statistics --comment above select (1.) to run this select query
select 
    (select count(*) from customer_stats) as total_buyers_2025,
    (select avg_spent_2025 from avg_spent) as overall_avg_2025,
    (select count(*) from main_results) as returned_rows_count;	
	
--=======================================
--### Question 2 — Premium-priced products.
--=======================================
with category_stats as(
		select p.product_id,p.product_name,p.category,p.unit_price,
		(
		(select 
			avg(sub.unit_price) 
		from products sub 
		where sub.category = p.category)
			) as avg_price
		from products p	
		where p.product_status = 'active'
),
	main_results as (
	select product_id,product_name,category,unit_price,
	round(avg_price,2) as category_avg_price,
	round(unit_price - avg_price,2) as price_gap
	from category_stats
	where unit_price > avg_price
)
---1st query select
select *
from main_results
order by category asc, price_gap desc;

---2nd query select 
select category, count(*) as rows_per_category
from main_results
group by category
order by category;


--=============================================
--### Question 3 — 2026 monthly profit and loss 
--=============================================
with order_lines_2026 as (
    -- cte 1: completed order lines with month, revenue, and cost for jan-oct 2026
    select 
        to_char(o.order_date,'yyyy-mm') as month,
        (oi.quantity * p.unit_price) as line_revenue,
        (oi.quantity * p.cost_price) as line_cost
    from orders o
    join order_items oi on o.order_id = oi.order_id
	join products p on oi.product_id = p.product_id
    where o.order_status = 'completed'
      and o.order_date >= '2026-01-01'
      and o.order_date < '2026-11-01'
),
monthly_aggregates as (
    -- cte 2: aggregate total revenue and cost per month
    select 
        month,
        sum(line_revenue) as revenue,
        sum(line_cost) as cost
    from order_lines_2026
    group by month
),
monthly_profit as (
    -- cte 3: calculate gross profit per month
    select 
        month,
        revenue,
        cost,
        (revenue - cost) as gross_profit
    from monthly_aggregates
)
-- final select: add margin percentage and format outputs for the 10-month p&l
select 
    month,
    round(revenue, 2) as revenue,
    round(cost, 2) as cost,
    round(gross_profit, 2) as gross_profit,
    round((gross_profit / nullif(revenue, 0)) * 100, 2) as margin_pct
from monthly_profit
order by month asc;

--==================================================
--### Question 4 — Cross-category shoppers in Nakuru
--Scenaraion: The Nakuru regional manager wants customers who already shop across several departments, for a bundle campaign.
--==================================================
with customer_order_summary as (
    -- derived table / cte calculating category count and revenue manually with discounts
    select 
        o.customer_id,
        count(distinct p.category) as category_count,
        sum((oi.quantity * oi.unit_price) * (1 - coalesce(oi.discount_percentage, 0) / 100.0)) as total_spent
    from orders o
    join order_items oi on o.order_id = oi.order_id
    join products p on oi.product_id = p.product_id
    where o.order_status = 'completed'
    group by o.customer_id
)
-- -- 1st query: nakuru customers with 3 or more distinct categories
select 
    c.customer_id,
    c.first_name || ' ' || c.last_name as full_name,
    c.county,
    cos.category_count,
    round(cos.total_spent, 2) as total_spent
from customers c
join customer_order_summary cos on c.customer_id = cos.customer_id
where c.county = 'Nakuru'
  and cos.category_count >= 3
order by cos.category_count desc, cos.total_spent desc;

-- 2nd query: total qualifying nakuru customers vs. those who bought from all 5 categories
select 
    count(*) as qualifying_nakuru_customers,
    sum(case when cos.category_count = 5 then 1 else 0 end) as bought_from_all_5
from customers c
join customer_order_summary cos on c.customer_id = cos.customer_id
where c.county = 'Nakuru'
  and cos.category_count >= 3;

--==============================================
--### Question 5 — Products nobody has ordered
--=============================================
select product_id, product_name, category, 
		product_status, stock_quantity, created_at
from products p
where  NOT EXISTS (
			select 1
			from order_items oi
			where p.product_id = oi.product_id
		)
order by category asc, product_name asc;
















