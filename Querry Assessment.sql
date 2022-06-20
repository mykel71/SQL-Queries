

--1.	A list of clients with a CustomerStatusId of 1, ordered by Surname then Firstname. 
--Columns required are Surname, Firstname, CustomerStatusId and CreateDateTime.

Select Surname, FirstName, CustomerStatusId, CreateDateTime
From Customer
Where CustomerStatusId = 1
Order by Surname, Firstname;


--2.	A list of stock items that were sold in January 2018. 
--Stock Description is the only required field. 

Select Distinct [Description]
From Stock
Where StockId IN (
Select Distinct StockId 
From SaleItem 
Where SaleId IN (
	Select SaleId
	From Sale
	Where CreateDateTime Between '2018-01-01' and '2010-02-01')
	)


--3.	A list of stock items that were not sold in January 2018. 
--Stock Description is the only required field.


SELECT [Description]
FROM Stock s
Where StockId NOT IN (Select Distinct StockId 
From SaleItem 
Where SaleId IN (
	Select SaleId
	From Sale
	Where CreateDateTime Between '2018-01-01' and '2010-02-01')
	)


--4.	A list of the top 10 highest selling stock items for January 2018. 
--Fields required are Description, Quantity Sold.

Select TOP 10 [Description], QuantitySold AS [Quantity Sold]
From Stock
INNER JOIN
(Select Distinct StockId, Sum(Quantity) AS QuantitySold
From SaleItem
Where SaleId IN (
	Select SaleId
	From Sale
	Where CreateDateTime Between '2018-01-01' and '2010-02-01')
	Group By StockId)AS T1 ON Stock.StockId = T1.StockId;



--5.	A list of the top 10 customers for January 2018 in terms of sale value. 
--Fields required are Firstname, Surname, Number of Sales, Value of Sales.

--Quantity Price - Discount = Value of each sale

--Assumptions : Tax is a decimal = 0,15 
--Assumption 2 : Discount is a decimal e.g 0,1
-- Cursor return the value only for the time period im intrested in

-- a stored Procedure that will return the customers needed
Create Procedure sp_Top10CustomersForJanuary2018

AS
	BEGIN
	--Create a temporary table
Create Table #SaleValue (SaleId int not null, SaleItemId int not null, [Value] decimal not null)


DECLARE @SaleItemId int, @StockId int, @Quantity int, @Value decimal 

DECLARE Sale_cursor CURSOR FOR 
SELECT Distinct SaleItemId 
FROM SaleItem
WHERE SaleId IN (
	Select SaleId
	From Sale
	Where CreateDateTime Between '2018-01-01' and '2010-02-01') 

OPEN Sale_cursor  
FETCH NEXT FROM Sale_cursor INTO @SaleItemId 

WHILE @@FETCH_STATUS = 0  
BEGIN  

	 Insert into #SaleValue(SaleId, SaleItemId, [Value])

	 Values 
			((
			Select SaleId From SaleItem Where SaleItemId = @SaleItemId
			), 
			@SaleItemId, 
			-- Calculate the value of each item
			(
			Select (Quantity *(Price - (Discount * Price)) * (1+ Tax) )
			From SaleItem
			Where SaleItemId = @SaleItemId
			))

      FETCH NEXT FROM Sale_cursor INTO @SaleItemId
END 

CLOSE Sale_cursor  
DEALLOCATE Sale_cursor 


Select TOP 10 Firstname, Surname, NumberOfSales AS [Number of Sales], ValueOfSales AS [Value Of Sales]
From Customer c
INNER JOIN (
SELECT CustomerId, Count(SaleId) AS NumberOfSales From Sale
Where SaleId IN (Select SaleId
	From Sale
	Where CreateDateTime Between '2018-01-01' and '2010-02-01')

)AS T1 ON c.CustomerId = T1.CustomerId

INNER JOIN (

SELECT CustomerId, SUM(SaleTotal) AS ValueOfSales FROM 
(
SELECT CustomerId, s.SaleId,SaleTotal FROM 
(SELECT SaleId, Sum(Value)AS SaleTotal From #SaleValue) AS Ts
INNER JOIN Sale s ON s.SaleId = Ts.SaleId) AS tt


)AS T2 ON c.CustomerId = T2.CustomerId
Order By [Value Of Sales] DESC
Drop Table #SaleValue
END;
