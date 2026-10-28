# Kenya Retail Sales & Customer Intelligence: Inflation-Aware Demand Forecasting

Individual Data Science & Analytics Capstone. It analyses 15,000 synthetic retail sales lines (1,000 customers, 100 products, 15 stores in 5 counties) from Wednesday 01 October 2025 to Wednesday 30 September 2026. The data is joined with official KNBS monthly CPI. The project ends in a three-month demand forecast and a four-page Power BI dashboard.

**Data note:** retail transactions are synthetic. Only the CPI series (data/raw/knbs) is official data. Results demonstrate an analytical workflow; they are not evidence of real Kenyan retailer or consumer behaviour.

## Headline results
- Net sales (after discounts): KSh 17,062,049 on 36,151 units, 5,617 transactions and 994 active customers.
- Estimated gross profit: KSh 3,952,221, a gross profit margin of 23.16% (unit cost x quantity as cost).
- Household earns 54% of net sales (KSh 9,213,015) from 9,129 units. Food sells the most units (14,227) but has the lowest margin (19.4%).
- The top 10 products make up about 58% of net sales. Top product: Microwave Oven 20L (KSh 3,534,111).
- Forecast, Oct to Dec 2026 (Random Forest): 2,979, 3,022 and 2,988 units (8,989 in total). Test WAPE: 2.58%.
- CPI rose 6.56% over the 12 months (146.84 to 156.47). The correlation with monthly units is weak (Spearman rho = 0.028, p = 0.9312).

## Research questions
1. How do sales value and unit demand vary over time, across product categories, and across weekdays?
2. Which products show the largest changes in demand?
3. Do demand, estimated sales value, or promotion-day sales show statistically detectable differences or associations?
4. Can a simple model forecast monthly unit demand over a short horizon?
5. What can and cannot be concluded about inflation sensitivity from the available data?

## Repository structure
```text
.
├── data/
│   ├── raw/
│   │   ├── knbs/national_cpi_monthly.csv
│   │   └── synthetic/            sales, customers, products, stores, promotions, public_holidays
│   └── cleaned/                  *_cleaned.csv and *_cleaned.parquet for all seven tables
│       ├── powerbi_monthly_actuals.csv   (Month, ActualUnits)
│       ├── powerbi_model_test.csv        (Month, Actual, Naive, Linear Regression, Random Forest)
│       └── powerbi_forecast.csv          (Month, ForecastUnits, Model, Type)
├── notebooks/
│   ├── 01_data_inspection.ipynb
│   ├── 02_data_cleaning.ipynb
│   ├── 03_eda.ipynb
│   ├── 04_statistical_analysis.ipynb
│   └── 05_demand_forecasting.ipynb
├── sql/
│   ├── schema.sql                PostgreSQL tables, keys, constraints, indexes
│   ├── data_validation.sql       10 data quality checks
│   ├── analysis_queries.sql      18 analysis queries
│   └── reports/                  18 screenshots of query results
├── powerbi/
│   ├── kenya_retail_intelligence.pbix
│   ├── insight.md                measures, validation, findings and actions for all four pages
│   └── reports/                  dashboard page screenshots
├── requirements.txt
└── README.md
```

## Requirements
- Python with the packages in `requirements.txt` (pandas, numpy, matplotlib, seaborn, scipy, scikit-learn, pyarrow, openpyxl, jupyter, ipykernel)
- Git
- PostgreSQL, only if you run the SQL scripts
- Microsoft Power BI Desktop (Windows), only to open the `.pbix`

## Set up Python
Run from the repository root in PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
jupyter lab
```

If PowerShell blocks environment activation:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m jupyter lab
```

## Notebook order
Run these in order. Each notebook reads files created by the one before it, and the parquet files need `pyarrow`.

1. `01_data_inspection.ipynb`: inspects the raw files for shape, types, missing values and duplicates.
2. `02_data_cleaning.ipynb`: standardises column names, converts dates to datetime, drops `PromotionID` from sales, fills missing holiday `ObservedDate` from `Date`, fixes a customer segment spelling inconsistency, and saves the cleaned files.
3. `03_eda.ipynb`: monthly trend, category, store, county, product, customer segment, weekday, payment method, discount, holiday and CPI views, plus gross profit and margin by product.
4. `04_statistical_analysis.ipynb`: Kruskal-Wallis, Mann-Whitney and Spearman tests (see Statistical findings).
5. `05_demand_forecasting.ipynb`: monthly unit demand, lag features, three models, a chronological test, the three-month forecast, and the three `powerbi_*.csv` exports.

