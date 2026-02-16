USE ecommerce_system;

-- PRODUCTION

-- Product
INSERT INTO production.product (name, description, brand) VALUES
('Laptop Pro 15', 'High-end laptop with Retina display', 'TechBrand'),
('Smartphone X', 'Latest smartphone with OLED display', 'PhoneCorp'),
('Wireless Headphones', 'Noise-cancelling over-ear headphones', 'SoundMax'),
('Gaming Mouse', 'RGB gaming mouse with high precision', 'GameTech'),
('4K Monitor', 'Ultra HD monitor for gaming and work', 'ViewSharp'),
('Mechanical Keyboard', 'RGB mechanical keyboard with blue switches', 'KeyMasters'),
('Smartwatch Z', 'Fitness tracker and smartwatch', 'WatchCo'),
('Bluetooth Speaker', 'Portable speaker with deep bass', 'SoundMax'),
('External SSD', 'Fast USB-C 1TB storage', 'TechBrand'),
('Drone Aerial', 'Compact drone with 4K camera', 'FlyHigh');

-- Category
INSERT INTO production.category (name, description) VALUES
('Electronics', 'Electronic devices and accessories'),
('Computers', 'Desktops, laptops, and peripherals'),
('Smartphones', 'Mobile phones and accessories'),
('Audio', 'Headphones, speakers, and audio devices'),
('Gaming', 'Gaming gear and consoles'),
('Wearables', 'Smart watches and fitness trackers'),
('Storage', 'External drives and storage devices'),
('Photography', 'Cameras and drones'),
('Office', 'Office and productivity accessories'),
('Home', 'Home electronics and gadgets');

-- Product-Category Mapping
INSERT INTO production.product_category (product_id, category_id) VALUES
(1, 2), (1, 1),
(2, 3), (2, 1),
(3, 4), 
(4, 5), 
(5, 2), 
(6, 5), 
(7, 6), 
(8, 4), 
(9, 7), 
(10, 8);

---------------------------------------------------------------------------------------------------------------------------

-- USERS

-- Roles
INSERT INTO users.role (type) VALUES
('Admin'), ('Customer'), ('Vendor');

-- Users
INSERT INTO users.users (first_name, last_name, email, password, role_id) VALUES
('Alice','Johnson','alice@gmail.com',HASHBYTES('SHA2_256','pass1'),2),
('Bob','Smith','bob@gmail.com',HASHBYTES('SHA2_256','pass2'),2),
('Charlie','Brown','charlie@gmail.com',HASHBYTES('SHA2_256','pass3'),2),
('Diana','Prince','diana@gmail.com',HASHBYTES('SHA2_256','pass4'),1),
('Evan','Taylor','evan@gmail.com',HASHBYTES('SHA2_256','pass5'),3),  -- Vendor
('Fiona','White','fiona@gmail.com',HASHBYTES('SHA2_256','pass6'),3), -- Vendor
('George','King','george@gmail.com',HASHBYTES('SHA2_256','pass7'),3),-- Vendor
('Hannah','Lee','hannah@gmail.com',HASHBYTES('SHA2_256','pass8'),2),
('Ian','Walker','ian@gmail.com',HASHBYTES('SHA2_256','pass9'),2),
('Julia','Roberts','julia@gmail.com',HASHBYTES('SHA2_256','pass10'),2);

-- Addresses
INSERT INTO users.address (user_id, apartment, street, city, state, zip) VALUES
(1,'101','Maple St','Los Angeles','CA','90001'),
(2,'202','Oak St','Los Angeles','CA','90002'),
(3,'303','Pine St','Los Angeles','CA','90003'),
(4,'404','Cedar St','Los Angeles','CA','90004'),
(5,'505','Elm St','Los Angeles','CA','90005'),
(6,'606','Birch St','Los Angeles','CA','90006'),
(7,'707','Spruce St','Los Angeles','CA','90007'),
(8,'808','Ash St','Los Angeles','CA','90008'),
(9,'909','Willow St','Los Angeles','CA','90009'),
(10,'1001','Poplar St','Los Angeles','CA','90010');

