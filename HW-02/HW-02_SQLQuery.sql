--1. Все товары, в которых в название есть пометка urgent или название начинается с Animal
SELECT StockItemName FROM [Warehouse].[StockItems]
WHERE StockItemName LIKE '%urgent%' OR StockItemName LIKE 'Animal%'
ORDER BY StockItemName
GO

--2. Поставщиков, у которых не было сделано ни одного заказа (потом покажем как это делать через подзапрос, сейчас сделайте через JOIN)
SELECT [Purchasing].[Suppliers].[SupplierName], COUNT([Purchasing].[PurchaseOrders].[PurchaseOrderID]) AS OrdersNumber FROM [Purchasing].[Suppliers]
	LEFT JOIN [Purchasing].[PurchaseOrders]
		ON [Purchasing].[Suppliers].[SupplierID] = [Purchasing].[PurchaseOrders].[SupplierID]
GROUP BY [Purchasing].[Suppliers].[SupplierName]
HAVING  COUNT([Purchasing].[PurchaseOrders].[PurchaseOrderID])=0
GO

--3. Продажи с названием месяца, в котором была продажа, номером квартала, к которому относится продажа, включите также к какой трети года относится дата - каждая треть по 4 месяца, дата забора заказа должна быть задана, с ценой товара более 100$ либо количество единиц товара более 20. Добавьте вариант этого запроса с постраничной выборкой пропустив первую 1000 и отобразив следующие 100 записей. Соритровка должна быть по номеру квартала, трети года, дате продажи.
SELECT [Sales].[Orders].[OrderID],
	CASE 
		WHEN MONTH([Sales].[Orders].[OrderDate])=1 THEN 'January'
		WHEN MONTH([Sales].[Orders].[OrderDate])=2 THEN 'February'
		WHEN MONTH([Sales].[Orders].[OrderDate])=3 THEN 'March'
		WHEN MONTH([Sales].[Orders].[OrderDate])=4 THEN 'April'
		WHEN MONTH([Sales].[Orders].[OrderDate])=5 THEN 'May'
		WHEN MONTH([Sales].[Orders].[OrderDate])=6 THEN 'June'
		WHEN MONTH([Sales].[Orders].[OrderDate])=7 THEN 'July'
		WHEN MONTH([Sales].[Orders].[OrderDate])=8 THEN 'August'
		WHEN MONTH([Sales].[Orders].[OrderDate])=9 THEN 'September'
		WHEN MONTH([Sales].[Orders].[OrderDate])=10 THEN 'October'
		WHEN MONTH([Sales].[Orders].[OrderDate])=11 THEN 'November'
		WHEN MONTH([Sales].[Orders].[OrderDate])=12 THEN 'December'
		ELSE 'N/A'
	END AS [Month],
	CASE 
		WHEN MONTH([Sales].[Orders].[OrderDate]) IN(1,2,3) THEN 'Q1'
		WHEN MONTH([Sales].[Orders].[OrderDate]) IN(4,5,6) THEN 'Q2'
		WHEN MONTH([Sales].[Orders].[OrderDate]) IN(7,8,9) THEN 'Q3'
		WHEN MONTH([Sales].[Orders].[OrderDate]) IN(10,11,12) THEN 'Q4'
		ELSE 'N/A'
	END AS [Quarter],
	CASE 
		WHEN MONTH([Sales].[Orders].[OrderDate]) IN(1,2,3,4) THEN '1'
		WHEN MONTH([Sales].[Orders].[OrderDate]) IN(5,6,7,8) THEN '2'
		WHEN MONTH([Sales].[Orders].[OrderDate]) IN(9,10,11,12) THEN '3'
		ELSE 'N/A'
	END AS [Third],
