--================================================================
--## Section D — Views, functions, stored procedures and triggers
--================================================================

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
-- 1. Stored Procedure: sp_update_product_price
create or replace procedure sp_update_product_price(p_product_id integer,p_new_price numeric,p_reason varchar)
language plpgsql
as $$
declare
    v_old_price  numeric;
	v_cost_price numeric;
begin
    -- validate new price is strictly positive
    if p_new_price is null or p_new_price <= 0 then
        raise exception 'invalid price (%): new unit price must be greater than 0.', p_new_price;
    end if;

    -- lock the target product row to prevent concurrent price anomalies
    select unit_price, cost_price
      into v_old_price, v_cost_price
      from products
     where product_id = p_product_id
       for UPDATE;

    -- checking if product exists
    if not found then
        raise exception 'product id % does not exist.', p_product_id;
    end if;

    -- check if new price is not below cost price
    if p_new_price < v_cost_price then
        raise exception 'price validation failed for product %: new price (%) cannot be below cost price (%).',
            p_product_id, p_new_price, v_cost_price;
    end if;

    --if all checks pass then, update the product's selling price
    update products
       set unit_price = p_new_price
     where product_id = p_product_id;

    -- recording the price transition in product_price_history
    insert into product_price_history (product_id,old_price,new_price,change_reason)
    values (p_product_id,v_old_price,p_new_price,p_reason);

    -- recording the jsonb diff in audit_logs
    insert into audit_logs (table_name, record_id,action,old_data,new_data)
    values ('products',p_product_id,'UPDATE',jsonb_build_object('unit_price', v_old_price),
        jsonb_build_object('unit_price', p_new_price));
end;
$$;

-- Step 1: Inspect initial state, apply valid price increase, and verify logs

-- 1a. checking state of product 71 before update
select product_id, product_name, unit_price, cost_price
  from products
 where product_id = 71;

-- 1b. Executing a valid price update (KES 1,099.00)
call sp_update_product_price(71,1099.00,'supplier price increase - Nov 2026');

-- 1c. checking state of product 71 after update
select product_id, product_name, unit_price, cost_price
  from products
 where product_id = 71;

-- 1d. check if there is a new entry in product_price_history
select price_history_id, product_id, old_price, new_price, change_reason
  from product_price_history
 where product_id = 71
 order by price_history_id desc
 limit 1;

-- 1e. verifying new entry in audit_logs
select table_name, record_id, action, old_data, new_data
  from audit_logs
 where table_name = 'products'
   and record_id = 71
 order by audit_id desc
 limit 1;

-- step 2: test rejection when new price is below cost_price (kes 500.00)
-- 2a. attempting invalid price update
call sp_update_product_price( 71,500.00,'attempted below-cost markdown');

-- 2b. confirm product price remains 1099.00
select product_id, product_name, unit_price, cost_price
  from sokomart.products
 where product_id = 71;

-- 2c. confirming no extra history row was written after low price was entered
select price_history_id, product_id, old_price, new_price, change_reason
  from product_price_history
 where product_id = 71
 order by price_history_id desc;

--=============================================================================
--### Question 19 — Trigger + procedure: order status changes are always logged 
--==============================================================================
--(a) Trigger Function and Trigger Definition
-- Create the trigger function to handle status history and audit logging
CREATE OR REPLACE FUNCTION sokomart.fn_orders_status_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        -- Record initial order creation status with old_status as NULL
        INSERT INTO sokomart.order_status_history (order_id, old_status, new_status)
        VALUES (NEW.order_id, NULL, NEW.order_status);

        -- Record the insert in audit_logs
        INSERT INTO sokomart.audit_logs (table_name, record_id, action, old_data, new_data)
        VALUES (
            'orders',
            NEW.order_id,
            'INSERT',
            NULL,
            jsonb_build_object('order_status', NEW.order_status)
        );

        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        -- Only log if the status has actually changed using IS DISTINCT FROM
        IF (OLD.order_status IS DISTINCT FROM NEW.order_status) THEN
            INSERT INTO sokomart.order_status_history (order_id, old_status, new_status)
            VALUES (NEW.order_id, OLD.order_status, NEW.order_status);

            INSERT INTO sokomart.audit_logs (table_name, record_id, action, old_data, new_data)
            VALUES (
                'orders',
                NEW.order_id,
                'UPDATE',
                jsonb_build_object('order_status', OLD.order_status),
                jsonb_build_object('order_status', NEW.order_status)
            );
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$;

