--====================================================
--## Section C — Advanced aggregation with subqueries 
--====================================================

--=================================
--### Question 11 — Customer tiers
--=================================
select 
    tier, 
    count(customer_id) as customer_count,
    min(total_spent) as min_spent, 
    max(total_spent) as max_spent,
    round(avg(total_spent), 2) as avg_spent,
    round(
        (sum(total_spent) / (
            select sum(total_spent) 
            from (
                select sum(oi.line_total) as total_spent
                from orders o
                join order_items oi using (order_id)
                where o.order_status = 'completed'
                group by o.customer_id
            ) as total_rev
        )) * 100, 2
    ) as revenue_share_pct
from (
    select 
        customer_id, 
        total_spent,
        case
            when total_spent >= 1000000 then 'Platinum'
            when total_spent >= 500000 then 'Gold'
            when total_spent >= 100000 then 'Silver'
            else 'Bronze'
        end as tier
    from (
        select o.customer_id, sum(oi.line_total) as total_spent
        from orders o
        join order_items oi using (order_id)
        where o.order_status = 'completed'
        group by o.customer_id
    ) as inner_revenue
) as middle_tiers
group by tier
order by case
    when tier = 'platinum' then 1
    when tier = 'gold' then 2
    when tier = 'silver' then 3
    else 4 
end;

--==================================================
--### Question 12 — What did Mombasa buy in October?
--==================================================
--1st Query:
select 
    c.customer_id, c.first_name||' '||last_name as full_name,
    count(distinct p.product_name) as product_count,
    string_agg(distinct p.product_name, '; ' order by p.product_name) as products_ordered
from customers c
join orders o on c.customer_id = o.customer_id
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
where c.county = 'Mombasa'
  and o.order_status != 'cancelled'
  and o.order_date >= '2026-10-01' 
  and o.order_date < '2026-11-01'
  and exists (
      select 1
      from orders o2
      where o2.customer_id = c.customer_id
        and o2.order_status <> 'cancelled'
        and o2.order_date >= '2026-10-01'
        and o2.order_date < '2026-11-01'
  )
group by c.customer_id, full_name
order by product_count desc, c.customer_id;

--2nd Query:
select count(*) as qualifying_customers
from customers c
where c.county = 'Mombasa'
  and exists (
      select 1
      from orders o
      where o.customer_id = c.customer_id
        and o.order_status <> 'cancelled'
        and o.order_date >= '2026-10-01'
        and o.order_date < '2026-11-01'
);
--=================================================
-- ### Question 13 — Payment health by method, 2026
--=================================================
with payment_stats as(
	select 
		payment_method,
		count(*) FILTER (where true) as total_payments,
		count(*)FILTER (where payment_status = 'successful') as successful,
		count(*)FILTER (where payment_status = 'failed') as failed,
		count(*)FILTER (where payment_status = 'pending') as pending,
		coalesce(sum(amount) FILTER (where payment_status = 'failed'),0) as failed_amount
	from payments
	where payment_date >= '2026-01-01'
		and payment_date < '2027-01-01'
	group by payment_method
)
select 
	payment_method, total_payments, successful, failed, pending, 
	round(100.0* successful/total_payments,2) as success_rate_pct, 
	failed_amount
from payment_stats
order by total_payments desc;

--======================================================
-- ### Question 14 — Which departments carry the profit?
--======================================================
with category_stats as (
    select 
        p.category, 
        sum(oi.line_total) as revenue, 
        sum(oi.line_total) - sum(oi.quantity * p.cost_price) as gross_profit
    from products p
    join order_items oi on p.product_id = oi.product_id
    join orders o on oi.order_id = o.order_id
    where o.order_status = 'completed'
      and o.order_date >= '2025-01-01'
      and o.order_date < '2026-01-01'
    group by p.category
)
select 
    category,revenue,gross_profit,
    round(100 * gross_profit / nullif(revenue, 0), 2) as margin_pct,
    round((select avg(gross_profit) from category_stats), 2) as avg_category_gross_profit,
    round(
        100 * (gross_profit - (select avg(gross_profit) from category_stats)) 
        / nullif((select avg(gross_profit) from category_stats), 0), 
        2
    ) as pct_above_avg
from category_stats
where gross_profit > (select avg(gross_profit) from category_stats)
order by gross_profit desc;

--=================================================
-- ### Question 15 — One sales table with subtotals 
--=================================================
with completed_2026_lines as (
    select 
        o.order_id,
        o.shipping_county as county,
        p.category,
        (oi.line_total) as line_revenue
    from orders o
    join order_items oi on o.order_id = oi.order_id
    join products p on oi.product_id = p.product_id
    where o.order_status = 'completed'
      and o.order_date >= '2026-01-01'
      and o.order_date < '2027-01-01'
      and o.shipping_county in ('Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Uasin Gishu')
)
select
    case 
        when grouping(county) = 0 and grouping(category) = 0 then 'county x category'
        when grouping(county) = 0 and grouping(category) = 1 then 'county total'
        when grouping(county) = 1 and grouping(category) = 0 then 'category total'
        when grouping(county) = 1 and grouping(category) = 1 then 'grand total'
    end as grouping_level,
    case 
        when grouping(county) = 1 then 'all counties' 
        else county 
    end as county,
    case 
        when grouping(category) = 1 then 'all categories' 
        else category 
    end as category,
    sum(line_revenue) as revenue,
    count(distinct order_id) as order_count
from completed_2026_lines
group by grouping sets (
    (county, category),
    (county),
    (category),
    ())
