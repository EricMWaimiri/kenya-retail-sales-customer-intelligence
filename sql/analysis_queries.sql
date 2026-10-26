-- Kenya Retail Sales & Customer Intelligence
-- PostgreSQL analysis queries: joins, aggregations, window functions, cohorts, RFM.
-- Sales calculated as Quantity * UnitPriceKsh are list-price sales before discounts unless noted.

-- Monthly Sales Trend
SELECT
    DATE_TRUNC('month', s."TransactionDate") AS month,
    SUM(s."Quantity" * p."UnitPriceKsh") AS gross_sales,
    SUM(s."Quantity") AS total_units,
    COUNT(DISTINCT s."TransactionID") AS transactions
FROM sales s
JOIN products p ON s."ProductID" = p."ProductID"
GROUP BY 1
ORDER BY 1;

-- Top Product Categories
WITH category_sales AS (
    SELECT
        p."Category",
        SUM(s."Quantity" * p."UnitPriceKsh") AS gross_sales,
        SUM(s."Quantity") AS total_units
    FROM sales s
    JOIN products p ON s."ProductID" = p."ProductID"
    GROUP BY p."Category"
)
SELECT
    "Category",
    gross_sales,
    total_units,
    ROUND(
        gross_sales * 100.0 / NULLIF(SUM(gross_sales) OVER (), 0),
        2
    ) AS pct_of_total
FROM category_sales
ORDER BY gross_sales DESC;

-- Sales by Customer Segment & Payment Method
SELECT
    c."CustomerSegment",
    s."PaymentMethod",
    COUNT(*) AS sales_lines,
    SUM(s."Quantity" * p."UnitPriceKsh") AS gross_sales
FROM sales s
JOIN customers c ON s."CustomerID" = c."Id"
JOIN products p ON s."ProductID" = p."ProductID"
GROUP BY 1, 2
ORDER BY gross_sales DESC;

-- Monthly Sales vs CPI
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', s."TransactionDate") AS month,
        SUM(s."Quantity" * p."UnitPriceKsh") AS gross_sales
    FROM sales s
    JOIN products p ON s."ProductID" = p."ProductID"
    GROUP BY 1
)
SELECT
    ms.month,
    ms.gross_sales,
    c."Cpi",
    c."BasePeriod"
FROM monthly_sales ms
LEFT JOIN national_cpi c
    ON DATE_TRUNC('month', c."Date") = ms.month
ORDER BY ms.month;

-- Store and County Performance
SELECT
    st."County",
    st."StoreName",
    SUM(s."Quantity" * p."UnitPriceKsh") AS gross_sales,
    COUNT(DISTINCT s."TransactionID") AS transactions
FROM sales s
JOIN stores st ON s."StoreID" = st."StoreID"
JOIN products p ON s."ProductID" = p."ProductID"
GROUP BY 1, 2
ORDER BY gross_sales DESC;

-- Top 10 Products by Gross Sales
SELECT
    p."ProductName",
    p."Category",
    SUM(s."Quantity" * p."UnitPriceKsh") AS gross_sales,
    SUM(s."Quantity") AS total_units
FROM sales s
JOIN products p ON s."ProductID" = p."ProductID"
GROUP BY p."ProductName", p."Category"
ORDER BY gross_sales DESC
LIMIT 10;

-- Simple RFM View (Recency, Frequency, Monetary)
SELECT
    c."Id" AS customer_id,
    c."CustomerSegment",
    MAX(s."TransactionDate") AS last_purchase,
    COUNT(DISTINCT s."TransactionID") AS frequency,
    SUM(s."Quantity" * p."UnitPriceKsh") AS monetary_value
FROM sales s
JOIN customers c ON s."CustomerID" = c."Id"
JOIN products p ON s."ProductID" = p."ProductID"
GROUP BY c."Id", c."CustomerSegment"
ORDER BY monetary_value DESC
LIMIT 20;

-- Month-over-Month Growth
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', s."TransactionDate") AS month,
        SUM(s."Quantity" * p."UnitPriceKsh") AS gross_sales
    FROM sales s
    JOIN products p ON s."ProductID" = p."ProductID"
    GROUP BY 1
)
SELECT
    month,
    gross_sales,
    SUM(gross_sales) OVER (ORDER BY month) AS running_total,
    ROUND(
        (gross_sales - LAG(gross_sales) OVER (ORDER BY month)) * 100.0 /
        NULLIF(LAG(gross_sales) OVER (ORDER BY month), 0), 2
    ) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- Customer Activity Matrix by Signup Month