## Data cleaning summary
| Table | Rows | Notes |
|---|---|---|
| sales | 15,000 | 5,617 distinct TransactionIDs (one transaction can have several product lines), 994 customers, 15 stores, 100 products |
| customers | 1,000 | 4 segments (New, Occasional, Lapsed, Regular) and 5 age groups |
| products | 100 | 4 categories (Food, Beverages, Household, Personal Care), prices in KSh |
| stores | 15 | 5 counties (Nairobi, Machakos, Mombasa, Nakuru, Kisumu), 3 stores each |
| promotions | 15 | discounts from 8% to 25% |
| public holidays | 25 | |
| national CPI | 141 | monthly, Jan 2015 onwards |

The CPI file has two base periods (36 `pre_rebase` rows and 105 `feb2019_100` rows). All months used in the analysis (Oct 2025 to Sep 2026) are on the `feb2019_100` base, so no rebasing is needed.

## SQL workflow
1. Create a PostgreSQL database.
2. Review and run `sql/schema.sql` (it only creates tables if they do not exist).
3. Load the cleaned CSVs from `data/cleaned/` into the tables.
4. Run `sql/data_validation.sql`: row counts, duplicate keys, missing key fields, invalid quantities and discounts, orphan foreign keys, sales and CPI date coverage, CPI base periods, promotion and holiday dates.
5. Run `sql/analysis_queries.sql`: monthly trend, categories, segments, CPI comparison, store and county performance, top products, RFM segmentation, month-over-month growth, a signup-month activity matrix, promotion periods, basket size, profit rankings, and customer types.

Sales calculated as Quantity x UnitPriceKsh are list-price sales before discounts unless a query says otherwise. Never commit database passwords or connection strings.

## Power BI dashboard
Open `powerbi/kenya_retail_intelligence.pbix`. If asked, point each table at the matching file in `data/cleaned/`, then refresh.

| Page | Contents |
|---|---|
| Executive Overview | KPI cards, monthly net sales, actual units vs the three-month forecast |
| Product & Store Performance | Top and bottom 10 products, category and store sales, units by category over time, filters for date, category, product and store |
| Customer Intelligence | Segment and age-group comparison, transactions and net sales per customer, repeat customer rate, customers active in the last 90 days |
| Demand Forecast & Inflation | Forecast table, model test (actual vs predicted), CPI beside monthly units, forecast limitations |

How it is built:
- Tables: the seven cleaned tables, the three forecast exports, and a date table. Sales links to products, stores, customers and the date table.
- Two calculated tables (`DemandChart`, `CpiDemand`) only combine actuals with forecast, or CPI with units, for charting. Forecast months are never counted as actual sales.
- Measures use net sales (after discount): Net Sales, Estimated Gross Profit, Gross Profit Margin %, Avg Basket Value, Transactions, Active Customers and others. They are listed with definitions in `powerbi/insight.md`.

Validation: Power BI cards were compared with figures calculated in Python from the cleaned CSVs. Total units (36,151), line items (15,000), transactions (5,617), active customers (994), net sales (KSh 17,062,049), estimated gross profit (KSh 3,952,221), margin (23.16%), forecast total (8,989) and WAPE (2.58%) all matched.

## Statistical findings
Estimated sales value in the statistical notebook is quantity x catalogue unit price before discounts. It differs from the net sales shown in Power BI.

- **Product category differences:** Kruskal-Wallis statistic 846.3533, p < 0.001. At least two category distributions differ; post-hoc tests are needed to identify which pairs.
- **Weekday differences:** Tuesday had the highest mean daily sales (KSh 53,671.38) and Thursday the lowest (KSh 40,345.69), but Kruskal-Wallis H = 6.1658, p = 0.4049. This is insufficient evidence of a weekday effect.
- **Monthly estimated sales value vs CPI:** Spearman rho = 0.3287, p = 0.2969 (12 months). No clear evidence of association.
- **Monthly unit demand vs CPI:** rho = 0.028, p = 0.9312 (12 months). No clear evidence of association.
- **Average catalogue price vs CPI:** rho = 0.4895, p = 0.1063 (12 months). Not significant.
- **Promotion vs non-promotion days:** mean daily sales of KSh 45,817.76 on promotion days and KSh 48,855.34 on other days; Mann-Whitney p = 0.0846. This does not show promotions are ineffective: promotion days are identified by date overlap only, because `PromotionID` was dropped from sales.
- **Category demand vs CPI:** Personal Care rho = 0.5884, p = 0.0441; Beverages rho = -0.1331, p = 0.6801; Food rho = 0.0350, p = 0.9141; Household rho = -0.1608, p = 0.6175. With four categories tested on synthetic data, the Personal Care result is nominal and should be treated cautiously.
- **Product trends:** 7 of 100 products had a significant monthly demand trend (p < 0.05): up for Jam 350g (rho = 0.772), Baby Wipes 80 pack, Watermelon 1 piece, Scouring Powder 500g and Coffee Beans 250g; down for Cabbages 1kg (rho = -0.646) and Mop and Bucket Set. Testing 100 products would produce about 5 false positives by chance at p < 0.05, so these trends need multiple-testing correction and more data.

