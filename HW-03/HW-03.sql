USE [WideWorldImporters]
--1. Выберите сотрудников, которые являются продажниками, и еще не сделали ни одной продажи.
--1.1 Subquery
SELECT p.FullName, p.PersonID, i.SalesCount
FROM [Application].[People] AS p
	JOIN 
	(SELECT s.SalespersonPersonID, COUNT(s.InvoiceID) AS SalesCount
	FROM [Sales].[Invoices] AS s 
	GROUP BY s.SalespersonPersonID
	HAVING COUNT(s.InvoiceID) = 0) AS i 
	ON p.PersonID = i.SalespersonPersonID
WHERE p.IsSalesperson = 1;
--1.2 CTE
WITH SalesSumCTE AS 
(
	SELECT s.SalespersonPersonID, COUNT(s.InvoiceID) AS SalesCount
	FROM [Sales].[Invoices] AS s 
	GROUP BY s.SalespersonPersonID
	HAVING COUNT(s.InvoiceID) = 0
)
SELECT p.FullName, p.PersonID, i.SalesCount
FROM [Application].[People] AS p
JOIN SalesSumCTE AS i
ON p.PersonID = i.SalespersonPersonID
WHERE p.IsSalesperson = 1;
--2. Выберите товары с минимальной ценой (подзапросом), 2 варианта подзапроса.
--2.1 
SELECT s.StockItemID, s.StockItemName, s.UnitPrice
FROM [Warehouse].[StockItems] AS s
WHERE s.UnitPrice <= ALL (SELECT s.UnitPrice FROM [Warehouse].[StockItems] AS s);
--2.2
SELECT s.StockItemID, s.StockItemName, s.UnitPrice
FROM [Warehouse].[StockItems] AS s
WHERE s.UnitPrice = (SELECT MIN(s.UnitPrice) FROM [Warehouse].[StockItems] AS s);
--3. Выберите информацию по клиентам, которые перевели компании 5 максимальных платежей из [Sales].[CustomerTransactions] представьте 3 способа (в том числе с CTE)
--3.1 Subquery in FROM
SELECT c.CustomerID, c.CustomerName, c.PhoneNumber, t.TransactionAmount
FROM [Sales].[Customers] AS c
	JOIN
	(SELECT TOP(5) CustomerID, TransactionAmount 
	FROM [Sales].[CustomerTransactions]
	ORDER BY TransactionAmount DESC) AS t
	ON c.CustomerID = t.CustomerID
ORDER BY t.TransactionAmount DESC;
--3.2 Subquery in SELECT
SELECT TOP(5) 
	t.CustomerID,  
	(SELECT c.CustomerName FROM [Sales].[Customers] AS c WHERE c.CustomerID = t.CustomerID) AS CustomerName,
	(SELECT c.PhoneNumber FROM [Sales].[Customers] AS c WHERE c.CustomerID = t.CustomerID) AS PhoneNumber,
	t.TransactionAmount
FROM [Sales].[CustomerTransactions] AS t
ORDER BY t.TransactionAmount DESC;
--3.3 using CTE
WITH TopTransactionsCTE AS
(
	SELECT TOP(5) CustomerID, TransactionAmount 
	FROM [Sales].[CustomerTransactions]
	ORDER BY TransactionAmount DESC
)
SELECT c.CustomerID, c.CustomerName, c.PhoneNumber, t.TransactionAmount
FROM [Sales].[Customers] AS c
	JOIN TopTransactionsCTE AS t
	ON c.CustomerID = t.CustomerID
ORDER BY t.TransactionAmount DESC;
--3.4 using JOIN
SELECT TOP(5) c.CustomerID, c.CustomerName, c.PhoneNumber, t.TransactionAmount
FROM [Sales].[Customers] AS c
	JOIN [Sales].[CustomerTransactions] AS t
	ON c.CustomerID = t.CustomerID
ORDER BY t.TransactionAmount DESC;
--4. Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров, а также Имя сотрудника, который осуществлял упаковку заказов
--4.1 Первоначальная идея - прописать кучу джоинов
SELECT DISTINCT t.CityID, t.CityName, p.FullName AS PackedBy
FROM [Sales].[Invoices] AS i
	JOIN [Sales].[InvoiceLines] AS l 
		ON i.InvoiceID = l.InvoiceID
	JOIN (SELECT TOP(3) [StockItemID], [UnitPrice] FROM [Warehouse].[StockItems] ORDER BY [UnitPrice] DESC) AS s
		ON l.StockItemID = s.StockItemID
	JOIN [Sales].[Customers] AS c
		ON c.CustomerID = i.CustomerID
	JOIN [Application].[Cities] AS t
		ON c.DeliveryCityID = t.CityID
	JOIN [Application].[People] AS p
		ON i.PackedByPersonID = p.PersonID