SELECT
    DATE_TRUNC('month', c."SignupDate") AS cohort_month,
    DATE_TRUNC('month', s."TransactionDate") AS order_month,
    COUNT(DISTINCT c."Id") AS active_customers,
    SUM(s."Quantity" * p."UnitPriceKsh") AS gross_sales
FROM customers c
JOIN sales s ON c."Id" = s."CustomerID"
JOIN products p ON s."ProductID" = p."ProductID"
GROUP BY 1, 2
ORDER BY 1, 2;

-- Full RFM Segmentation
WITH rfm AS (
    SELECT
        c."Id" AS customer_id,
        c."CustomerSegment",
        MAX(s."TransactionDate") AS last_purchase,
        COUNT(DISTINCT s."TransactionID") AS frequency,
        SUM(s."Quantity" * p."UnitPriceKsh") AS monetary
    FROM sales s
    JOIN customers c ON s."CustomerID" = c."Id"
    JOIN products p ON s."ProductID" = p."ProductID"
    GROUP BY c."Id", c."CustomerSegment"
),
rfm_scored AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY last_purchase DESC) AS recency_score,  -- higher = more recent
        NTILE(4) OVER (ORDER BY frequency) AS frequency_score,
        NTILE(4) OVER (ORDER BY monetary) AS monetary_score
    FROM rfm
)
SELECT
    customer_id,
    "CustomerSegment",
    last_purchase,
    frequency,
    ROUND(monetary, 2) AS monetary,
    recency_score,
    frequency_score,
    monetary_score,
    recency_score + frequency_score + monetary_score AS rfm_total
FROM rfm_scored
ORDER BY rfm_total DESC
LIMIT 30;

-- Top Customers by County
WITH ranked_customers AS (
    SELECT
        st."County",
        c."Id" AS customer_id,
        c."CustomerSegment",
        SUM(s."Quantity" * p."UnitPriceKsh") AS total_spent,
        RANK() OVER (
            PARTITION BY st."County"
            ORDER BY SUM(s."Quantity" * p."UnitPriceKsh") DESC
        ) AS rank_in_county
    FROM sales s
    JOIN customers c ON s."CustomerID" = c."Id"
    JOIN stores st ON s."StoreID" = st."StoreID"
    JOIN products p ON s."ProductID" = p."ProductID"
    GROUP BY st."County", c."Id", c."CustomerSegment"
)
SELECT *
FROM ranked_customers
WHERE rank_in_county <= 5
ORDER BY "County", rank_in_county;

-- Category Performance by Month (cleaned with CTE)
WITH monthly_category AS (
    SELECT
        DATE_TRUNC('month', s."TransactionDate") AS month,
        p."Category",
        SUM(s."Quantity" * p."UnitPriceKsh") AS gross_sales
    FROM sales s
    JOIN products p ON s."ProductID" = p."ProductID"
    GROUP BY 1, 2
)
SELECT
    month,
    "Category",
    gross_sales,
    ROUND(
        gross_sales * 100.0 /
        NULLIF(SUM(gross_sales) OVER (PARTITION BY month), 0), 2
    ) AS pct_of_month
FROM monthly_category
ORDER BY month, gross_sales DESC;

-- Promotion Period Impact (Date-based overlap only)
SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM promotions pr
            WHERE s."TransactionDate"::date BETWEEN pr."StartDate" AND pr."EndDate"
        ) THEN 'During Promotion'
        ELSE 'Outside Promotion'
    END AS period_type,
    COUNT(*) AS sales_lines,
    SUM(s."Quantity" * p."UnitPriceKsh") AS gross_sales,
    ROUND(AVG(s."DiscountPct"), 2) AS avg_discount_pct
FROM sales s
JOIN products p ON s."ProductID" = p."ProductID"
GROUP BY 1;

