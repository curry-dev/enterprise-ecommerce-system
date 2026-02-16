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
-- 2. Lock stock (increase reserved_quantity)
-- 3. Create order
-- 4. Insert order_items
-- 5. Create shipment per vendor
-- 6. Create payment
-- 7. Clear cart
-- 8. Commit everything or rollback

-- Dynamic Discount Engine (Scalar Function)
-- 1. If user has > 10 orders → 5% discount
-- 2. If vendor rating > 4.5 → 2% discount
-- 3. If inventory low (< 5 units) → no discount
-- Return final discount %

---------------------------------------------------------------------------------------------------------------------------

-- 2. Prevent Overselling (Inventory Trigger)

-- When Order_Item is inserted:
-- 1. Deduct inventory.quantity_available
-- 2. Reduce reserved_quantity
-- 3. Prevent negative stock
-- 4. If quantity_available < 0 → rollback

-- Must Use
-- 1. AFTER INSERT Trigger
-- 2. Validation logic
-- 3. RAISERROR

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

---------------------------------------------------------------------------------------------------------------------------

-- 5. Automatic Order Status Updates (Trigger)

-- When all shipments for an order are delivered:
-- 1. Update Order.status = 'DELIVERED'

-- Use:
-- 1. AFTER UPDATE trigger on Shipment
-- 2. COUNT logic

---------------------------------------------------------------------------------------------------------------------------

-- 6. Temporary Table for Sales Report

-- Generate monthly sales report:
-- 1. Load all paid orders into temp table
-- 2. Join with order_items
-- 3. Aggregate revenue by category
-- 4. Rank top 5 categories

-- Must Use:
-- 1. #Temporary table
-- 2. Window functions
-- 3. CTE

---------------------------------------------------------------------------------------------------------------------------

-- 7. Table Variable for Bulk Price Update

-- Vendor wants to update prices for multiple listings.
-- 1. Accept table-valued parameter
-- 2. Validate approval_status
-- 3. Update only ACTIVE listings

---------------------------------------------------------------------------------------------------------------------------

-- 8. Fraud Detection Flag

-- Flag users where:
-- 1. 5 failed payments in 1 hour
-- 2. Orders to 5 different states in 1 day
-- 3. High-value order with new account

-- Uses:
-- 1. Window functions
-- 2. Date logic
-- 3. Case statements

---------------------------------------------------------------------------------------------------------------------------

-- 9. Automatic Review Eligibility Trigger

-- Only allow review if:
-- 1. User purchased product
-- 2. Order delivered

-- Use:
-- 1. INSTEAD OF INSERT trigger on Review
-- 2. Validation against Order_Item

---------------------------------------------------------------------------------------------------------------------------

-- 10. Order Cancellation Workflow

-- Must:
-- 1. Check status
-- 2. Refund payment
-- 3. Restore inventory
-- 4. Update shipment status
-- 5. Use transaction