-- Create the AFTER INSERT OR UPDATE trigger restricted to order_status changes
CREATE TRIGGER trg_orders_status_audit
AFTER INSERT OR UPDATE OF order_status ON sokomart.orders
FOR EACH ROW
EXECUTE FUNCTION sokomart.fn_orders_status_audit();


---(b) Stored Procedure: sokomart.sp_update_order_status

CREATE OR REPLACE PROCEDURE sokomart.sp_update_order_status(p_order_id INTEGER,p_new_status VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status VARCHAR;
BEGIN
    -- Lock the target order row
    SELECT order_status
      INTO v_current_status
      FROM sokomart.orders
     WHERE order_id = p_order_id
       FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order ID % does not exist.', p_order_id;
    END IF;
    -- Enforce strict state transition rules
    IF NOT (
        (v_current_status = 'pending' AND p_new_status = 'completed') OR
        (v_current_status = 'pending' AND p_new_status = 'cancelled') OR
        (v_current_status = 'completed' AND p_new_status = 'returned')
    ) THEN
        RAISE EXCEPTION 'Invalid status transition from "%" to "%" for order %.',
            v_current_status, p_new_status, p_order_id;
    END IF;

    -- Update the order status
    UPDATE sokomart.orders
       SET order_status = p_new_status
     WHERE order_id = p_order_id;

    -- Conditional updates for payments based on new status
    IF p_new_status = 'completed' THEN
        UPDATE sokomart.payments
           SET payment_status = 'successful'
         WHERE order_id = p_order_id;
    ELSIF p_new_status = 'cancelled' THEN
        UPDATE sokomart.payments
           SET payment_status = 'failed'
         WHERE order_id = p_order_id
           AND payment_status = 'unpaid';
    END IF;
END;
$$;

--(c) Proof & Verification Script
-- Step 1: Initial state of order 48882 (pending)

SELECT o.order_id, o.order_status, p.payment_status
  FROM sokomart.orders o
  LEFT JOIN sokomart.payments p ON o.order_id = p.order_id
 WHERE o.order_id = 48882;

-- Call procedure to complete the order
CALL sokomart.sp_update_order_status(48882, 'completed');

-- Show state after completion
SELECT o.order_id, o.order_status, p.payment_status
  FROM sokomart.orders o
  LEFT JOIN sokomart.payments p ON o.order_id = p.order_id
 WHERE o.order_id = 48882;

-- Show the new history row
SELECT order_id, old_status, new_status
  FROM sokomart.order_status_history
 WHERE order_id = 48882
 ORDER BY status_history_id DESC
 LIMIT 1;


-- Show the audit row
SELECT table_name, record_id, action, old_data, new_data
  FROM sokomart.audit_logs
 WHERE table_name = 'orders'
   AND record_id = 48882
 ORDER BY audit_id DESC
 LIMIT 1;


-- Step 2: Run a plain UPDATE setting it to 'returned' and verify trigger logging

UPDATE sokomart.orders
   SET order_status = 'returned'
 WHERE order_id = 48882;

-- Verify history row captured the plain update
SELECT order_id, old_status, new_status
  FROM sokomart.order_status_history
 WHERE order_id = 48882
 ORDER BY status_history_id DESC
 LIMIT 1;

-- Step 3: Run an update that does NOT change order_status (e.g., shipping_county)
-- Count history rows before non-status update
SELECT count(*) AS history_count 
  FROM sokomart.order_status_history 
 WHERE order_id = 48882;

-- Perform update on a non-status column
UPDATE sokomart.orders
   SET shipping_county = shipping_county
 WHERE order_id = 48882;

-- Confirm history row count remains unchanged (still exactly 2 rows)
SELECT count(*) AS history_count 
  FROM sokomart.order_status_history 
 WHERE order_id = 48882;

-- Step 4: Test exception handling for invalid transition on a cancelled order (49961)
CALL sokomart.sp_update_order_status(49961, 'completed');



















