-- Statystyki dotyczące rezerwacji stolików miesięczne

CREATE VIEW dbo.[StatTablesMonth]
AS
SELECT DATENAME(month, O.OrderDate)          AS Month,
       DATENAME(year, O.OrderDate)           as Year,
       COUNT(T.TableID)                      AS NumReservedTables,
       SUM(T.ChairAmount) / COUNT(T.TableID) AS AvgPplCount
FROM [Order] AS O
         INNER JOIN
     Reservation AS R ON R.OrderID = O.OrderID
         INNER JOIN
     [Table] T on R.TableID = T.TableID
WHERE (O.OrderStatusID = 4)
GROUP BY DATENAME(month, O.OrderDate), DATENAME(year, O.OrderDate)
go

-- Statystyki dotyczące rezerwacji stolików tygodniowo

CREATE VIEW dbo.[StatTablesWeek]
AS
SELECT DATENAME(week, O.OrderDate)           AS Week,
       DATENAME(year, O.OrderDate)           as Year,
       COUNT(T.TableID)                      AS NumReservedTables,
       SUM(T.ChairAmount) / COUNT(T.TableID) AS AvgPplCount
FROM [Order] AS O
         INNER JOIN
     Reservation AS R ON R.OrderID = O.OrderID
         INNER JOIN
     [Table] T on R.TableID = T.TableID
WHERE (O.OrderStatusID = 4)
GROUP BY DATENAME(week, O.OrderDate), DATENAME(year, O.OrderDate)
go

-- Wycofane potrawy

CREATE VIEW dbo.[CanceledDishes]
AS
SELECT DishID, Name, IsSeafood
from Dish
where IsAvailable = 0
GO

-- Zamówienia na miejscu w realizacji
CREATE VIEW dbo.[Orders on-site in execution]
AS
select *
from dbo.[Orders in execution] O
where O.OrderID in (select R.OrderID from Reservation R)
go

-- Zamówienia na wynos w realizacji
CREATE VIEW dbo.[Take-away orders in execution]
AS
select *
from dbo.[Orders in execution] O
where O.OrderID not in (select R.OrderID from Reservation R)
go

-- Zamówienia w realizacji
CREATE VIEW dbo.[Orders in execution]
AS
SELECT OrderID, CustomerID, OrderDate, OrderCompletionDate, OrderSum, DurationTime
from [Order] O
where OrderStatusID = 3
go

-- generowanie statystyk dla klientów indywidualnych oraz firm dotyczących kwot
CREATE VIEW dbo.[StatCustOrder]
AS
SELECT DATENAME(month, O.OrderDate)          AS Month,
       DATENAME(year, O.OrderDate)           as Year,
       c.CustomerID,
       Sum(OrderSum) as SumOfOrders
FROM [Order] AS O
         INNER JOIN Customer c on O.CustomerID = c.CustomerID
WHERE (O.OrderStatusID = 4)
GROUP BY DATENAME(month, O.OrderDate), DATENAME(year, O.OrderDate), c.CustomerID
go