---------------------------------------------------------------------------------------------------------------------------

-- VENDOR

-- Vendors
INSERT INTO vendor.vendor (user_id, name, status) VALUES
(5,'TechWorld','APPROVED'),
(6,'GadgetPro','APPROVED'),
(7,'GameHouse','APPROVED');

-- Vendor Products
INSERT INTO vendor.vendor_product (vendor_id, product_id, price, discount, condition, status) VALUES
-- Laptop sold by 2 vendors
(1,1,1500,10,'NEW','ACTIVE'),
(2,1,1400,5,'REFURBISHED','ACTIVE'),

-- Smartphone variations
(1,2,999,0,'NEW','ACTIVE'),
(3,2,899,0,'USED','ACTIVE'),

-- Headphones
(2,3,199,5,'NEW','ACTIVE'),
(3,3,150,0,'USED','ACTIVE'),

-- Gaming Mouse
(3,4,49,0,'NEW','ACTIVE'),

-- Monitor (one inactive)
(1,5,399,15,'NEW','ACTIVE'),
(2,5,380,0,'NEW','OUT_OF_STOCK'),

-- Keyboard (blocked example)
(2,6,129,5,'NEW','ACTIVE'),
(1,6,100,0,'DAMAGED','BLOCKED');

-- Inventory
INSERT INTO vendor.inventory (vendor_product_id, quantity_available) VALUES
(1,50),(2,100),(3,80),(4,200),(5,30),
(6,120),(7,75),(8,60),(9,25),(10,40);

-- Reviews
INSERT INTO vendor.review (user_id, vendor_product_id, rating, comment) VALUES
(1,1,5,'Excellent product!'),
(2,2,4,'Good value for money'),
(3,3,5,'Highly recommend!'),
(4,4,3,'Average quality'),
(5,5,4,'Satisfied with purchase'),
(6,6,5,'Works perfectly'),
(7,7,4,'Very good'),
(8,8,3,'Okay for the price'),
(9,9,2,'Not as expected'),
(10,10,5,'Amazing drone!');

---------------------------------------------------------------------------------------------------------------------------

-- ORDERS

-- Orders
INSERT INTO orders.orders (user_id, created_at) VALUES
(1, DATEADD(DAY,-10,GETDATE())),
(2, DATEADD(DAY,-9,GETDATE())),
(3, DATEADD(DAY,-8,GETDATE())),
(4, DATEADD(DAY,-7,GETDATE())),
(5, DATEADD(DAY,-6,GETDATE())),
(6, DATEADD(DAY,-5,GETDATE())),
(7, DATEADD(DAY,-4,GETDATE())),
(8, DATEADD(DAY,-3,GETDATE())),
(9, DATEADD(DAY,-2,GETDATE())),
(10,DATEADD(DAY,-1,GETDATE()));

-- Order Items
INSERT INTO orders.order_item (order_id, vendor_product_id, price_at_purchase, quantity) VALUES
(1,1,1500.00,1),
(2,2,999.99,1),
(3,3,199.99,2),
(4,4,49.99,3),
(5,5,399.99,1),
(6,6,129.99,2),
(7,7,299.99,1),
(8,8,89.99,1),
(9,9,149.99,1),
(10,10,599.99,1);

-- Payments
INSERT INTO orders.payment (order_id, amount, method, status) VALUES
(1,1500.00,'Credit Card','COMPLETE'),
(2,999.99,'PayPal','COMPLETE'),
(3,399.98,'Credit Card','COMPLETE'),
(4,149.97,'Debit Card','COMPLETE'),
(5,399.99,'Credit Card','PENDING'),
(6,259.98,'PayPal','COMPLETE'),
(7,299.99,'Credit Card','COMPLETE'),
(8,89.99,'Debit Card','PENDING'),
(9,149.99,'Credit Card','COMPLETE'),
(10,599.99,'Credit Card','COMPLETE');

