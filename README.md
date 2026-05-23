# ⚖️ Weighbridge Management Analytics

### SQL Server + Power BI | Granite Quarry Operations

![Overview Dashboard](screenshots/dashboard_overview.png)
![Agent Performance Dashboard](screenshots/dashboard_agents.png)

-----

## 📌 Project Overview

This project analyzes **two weeks of real weighbridge transaction data** from a granite quarry operation in Nigeria. It covers truck throughput, product revenue performance, agent account analysis, and operational efficiency through turnaround time tracking.

The data was obtained with permission from the organization and anonymized for portfolio purposes.

**Tools Used:** Microsoft SQL Server (SSMS) · Power BI Desktop · Microsoft Excel

-----

## 🏗️ Business Context

A weighbridge is a large scale used to weigh heavy vehicles. In a quarry setting, every truck is weighed **twice**:

- **Tare weight** — truck weighed empty on arrival
- **Gross weight** — truck weighed again after loading

The difference (Net = Gross − Tare) determines how many tons of product were loaded. This data drives **revenue calculation, product demand tracking, and operational efficiency monitoring.**

**Turnaround time** = time between tare and gross weighing. A longer turnaround means the truck waited longer to be loaded — a key efficiency metric.

-----

## 📊 Dataset

|Attribute         |Detail                                          |
|------------------|------------------------------------------------|
|Period            |May 5 – May 19, 2026 (13 working days)          |
|Total Transactions|1,769                                           |
|Total Net Tons    |35,586.28                                       |
|Total Revenue     |₦355,747,075                                    |
|Active Agents     |56                                              |
|Active Trucks     |509                                             |
|Operators         |3                          |
|Products          |5/8, 3/8, 1/2, Stone Dust, Hard Core, Stone Base|

**Note:** Sundays are excluded (quarry closed). A price change occurred on May 18, 2026 — 5/8 and 3/8 increased from ₦12,000/ton to ₦13,000/ton.

-----

## 🧹 Data Cleaning

Raw data was cleaned in Excel before being imported into SQL Server:

|Issue                                           |Action Taken                                                    |
|------------------------------------------------|----------------------------------------------------------------|
|Operator name typo (KEBNNY)                     |Corrected to KENNY                                              |
|2 rows with incorrect GrossTime month (December)|Fixed using date extracted from TransactionID                   |
|110 rows with negative turnaround times         |Corrected to absolute value (tare/gross entry order was swapped)|
|Agent name typo (OLANREWAJ)                     |Corrected to OLANREWAJU                                         |
|Product codes renamed                           |e.g. 3/4D → 5/8, DUST → Stone Dust                              |

**Output:** Clean master dataset with 1,769 rows and 15 columns including calculated Revenue and TurnaroundMinutes fields.

-----

## 🗄️ Database Schema

The database `Weighbridge_db` follows a **star schema** design with 1 fact table and 5 dimension tables.

```
fact_transaction
    ├── dim_products       (via Product name)
    ├── dim_agents         (via Agent name)
    ├── dim_operators      (via Operator name)
    ├── dim_trucks         (via Truck number)
    └── dim_price_history  (via dim_products → ProductID)
```

### Tables

|Table              |Rows |Description                       |
|-------------------|-----|----------------------------------|
|`fact_transaction` |1,769|Core transaction records          |
|`dim_products`     |6    |Product names and current prices  |
|`dim_agents`       |56   |Agent accounts                    |
|`dim_operators`    |3    |Weighbridge operators             |
|`dim_trucks`       |509  |Registered truck numbers          |
|`dim_price_history`|8    |Price changes over time by product|

-----

## 🔍 SQL Analysis Queries

Seven business analysis queries were written and executed in SQL Server:

### 1. Total Revenue for the Period

```sql
SELECT 
    SUM(Revenue) AS TotalRevenue,
    SUM(NetTons) AS TotalNetTons,
    COUNT(*) AS TotalTransactions
FROM fact_transaction;
```

**Result:** ₦355,747,075 · 35,586.28 tons · 1,769 transactions

-----

### 2. Revenue by Product

```sql
SELECT 
    Product,
    COUNT(*) AS TotalTransactions,
    ROUND(SUM(NetTons), 2) AS TotalNetTons,
    SUM(Revenue) AS TotalRevenue
FROM fact_transaction
GROUP BY Product
ORDER BY TotalRevenue DESC;
```

**Key Insight:** 5/8 is the revenue king at 42.8% of total revenue (₦152M) despite having the longest average turnaround time.

-----

### 3. Top 10 Agents by Revenue

```sql
SELECT TOP 10
    Agent,
    COUNT(*) AS TotalTrips,
    ROUND(SUM(NetTons), 2) AS TotalNetTons,
    SUM(Revenue) AS TotalRevenue
FROM fact_transaction
GROUP BY Agent
ORDER BY TotalRevenue DESC;
```

**Key Insight:** MUBAS and OLASUNKANMI together account for ₦91M — 25.6% of total revenue. Interestingly, OLASUNKANMI has more trips (198 vs 156) but MUBAS earns more revenue, meaning MUBAS consistently moves heavier loads.

-----

### 4. Daily Volume and Revenue

```sql
SELECT 
    Date,
    COUNT(*) AS DailyTransactions,
    ROUND(SUM(NetTons), 2) AS DailyNetTons,
    SUM(Revenue) AS DailyRevenue
FROM fact_transaction
GROUP BY Date
ORDER BY Date;
```

