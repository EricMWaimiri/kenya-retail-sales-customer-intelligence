-- Kenya Retail Sales & Customer Intelligence
-- Run after loading the data and creating the schema.
-- These queries check row counts, missing values, duplicate keys, relationships, ranges and date coverage.
-- A validation query returning rows means investigate the listed issue; it does not always mean the data is unusable.

-- 1. Row counts for all seven tables
SELECT 'stores' AS table_name, COUNT(*) AS row_count FROM stores
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'promotions', COUNT(*) FROM promotions
UNION ALL SELECT 'public_holidays', COUNT(*) FROM public_holidays
UNION ALL SELECT 'national_cpi', COUNT(*) FROM national_cpi
UNION ALL SELECT 'sales', COUNT(*) FROM sales
ORDER BY table_name;

-- 2. Check duplicate primary-key values in source data before loading.
-- (Primary keys prevent duplicates after successful table creation.)
SELECT "SaleID", COUNT(*) AS duplicate_count FROM sales GROUP BY "SaleID" HAVING COUNT(*) > 1;
SELECT "ProductID", COUNT(*) AS duplicate_count FROM products GROUP BY "ProductID" HAVING COUNT(*) > 1;
SELECT "StoreID", COUNT(*) AS duplicate_count FROM stores GROUP BY "StoreID" HAVING COUNT(*) > 1;
SELECT "Id", COUNT(*) AS duplicate_count FROM customers GROUP BY "Id" HAVING COUNT(*) > 1;

-- 3. Required or key sales fields that are missing
SELECT
    COUNT(*) FILTER (WHERE "SaleID" IS NULL) AS missing_sale_id,
    COUNT(*) FILTER (WHERE "TransactionID" IS NULL OR BTRIM("TransactionID") = '') AS missing_transaction_id,
    COUNT(*) FILTER (WHERE "TransactionDate" IS NULL) AS missing_transaction_date,
    COUNT(*) FILTER (WHERE "ProductID" IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE "Quantity" IS NULL) AS missing_quantity
FROM sales;

-- 4. Check invalid sales quantities, discounts, or prices
SELECT * FROM sales WHERE "Quantity" IS NULL OR "Quantity" <= 0;
SELECT * FROM sales WHERE "DiscountPct" IS NOT NULL AND ("DiscountPct" < 0 OR "DiscountPct" > 100);
SELECT * FROM products WHERE "UnitCostKsh" < 0 OR "UnitPriceKsh" < 0;

-- 5. Check for orphan foreign keys (normally prevented by the schema's FK constraints)
SELECT s."SaleID", s."CustomerID"
FROM sales s LEFT JOIN customers c ON s."CustomerID" = c."Id"
WHERE s."CustomerID" IS NOT NULL AND c."Id" IS NULL;

SELECT s."SaleID", s."StoreID"
FROM sales s LEFT JOIN stores st ON s."StoreID" = st."StoreID"
WHERE s."StoreID" IS NOT NULL AND st."StoreID" IS NULL;

SELECT s."SaleID", s."ProductID"
FROM sales s LEFT JOIN products p ON s."ProductID" = p."ProductID"
WHERE s."ProductID" IS NOT NULL AND p."ProductID" IS NULL;

-- 6. Check sales date coverage and quantity summary
SELECT
    MIN("TransactionDate") AS first_transaction,
    MAX("TransactionDate") AS last_transaction,
    COUNT(*) AS sales_lines,
    COUNT(DISTINCT "TransactionID") AS distinct_transactions,
    SUM("Quantity") AS total_units
FROM sales;

-- 7. Check CPI coverage and whether more than one base period exists.
-- CPI index values from different base periods should not be compared directly without rebasing.
SELECT
    MIN("Date") AS first_cpi_month,
    MAX("Date") AS last_cpi_month,
    COUNT(*) AS cpi_rows,
    COUNT(DISTINCT "BasePeriod") AS number_of_base_periods
FROM national_cpi;

SELECT "BasePeriod", COUNT(*) AS months
FROM national_cpi
GROUP BY "BasePeriod"
ORDER BY "BasePeriod";

-- 8. Check months in sales that do not have a matching CPI row.
WITH sales_months AS (
    SELECT DATE_TRUNC('month', "TransactionDate") AS month
    FROM sales
    GROUP BY 1
)
SELECT sm.month::date AS sales_month
FROM sales_months sm
LEFT JOIN national_cpi c ON DATE_TRUNC('month', c."Date") = sm.month
WHERE c."Date" IS NULL
ORDER BY sales_month;

-- 9. Check promotion date ranges and holiday date coverage.
SELECT * FROM promotions
WHERE "StartDate" IS NULL OR "EndDate" IS NULL OR "EndDate" < "StartDate";

SELECT MIN("Date") AS first_holiday, MAX("Date") AS last_holiday, COUNT(*) AS holiday_rows
FROM public_holidays;

-- 10. Basic sales totals. This is list-price sales before discounts, not net revenue.
SELECT
    SUM(s."Quantity" * p."UnitPriceKsh") AS list_price_sales_ksh,
    SUM(s."Quantity") AS units_sold,
    COUNT(DISTINCT s."TransactionID") AS transactions
FROM sales s
JOIN products p ON s."ProductID" = p."ProductID";
