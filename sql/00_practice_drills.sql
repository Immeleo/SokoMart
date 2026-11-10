-- ## Practice drills (Monday morning — unmarked)
---===================================
--| D1 | List the products whose `unit_price` is above the average `unit_price` of **all** products. 
-- Show the 10 most expensive, then on a second query the count. 
--| Scalar subquery in `WHERE` and `SELECT` | `product_id, product_name, category, unit_price, overall_avg_price`; then one number |
-- answers: screenshots/D1_a.png and screenshots/D1_b.png
---===================================
--1st query:D1_a
select p.product_id, p.product_name, p.category, p.unit_price,
	(select round(avg(unit_price), 2) from products) as overall_avg_price  --scalar subquery
from products p
where p.unit_price > (select avg(unit_price) from products)
order by p.unit_price DESC
limit 10;

--2nd query:D1_b
select count(*) as products_abv_avg
from products
where unit_price > (select avg(unit_price) from products);

--==========================================
--| D2 | List customers living in **Mombasa** who placed at least one order (any status) in **December 2025**.
--| `IN (subquery)` | `customer_id, first_name, last_name, email`; then the count |
-- answer: screenshots/D2.png
--==========================================
select  c.customer_id, c.first_name, c.last_name, c.email,
    (
        select count(*) 
        from orders o 
        where o.customer_id = c.customer_id 
          and o.order_date >= '2025-12-01' 
          and o.order_date < '2026-01-01'
    ) as december_order_count
from customers c
where c.county = 'Mombasa'
  and c.customer_id in (
      select o.customer_id 
      from orders o
      where o.order_date >= '2025-12-01' 
        and o.order_date < '2026-01-01'
  )
order by december_order_count desc, c.customer_id;

--=============================================
--| D3 | How many customers living in **Kisumu** have at least one payment with `payment_status = 'failed'`? 
--| `EXISTS` correlated subquery | `kisumu_customers_with_failed_payment` (one number) |
-- answer: screenshots/D3.png
--=============================================
select count(*) as kisumu_customers_with_failed_payment
from customers c
where c.county= 'Kisumu'
  and exists (
      select 1
      from orders o
      join payments p on o.order_id = p.order_id
      where o.customer_id = c.customer_id
        and p.payment_status = 'failed'
  );

--===================================
--| D4 | For each `order_status`,
-- show the number of orders, the average number of lines per order and the average number of units per order. 
-- Compute the per-order figures in a subquery in `FROM`. 
--| Derived table | `order_status, orders, avg_lines_per_order, avg_units_per_order` |
-- answer:screenshots/D4.png
--=================================
select 
    sub.order_status,
    count(sub.order_id) as orders,
    round(avg(sub.line_count), 2) as avg_lines_per_order,
    round(avg(sub.unit_count), 2) as avg_units_per_order
from (
    select 
        o.order_id,
        o.order_status,
        count(*) as line_count,
        sum(oi.quantity) as unit_count
    from orders o
    join order_items oi on o.order_id = oi.order_id
    group by o.order_id, o.order_status
) sub
group by sub.order_status
order by sub.order_status;
--===========================
--| D5 | Top 5 **shipping counties** by number of completed orders in 2026. 
-- Put the filtered orders in a CTE. | Single CTE | `shipping_county, completed_orders` |
-- answer: screenshots/D5.png
--==========================
with completed_orders_2026 as (
	select shipping_county,
			order_id
	from orders o
	where order_status = 'completed'
	and o.order_date >= '2026-01-01'
	and o.order_date < '2027-01-01'
)
select shipping_county, count(order_id) as completed_orders
from completed_orders_2026
group by shipping_county
order by completed_orders Desc
limit 5;

--=================================
--| D6 | For 2025: completed orders per month, the 2025 monthly average, 
-- and whether each month is `above average` or `at/below average`. 
-- Use two CTEs (monthly counts, then the stats). 
--| Chained CTEs | `month, completed_orders, avg_per_month, vs_average` (12 rows) |
--answer: screenshots/D6.png
---================================
with monthly_counts as (
	select to_char(order_date,'YYYY-MM') as month,
			count(order_id) as completed_orders
			from orders
			where order_status  = 'completed'
				and order_date >='2025-01-01'
				and order_date < '2026-01-01'
			group by month
),
stats as (
	select round(avg(completed_orders),2) as avg_per_month
	from monthly_counts
)
select mc.month,mc.completed_orders,
	s.avg_per_month,
	case 
        when mc.completed_orders > s.avg_per_month then 'above average'
        else 'at/below average'
    end as vs_average
