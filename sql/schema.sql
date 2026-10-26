-- Kenya Retail Sales & Customer Intelligence
-- PostgreSQL database schema
-- This file creates the tables only. It does NOT delete existing tables or data.
-- Run this against an empty project database, or adapt it before changing an existing database.

CREATE TABLE IF NOT EXISTS stores (
    "StoreID" INTEGER PRIMARY KEY,
    "StoreName" VARCHAR(100),
    "Town" VARCHAR(50),
    "County" VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS products (
    "ProductID" INTEGER PRIMARY KEY,
    "ProductName" VARCHAR(150),
    "Category" VARCHAR(50),
    "UnitCostKsh" NUMERIC(12,2),
    "UnitPriceKsh" NUMERIC(12,2),
    CONSTRAINT products_nonnegative_cost CHECK ("UnitCostKsh" >= 0),
    CONSTRAINT products_nonnegative_price CHECK ("UnitPriceKsh" >= 0)
);

CREATE TABLE IF NOT EXISTS customers (
    "Id" INTEGER PRIMARY KEY,
    "SignupDate" DATE,
    "LastName" VARCHAR(100),
    "AgeGroup" VARCHAR(30),
    "CustomerSegment" VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS promotions (
    "PromotionID" INTEGER PRIMARY KEY,
    "PromotionName" VARCHAR(150),
    "StartDate" DATE,
    "EndDate" DATE,
    "DiscountPct" INTEGER,
    CONSTRAINT promotions_valid_dates CHECK ("EndDate" >= "StartDate"),
    CONSTRAINT promotions_discount_range CHECK ("DiscountPct" BETWEEN 0 AND 100)
);

CREATE TABLE IF NOT EXISTS public_holidays (
    "Date" DATE PRIMARY KEY,
    "HolidayName" VARCHAR(100),
    "DayOfWeek" VARCHAR(20),
    "ObservedDate" DATE,
    "HolidayType" VARCHAR(50),
    "Notes" TEXT
);

CREATE TABLE IF NOT EXISTS national_cpi (
    "Date" DATE PRIMARY KEY,
    "Year" INTEGER,
    "Month" INTEGER,
    "Cpi" NUMERIC(10,3),
    "BasePeriod" VARCHAR(30),
    CONSTRAINT national_cpi_valid_month CHECK ("Month" BETWEEN 1 AND 12),
    CONSTRAINT national_cpi_positive_index CHECK ("Cpi" > 0)
);

CREATE TABLE IF NOT EXISTS sales (
    "SaleID" INTEGER PRIMARY KEY,
    "TransactionID" VARCHAR(30),
    "TransactionDate" TIMESTAMP,
    "CustomerID" INTEGER REFERENCES customers("Id"),
    "StoreID" INTEGER REFERENCES stores("StoreID"),
    "ProductID" INTEGER REFERENCES products("ProductID"),
    "Quantity" INTEGER,
    "DiscountPct" NUMERIC(5,2),
    "PaymentMethod" VARCHAR(30),
    CONSTRAINT sales_positive_quantity CHECK ("Quantity" > 0),
    CONSTRAINT sales_discount_range CHECK ("DiscountPct" IS NULL OR "DiscountPct" BETWEEN 0 AND 100)
);

-- Helpful indexes for common joins and date-based analysis.
CREATE INDEX IF NOT EXISTS idx_sales_transaction_date ON sales ("TransactionDate");
CREATE INDEX IF NOT EXISTS idx_sales_transaction_id ON sales ("TransactionID");
CREATE INDEX IF NOT EXISTS idx_sales_customer_id ON sales ("CustomerID");
CREATE INDEX IF NOT EXISTS idx_sales_store_id ON sales ("StoreID");
CREATE INDEX IF NOT EXISTS idx_sales_product_id ON sales ("ProductID");
CREATE INDEX IF NOT EXISTS idx_customers_signup_date ON customers ("SignupDate");
CREATE INDEX IF NOT EXISTS idx_promotions_dates ON promotions ("StartDate", "EndDate");
