CREATE TABLE  dim_products (
ProductId INT PRIMARY KEY,
Product VARCHAR (50),
CurrentPricePerTon INT 
);

INSERT INTO dim_products (ProductId,Product,CurrentPricePerTon)
VALUES
(1,'5/8',13000),
(2,'3/8',13000),
(3,'1/2',9000),
(4,'Stone dust',7500),
(5,'Hard core',9000),
(6,'Stone base',9000);

CREATE TABLE dim_operators (
OperatorId INT PRIMARY KEY,
Operator VARCHAR(50) NOT NULL);

INSERT INTO dim_operators (OperatorId,Operator)
VALUES
(1,'FUNKE'),
(2,'HANNA'),
(3,'KENNY');

CREATE TABLE dim_agents (
AgentID INT PRIMARY KEY,
AgentName VARCHAR(100) NOT NULL);

INSERT INTO dim_agents (AgentID,AgentName)
SELECT
ROW_NUMBER() OVER (ORDER BY Agent) AS AgentID,
Agent AS AgentName
FROM (
SELECT DISTINCT Agent
FROM fact_transaction
) AS unique_agents;

CREATE TABLE dim_trucks (
TruckID INT PRIMARY KEY,
TruckNumber VARCHAR (20) NOT NULL);

INSERT INTO dim_trucks (TruckID,TruckNumber)
SELECT
ROW_NUMBER () OVER (ORDER BY TruckNumber) AS TruckID,
TruckNumber
FROM (
SELECT
DISTINCT TruckNumber
FROM
fact_transaction) AS unique_trucks;

CREATE TABLE dim_price_history (
PriceHistoryID INT PRIMARY KEY,
ProductID INT NOT NULL,
PricePerTon INT NOT NULL,
EffectiveFrom DATE NOT NULL,
EffectiveTo DATE);

INSERT INTO dim_price_history (PriceHistoryID,ProductID,PricePerTon,EffectiveFrom,EffectiveTo)
vALUES
(1,1,12000,'2026-05-05','2026-05-17'),
(2,1,13000,'2026-05-05', NULL),
(3,2,12000,'2026-05-05','2026-05-17'),
(4,2,13000,'2026-05-05', NULL),
(5,3,9000,'2026-05-05', NULL),
(6,4,7500,'2026-05-05', NULL),
(7,5,9000,'2026-05-05', NULL),
(8,6,9000,'2026-05-05', NULL);
