USE WideWorldImporters
--1. Все товары, в которых в название есть пометка urgent или название начинается с Animal
SELECT StockItemName FROM Warehouse.StockItems
WHERE StockItemName LIKE '%urgent%' OR StockItemName LIKE 'Animal%'
ORDER BY StockItemName
GO

--2. Поставщиков, у которых не было сделано ни одного заказа (потом покажем как это делать через подзапрос, сейчас сделайте через JOIN)
SELECT S.SupplierName, COUNT(P.PurchaseOrderID) AS OrdersNumber 
FROM Purchasing.Suppliers AS S
	LEFT JOIN Purchasing.PurchaseOrders AS P
		ON s.SupplierID = p.SupplierID
WHERE p.PurchaseOrderID IS NULL
GROUP BY S.SupplierName
GO

--3. Продажи с названием месяца, в котором была продажа, номером квартала, к которому относится продажа, включите также к какой трети года относится дата - каждая треть по 4 месяца, дата забора заказа должна быть задана, с ценой товара более 100$ либо количество единиц товара более 20. Добавьте вариант этого запроса с постраничной выборкой пропустив первую 1000 и отобразив следующие 100 записей. Соритровка должна быть по номеру квартала, трети года, дате продажи.
SELECT o.OrderID, MONTH(o.OrderDate) AS OrderMonth, datepart(qq,o.OrderDate) AS OrderQuarter, 
	CASE
		WHEN MONTH(o.OrderDate) BETWEEN 1 AND 4 THEN 1
		WHEN MONTH(o.OrderDate) BETWEEN 5 AND 8  THEN 2
		ELSE 3
	END AS OrderThird,
o.PickingCompletedWhen AS PickingDate
FROM Sales.Orders AS o
LEFT JOIN Sales.OrderLines AS l
ON o.OrderID = l.OrderID
WHERE UnitPrice > 100 OR PickedQuantity > 20
ORDER BY OrderQuarter,OrderThird,PickingDate
GO
-- Пропускаем первую 1000 и выводим 100
SELECT o.OrderID, MONTH(o.OrderDate) AS OrderMonth, datepart(qq,o.OrderDate) AS OrderQuarter, 
	CASE
		WHEN MONTH(o.OrderDate) BETWEEN 1 AND 4 THEN 1
		WHEN MONTH(o.OrderDate) BETWEEN 5 AND 8  THEN 2
		ELSE 3
	END AS OrderThird,
o.PickingCompletedWhen AS PickingDate
FROM Sales.Orders AS o
LEFT JOIN Sales.OrderLines AS l
ON o.OrderID = l.OrderID
WHERE UnitPrice > 100 OR PickedQuantity > 20
ORDER BY OrderQuarter,OrderThird,PickingDate
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY

GO
--4. Заказы поставщикам, которые были исполнены за 2014й год с доставкой Road Freight или Post, добавьте название поставщика, имя контактного лица принимавшего заказ
SELECT PO.PurchaseOrderID, M.DeliveryMethodName,S.SupplierName, P.FullName, T.FinalizationDate
FROM Purchasing.PurchaseOrders AS PO
	LEFT JOIN Purchasing.Suppliers AS S
		ON PO.SupplierID = S.SupplierID
	LEFT JOIN Application.DeliveryMethods AS M
		ON PO.DeliveryMethodID = M.DeliveryMethodID
	LEFT JOIN Application.People AS P
		ON PO.ContactPersonID = P.PersonID
	LEFT JOIN Purchasing.SupplierTransactions AS T
		ON PO.PurchaseOrderID = T.PurchaseOrderID
WHERE (FinalizationDate >= '2014/01/01' AND FinalizationDate < '2015/01/01') AND (DeliveryMethodName = 'Road Freight' OR DeliveryMethodName = 'Post')
GO

--5. 10 последних по дате продаж с именем клиента и именем сотрудника, который оформил заказ.
SELECT TOP (10) O.OrderID, O.OrderDate, C.CustomerName, P.FullName AS SalesPersonNam
FROM Sales.Orders AS O
	LEFT JOIN Sales.Customers AS C
		ON O.CustomerID = C.CustomerID
	LEFT JOIN Application.People AS P
		ON O.SalespersonPersonID = P.PersonID
ORDER BY O.OrderDate DESC
GO

--6. Все ид и имена клиентов и их контактные телефоны, которые покупали товар Chocolate frogs 250g
SELECT C.CustomerID AS ID, C.CustomerName AS [Name], C.PhoneNumber AS PhoneNumber, COUNT(O.OrderID) AS OrdersNumber
FROM Sales.Customers AS C
	LEFT JOIN Sales.Orders AS O
		ON C.CustomerID = O.CustomerID
	LEFT JOIN Sales.OrderLines AS OL
		ON O.OrderID = OL.OrderID
	LEFT JOIN Warehouse.StockItems AS S
		ON OL.StockItemID = S.StockItemID
WHERE S.StockItemName ='Chocolate frogs 250g'
GROUP BY C.CustomerID, C.CustomerName, C.PhoneNumber
GO