-- 1. Checkout Flow

-- Convert a cart into:
-- 1. Order
-- 2. Order_Items
-- 3. Payment record
-- 4. Shipment records (one per vendor)
-- 5. Inventory updates

-- Must Use
-- 1. Stored Procedure
-- 2. Transaction
-- 3. Table Variable
-- 4. Error handling
-- 5. Inventory validation
-- 6. Trigger (optional for audit)

-- Business Rules
-- 1. Validate inventory availability
-- 2. Create order
-- 3. Insert order_items
-- 4. Create shipment per vendor
-- 5. Create payment
-- 6. Clear cart
-- 7. Commit everything or rollback

CREATE OR ALTER PROC sp_checkout 
@cart_id INT, @user_id INT, @payment_method VARCHAR(50)
AS
BEGIN
SET NOCOUNT ON

BEGIN TRY
    BEGIN TRANSACTION

        DECLARE @total_amount DECIMAL(10, 2), @order_id INT

        -- load cart_items into table variable
        DECLARE @cart_items TABLE (vendor_product_id INT, quantity INT, price DECIMAL(10,2))
        INSERT INTO @cart_items
        SELECT ci.vendor_product_id, ci.quantity, vp.price
        FROM orders.cart_item ci
        JOIN vendor.vendor_product vp ON ci.vendor_product_id = vp.vendor_product_id
        WHERE ci.cart_id = @cart_id;

        -- check inventory for these cart items
        IF EXISTS (
            SELECT 1
            FROM @cart_items c
            JOIN vendor.inventory i ON c.vendor_product_id = i.vendor_product_id
            WHERE i.quantity_available < c.quantity
        )
        BEGIN
            RAISERROR('The items in cart are no longer available.', 16, 1)
            ROLLBACK
            RETURN
        END

        -- create order
        INSERT INTO orders.orders (user_id, cart_id, created_at)
        VALUES (@user_id, @cart_id, GETDATE());
        SET @order_id = SCOPE_IDENTITY();

        -- insert order items
        INSERT INTO orders.order_item (order_id, vendor_product_id, price_at_purchase, quantity) 
        SELECT @order_id, vendor_product_id, price, quantity 
        FROM @cart_items;

        -- update inventory
        UPDATE i 
        SET quantity_available = quantity_available - c.quantity, last_updated = GETDATE()
        FROM vendor.inventory i
        JOIN @cart_items c ON i.vendor_product_id = c.vendor_product_id;

        -- calculate bill
        SELECT @total_amount = SUM(price * quantity) FROM @cart_items;

        -- create payment record
        INSERT INTO orders.payment (order_id, amount, method, status, created_at)
        VALUES (@order_id, @total_amount, @payment_method, 'PENDING', GETDATE());

        -- create shipment record
        INSERT INTO orders.shipment (order_id, vendor_id, status)
        SELECT DISTINCT @order_id, vp.vendor_id, 'PENDING' 
        FROM @cart_items c
        JOIN vendor.vendor_product vp ON c.vendor_product_id = vp.vendor_product_id;

        -- clear cart
        DELETE FROM orders.cart_item WHERE cart_id = @cart_id;
        DELETE FROM orders.cart WHERE cart_id = @cart_id;

        PRINT 'Checkout completed successfully.';

    COMMIT
END TRY
BEGIN CATCH
    ROLLBACK
    DECLARE @error_message VARCHAR(100) = 'Error in placing order.'
    RAISERROR(@error_message,16,1)
END CATCH

END;

EXEC sp_checkout 1, 1, 'PAYPAL';

---------------------------------------------------------------------------------------------------------------------------

-- 2. Dynamic Discount Engine (Scalar Function)

-- 1. If user has > 10 orders → 5% discount
-- 2. If vendor rating > 4.5 → 2% discount
-- 3. If inventory low (< 5 units) → no discount
-- Return final discount %

GO
CREATE OR ALTER FUNCTION orders.fn_dynamic_discount (@user_id INT, @vendor_product_id INT) RETURNS DECIMAL(5, 2) 
AS 
BEGIN
DECLARE @discount DECIMAL(5, 2) = 0, @user_order_count INT = 0, @vendor_rating DECIMAL(3, 2) = 0, @vendor_id INT

