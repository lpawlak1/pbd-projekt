## Widoki

#### Stoliki, które są aktualnie dostępne dla gości (nie stoją na zapleczu)
```sql
CREATE VIEW dbo.[TablesInUse]
AS
SELECT TableID, ChairAmount
FROM [Table]
WHERE isActive = 1
GO

```

#### Dania, które nie są wyłączone z użytku (np sezonowe)
```sql
CREATE VIEW dbo.[AvailableDishes]
AS
SELECT DishID, Name, IsSeafood
FROM Dish
WHERE IsAvailable = 1
GO
```

#### Zamówienia / rezerwacje, które nie zostały opłacone
```sql
CREATE VIEW dbo.[NeedPayment]
AS
SELECT OrderID,
       OrderStatusID,
       PaymentStatusID,
       CustomerID,
       OrderSum,
       InvoiceID,
       OrderDate,
       OrderCompletionDate
FROM [Order]
WHERE PaymentStatusID = 1
GO

```

#### Rezerwacje, które nie zostały potwierdzone przez pracownika
```sql
CREATE VIEW dbo.[NeedConfirmation]
AS
SELECT OrderID, OrderStatusID, CustomerID, OrderSum, InvoiceID, OrderDate, OrderCompletionDate
FROM [Order]
WHERE OrderStatusID = 1
GO

```

#### Menu, które aktualnie obowiązuje
```sql
-- Current menu - lists current menu.
CREATE VIEW dbo.[CurrentMenu]
AS
SELECT M.MenuID, D.DishID, D.Name, M.AddDate, M.RemoveDate
FROM Dish D
         INNER JOIN Menu M ON D.DishID = M.DishID
WHERE (M.AddDate <= GETDATE()) AND (M.RemoveDate IS NULL)
   OR (M.AddDate <= GETDATE()) AND (GETDATE() < M.RemoveDate)
GO

```

#### Podsumowanie rezerwacji
```sql
ALTER VIEW dbo.[OrderSummary]
AS
    SELECT D.Name                AS 'Dish Name',
           OD.Quantity,
           O.OrderSum            AS 'Charged for',
           C.CustomerID          AS 'Customer number',
           O.OrderDate           AS 'Order received',
           O.OrderCompletionDate AS 'Order completed',
           R2.TableID            AS 'Chosen table'
    FROM [Order] O
             INNER JOIN OrderDetails OD on O.OrderID = OD.OrderID
             INNER JOIN Dish D on OD.DishID = D.DishID
             INNER JOIN Customer C on O.CustomerID = C.CustomerID
             LEFT JOIN DiscountDetails DD on C.CustomerID = DD.CustomerID
             LEFT JOIN Discount D2 on DD.DiscountID = D2.DiscountID
             LEFT JOIN Reservation R2 on O.OrderID = R2.OrderID
GO

```

#### Dania wymagane na dzisiaj
```sql
CREATE VIEW dbo.[OrdersForToday]
AS
    SELECT O.OrderID,
           D.Name,
           OD.Quantity,
           O.OrderDate,
           O.OrderCompletionDate,
           D.IsSeafood
    FROM [Order] O
INNER JOIN OrderDetails OD on O.OrderID = OD.OrderID
INNER JOIN Dish D on OD.DishID = D.DishID
WHERE CAST(O.OrderDate AS Date) = (SELECT CAST( GETDATE() AS Date ))
GO

```

#### Częstość zamawiania danego dania
```sql
CREATE VIEW dbo.frequency_of_orders_of_dish AS
(
SELECT DishID, count(*) AS AmountOfOrders
FROM OrderDetails
GROUP BY DishID
)

```

#### Suma dla firmy (zamówień)
```sql
CREATE VIEW dbo.sum_of_order_for_company AS
(
select C2.CompanyName, SUM(O.OrderSum) as sum
from [Order] [O]
         join Customer C on O.CustomerID = C.CustomerID
         join Company C2 on C.CustomerID = C2.CustomerID
GROUP BY C2.CompanyName
    )

```

