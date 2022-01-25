-- Tables in use - lists tables that are possible to use in a restaurant.
CREATE VIEW dbo.[TablesInUse]
AS
SELECT TableID, ChairAmount
FROM [Table]
WHERE isActive = 1
GO

-- Available dishes - lists dishes currently available to use in the menu.
CREATE VIEW dbo.[AvailableDishes]
AS
SELECT DishID, Name, IsSeafood
FROM Dish
WHERE IsAvailable = 1
GO

-- Need payment - list orders that are yet to be paid.
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

-- Need confirmation - lists reservations that need to be confirmed by staff.
CREATE VIEW dbo.[NeedConfirmation]
AS
SELECT OrderID, OrderStatusID, CustomerID, OrderSum, InvoiceID, OrderDate, OrderCompletionDate
FROM [Order]
WHERE OrderStatusID = 1
GO

-- Current menu - lists current menu.
CREATE VIEW dbo.[CurrentMenu]
AS
SELECT M.MenuID, D.DishID, D.Name, M.AddDate, M.RemoveDate
FROM Dish D
         INNER JOIN Menu M ON D.DishID = M.DishID
WHERE (M.AddDate <= GETDATE()) AND (M.RemoveDate IS NULL)
   OR (M.AddDate <= GETDATE()) AND (GETDATE() < M.RemoveDate)
GO

-- Order Summary - lists most important information's about the order:
-- ordered dishes, quantity of them, charge for order, customer identifier,
-- order date, order completion date, reserved table.
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

-- Generate orders for today - lists today's ordered dishes along with
-- their execution deadline (OrderCompletionDate).
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