-- get vendor of product
SELECT @vendor_id = vendor_id
FROM vendor.vendor_product
WHERE vendor_product_id = @vendor_product_id;

-- get vendor rating
SELECT @vendor_rating = AVG(CAST(rating AS DECIMAL(3,2)))
FROM vendor.review r
JOIN vendor.vendor_product vp ON r.vendor_product_id = vp.vendor_product_id
WHERE vp.vendor_id = @vendor_id;

-- count completed orders of user
SELECT @user_order_count = COUNT(*)
FROM orders.orders o
JOIN orders.order_item oi ON o.order_id = oi.order_id 
JOIN orders.shipment s ON o.order_id = s.order_id 
WHERE o.user_id = @user_id AND s.status = 'DELIVERED';;

IF @vendor_rating > 4.5 SET @discount = @discount + 2;
IF @user_order_count > 10 SET @discount = @discount + 5;

RETURN @discount
END
GO

SELECT orders.fn_dynamic_discount(3, 6);
GO

---------------------------------------------------------------------------------------------------------------------------

-- 3. Vendor Performance Dashboard View

-- Create a View that shows per vendor:
-- 1. Total revenue
-- 2. Total orders
-- 3. Average rating
-- 4. Active listings
-- 5. Inventory value

-- Must Use
-- 1. JOINs
-- 2. GROUP BY
-- 3. Aggregations
-- 4. LEFT JOIN for ratings
-- 5. Subqueries

CREATE OR ALTER VIEW vw_vendor_dashboard 
AS 
SELECT 
    v.vendor_id, 
    v.name, 
    ISNULL(SUM(oi.price_at_purchase * oi.quantity), 0) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ISNULL(AVG(CAST(r.rating AS DECIMAL(3,2))), 0) AS avg_rating, 
    (
        SELECT COUNT(*)
        FROM vendor.vendor_product vp2
        WHERE vp2.vendor_id = v.vendor_id AND vp2.status = 'ACTIVE'
    ) AS active_listings, 
    (
        SELECT ISNULL(SUM(i.quantity_available * vp3.price), 0)
        FROM vendor.vendor_product vp3
        JOIN vendor.inventory i ON vp3.vendor_product_id = i.vendor_product_id
        WHERE vp3.vendor_id = v.vendor_id
    ) AS inventory_value 
    FROM vendor.vendor v 
    LEFT JOIN vendor.vendor_product vp ON v.vendor_id = vp.vendor_id 
    LEFT JOIN orders.order_item oi ON vp.vendor_product_id = oi.vendor_product_id 
    LEFT JOIN orders.orders o ON oi.order_id = o.order_id 
    LEFT JOIN orders.shipment s ON o.order_id = s.order_id AND s.status = 'DELIVERED' 
    LEFT JOIN vendor.review r ON vp.vendor_product_id = r.vendor_product_id 
    GROUP BY v.vendor_id, v.name;
GO

SELECT * FROM vw_vendor_dashboard;
GO

---------------------------------------------------------------------------------------------------------------------------

-- 4. User Purchase History Function

-- Return:
-- 1. Total spent
-- 2. Total orders
-- 3. Last purchase date
-- 4. Most purchased category

-- Must Use
-- 1. Table-valued function
-- 2. Aggregation
-- 3. Subqueries

CREATE OR ALTER FUNCTION users.fn_user_purchase_summary (@user_id INT) RETURNS TABLE
AS
RETURN (
    SELECT 
        ISNULL(SUM(oi.price_at_purchase * oi.quantity), 0) AS total_spent, 
        COUNT(DISTINCT o.order_id) AS total_orders, 
        MAX(o.created_at) AS last_purchase_date, 
        (
            SELECT TOP 1 c.name
            FROM orders.orders o2
            JOIN orders.order_item oi2 ON o2.order_id = oi2.order_id
            JOIN vendor.vendor_product vp ON oi2.vendor_product_id = vp.vendor_product_id
            JOIN production.product p ON vp.product_id = p.product_id
            JOIN production.product_category pc ON p.product_id = pc.product_id
            JOIN production.category c ON pc.category_id = c.category_id 
            JOIN orders.shipment s ON o2.order_id = s.order_id 
            WHERE o2.user_id = @user_id AND s.status = 'DELIVERED'
            GROUP BY c.name
            ORDER BY SUM(oi2.quantity) DESC
        ) AS most_purchased_category

    FROM orders.orders o
    JOIN orders.order_item oi ON o.order_id = oi.order_id 
    JOIN orders.shipment s ON o.order_id = s.order_id
    WHERE o.user_id = @user_id AND s.status = 'DELIVERED'
);
GO