from monthly_counts mc
cross join stats s
order by mc.month ASC;

--===============================
--| D7 | Write `sokomart.fn_order_count(p_customer_id INTEGER) RETURNS INTEGER` 
-- — the number of orders (any status) a customer has. 
-- Call it for customer **177** and for a customer that does not exist (`-1`). 
--| SQL function | two numbers |
-- answer: see comments 
--=============================
create or replace function fn_order_count(p_customer_id int)
returns int
language plpgsql
as $$
declare 
	order_count int;
begin
	select count(*)
	into order_count
	from orders
	where customer_id = p_customer_id;
	return order_count;
end;
$$;

select fn_order_count(117) as no_of_orders; --- gives 6
select fn_order_count(-1) as no_of_orders; --- give 0

--===============================
--| D8 | Write `sokomart.sp_set_customer_status(p_customer_id INTEGER, p_status VARCHAR)`. 
-- It raises an exception for a status other than `active / inactive / suspended`, 
-- and for a customer that does not exist. Inside `BEGIN … ROLLBACK`, 
-- set customer **177** to `suspended`, show it, roll back, show it is `active` again. 
-- Then show the exception for status `'vip'`. | Stored procedure, `RAISE EXCEPTION`, `CALL` 
--| the three status checks + the error message |
-- part of answer: screenshots/D8_exception.png
--===============================
create or replace procedure sp_set_customer_status(p_customer_id integer, p_status varchar)
language plpgsql as $$
declare
    v_exists boolean;
begin
    -- 1. check if the status is valid
    if p_status not in ('active', 'inactive', 'suspended') then
        raise exception 'invalid status: %. allowed statuses are active, inactive, or suspended.', p_status;
    end if;

    -- 2. check if the customer exists
    select exists (select 1 from customers where customer_id = p_customer_id) into v_exists;
    
    if not v_exists then
        raise exception 'customer with id % does not exist.', p_customer_id;
    end if;

    -- 3. update the customer status
    update customers
    set customer_status = p_status
    where customer_id = p_customer_id;
end;
$$;

-- step A: check current status of customer 177
select customer_status from customers where customer_id = 177;

-- step B: start a transaction block to test updating and rolling back
begin;
    -- set customer 177 to suspended
    call sp_set_customer_status(177, 'suspended');
    
    -- show that it changed to suspended within the transaction
    select customer_id, customer_status as status_inside_transaction 
    from customers where customer_id = 177;

-- roll back the transaction to restore the original state
rollback;

-- step C: show that the status is back to active (or its original state) after rollback
select customer_id, customer_status as status_after_rollback 
from customers where customer_id = 177;

-- step D: test exception handling for an invalid status ('vip')
begin;
    call sp_set_customer_status(177, 'vip');
end;

--===================================
-- | D9 | Beauty products whose `stock_quantity` is below the **average Beauty stock**. 
-- Put the Beauty products in a CTE and compare with a scalar subquery on that CTE. 
-- | CTE + scalar subquery | `product_id, product_name, stock_quantity, beauty_avg_stock` |
-- answers: screenshots/D9.png
--====================================
with beauty_products as (
	select product_id, product_name,
			stock_quantity
	from products
	where  category = 'Beauty'
	group by product_id, product_name
)
select product_id, product_name,
			stock_quantity,
			(select round(avg(stock_quantity),2) 
				from beauty_products) as beauty_avg_stock
from beauty_products
where stock_quantity < (select avg(stock_quantity) from beauty_products)
group by product_id, product_name,stock_quantity
order by stock_quantity asc;

--===============================
--| D10 | Write `sokomart.sp_county_summary(IN p_county VARCHAR, OUT p_customers INTEGER, OUT p_revenue NUMERIC)`
--returning the number of customers living in the county and their completed revenue. 
--`CALL sokomart.sp_county_summary('Nakuru', NULL, NULL);` 
--| Procedure with `OUT` parameters | `p_customers, p_revenue` (one row) |
---answer: screenshots/D10.png
--==============================
CREATE OR REPLACE PROCEDURE sp_county_summary(IN p_county VARCHAR, OUT p_customers INTEGER, OUT p_revenue NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    -- 1. Count the number of customers living in the specified county
    SELECT COUNT(*) 
    INTO p_customers
    FROM customers 
    WHERE county = p_county;

    -- 2. Calculate the total completed revenue for customers in that county
    SELECT COALESCE(SUM(o.total_amount), 0)
    INTO p_revenue
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE c.county = p_county
      AND o.order_status = 'completed';
END;
$$;

---using the procedure summary
call sp_county_summary('Nakuru',NULL,NULL);





