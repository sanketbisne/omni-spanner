-- ==============================================================================
-- Basic SQL Operations & Exploration for Spanner Omni Retail Sample DB
-- ==============================================================================

-- 1. Inspect the Database Schema
SHOW TABLES;

-- 2. Inspect Table Schema for Products
SELECT column_name, data_type, is_nullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'Products';

-- 3. Retrieve first 5 products to see structure
SELECT ProductID, Name, Category, PriceUSD
FROM Products
LIMIT 5;

-- 4. Retrieve first 5 orders
SELECT OrderID, UserID, OrderDate, TotalAmountUSD, OrderStatus
FROM Orders
LIMIT 5;

-- 5. Query Products priced under $100
SELECT Name, Category, PriceUSD
FROM Products
WHERE PriceUSD < 100
ORDER BY PriceUSD ASC
LIMIT 5;

-- 6. Retrieve detailed Order information for a specific customer
SELECT o.OrderID, o.OrderDate, o.TotalAmountUSD, u.Email
FROM Orders o
JOIN Users u ON o.UserID = u.UserID
LIMIT 5;
