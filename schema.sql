---table creation
CREATE TABLE events (
    user_id INT,
    event_type VARCHAR(50),
    timestamp TIMESTAMPTZ,
    device VARCHAR(20),
    source VARCHAR(20)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    amount DECIMAL(10,2),
    discount DECIMAL(10,2),
    status VARCHAR(20),
    timestamp TIMESTAMPTZ
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2)
);
--verify importing data
SELECT COUNT(*) FROM events;   
SELECT COUNT(*) FROM orders;    
SELECT COUNT(*) FROM products;

-- Peek at the first few rows
SELECT * FROM events LIMIT 5;
SELECT * FROM orders LIMIT 5;
SELECT * FROM products LIMIT 5;

-- explore data
-- What event types exist?
SELECT DISTINCT event_type FROM events;

-- Which traffic sources?
SELECT DISTINCT source FROM events;

-- Orders statuses (should all be 'completed' in this dataset)
SELECT DISTINCT status FROM orders;

-- Date range
SELECT MIN(timestamp), MAX(timestamp) FROM events;
