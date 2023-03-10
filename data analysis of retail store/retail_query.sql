--Выручка по странам
--Определили среднюю выручку по странам и отобрали TOP 5 стран с наибольшей выручкой
SELECT No, Country, Revenue, ROUND(average_revenue::DECIMAL(38,3), 2) AS Average_Revenue, Revenue-ROUND(average_revenue::DECIMAL(38,3), 2) As Diff
FROM(
SELECT rank() OVER(ORDER BY SUM(Quantity*UnitPrice) DESC) AS No , Country, ROUND(SUM(Quantity*UnitPrice), 2) AS Revenue, AVG(Revenue) OVER w AS average_revenue
FROM default.retail
WHERE Quantity>=0
GROUP BY Country
WINDOW w AS ()
ORDER BY Revenue DESC
) AS country_table
LIMIT 5 

--Средние значения по странам
--Определили среднюю цену за единицу в каждой стране, среднюю цену по всем странамб количество проданных единиц по каждой стране 
--и среднее количество проданных единиц
SELECT Country, AVG(UnitPrice) AS AvPrice_per_unit, AVG(AVG(UnitPrice)) OVER() AS Total_AvPrice, SUM(Quantity) AS Units_sold, AVG(SUM(Quantity)) OVER() AS AvUnits_sold
FROM default.retail
WHERE Quantity>=0  
GROUP BY Country
ORDER BY AvPrice_per_unit DESC

--Средние значения на покупателя в UK
--Определили среднее количество заказов на покупателя и среднюю выручку на покупателя
SELECT AVG(purchases) AS Average_Revenue_per_User, AVG(number_orders) AS Average_orders_per_User
FROM (
SELECT CustomerID, SUM(Quantity*UnitPrice) AS purchases, COUNT(DISTINCT InvoiceNo) AS number_orders
FROM default.retail
WHERE Quantity>=0 AND Country='United Kingdom' 
GROUP BY CustomerID
ORDER BY purchases)

--Частота заказов в UK
--Сгруппировали покупателей по количеству сделанных заказов
--Для каждой группы расчитали выручку, процент выручки группы от общей, количество покупателей в группе и процент количества покупателей
SELECT Amount_of_orders, Revenue, ROUND((Revenue/Total_revenue)*100) AS PercentageRev, Amount_of_customers, ROUND((Amount_of_customers/total_customers)*100) PercentageCustom 
FROM
(
SELECT SUM(purchases) AS Revenue, SUM(Revenue) OVER() AS Total_revenue, COUNT( DISTINCT CustomerID) AS Amount_of_customers, SUM(Amount_of_customers) OVER() AS total_customers,
CASE 
WHEN amount_of_purchases>100 THEN 'more than 100'
WHEN amount_of_purchases>90 THEN '90 - 100'
WHEN amount_of_purchases>70 THEN '70 - 90'
WHEN amount_of_purchases>50 THEN '50 - 70'
WHEN amount_of_purchases>30 THEN '30 - 50'
WHEN amount_of_purchases>10 THEN '10 - 30'
WHEN amount_of_purchases>5 THEN '5 - 10'
ELSE 'less than 5'
END AS Amount_of_orders
FROM(
SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS amount_of_purchases, SUM(Quantity*UnitPrice) AS purchases
FROM default.retail
WHERE Quantity>=0 AND Country='United Kingdom' 
GROUP BY CustomerID
ORDER BY amount_of_purchases DESC)
GROUP BY Amount_of_orders
ORDER BY Revenue DESC
) AS t

--Сумма заказов в UK
--Сгруппировали покупателей по сумме сделанных заказов
--Для каждой группы расчитали выручку, процент выручки группы от общей, количество покупателей в группе и процент количества покупателей
SELECT Types_of_checks, Revenue_by_CheckType, ROUND((Revenue_by_CheckType/Total_revenue)*100, 2) AS PercentageRev, 
    Amount_of_customers, ROUND((Amount_of_customers/Total_amount)*100, 2) AS PercentageCustom
FROM (
SELECT SUM(purchases) AS Revenue_by_CheckType, 
    COUNT( DISTINCT CustomerID) AS Amount_of_customers,
    SUM(Revenue_by_CheckType) OVER() AS Total_revenue, 
    SUM(Amount_of_customers) OVER () AS Total_amount,
CASE 
WHEN purchases>100000 THEN 'more than 100 000'
WHEN purchases>50000 THEN '50 000 - 100 000'
WHEN purchases>10000 THEN '10 000 - 50 000'
WHEN purchases>1864 THEN 'average revenue - 10 000'
ELSE 'less than average'
END AS Types_of_checks
FROM(
SELECT CustomerID, SUM(Quantity*UnitPrice) AS purchases
FROM default.retail
WHERE Quantity>=0 AND Country='United Kingdom' 
GROUP BY CustomerID
ORDER BY purchases DESC)
GROUP BY Types_of_checks
ORDER BY Revenue_by_CheckType DESC
) AS t

--Рейтинг товаров
--Каждому товару присвоили ранг по выручке и количеству проданных единиц
SELECT Description, StockCode,  No_amount, Amount_of_purchases, ROUND((Amount_of_purchases/Total_purchases*100), 2) AS PercentagePurch,
    No_sum, Revenue, ROUND((Revenue/Total_Revenue)*100, 2) AS PercentageRev
FROM(
SELECT Description, StockCode, 
    COUNT(DISTINCT InvoiceNo) AS Amount_of_purchases, rank() OVER(ORDER BY Amount_of_purchases DESC) AS No_amount, 
    SUM(Amount_of_purchases) OVER() AS Total_purchases,
    SUM(Quantity*UnitPrice) AS Revenue, rank() OVER(ORDER BY Revenue DESC) AS No_sum,
    SUM(Revenue) OVER() AS Total_Revenue
FROM default.retail
WHERE Quantity>=0 AND Country='United Kingdom' 
GROUP BY StockCode, Description
) AS t
WHERE No_amount<11 OR No_sum =1