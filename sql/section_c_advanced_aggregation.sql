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