SELECT * FROM users.fn_user_purchase_summary(3);
GO

---------------------------------------------------------------------------------------------------------------------------

-- 5. Temporary Table for Sales Report

-- Generate monthly sales report:
-- 1. Load all paid orders into temp table
-- 2. Join with order_items
-- 3. Aggregate revenue by category
-- 4. Rank top 5 categories

-- Must Use:
-- 1. #Temporary table
-- 2. Window functions
-- 3. CTE

CREATE OR ALTER PROCEDURE sp_monthly_sales_report 
@year INT, @month INT
AS
BEGIN
    SET NOCOUNT ON

    -- temp table for paid orders
    CREATE TABLE #PaidOrders (order_id INT PRIMARY KEY, user_id INT, created_at DATETIME);

    INSERT INTO #PaidOrders (order_id, user_id, created_at)
    SELECT o.order_id, user_id, created_at
    FROM orders.orders o 
    JOIN orders.shipment s ON o.order_id = s.order_id
    WHERE s.status = 'DELIVERED' AND YEAR(created_at) = @year AND MONTH(created_at) = @month;

    -- get the sales report
    WITH CategoryRevenue AS (
        SELECT c.category_id, c.name AS category_name, SUM(oi.price_at_purchase * oi.quantity) AS total_revenue
        FROM #PaidOrders po
        JOIN orders.order_item oi ON po.order_id = oi.order_id
        JOIN vendor.vendor_product vp ON oi.vendor_product_id = vp.vendor_product_id
        JOIN production.product p ON vp.product_id = p.product_id
        JOIN production.product_category pc ON p.product_id = pc.product_id
        JOIN production.category c ON pc.category_id = c.category_id
        GROUP BY c.category_id, c.name
    ),
    RankedCategories AS (
        SELECT category_id, category_name, total_revenue, 
            RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
        FROM CategoryRevenue
    )
    SELECT category_id, category_name, total_revenue, revenue_rank 
    FROM RankedCategories
    WHERE revenue_rank <= 5
    ORDER BY revenue_rank;

END;
GO

EXEC sp_monthly_sales_report 2026, 2;
GO

---------------------------------------------------------------------------------------------------------------------------

-- 6. Fraud Detection Flag

-- Flag users where:
-- 1. 5 failed payments in 1 hour
-- 2. Orders to 5 different states in 1 day
-- 3. High-value order with new account

-- Uses:
-- 1. Window functions
-- 2. Date logic
-- 3. Case statements

CREATE OR ALTER VIEW vw_suspicious_activity
AS
WITH FailedPaymentsCTE AS
(
    SELECT p1.payment_id, o.user_id, p1.created_at, (
        SELECT COUNT(*)
        FROM orders.payment p2
        JOIN orders.orders o2 ON p2.order_id = o2.order_id
        WHERE o2.user_id = o.user_id
            AND p2.status = 'FAILED'
            AND p2.created_at BETWEEN DATEADD(HOUR, -1, p1.created_at) AND p1.created_at
    ) AS failed_count_1hr
    FROM orders.payment p1
    JOIN orders.orders o ON p1.order_id = o.order_id
    WHERE p1.status = 'FAILED'
),
StateSpreadCTE AS (
    SELECT o.user_id, CAST(o.created_at AS DATE) AS order_date, COUNT(DISTINCT a.state) AS states_in_one_day
    FROM orders.orders o
    JOIN users.address a ON o.user_id = a.user_id 
    JOIN orders.shipment s ON o.order_id = s.order_id 
    WHERE s.status = 'DELIVERED'
    GROUP BY o.user_id, CAST(o.created_at AS DATE)
),
HighValueCTE AS (
    SELECT o.user_id, o.order_id, SUM(oi.price_at_purchase * oi.quantity) AS order_total, DATEDIFF(DAY, u.created_at, o.created_at) AS days_since_signup
    FROM orders.orders o
    JOIN orders.order_item oi ON o.order_id = oi.order_id
    JOIN users.users u ON o.user_id = u.user_id 
    JOIN orders.shipment s ON o.order_id = s.order_id 
    WHERE s.status = 'DELIVERED'
    GROUP BY o.user_id, o.order_id, u.created_at, o.created_at
)