ORDER BY t.CityName
--4.2. Попытка решить через вложенные запросы, чтобы не джоинить таблицы целиком
SELECT DISTINCT t.CityID, t.CityName, p.FullName AS PackedBy
FROM 
	(SELECT InvoiceID, CustomerID, PackedByPersonID FROM [Sales].[Invoices]) AS i
		JOIN (SELECT [InvoiceID], [StockItemID] FROM [Sales].[InvoiceLines]) AS l 
			ON i.InvoiceID = l.InvoiceID
		JOIN (SELECT TOP(3) [StockItemID], [UnitPrice] FROM [Warehouse].[StockItems] ORDER BY [UnitPrice] DESC) AS s
			ON l.StockItemID = s.StockItemID
		JOIN (SELECT CustomerID, DeliveryCityID FROM [Sales].[Customers]) AS c
			ON c.CustomerID = i.CustomerID
		JOIN (SELECT CityID, CityName FROM [Application].[Cities]) AS t
			ON c.DeliveryCityID = t.CityID
		JOIN (SELECT PersonID, FullName FROM [Application].[People]) AS p
			ON i.PackedByPersonID = p.PersonID
ORDER BY t.CityName;
--План запросов не показывает разницы в скорости выполнения

--5.1 Объясните, что делает и оптимизируйте запрос. Приложите план запроса и его анализ, а также ход ваших рассуждений по поводу оптимизации. Можно двигаться как в сторону улучшения читабельности запроса (что уже было в материале лекций), так и в сторону упрощения плана\ускорения.
--Селект выдаст дату и айди чека, имя продавца, сумму чека и сумму переданных товаров для заказов на сумму боле 27000. По всей видимости, необходимо было сравнить сумму чека с суммой доставленных товаров на предмет расхождений
--Вариант оптимизации запроса. Постарался повысить читаемость, плюс улучшился QueryCost - 39%vs61%, правда я не понял, благодаря чему :-(
WITH TotalSumForPickingOrdersCTE AS 
(SELECT OrderID,
		SUM(OL.PickedQuantity*OL.UnitPrice) AS TotalSumForPickingOrders
		FROM Sales.OrderLines AS OL
		WHERE (SELECT O.PickingCompletedWhen FROM Sales.Orders AS O WHERE O.OrderID = OL.OrderID) is not null
		GROUP BY OrderID
),
SalesTotalsCTE AS
(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSummByInvoice
			FROM Sales.InvoiceLines
			GROUP BY InvoiceId
			HAVING SUM(Quantity*UnitPrice) > 27000
)
SELECT
	i.InvoiceID,
	i.InvoiceDate,
	(SELECT p.FullName	
		FROM Application.People AS p
		WHERE p.PersonID = i.SalespersonPersonID
	) AS SalesPersonName,
	t.TotalSummByInvoice,
	s.TotalSumForPickingOrders
FROM Sales.Invoices AS i
	JOIN SalesTotalsCTE AS t
	ON i.InvoiceID = t.InvoiceID
	JOIN TotalSumForPickingOrdersCTE AS s
	ON s.OrderID = i.InvoiceID
ORDER BY TotalSummByInvoice DESC;

--Первоначальный запрос
SELECT
Invoices.InvoiceID,
Invoices.InvoiceDate,
(SELECT People.FullName
FROM Application.People
WHERE People.PersonID = Invoices.SalespersonPersonID
) AS SalesPersonName,
SalesTotals.TotalSumm AS TotalSummByInvoice,
(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
FROM Sales.OrderLines
WHERE OrderLines.OrderId = (SELECT Orders.OrderId
FROM Sales.Orders
WHERE Orders.PickingCompletedWhen IS NOT NULL
AND Orders.OrderId = Invoices.OrderId)
) AS TotalSummForPickedItems
FROM Sales.Invoices
JOIN
(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
FROM Sales.InvoiceLines
GROUP BY InvoiceId
HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

