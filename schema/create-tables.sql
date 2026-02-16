CREATE SCHEMA production;
GO

CREATE TABLE production.product (
    product_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(200),
    brand VARCHAR(50),
    is_active BIT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE production.category (
    category_id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200)
);

CREATE TABLE production.product_category (
    product_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (product_id, category_id),
    FOREIGN KEY (product_id) REFERENCES production.product(product_id),
    FOREIGN KEY (category_id) REFERENCES production.category(category_id)
);

GO

---------------------------------------------------------------------------------------------------------------------------

CREATE SCHEMA users;
GO

CREATE TABLE users.role (
    role_id INT PRIMARY KEY,
    type VARCHAR(50) NOT NULL
);

CREATE TABLE users.users (
    user_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARBINARY(255) NOT NULL,
    role_id INT NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'DEACTIVATED', 'DELETED')),
    address_id INT,
    FOREIGN KEY (role_id) REFERENCES users.role(role_id)
);

CREATE TABLE users.address (
    address_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    apartment VARCHAR(100),
    street VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    zip VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users.users(user_id)
);

GO

---------------------------------------------------------------------------------------------------------------------------

CREATE SCHEMA vendor;
GO

CREATE TABLE vendor.vendor (
    vendor_id INT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'SUSPENDED', 'REJECTED')),
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES users.users(user_id)
);

CREATE TABLE vendor.vendor_product (
    vendor_product_id INT PRIMARY KEY,
    vendor_id INT NOT NULL,
    product_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    discount DECIMAL(5,2) DEFAULT 0,
    condition VARCHAR(20) DEFAULT 'NEW' CHECK (condition IN ('NEW', 'USED', 'REFURBISHED', 'DAMAGED')),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'OUT_OF_STOCK', 'REMOVED', 'BLOCKED')),
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (vendor_id) REFERENCES vendor.vendor(vendor_id),
    FOREIGN KEY (product_id) REFERENCES production.product(product_id)
);

CREATE TABLE vendor.inventory (
    inventory_id INT PRIMARY KEY,
    vendor_product_id INT NOT NULL UNIQUE,
    quantity_available INT DEFAULT 0 CHECK (quantity_available >= 0),
    last_updated DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (vendor_product_id) REFERENCES vendor.vendor_product(vendor_product_id)
);

CREATE TABLE vendor.review (
    review_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    vendor_product_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES users.users(user_id),
    FOREIGN KEY (vendor_product_id) REFERENCES vendor.vendor_product(vendor_product_id)
);

GO

---------------------------------------------------------------------------------------------------------------------------

CREATE SCHEMA orders;
GO

CREATE TABLE orders.orders (
    order_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES users.users(user_id)
);

CREATE TABLE orders.order_item (
    order_item_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    vendor_product_id INT NOT NULL,
    price_at_purchase DECIMAL(10,2) NOT NULL,
    quantity INT DEFAULT 1,
    FOREIGN KEY (order_id) REFERENCES orders.orders(order_id),
    FOREIGN KEY (vendor_product_id) REFERENCES vendor.vendor_product(vendor_product_id)
);

CREATE TABLE orders.payment (
    payment_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    method VARCHAR(50),
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETE')),
    reference_number VARCHAR(50),
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (order_id) REFERENCES orders.orders(order_id)
);

CREATE TABLE orders.shipment (
    shipment_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    vendor_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'DELIVERED', 'LOST', 'REFUNDED')),
    tracking_number VARCHAR(50),
    shipped_at DATETIME,
    delivered_at DATETIME,
    FOREIGN KEY (order_id) REFERENCES orders.orders(order_id),
    FOREIGN KEY (vendor_id) REFERENCES vendor.vendor(vendor_id)
);

CREATE TABLE orders.cart (
    cart_id INT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES users.users(user_id)
);

CREATE TABLE orders.cart_item (
    cart_item_id INT PRIMARY KEY,
    cart_id INT NOT NULL,
    vendor_product_id INT NOT NULL,
    quantity INT DEFAULT 1,
    FOREIGN KEY (cart_id) REFERENCES orders.cart(cart_id),
    FOREIGN KEY (vendor_product_id) REFERENCES vendor.vendor_product(vendor_product_id)
);