#### Suma dla indywidualnego klienta (zamówień)
```sql
CREATE VIEW dbo.sum_of_order_for_individual_customer AS
(
select CONCAT(IC.LastName,' ',IC.FirstName) AS name,SUM(O.OrderSum) as sum
from [Order] [O]
         join Customer C on O.CustomerID = C.CustomerID
        join IndividualCustomer IC on C.CustomerID = IC.CustomerID
GROUP BY CONCAT(IC.LastName,' ',IC.FirstName)
    )

```

#### Rabaty dla firmy jednorazowe aktywne
```sql
CREATE VIEW dbo.active_discounts_for_companies_one_use AS
(
select C.CustomerID, C2.CompanyName,D.Multiplier,DD.StartDate
from Customer C
    JOIN Company C2 on C.CustomerID = C2.CustomerID
    JOIN DiscountDetails DD on C.CustomerID = DD.CustomerID
    join Discount D on DD.DiscountID = D.DiscountID
WHERE DD.EndDate IS NULL AND DD.IsActive = 1
)
```

#### Rabaty dla firmy okresowe aktywne
```sql
CREATE VIEW dbo.active_discounts_for_companies_time_period AS
(
select C.CustomerID, C2.CompanyName,D.Multiplier,DD.StartDate,DD.EndDate
from Customer C
    JOIN Company C2 on C.CustomerID = C2.CustomerID
    JOIN DiscountDetails DD on C.CustomerID = DD.CustomerID
    join Discount D on DD.DiscountID = D.DiscountID
WHERE DD.EndDate IS NOT NULL AND DD.IsActive = 1
)
```

#### Rabaty dla indywidualnego klienta jednorazowe aktywne
```sql
CREATE VIEW dbo.active_discounts_for_individual_one_use AS
(
select C.CustomerID, CONCAT(IC.LastName,' ',IC.FirstName) AS Name,D.Multiplier,DD.StartDate
from Customer C
    JOIN IndividualCustomer IC on C.CustomerID = IC.CustomerID
    JOIN DiscountDetails DD on C.CustomerID = DD.CustomerID
    join Discount D on DD.DiscountID = D.DiscountID
WHERE DD.EndDate IS NULL AND DD.IsActive = 1)

```

#### Rabaty dla indywidualnego klienta okresowe aktywne
```sql
CREATE VIEW dbo.active_discounts_for_individual_time_period AS
(
select C.CustomerID, CONCAT(IC.LastName,' ',IC.FirstName) AS Name,D.Multiplier,DD.StartDate,DD.EndDate
from Customer C
    JOIN IndividualCustomer IC on C.CustomerID = IC.CustomerID
    JOIN DiscountDetails DD on C.CustomerID = DD.CustomerID
    join Discount D on DD.DiscountID = D.DiscountID
WHERE DD.EndDate IS NOT NULL AND DD.IsActive = 1)


```

#### Statystyki dotyczące rezerwacji stolików miesięczne
```sql
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

```

#### Statystyki dotyczące rezerwacji stolików tygodniowo
```sql

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

```

#### Wycofane potrawy
```sql

CREATE VIEW dbo.[CanceledDishes]
AS
SELECT DishID, Name, IsSeafood
from Dish
where IsAvailable = 0
GO

```

#### Zamówienia na miejscu w realizacji
```sql
CREATE VIEW dbo.[Orders on-site in execution]
AS
select *
from dbo.[Orders in execution] O
where O.OrderID in (select R.OrderID from Reservation R)
go


```

#### Zamówienia na wynos w realizacji
```sql
CREATE VIEW dbo.[Take-away orders in execution]
AS
select *
from dbo.[Orders in execution] O
where O.OrderID not in (select R.OrderID from Reservation R)
go
```

#### Zamówienia w realizacji
```sql
CREATE VIEW dbo.[Orders in execution]
AS
SELECT OrderID, CustomerID, OrderDate, OrderCompletionDate, OrderSum, DurationTime
from [Order] O
where OrderStatusID = 3
go
```

#### Generowanie statystyk dla klientów indywidualnych oraz firm dotyczących kwot
```sql
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
```