SELECT DISTINCT u.user_id, u.email,
    CASE WHEN fp.failed_count_1hr >= 5 THEN 1
    ELSE 0
    END AS flag_failed_payments,

    CASE WHEN ss.states_in_one_day >= 5 THEN 1
    ELSE 0
    END AS flag_multi_state_orders,

    CASE WHEN hv.order_total > 1000 AND hv.days_since_signup <= 7 THEN 1
    ELSE 0
    END AS flag_high_value_new_user
FROM users.users u
LEFT JOIN FailedPaymentsCTE fp ON u.user_id = fp.user_id
LEFT JOIN StateSpreadCTE ss ON u.user_id = ss.user_id
LEFT JOIN HighValueCTE hv ON u.user_id = hv.user_id
WHERE fp.failed_count_1hr >= 5 OR ss.states_in_one_day >= 5 OR (hv.order_total > 1000 AND hv.days_since_signup <= 7);
GO

SELECT * FROM vw_suspicious_activity;
GO

---------------------------------------------------------------------------------------------------------------------------

-- 7. Automatic Review Eligibility Trigger

-- Only allow review if:
-- 1. User purchased product
-- 2. Order delivered

-- Use:
-- 1. INSTEAD OF INSERT trigger on Review
-- 2. Validation against Order_Item

CREATE OR ALTER TRIGGER trg_review_insert_validation
ON vendor.review
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO Review (user_id, vendor_product_id, rating, comment, created_at)
    SELECT i.user_id, i.vendor_product_id, i.rating, i.comment, GETDATE()
    FROM Inserted i
    WHERE EXISTS (
        SELECT 1
        FROM orders.orders o
        JOIN orders.order_item oi ON o.order_id = oi.order_id 
        JOIN orders.shipment s ON o.order_id = s.order_id
        WHERE o.user_id = i.user_id AND oi.vendor_product_id = i.vendor_product_id AND s.status = 'DELIVERED'
    );
END;
GO

---------------------------------------------------------------------------------------------------------------------------

-- 8. Order Cancellation Workflow

-- Must:
-- 1. Check status
-- 2. Refund payment
-- 3. Restore inventory
-- 4. Update shipment status
-- 5. Use transaction