These findings describe the generated dataset and should not be generalised to real Kenyan retail markets.

## Exploratory findings
- Average transaction value is KSh 3,101.14 at list price, with about 6.4 units per transaction.
- M-Pesa accounts for 54.2% of sales lines, Cash 25.5% and Card 20.4%.
- 2,500 of 15,000 sales lines (16.7%) carry a discount; the rest carry none.
- The 12 public holiday days in the period averaged KSh 37,761 in daily sales, against KSh 48,062 on the 353 other days.
- Customer segments are nearly equal in size and sales (net sales KSh 4.1M to KSh 4.5M each), and in net sales per customer (KSh 16,502 to KSh 17,687).

## Forecasting and evaluation
Model features are the previous three months of demand plus the month number. The split is chronological: the model learns from Jan to Jun 2026 and is tested on Jul to Sep 2026. A rolling one-month-ahead prediction is used on the test months, then a recursive three-month forecast.

| Model | MAE | RMSE | WAPE % |
|---|---|---|---|
| Random Forest (max depth 2) | 77.74 | 82.40 | 2.58 |
| Naive (last month) | 119.33 | 123.40 | 3.95 |
| Linear Regression | 146.81 | 172.64 | 4.87 |

Random Forest had the lowest error and produced the forecast of 2,979 (Oct 2026), 3,022 (Nov 2026) and 2,988 (Dec 2026) units. Only 12 monthly observations exist, so after lagging only 9 rows were usable, 6 for training and 3 for testing. The forecast is essentially flat at about 3,000 units a month, so treat it as a baseline, not a reliable operational forecast.

## Recommendations
1. Use the forecast as a baseline of about 3,000 units a month with a 3% to 5% safety buffer, and compare it with actuals as each month closes.
2. Protect availability of the top household appliances: a few products drive over half of net sales.
3. Review very low-value items (for example Avocado 1 piece, Bottled Water 500ml, Salt 1kg) for shelf space or bundling.
4. Look into why Coast Retail 03 (KSh 920,663) and Metro Retail 02 (KSh 952,733) trail Metro Retail 01 (KSh 1,427,901).
5. Redefine customer segments (for example from recency and frequency) before using them in campaigns, because the current labels do not separate purchasing behaviour.
6. Collect actual selling prices after discounts, promotion IDs on sales, and several years of history to support price-response and inflation-aware forecasting.

## Limitations
- Retail transaction data is synthetic, and profit is estimated from catalogue unit costs.
- Only 12 months of history; CPI comparisons use 12 matched monthly points.
- Catalogue prices are constant for each of the 100 products, so within-product price changes and price sensitivity cannot be measured.
- The forecast test set contains only three months, and the forecast does not capture seasonality or promotions.
- Product-level tests need multiple-testing correction.
- Promotions are matched by date overlap, not attributed to individual sales.
- 1,911 sales lines are dated before the customer's SignupDate, and the age group label "44-54" is probably meant to be "45-54". Both come from the source data.
- 6 of 1,000 customers made no purchases in the period.
- CPI is shown beside demand only; no causal link is claimed.

## Evidence and deliverables
- Cleaning: `notebooks/02_data_cleaning.ipynb`
- Exploration: `notebooks/03_eda.ipynb`
- Statistical analysis: `notebooks/04_statistical_analysis.ipynb`
- Demand forecasting: `notebooks/05_demand_forecasting.ipynb`
- SQL: `sql/schema.sql`, `sql/data_validation.sql`, `sql/analysis_queries.sql`, `sql/reports/`
- Power BI: `powerbi/kenya_retail_intelligence.pbix`, `powerbi/insight.md`, `powerbi/reports/`
- Forecast exports: `data/cleaned/powerbi_monthly_actuals.csv`, `data/cleaned/powerbi_model_test.csv`, `data/cleaned/powerbi_forecast.csv`

## Data provenance and licensing
- Retail transactions, customers, products, stores, promotions and public holidays in `data/raw/synthetic/` are synthetic and generated from Mockaroo and are not official KNBS or real world data.
- National CPI in `data/raw/knbs/national_cpi_monthly.csv` comes from KNBS. <https://www.knbs.or.ke/cpi-and-inflation-rates/>

## Author
<ERIC MWANGI>