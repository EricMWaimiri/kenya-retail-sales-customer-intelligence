# Power BI Dashboard: Findings and Documentation

Project: Kenya Retail Sales & Customer Intelligence: Inflation-Aware Demand Forecasting
Data period: Wednesday 01 October 2025 to Wednesday 30 September 2026
Note: transaction data is synthetic, so profit figures are estimates.

## 1. KPIs and Measures

| Measure | Definition |
|---|---|
| Total Units | Sum of Quantity |
| Line Items | Count of sales rows |
| Transactions | Distinct TransactionID |
| Active Customers | Distinct CustomerID |
| Gross Sales | Quantity x UnitPriceKsh |
| Net Sales | Gross Sales after DiscountPct |
| Total Cost | Quantity x UnitCostKsh |
| Estimated Gross Profit | Net Sales minus Total Cost |
| Gross Profit Margin % | Estimated Gross Profit / Net Sales |
| Avg Basket Value | Net Sales / Transactions |
| Units Share % | Total Units / Total Units across all products |
| Net Sales per Customer | Net Sales / Active Customers |
| Transactions per Customer | Transactions / Active Customers |
| Repeat Customers | Customers with 2 or more distinct transactions |
| Repeat Customer Rate % | Repeat Customers / Active Customers |
| Active Last 90 Days | Distinct customers from 03 Jul 2026 to 30 Sep 2026 |
| Forecast Units Total | Sum of the three forecast months |
| Model Test WAPE % | Sum of absolute errors / sum of actual units (Random Forest, Jul to Sep 2026) |
| Avg Forecast per Month | Average of the three forecast months |

## 2. Validation against Python

| Measure | Python result | Power BI result |
|---|---|---|
| Total Units | 36,151 | 36,151 |
| Line Items | 15,000 | 15,000 |
| Transactions | 5,617 | 5,617 |
| Active Customers | 994 | 994 |
| Gross Sales | KSh 17,419,090 | KSh 17,419,090 |
| Net Sales | KSh 17,062,049 | KSh 17,062,049 |
| Total Cost | KSh 13,109,828 | KSh 13,109,828 |
| Estimated Gross Profit | KSh 3,952,221 | KSh 3,952,221 |
| Gross Profit Margin % | 23.16% | 23.16% |
| Forecast Units Total | 8,989 | 8,989 |
| Model Test WAPE % | 2.58% | 2.58% |

## 3. Page 1: Executive Overview

### Findings
- Net sales were KSh 17.06M on 36,151 units, with an estimated gross margin of 23.16%.
- Monthly net sales ranged from KSh 1.19M (Jan 2026) to KSh 1.62M (Sep 2026).
- Monthly demand stayed close to 3,000 units: lowest Feb 2026 (2,726), highest Mar 2026 (3,140).
- 2,500 of 15,000 line items were discounted, about 14% of net sales (KSh 2.43M).
- Forecast for Oct to Dec 2026: 2,979, 3,022 and 2,988 units (flat demand). Test error (WAPE) was 2.58% over 3 months.

### Recommended actions
- Plan stock for about 3,000 units a month.
- Review discount depth, since discounts cut margin on a significant share of sales.
- Treat the forecast with caution: it is based on only 12 months of data.

## 4. Page 2: Product and Store Performance

### Findings
- Household earned KSh 9,213,015 (54% of net sales) from only 9,129 units, because its items have high unit prices. Its estimated margin was the highest at 25.3%.
- Food led on units (14,227) but earned only KSh 3,103,482 (19.4% margin, the lowest).
- Beverages: KSh 3,071,081 (21.1%). Personal Care: KSh 1,674,471 (22.3%).
- The top 10 products made up about 58% of net sales. The top product was Microwave Oven 20L at KSh 3,534,111 (313 units).
- The lowest product was Avocado 1 piece at KSh 8,439.
- Store net sales ranged from KSh 920,663 (Coast Retail 03) to KSh 1,427,901 (Metro Retail 01).

### Recommended actions
- Protect availability of the top household appliances, since a few products drive over half of sales.
- Review the very low-value items (for example Avocado, Bottled Water 500ml, Salt) for shelf space or bundling.
- Look at why Coast Retail 03 and Metro Retail 02 trail the other stores before changing stock levels.

## 5. Page 3: Customer Intelligence

### Findings
- 994 of 1,000 customers purchased. 973 of them (97.9%) bought on 2 or more transactions.
- Average of 5.7 transactions and KSh 17,165 net sales per customer.
- 736 customers were active in the last 90 days (3 Jul to 30 Sep 2026).
- The four segments behave very similarly: net sales per customer ranged from KSh 16,502 (Occasional) to KSh 17,687 (Regular), and transactions per customer were about 5.6 to 5.7 in every segment.
- By age group, net sales per customer ranged from KSh 16,173 (44-54) to KSh 18,268 (25-34).
- Active customers per month ranged from 334 (Feb 2026) to 391 (Oct 2025).

### Recommended actions
- Do not target by segment label alone: the labels do not separate purchasing behaviour in this dataset.
- Revisit how segments are defined (for example from recency and frequency) before using them in campaigns.

## 6. Page 4: Demand Forecast and Inflation

### Findings
- Forecast for Oct to Dec 2026 (Random Forest): 2,979, 3,022 and 2,988 units, 8,989 in total, which is flat demand.
- On the Jul to Sep 2026 test months the model's WAPE was 2.58%, against 3.95% for the naive baseline and 4.87% for linear regression.
- CPI rose 6.56% over the 12 months (146.84 to 156.47), while monthly units stayed near 3,000.
- The correlation between CPI and units was 0.13, which is weak. No causal link is claimed.

### Recommended actions
- Use the forecast as a baseline of about 3,000 units a month, with a safety buffer of roughly 3 to 5%.
- Re-run the model monthly as new data arrives, and compare actual units with the forecast.

## 7. Limitations
- Transaction data is synthetic, so profit is estimated.
- Only 12 months of history; the model was trained on 6 months and tested on 3.
- The forecast is flat and does not capture seasonality or promotions.
- CPI is shown alongside demand only; no causation is claimed.
- 1,911 line items are dated before the customer's SignupDate, a data-quality issue in the synthetic data.
- The age group label "44-54" comes from the source data and is probably meant to be "45-54".
- 6 customers have no purchases in the period.