CREATE OR ALTER PROCEDURE sp_cancel_order
@order_id INT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @order_status VARCHAR(20);

        -- 1️⃣ Check Order Status
        SELECT @order_status = status
        FROM orders.orders o JOIN orders.shipment s ON o.order_id = s.order_id
        WHERE o.order_id = @order_id;

        IF @order_status IS NULL
        BEGIN
            RAISERROR('Order does not exist.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        IF @order_status IN ('DELIVERED', 'CANCELLED')
        BEGIN
            RAISERROR('Cannot cancel delivered or already cancelled orders.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        -- Refund Payment
        UPDATE orders.payment
        SET status = 'REFUNDED' 
        WHERE order_id = @order_id AND status = 'COMPLETE';  -- Only refund completed payments

        -- Restore Inventory
        UPDATE i
        SET i.quantity_available = i.quantity_available + oi.quantity, i.last_updated = GETDATE()
        FROM vendor.inventory i
        JOIN orders.order_item oi ON i.vendor_product_id = oi.vendor_product_id
        WHERE oi.order_id = @order_id;

        -- Update Shipment Status
        UPDATE orders.shipment
        SET status = 'CANCELLED'
        WHERE order_id = @order_id AND status NOT IN ('DELIVERED');

        COMMIT;

        PRINT 'Order cancelled and inventory/payment updated successfully.';

    END TRY
    BEGIN CATCH
        ROLLBACK;
        RAISERROR('Error in cancelling order.',16,1);
    END CATCH
END;
GO

EXEC sp_cancel_order 5;
GO

---------------------------------------------------------------------------------------------------------------------------

-- 9. Fix fragmentation

-- FIND FRAGMENTATION
CREATE OR ALTER PROC check_fragmentation 
@table_name VARCHAR(50), @avg_frag DECIMAL(5, 2) OUTPUT, @avg_page_space DECIMAL(5, 2) OUTPUT 
AS 
BEGIN
select @avg_frag = avg_fragmentation_in_percent, @avg_page_space = avg_page_space_used_in_percent 
from sys.dm_db_index_physical_stats(db_id(),null,null,null,'SAMPLED') as IPS
inner join sys.indexes as i on ips.object_id = i.object_id and (ips.index_id = i.index_id)
where OBJECT_NAME(ips.object_id) = @table_name
order by avg_fragmentation_in_percent desc
END;
GO

-- FIX FRAGMENTATION
CREATE OR ALTER PROC fix_fragmentation 
@frag DECIMAL(5, 2), @table_name VARCHAR(50)
AS 
BEGIN
DECLARE @cmd NVARCHAR(MAX), @decision VARCHAR(10);
IF @frag <= 30
SET @decision = 'REORGANIZE'
ELSE
SET @decision = 'REBUILD'
SET @cmd = N'ALTER INDEX ALL ON ' + @table_name + ' ' + @decision;
EXEC SP_EXECUTESQL @cmd;
END;
GO

DECLARE @frag DECIMAL(5, 2), @space DECIMAL(5, 2), @table_name VARCHAR(50) = 't1', @decision VARCHAR(10);

-- FIND FRAGMENTATION
EXEC check_fragmentation @table_name = @table_name, @avg_frag = @frag OUTPUT, @avg_page_space = @space OUTPUT;
SELECT @frag AS Before_AvgFragmentation, @space AS Before_AvgPageSpaceUsed;

-- FIX FRAGMENTATION
EXEC fix_fragmentation @frag = @frag, @table_name = @table_name;
EXEC check_fragmentation @table_name = @table_name, @avg_frag = @frag OUTPUT, @avg_page_space = @space OUTPUT;
SELECT @frag AS After_AvgFragmentation, @space AS After_AvgPageSpaceUsed;

GO

---------------------------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_data_profile_clean_products
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        -- Table variable to store category-wise average price
        DECLARE @CategoryAvgPrice TABLE (category_id INT PRIMARY KEY, avg_price DECIMAL(10,2));

        INSERT INTO @CategoryAvgPrice(category_id, avg_price)
        SELECT pc.category_id, AVG(vp.price)
        FROM vendor.vendor_product vp
        JOIN production.product_category pc ON vp.product_id = pc.product_id
        WHERE vp.price IS NOT NULL
        GROUP BY pc.category_id;

        -- Temporary table for profiling stats
        CREATE TABLE #ProductProfile (vendor_product_id INT, name_missing BIT, price_missing BIT, invalid_condition BIT, status_inactive BIT);

        INSERT INTO #ProductProfile(vendor_product_id, name_missing, price_missing, invalid_condition, status_inactive)
        SELECT
            vp.vendor_product_id,
            CASE WHEN p.name IS NULL OR p.name = '' THEN 1 ELSE 0 END,
            CASE WHEN vp.price IS NULL OR vp.price <= 0 THEN 1 ELSE 0 END,
            CASE WHEN vp.[condition] NOT IN ('NEW','USED') THEN 1 ELSE 0 END,
            CASE WHEN vp.status <> 'ACTIVE' THEN 1 ELSE 0 END
        FROM vendor.vendor_product vp 
        JOIN production.product p ON vp.product_id = p.product_id;

        -- Set-based update for missing prices using JOIN
        UPDATE vp
        SET vp.price = cap.avg_price
        FROM vendor.vendor_product vp
        JOIN production.product_category pc ON vp.product_id = pc.product_id
        JOIN @CategoryAvgPrice cap ON pc.category_id = cap.category_id
        WHERE vp.price IS NULL OR vp.price <= 0;

        -- Fix invalid conditions
        UPDATE vendor.vendor_product
        SET [condition] = 'UNKNOWN'
        WHERE [condition] NOT IN ('NEW', 'USED', 'REFURBISHED', 'DAMAGED') OR [condition] IS NULL;

        SELECT * FROM #ProductProfile;

        COMMIT;

    END TRY
    BEGIN CATCH
        ROLLBACK;
        DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Data profiling/cleaning failed: %s', 16, 1, @err);
    END CATCH
END;
GO

EXEC sp_data_profile_clean_products
GO