order by grouping(county),county, grouping(category),category;

--===============================================================================
-- ### Question 16 — Customer summary view and monthly category materialized view 
--===============================================================================
---Part (a): Customer Purchase Summary View
-- 1. Creating the customer purchase summary view
create or replace view v_customer_purchase_summary as
with order_totals as (
    select 
        o.order_id, o.customer_id,o.order_date,
        sum(oi.line_total) as order_revenue
    from orders o
    join order_items oi on o.order_id = oi.order_id
    where o.order_status = 'completed'
    group by o.order_id, o.customer_id, o.order_date
),
	customer_metrics as (
	    select 
	        customer_id, count(order_id) as completed_orders,
			sum(order_revenue) as lifetime_spent,
	        avg(order_revenue) as avg_order_value,
			min(order_date) as first_order_date,
			max(order_date) as last_order_date
	    from order_totals
	    group by customer_id
)
select 
    c.customer_id,c.first_name||' '||last_name as full_name,c.county,c.registration_date,
    coalesce(cm.completed_orders, 0) as completed_orders,
    coalesce(cm.lifetime_spent, 0) as lifetime_spent,
    coalesce(cm.avg_order_value, 0) as avg_order_value,
    cm.first_order_date,cm.last_order_date,
    (date '2026-10-31' - cm.last_order_date::date) as days_since_last_order
from customers c
left join customer_metrics cm on c.customer_id = cm.customer_id;

-- 2. top 10 customers living in kiambu by lifetime_spent
select 
    customer_id,full_name,county,registration_date,completed_orders,lifetime_spent,
	avg_order_value,first_order_date,last_order_date, days_since_last_order
from v_customer_purchase_summary
where county = 'Kiambu'
order by lifetime_spent desc, completed_orders desc
limit 10;

-- 3. total rows in the view and count of customers with 0 completed orders
select 
    count(*) as total_customers,
    count(*) filter (where completed_orders = 0) as zero_order_customers
from v_customer_purchase_summary;

--Part (b): Monthly Category Materialized View & Index
-- 1. creating the materialized view
create materialized view mv_monthly_category_sales as
select 
    to_char(o.order_date,'yyyy-mm') as sales_month,p.category,
    count(distinct o.order_id) as orders,
    sum(oi.quantity) as units_sold,
    sum(oi.line_total) as revenue,
    sum(oi.line_total - (oi.quantity*p.cost_price)) as gross_profit
from orders o
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
where o.order_status = 'completed'
group by sales_month,p.category;

-- 2. create a unique index on (sales_month, category)
-- required to support refresh materialized view concurrently
create unique index idx_mv_monthly_category_sales_month_cat 
    on mv_monthly_category_sales (sales_month, category);

-- 3. query december 2025 rows ordered by revenue
select 
    sales_month,category,orders,units_sold,revenue,gross_profit
from mv_monthly_category_sales
where sales_month = '2025-12'
order by revenue desc;


--============================================================
-- ### Question 17 — Function: customer spend for a date range 
--============================================================
create or replace function fn_customer_spend(p_customer_id integer, p_start_date date, p_end_date date) 
returns numeric 
language plpgsql as $$
declare
    v_total numeric;
begin
    -- validate that end date is not before start date
    if p_end_date < p_start_date then
        raise exception 'invalid date range: end date (%) cannot be earlier than start date (%)', 
            p_end_date, p_start_date;
    end if;
    -- calculate completed revenue
    select coalesce(sum(oi.line_total), 0)
    into v_total
    from orders o
    join order_items oi on o.order_id = oi.order_id
    where o.customer_id = p_customer_id
      and o.order_status = 'completed'
      and o.order_date >= p_start_date 
      and o.order_date < (p_end_date + interval '1 day');
    return v_total;
end;
$$;

-- 1. Call it for customer **4000** for: 2025; Jan–Oct 2026; 1 Jan 2025–31 Oct 2026; December 2025; and for customer `-1
select 
    fn_customer_spend(4000, '2025-01-01', '2025-12-31') as spend_2025,
    fn_customer_spend(4000, '2026-01-01', '2026-10-31') as spend_jan_oct_2026,
    fn_customer_spend(4000, '2025-01-01', '2026-10-31') as spend_all_time_period,
    fn_customer_spend(4000, '2025-12-01', '2025-12-31') as spend_dec_2025,
    fn_customer_spend(-1, '2025-01-01', '2026-10-31') as spend_nonexistent_customer;
-- 2. show that the all-time value equals `lifetime_spent` for customer 4000 in your Q16 view.
select 
    v.customer_id,v.lifetime_spent,
   fn_customer_spend(v.customer_id, '2025-01-01', '2026-10-31') as fn_value,
    (v.lifetime_spent = fn_customer_spend(v.customer_id, '2025-01-01', '2026-10-31')) as matches
from v_customer_purchase_summary v
where v.customer_id = 4000;

-- 3. Use it inside a query: top 5 customers **living in Nairobi** by December 2025 spend.
select 
    c.customer_id,c.first_name||' '||c.last_name as full_name,
    fn_customer_spend(c.customer_id, '2025-12-01', '2025-12-31') as december_2025_spend
from customers c
where c.county = 'Nairobi'
order by december_2025_spend desc
limit 5;

-- 4. Show the exception for ('2026-02-01', '2026-01-01')
select fn_customer_spend(4000, '2026-02-01', '2026-01-01');

--================================================================
--### Question 18 — Procedure: change a price and keep its history 
--================================================================



