-- Average Basket Size by Segment & Store
SELECT
    c."CustomerSegment",
    st."StoreName",
    COUNT(DISTINCT s."TransactionID") AS transactions,
    ROUND(SUM(s."Quantity" * p."UnitPriceKsh") / COUNT(DISTINCT s."TransactionID"), 2) AS avg_basket_value,
    ROUND(SUM(s."Quantity") * 1.0 / COUNT(DISTINCT s."TransactionID"), 2) AS avg_units_per_basket
FROM sales s
JOIN customers c ON s."CustomerID" = c."Id"
JOIN stores st ON s."StoreID" = st."StoreID"
JOIN products p ON s."ProductID" = p."ProductID"
GROUP BY 1, 2
ORDER BY avg_basket_value DESC;

-- Product Profit Ranking without Discounts
SELECT
    p."ProductName",
    p."Category",
    SUM(s."Quantity") AS units_sold,
    SUM(s."Quantity" * p."UnitPriceKsh") AS gross_sales,
    SUM(s."Quantity" * (p."UnitPriceKsh" - p."UnitCostKsh")) AS gross_profit,
    ROUND(
        SUM(s."Quantity" * (p."UnitPriceKsh" - p."UnitCostKsh")) * 100.0 /
        NULLIF(SUM(s."Quantity" * p."UnitPriceKsh"), 0), 2
    ) AS gross_margin_pct
FROM sales s
JOIN products p ON s."ProductID" = p."ProductID"
GROUP BY p."ProductName", p."Category"
ORDER BY gross_profit DESC
LIMIT 15;

-- Product Profit Ranking with Discounts
SELECT
    p."ProductName",
    p."Category",
    SUM(s."Quantity") AS units_sold,
    SUM(s."Quantity" * p."UnitPriceKsh") AS gross_sales,
    SUM(s."Quantity" * p."UnitPriceKsh" * (1 - COALESCE(s."DiscountPct", 0) / 100.0)) AS net_sales,
    SUM(s."Quantity" * p."UnitCostKsh") AS cogs,
    SUM(
        (s."Quantity" * p."UnitPriceKsh" * (1 - COALESCE(s."DiscountPct", 0) / 100.0))
        - (s."Quantity" * p."UnitCostKsh")
    ) AS gross_profit,
    ROUND(
        SUM(
            (s."Quantity" * p."UnitPriceKsh" * (1 - COALESCE(s."DiscountPct", 0) / 100.0))
            - (s."Quantity" * p."UnitCostKsh")
        ) * 100.0
        / NULLIF(
            SUM(s."Quantity" * p."UnitPriceKsh" * (1 - COALESCE(s."DiscountPct", 0) / 100.0)),
            0
        ),
        2
    ) AS gross_margin_pct
FROM sales s
JOIN products p ON s."ProductID" = p."ProductID"
GROUP BY p."ProductName", p."Category"
ORDER BY gross_profit DESC
LIMIT 15;

-- Customer Type Ranking (One-time / Repeat / Loyal)
WITH customer_orders AS (
    SELECT
        s."CustomerID",
        COUNT(DISTINCT s."TransactionID") AS order_count,
        SUM(s."Quantity" * p."UnitPriceKsh") AS total_spent
    FROM sales s
    JOIN products p ON s."ProductID" = p."ProductID"
    GROUP BY s."CustomerID"
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time'
        WHEN order_count BETWEEN 2 AND 4 THEN 'Repeat (2-4)'
        ELSE 'Loyal (5+)'
    END AS customer_type,
    COUNT(*) AS customers,
    ROUND(AVG(total_spent), 2) AS avg_spent,
    SUM(total_spent) AS total_revenue
FROM customer_orders
GROUP BY 1
ORDER BY avg_spent DESC;

-- CPI vs Sales Correlation
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', s."TransactionDate") AS month,
        SUM(s."Quantity" * p."UnitPriceKsh") AS gross_sales,
        SUM(s."Quantity") AS total_units
    FROM sales s
    JOIN products p ON s."ProductID" = p."ProductID"
    GROUP BY 1
)
SELECT
    m.month,
    m.gross_sales,
    m.total_units,
    c."Cpi",
    c."BasePeriod",
    ROUND(m.gross_sales / NULLIF(c."Cpi", 0), 2) AS real_sales_index
FROM monthly m
JOIN national_cpi c ON DATE_TRUNC('month', c."Date") = m.month
ORDER BY m.month;