-- Shipments
INSERT INTO orders.shipment
(order_id, vendor_id, status, tracking_number, shipped_at, delivered_at)
VALUES

-- Order 1 (Single vendor, delivered)
(1, 1, 'DELIVERED', 'TRK10001',
 DATEADD(DAY,-9,GETDATE()),
 DATEADD(DAY,-7,GETDATE())),

-- Order 2 (Delivered late)
(2, 2, 'DELIVERED', 'TRK10002',
 DATEADD(DAY,-8,GETDATE()),
 DATEADD(DAY,-4,GETDATE())),

-- Order 3 (Multi-vendor order)
(3, 1, 'DELIVERED', 'TRK10003A',
 DATEADD(DAY,-7,GETDATE()),
 DATEADD(DAY,-5,GETDATE())),
(3, 3, 'DELIVERED', 'TRK10003B',
 DATEADD(DAY,-7,GETDATE()),
 DATEADD(DAY,-6,GETDATE())),

-- Order 4 (Lost shipment)
(4, 3, 'LOST', 'TRK10004',
 DATEADD(DAY,-6,GETDATE()),
 NULL),

-- Order 5 (Still pending, not shipped)
(5, 2, 'PENDING', NULL,
 NULL,
 NULL),

-- Order 6 (Delivered quickly)
(6, 1, 'DELIVERED', 'TRK10006',
 DATEADD(DAY,-4,GETDATE()),
 DATEADD(DAY,-3,GETDATE())),

-- Order 7 (Refunded after delivery issue)
(7, 3, 'REFUNDED', 'TRK10007',
 DATEADD(DAY,-3,GETDATE()),
 DATEADD(DAY,-2,GETDATE())),

-- Order 8 (Shipped but not delivered yet)
(8, 2, 'PENDING', 'TRK10008',
 DATEADD(DAY,-1,GETDATE()),
 NULL),

-- Order 9 (Delivered today)
(9, 1, 'DELIVERED', 'TRK10009',
 DATEADD(DAY,-2,GETDATE()),
 GETDATE()),

-- Order 10 (Delayed delivery)
(10, 2, 'DELIVERED', 'TRK10010',
 DATEADD(DAY,-5,GETDATE()),
 DATEADD(DAY,-1,GETDATE()));

-- Cart
INSERT INTO orders.cart (user_id, created_at, updated_at) VALUES
(1, DATEADD(DAY,-5,GETDATE()), DATEADD(DAY,-1,GETDATE())),
(2, DATEADD(DAY,-4,GETDATE()), DATEADD(DAY,-2,GETDATE())),
(3, DATEADD(DAY,-3,GETDATE()), DATEADD(DAY,-1,GETDATE())),
(4, DATEADD(DAY,-2,GETDATE()), DATEADD(DAY,-1,GETDATE())),
(5, DATEADD(DAY,-6,GETDATE()), DATEADD(DAY,-3,GETDATE())),
(6, DATEADD(DAY,-7,GETDATE()), DATEADD(DAY,-4,GETDATE())),
(7, DATEADD(DAY,-1,GETDATE()), GETDATE()),
(8, DATEADD(DAY,-8,GETDATE()), DATEADD(DAY,-2,GETDATE())),
(9, DATEADD(DAY,-9,GETDATE()), DATEADD(DAY,-5,GETDATE())),
(10,DATEADD(DAY,-10,GETDATE()), DATEADD(DAY,-6,GETDATE()));

-- Cart Items
INSERT INTO orders.cart_item (cart_id, vendor_product_id, quantity) VALUES
(1,1,1),(2,2,2),(3,3,1),(4,4,3),(5,5,1),
(6,6,2),(7,7,1),(8,8,1),(9,9,1),(10,10,1);
