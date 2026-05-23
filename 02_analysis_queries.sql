-- Total revenue for the period (2026-05-05 to 2026-05-19)
SELECT
SUM(Revenue) AS total_revenue,
SUM(NetTons) AS total_net_tons,
COUNT(*) AS total_transactions
FROM
fact_transaction;

--Revenue by Product (to see the biggest and lowest earner)
SELECT
p.Product,
COUNT(*) AS transactions,
SUM(NetTons) AS total_net_tons,
SUM(Revenue) AS total_revenue
FROM 
fact_transaction f
JOIN dim_products p
ON f.Product = p.Product
GROUP BY p.Product
ORDER BY total_revenue DESC;

--Top 10 Agents by Revenue
SELECT TOP 10
a.AgentName,
COUNT(*) AS transactions,
SUM(NetTons) AS total_net_tons,
SUM(f.revenue) AS total_revenue
FROM
fact_transaction f
JOIN dim_agents a
ON f.Agent = a.AgentName
GROUP BY a.AgentName
ORDER BY total_revenue DESC;

--Daily volume and revenue 
SELECT
Date,
Count(*) AS transactions,
ROUND(SUM(NetTons),2) AS total_net_tons,
SUM(Revenue) AS total_revenue
FROM
fact_transaction
GROUP BY Date
ORDER BY Date;

--Impact of price change
SELECT
Product,
CASE WHEN f.Date < '2026-05-18' THEN 'Before Price Change'
	ELSE 'After Price Change'
END AS Period,
COUNT(*) AS Transactions,
SUM(NetTons) AS Total_net_tons,
SUM(Revenue) AS Total_revenue
FROM
fact_transaction f
	WHERE Product IN ('5/8','3/8')
GROUP BY	Product,
			CASE WHEN f.Date < '2026-05-18' THEN 'Before Price Change'
			ELSE 'After Price Change'
			END
ORDER BY Product,
		 Period;
-- Top 10 most active trucks
SELECT TOP 10
t.TruckNumber,
COUNT(*) AS Total_trips,
ROUND(SUM(NetTons),2) AS Total_net_tons,
ROUND(AVG(f.TurnaroundMins),1) AS Avg_turnaround_mins
FROM fact_transaction f
JOIN dim_trucks t
ON f.TruckNumber = t.TruckNumber
GROUP BY t.TruckNumber
ORDER BY Total_trips DESC

--Average turnaround by Product
SELECT
Product,
ROUND(AVG(TurnaroundMins),1) AS Avg_turnaround_mins,
MIN(TurnaroundMins) AS min_turnaround,
MAX(TurnaroundMins) AS max_turnaround,
COUNT(*) AS Transactions
FROM fact_transaction
GROUP BY Product
ORDER BY Avg_turnaround_mins DESC

--Average Turnaround by Day
SELECT
Date,
COUNT(*) AS Transactions,
ROUND(AVG(TurnaroundMins),1) AS Avg_turnaround_mins
FROM fact_transaction
GROUP BY Date
ORDER BY Date;


