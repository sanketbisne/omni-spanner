-- ==============================================================================
-- Advanced Analytical Queries for Spanner Omni Retail DB
-- ==============================================================================

-- 1. Category Performance & Revenue Analysis
-- Computes the total transactions, total units sold, and total revenue grouped by category
SELECT
    p.Category,
    COUNT(DISTINCT o.OrderID) AS total_sales,
    SUM(oi.Quantity) AS units_sold,
    SUM(oi.PriceAtOrderUSD * oi.Quantity) AS revenue
FROM Products p
JOIN OrderItems oi ON p.ProductID = oi.ProductID
JOIN Orders o ON oi.OrderID = o.OrderID
GROUP BY p.Category
ORDER BY revenue DESC;

-- 2. Customer Lifetime Value (CLV) Leaderboard
-- Identifies top customers by total monetary spend across all successful orders
SELECT
    u.UserID,
    u.Email,
    COUNT(o.OrderID) AS total_orders,
    SUM(o.TotalAmountUSD) AS lifetime_spend,
    AVG(o.TotalAmountUSD) AS average_order_value
FROM Users u
JOIN Orders o ON u.UserID = o.UserID
WHERE o.OrderStatus = 'COMPLETED'
GROUP BY u.UserID, u.Email
ORDER BY lifetime_spend DESC
LIMIT 10;

-- 3. Monthly Sales Growth Trend
-- Calculates aggregated sales and orders grouped by month to analyze growth trends
SELECT
    FORMAT_DATE('%Y-%m', DATE(o.OrderDate)) AS sales_month,
    COUNT(o.OrderID) AS order_count,
    SUM(o.TotalAmountUSD) AS monthly_revenue,
    AVG(o.TotalAmountUSD) AS avg_basket_size
FROM Orders o
WHERE o.OrderStatus = 'COMPLETED'
GROUP BY sales_month
ORDER BY sales_month ASC;

-- 4. Vector Search Similarity Query (Advanced Multi-Model Feature)
-- Recommends the top 5 most similar products to product 123 (High-end Smartphone Model X)
-- based on the cosine distance of their 768-dimension embeddings
SELECT 
    p2.ProductID, 
    p2.Name, 
    p2.Category, 
    p2.PriceUSD,
    COSINE_DISTANCE(p1.ProductEmbedding, p2.ProductEmbedding) AS similarity
FROM Products p1, Products p2
WHERE p1.ProductID = 123 AND p2.ProductID != 123
ORDER BY similarity ASC
LIMIT 5;
