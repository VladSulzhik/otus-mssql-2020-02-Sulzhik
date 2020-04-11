USE WideWorldImporters
--1. ��� ������, � ������� � �������� ���� ������� urgent ��� �������� ���������� � Animal
SELECT StockItemName FROM Warehouse.StockItems
WHERE StockItemName LIKE '%urgent%' OR StockItemName LIKE 'Animal%'
ORDER BY StockItemName
GO

--2. �����������, � ������� �� ���� ������� �� ������ ������ (����� ������� ��� ��� ������ ����� ���������, ������ �������� ����� JOIN)
SELECT S.SupplierName, COUNT(P.PurchaseOrderID) AS OrdersNumber 
FROM Purchasing.Suppliers AS S
	LEFT JOIN Purchasing.PurchaseOrders AS P
		ON s.SupplierID = p.SupplierID
WHERE p.PurchaseOrderID IS NULL
GROUP BY S.SupplierName
GO

--3. ������� � ��������� ������, � ������� ���� �������, ������� ��������, � �������� ��������� �������, �������� ����� � ����� ����� ���� ��������� ���� - ������ ����� �� 4 ������, ���� ������ ������ ������ ���� ������, � ����� ������ ����� 100$ ���� ���������� ������ ������ ����� 20. �������� ������� ����� ������� � ������������ �������� ��������� ������ 1000 � ��������� ��������� 100 �������. ���������� ������ ���� �� ������ ��������, ����� ����, ���� �������.
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
-- ���������� ������ 1000 � ������� 100
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
--4. ������ �����������, ������� ���� ��������� �� 2014� ��� � ��������� Road Freight ��� Post, �������� �������� ����������, ��� ����������� ���� ������������ �����
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

--5. 10 ��������� �� ���� ������ � ������ ������� � ������ ����������, ������� ������� �����.
SELECT TOP (10) O.OrderID, O.OrderDate, C.CustomerName, P.FullName AS SalesPersonNam
FROM Sales.Orders AS O
	LEFT JOIN Sales.Customers AS C
		ON O.CustomerID = C.CustomerID
	LEFT JOIN Application.People AS P
		ON O.SalespersonPersonID = P.PersonID
ORDER BY O.OrderDate DESC
GO

--6. ��� �� � ����� �������� � �� ���������� ��������, ������� �������� ����� Chocolate frogs 250g
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