[Sales].[Orders].[PickingCompletedWhen] AS [Picking Date]
FROM [Sales].[Orders]
LEFT JOIN [Sales].[OrderLines]
ON [Sales].[Orders].[OrderID] = [Sales].[OrderLines].[OrderID]
WHERE [UnitPrice] > 100 OR [PickedQuantity] > 20
ORDER BY [Quarter],[Third],[Picking Date]
GO
-- Пропускаем первую 1000 и выводим 100
WITH OrdersCTE (OrderID, [Month], [Quarter], [Third], PickingDate) AS (
SELECT TOP(1100) [Sales].[Orders].[OrderID],
	CASE 
		WHEN MONTH([Sales].[Orders].[OrderDate])=1 THEN 'January'
		WHEN MONTH([Sales].[Orders].[OrderDate])=2 THEN 'February'
		WHEN MONTH([Sales].[Orders].[OrderDate])=3 THEN 'March'
		WHEN MONTH([Sales].[Orders].[OrderDate])=4 THEN 'April'
		WHEN MONTH([Sales].[Orders].[OrderDate])=5 THEN 'May'
		WHEN MONTH([Sales].[Orders].[OrderDate])=6 THEN 'June'
		WHEN MONTH([Sales].[Orders].[OrderDate])=7 THEN 'July'
		WHEN MONTH([Sales].[Orders].[OrderDate])=8 THEN 'August'
		WHEN MONTH([Sales].[Orders].[OrderDate])=9 THEN 'September'
		WHEN MONTH([Sales].[Orders].[OrderDate])=10 THEN 'October'
		WHEN MONTH([Sales].[Orders].[OrderDate])=11 THEN 'November'
		WHEN MONTH([Sales].[Orders].[OrderDate])=12 THEN 'December'
		ELSE 'N/A'
	END AS [Month],
	CASE 
		WHEN MONTH([Sales].[Orders].[OrderDate]) IN(1,2,3) THEN 'Q1'
		WHEN MONTH([Sales].[Orders].[OrderDate]) IN(4,5,6) THEN 'Q2'
		WHEN MONTH([Sales].[Orders].[OrderDate]) IN(7,8,9) THEN 'Q3'
		WHEN MONTH([Sales].[Orders].[OrderDate]) IN(10,11,12) THEN 'Q4'
		ELSE 'N/A'
	END AS [Quarter],
	CASE 
		WHEN MONTH([Sales].[Orders].[OrderDate]) IN(1,2,3,4) THEN '1'
		WHEN MONTH([Sales].[Orders].[OrderDate]) IN(5,6,7,8) THEN '2'
		WHEN MONTH([Sales].[Orders].[OrderDate]) IN(9,10,11,12) THEN '3'
		ELSE 'N/A'
	END AS [Third],
[Sales].[Orders].[PickingCompletedWhen] AS [Picking Date]
FROM [Sales].[Orders]
LEFT JOIN [Sales].[OrderLines]
ON [Sales].[Orders].[OrderID] = [Sales].[OrderLines].[OrderID]
WHERE [UnitPrice] > 100 OR [PickedQuantity] > 20
ORDER BY [Quarter],[Third],[Picking Date] ASC)
SELECT TOP(100) * FROM OrdersCTE
ORDER BY OrdersCTE.[Quarter], OrdersCTE.[Third], OrdersCTE.PickingDate DESC
GO

--4. Заказы поставщикам, которые были исполнены за 2014й год с доставкой Road Freight или Post, добавьте название поставщика, имя контактного лица принимавшего заказ
SELECT [Purchasing].[PurchaseOrders].[PurchaseOrderID], [DeliveryMethodName], [SupplierName], [FullName], [FinalizationDate] FROM [Purchasing].[PurchaseOrders]
	LEFT JOIN [Purchasing].[Suppliers]
		ON [Purchasing].[PurchaseOrders].[SupplierID] = [Purchasing].[Suppliers].[SupplierID]
	LEFT JOIN [Application].[DeliveryMethods]
		ON [Purchasing].[PurchaseOrders].[DeliveryMethodID] = [Application].[DeliveryMethods].[DeliveryMethodID]
	LEFT JOIN [Application].[People]
		ON [Purchasing].[PurchaseOrders].[ContactPersonID]= [Application].[People].[PersonID]
	LEFT JOIN [Purchasing].[SupplierTransactions]
		ON [Purchasing].[PurchaseOrders].[PurchaseOrderID] = [Purchasing].[SupplierTransactions].[PurchaseOrderID]
WHERE YEAR([FinalizationDate]) = 2014 AND ([DeliveryMethodName]='Road Freight' OR [DeliveryMethodName]='Post')
GO

--5. 10 последних по дате продаж с именем клиента и именем сотрудника, который оформил заказ.
SELECT TOP (10) [Sales].[Orders].[OrderID], [Sales].[Orders].[OrderDate], [Sales].[Customers].[CustomerName], [Application].[People].[FullName] AS [SalesPersonName]
FROM [Sales].[Orders]
	LEFT JOIN [Sales].[Customers]
		ON [Sales].[Orders].[CustomerID] = [Sales].[Customers].[CustomerID]
	LEFT JOIN [Application].[People]
		ON [Sales].[Orders].[SalespersonPersonID] = [Application].[People].[PersonID]
ORDER BY [Sales].[Orders].[OrderDate] DESC
GO

--6. Все ид и имена клиентов и их контактные телефоны, которые покупали товар Chocolate frogs 250g
SELECT [Sales].[Customers].[CustomerID] AS [ID], [Sales].[Customers].[CustomerName] AS [Name], [Sales].[Customers].[PhoneNumber] AS [PhoneNumber], COUNT([Sales].[Orders].[OrderID]) AS [OrdersNumber]
FROM [Sales].[Customers]
	LEFT JOIN [Sales].[Orders]
		ON [Sales].[Customers].[CustomerID] = [Sales].[Orders].[CustomerID]
	LEFT JOIN [Sales].[OrderLines]
		ON [Sales].[Orders].[OrderID] = [Sales].[OrderLines].[OrderID]
	LEFT JOIN [Warehouse].[StockItems]
		ON [Sales].[OrderLines].[StockItemID] = [Warehouse].[StockItems].[StockItemID]
WHERE [Warehouse].[StockItems].[StockItemName] ='Chocolate frogs 250g'
GROUP BY [Sales].[Customers].[CustomerID], [Sales].[Customers].[CustomerName], [Sales].[Customers].[PhoneNumber]
HAVING COUNT([Sales].[Orders].[OrderID]) > 0
GO