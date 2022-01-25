drop trigger orderDetailsInsert

-- Sprawdza czy danie które probujemy dodac do menu jest w bazie w czasie odbioru zamowienia zaznaczone jako dostepne i jest w menu wtedy
create trigger orderDetailsInsert
    on dbo.OrderDetails
    for insert as
BEGIN
    DECLARE @dishID INT = (SELECT DishID FROM Inserted)
    DECLARE @OrderID int = (SELECT OrderID FROM Inserted)
    Declare @OrderCompletionDate datetime = (select OrderCompletionDate from [Order] where [Order].OrderID = @OrderID)
    if exists(select * from Dish where Dish.DishID = @dishID and IsAvailable = 0)
        BEGIN
            ;
            THROW 50200, N'Niepoprawne DishID, Jego IsAvailable to 0 w tabeli Dish', 1
            ROLLBACK TRANSACTION;
        END
    if not exists(select *
                  from Menu
                  where Menu.DishID = @dishID
                    and AddDate < @OrderCompletionDate
                    and (RemoveDate is null or RemoveDate > @OrderCompletionDate))
        begin
            ;
            THROW 50200, N'Niepoprawne DishID, Coś z datami w menu nie jest ok', 1
            ROLLBACK TRANSACTION;
        end
END
go

drop trigger if exists ReservationInsert
-- Sprawdza czy stolik można dodać do rezerwacji (czy jest wtedy wolny i aktywny)
create trigger ReservationInsert
    on dbo.Reservation
    for insert as
BEGIN
    DECLARE @OrderID int = (SELECT OrderID FROM inserted)
    DECLARE @TableID int = (select TableID from inserted)
    DECLARE @OrderCompletionDate datetime
    DECLARE @OrderCompletionDateEnd datetime

    select @OrderCompletionDate = OrderCompletionDate,
           @OrderCompletionDateEnd = OrderCompletionDate + cast(DurationTime as datetime)
    from [Order]
    where OrderID = @OrderID

    DECLARE @TableInUseCount int
    select @TableInUseCount = Count(*)
    from [Order] O
             inner join Reservation R2 on O.OrderID = R2.OrderID
             inner join [Table] T on R2.TableID = T.TableID
    where O.OrderID != @OrderID
      and ((O.OrderCompletionDate <= @OrderCompletionDate and
            O.OrderCompletionDate + cast(DurationTime as datetime) <= @OrderCompletionDateEnd)
        or (O.OrderCompletionDate >= @OrderCompletionDate and
            O.OrderCompletionDate + cast(DurationTime as datetime) <= @OrderCompletionDateEnd)
        or (O.OrderCompletionDate >= @OrderCompletionDate and
            O.OrderCompletionDate + cast(DurationTime as datetime) >= @OrderCompletionDateEnd)
        or (O.OrderCompletionDate <= @OrderCompletionDate and
            O.OrderCompletionDate + cast(DurationTime as datetime) >= @OrderCompletionDateEnd)
        or (O.OrderCompletionDate <= @OrderCompletionDate and
            O.OrderCompletionDate + cast(DurationTime as datetime) >= @OrderCompletionDateEnd))
      and R2.TableID = @TableID
    --lewy mniejszy, prawy w srodku or lewy i pray w srodku or lewy w srodku i prawy z prawej or oba na zewnatrz  (tak jest w where po kolei)

    if @TableInUseCount > 0
        BEGIN
            ;
            THROW 50200, N'Dany stolik jest używany przez inny Order', 1
            ROLLBACK TRANSACTION;
        END
    if exists(select * from [Table] T where T.TableID = @TableID and T.isActive = 0)
        BEGIN
            ;
            THROW 50200, N'Stolik nie jest w użyciu (isActive jest 0)', 1
            ROLLBACK TRANSACTION;
        END
END
go

-- seafood trigger for orderDetails
CREATE TRIGGER [dbo].[SeaFoodOrder]
    ON [dbo].[OrderDetails]
    AFTER INSERT
    AS
BEGIN
    SET NOCOUNT ON
    DECLARE @orderID INT
    SET @orderID = (SELECT OrderID FROM Inserted)
    DECLARE @dishID INT
    SET @dishID = (SELECT DishID FROM Inserted)

    DECLARE @orderDate DATETIME
    SET @orderDate = (
        SELECT OrderDate
        FROM dbo.[Order]
        WHERE OrderID = @orderID
    )

    DECLARE @OrderCompletionDate DATETIME
    SET @OrderCompletionDate = (
        SELECT OrderCompletionDate
        FROM dbo.[Order]
        WHERE OrderID = @orderID
    )

    DECLARE @IsSeafood DATETIME
    SET @IsSeafood = (
        SELECT IsSeafood
        FROM dbo.Dish D
                 join OrderDetails O on D.DishID = O.DishID
        WHERE O.OrderID = @orderID
    )


    IF @IsSeafood = 1 AND
       (DATEPART(WEEKDAY, @OrderCompletionDate) NOT IN (5, 6, 7) OR
        DATEDIFF(DAY, @orderDate, @OrderCompletionDate) < 3)
        BEGIN
            ;
            THROW 50200,
                'Order is impossible, because it does not satisfy rules of seafood orders, read documentation of orders for more info', 1
            ROLLBACK TRANSACTION
        END
END
GO
ALTER TABLE [dbo].[OrderDetails]
    ENABLE TRIGGER [SeaFoodOrder]
GO

-- Trigger for checking if employee is an employee of a company.
CREATE TRIGGER [dbo].[EmployeeInsert]
    ON [dbo].[Employee]
    FOR INSERT AS
BEGIN
    DECLARE @CustomerID INT = (SELECT CustomerID FROM Inserted)

    IF NOT EXISTS(SELECT * FROM Company C WHERE C.CustomerID = @CustomerID)
        BEGIN
            ;
            THROW 50200, N'CustomerID of an employee does not belong to company', 1
            ROLLBACK TRANSACTION;
        END
END
GO