**Key Insight:** May 11 was the busiest day (203 trucks, ₦39.2M). May 8 was the slowest (74 trucks, ₦15.9M). Revenue jumped from May 18 onward due to the price increase on 5/8 and 3/8.

-----

### 5. Impact of Price Change (5/8 and 3/8)

```sql
SELECT 
    Product,
    CASE WHEN Date < '2026-05-18' THEN 'Before' ELSE 'After' END AS PricePeriod,
    COUNT(*) AS Transactions,
    SUM(Revenue) AS TotalRevenue,
    ROUND(SUM(Revenue) / COUNT(DISTINCT Date), 2) AS AvgDailyRevenue
FROM fact_transaction
WHERE Product IN ('5/8', '3/8')
GROUP BY Product,
    CASE WHEN Date < '2026-05-18' THEN 'Before' ELSE 'After' END
ORDER BY Product, PricePeriod DESC;
```

**Key Insight:** Despite the price increase, daily average revenue increased for both products — demand did not drop. Note: only 2 days of post-change data are available so extended observation is needed.

-----

### 6. Top 10 Most Active Trucks

```sql
SELECT TOP 10
    TruckNumber,
    COUNT(*) AS TotalTrips,
    ROUND(SUM(NetTons), 2) AS TotalNetTons,
    ROUND(AVG(NetTons), 2) AS AvgTonsPerTrip
FROM fact_transaction
GROUP BY TruckNumber
ORDER BY TotalTrips DESC;
```

**Key Insight:** YRE259XT is the dominant truck with 40 trips and 906.67 tons — nearly 3 trips per day across the period.

-----

### 7. Average Turnaround by Product and by Day

```sql
-- By Product
SELECT 
    Product,
    ROUND(AVG(TurnaroundMinutes), 1) AS AvgTurnaroundMins,
    MAX(TurnaroundMinutes) AS MaxTurnaround,
    MIN(TurnaroundMinutes) AS MinTurnaround
FROM fact_transaction
GROUP BY Product
ORDER BY AvgTurnaroundMins DESC;

-- By Day
SELECT 
    Date,
    COUNT(*) AS DailyTransactions,
    ROUND(AVG(TurnaroundMinutes), 1) AS AvgTurnaroundMins
FROM fact_transaction
GROUP BY Date
ORDER BY Date;
```

**Key Insight:** 1/2 has the fastest turnaround (24.9 mins) because it is pre-processed and immediately available. 5/8 and Stone Dust are slowest (84.7 and 63 mins) because they require on-demand crushing. May 13 had an anomalous 116-minute average despite normal truck volume — indicating an operational disruption.

-----

## 📈 Power BI Dashboard

The dashboard is built across **2 pages:**

### Page 1 — Overview

- 4 KPI Cards: Total Transactions · Total Revenue · Total Net Tons · Avg Turnaround
- Daily Revenue and Volume trend (combo chart)
- Revenue by Products (horizontal bar chart)
- Net Tons by Products (donut chart)
- Avg Turnaround Minutes by Day (line chart)

### Page 2 — Agent Performance Analysis

- Top 10 Agents by Revenue (horizontal bar)
- Top 10 Agents by Trips (column chart)
- Agents Revenue vs Trips (bubble scatter chart)
- Revenue by Agent as % of Total (treemap)
- Bottom KPI strip: Top Agent · Highest Trips · Avg Revenue per Trip · Best Turnaround · Active Agents · Total Revenue

-----

## 💡 Key Business Insights

1. **₦355.7M revenue generated** in just 13 working days from 1,769 transactions
1. **5/8 is the revenue king** — 42.8% of total revenue despite the longest turnaround time. High demand overrides the inefficiency
1. **MUBAS and OLASUNKANMI dominate** — top 2 agents account for ₦91M (25.6% of total)
1. **Price increase did not reduce demand** — daily average revenue increased after May 18 price change on 5/8 and 3/8
1. **Hard Core and Stone Base are underperforming** — only 54 combined transactions in 2 weeks despite fast turnaround times. These products may need a pricing review or sales push
1. **May 13 operational anomaly** — 116-minute average turnaround despite normal volume strongly indicates something disrupted operations that day
1. **YRE259XT is the workhorse** — 40 trips, 906 tons, nearly 3 trips per day

-----

## 📁 Repository Structure

```
Weighbridge-Management-Analytics/
│
├── data/
│   ├── Weighbridge_Master_Dataset.xlsx    # Cleaned master dataset
│   └── Weighbridge_Master_Dataset.csv     # CSV version for SQL import
│
├── sql/
│   ├── 01_create_tables.sql               # Schema and table creation
│   └── 02_analysis_queries.sql            # All 7 business analysis queries
│
├── dashboard/
│   └── Weighbridge_Dashboard.pbix         # Power BI dashboard file
│
├── screenshots/
│   ├── dashboard_overview.png             # Overview page screenshot
│   └── dashboard_agents.png              # Agent Performance page screenshot
│
└── README.md
```

-----

## 👩‍💻 About

Built by **Pearla** · Data Analyst  
[LinkedIn](https://www.linkedin.com/in/adefunke-oshinuga-894a09134) · [GitHub](https://github.com/Pearla141)

*This project uses real operational data obtained with organizational permission, anonymized for portfolio use.*
