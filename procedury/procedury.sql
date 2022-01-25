-- for index of orderid (@idd)
-- Creates one invoice from orderid
create procedure dbo.[create invoice] @idd integer,
                                      @InvoiceDate date,
                                      @InvoiceID int output as
begin
    declare @invoiceNum nvarchar(50) = concat('FV/', cast(@idd as nvarchar(50)), '/',
                                              cast(year((select OrderCompletionDate from [Order] where OrderID = @idd)) as nvarchar(4)))
    declare @CustomerID int = (select CustomerID from [Order] o where OrderID = @idd)
    declare @CountryName nvarchar(50)
    declare @CityName nvarchar(50)
    declare @Adress nvarchar(50)
    declare @PostalCode nvarchar(50)

    select @CountryName = CountryName, @CityName = CityName, @Adress = [Address], @PostalCode = PostalCode
    from Customer
             inner join dbo.City C on C.CityID = Customer.CityID
             inner join Country C2 on C.CountryID = C2.CountryID
    where CustomerID = @CustomerID;

    declare @InvoiceIDs table
                        (
                            ID int
                        )
    insert into Invoice(InvoiceNum, InvoiceDate, DueDate, CustomerID, PaymentStatusID, CountryName, CityName, Address,
                        PostalCode)
    output inserted.InvoiceID into @InvoiceIDs
    values (@invoiceNum, @InvoiceDate, dateadd(day, 12, GETDATE()), @CustomerID, 1, @CountryName, @CityName, @Adress,
            @PostalCode)

    select @InvoiceID = ID from @InvoiceIDs
    return @InvoiceID
end;
GO

-- Creates order when customer pays only for this one, not monthly
create procedure OrderInsertInstPay @CustomerID int,
                                    @OrderCompletionDate DATETIME,
                                    @DurationTime TIME as
begin
    Declare @OrderIDTable table
                          (
                              Id int
                          )
    Declare @OrderID int

    insert into dbo.[Order] (OrderDate, OrderStatusID, PaymentStatusID, CustomerID, OrderCompletionDate, OrderSum,
                             DurationTime)
    OUTPUT inserted.OrderID into @OrderIDTable
    values (GETDATE(), 1, 1, @CustomerID, @OrderCompletionDate, 0.0, @DurationTime);

    select @OrderID = Id from @OrderIDTable

    declare @InvoiceID int

    exec dbo.[create invoice] @idd = @OrderID, @InvoiceDate = @OrderCompletionDate, @InvoiceID = @InvoiceID output

    update [Order] set InvoiceID= @InvoiceID where OrderID = @OrderID

    return @OrderID
end;
GO

drop procedure OrderInsertMonthPay
-- Creates order when customer pays monthly
create procedure OrderInsertMonthPay @CustomerID int,
                                     @OrderCompletionDate DATETIME,
                                     @DurationTime TIME as
begin
    Declare @OrderIDTable table
                          (
                              Id int
                          )
    Declare @OrderID int

    insert into dbo.[Order] (OrderDate, OrderStatusID, PaymentStatusID, CustomerID, OrderCompletionDate, OrderSum,
                             DurationTime)
    OUTPUT inserted.OrderID into @OrderIDTable
    values (GETDATE(), 1, 1, @CustomerID, @OrderCompletionDate, 0.0, @DurationTime);

    select @OrderID = Id from @OrderIDTable

    declare @startOfMonth date = cast(DATEADD(month, DATEDIFF(month, 0, @OrderCompletionDate) + 1, 0) as date)

    declare @InvoiceID int
    select @InvoiceID = InvoiceID
    from Invoice
    where CustomerID = @CustomerID
      and month(InvoiceDate) = month(@startOfMonth)
      and year(InvoiceDate) = year(@startOfMonth)


    if @InvoiceID is null
        exec dbo.[create invoice] @idd = @OrderID, @InvoiceDate = @startOfMonth, @InvoiceID = @InvoiceID output

    update [Order] set InvoiceID= @InvoiceID where OrderID = @OrderID

    return @OrderID
end;
GO

-- Adds dish to order
-- Need add update if this combination (DishID,OrderID) exists
create procedure AddDishToOrder @DishId int,
                                @OrderId int,
                                @Quantity int as
begin
    declare @BasePrice money
    select @BasePrice = Price from Dish where Dish.DishID = @DishId

    insert into OrderDetails(OrderID, DishID, BasePrice, Quantity) values (@OrderId, @DishId, @BasePrice, @Quantity)

    declare @CurrentValue money
    select @CurrentValue = OrderSum from [Order] where OrderID = @OrderId

    declare @CustomerID int
    declare @OrderDate date
    select @CustomerID = CustomerID, @OrderDate = OrderDate from [Order] where OrderID = @OrderId

    declare @DiscMult decimal(3, 2)
    exec get_discount_mult @OrderDate, @CustomerID, @DiscMult output

    update [Order] set [Order].OrderSum = @CurrentValue + (@DiscMult * @BasePrice * @Quantity) where OrderID = @OrderId;

end;
GO


--Adds IndividualCustomer to Database
create procedure CreateIndivCustomer @CityName nvarchar(50),
                                     @Email nvarchar(50),
                                     @Phone nvarchar(50),
                                     @Address nvarchar(50),
                                     @PostalCode nvarchar(50),
                                     @FirstName nvarchar(50),
                                     @LastName nvarchar(50),
                                     @CustomerID int output as
begin
    Declare @CustomerIDTable table
                             (
                                 Id int
                             )
    Declare @CityID int

    select @CityID = CityID from City where CityName = @CityName

    if @CityID is null
        begin
            select 'Takie miasto nie istnieje' as ErrorMsg
            return 2
        end

    insert into dbo.Customer (Email, Phone, CityID, Address, PostalCode)
    OUTPUT inserted.CustomerID into @CustomerIDTable
    values (@Email, @Phone, @CityID, @Address, @PostalCode);

    select @CustomerID = Id from @CustomerIDTable

    Insert into dbo.IndividualCustomer (CustomerID, FirstName, LastName) values (@CustomerID, @FirstName, @LastName)
end

-- employeesDetailPerOrder, pokazuje pracowników którzy są przypisani do danego Zamówienia
    drop procedure if exists employeesDetailPerOrder
    create procedure employeesDetailPerOrder @OrderID int as
    begin
        select E.EmployeeFirstName as FirstName, E.EmployeeLastName as LastName
        from [Order] O
                 inner join EmployeeDetails ED on O.OrderID = ED.OrderID
                 inner join Employee E on ED.EmployeeID = E.EmployeeID
        where O.OrderID = @OrderID
    end
go

create procedure add_company_customer @Email nvarchar(50),
                                      @Phone nvarchar(50),
                                      @CityID int,
                                      @Address nvarchar(50),
                                      @PostalCode nvarchar(50),
                                      @NIP nvarchar(10),
                                      @REGON nvarchar(9),
                                      @KRS nvarchar(10),
                                      @CompanyName nvarchar(50) as
begin
    Declare @CustomerIdTable table
                             (
                                 Id int
                             )
    declare @CustomerID int
    insert into Customer (Email, Phone, CityID, Address, PostalCode)
    output inserted.CustomerID into @CustomerIdTable
    values (@Email, @Phone, @CityID, @Address, @PostalCode);
    select @CustomerID = id from @CustomerIdTable
    insert into Company (CustomerID, NIP, REGON, KRS, CompanyName)
    values (@CustomerID, @NIP, @REGON, @KRS, @CompanyName);
end
GO

create procedure add_employee @CustomerID int,
                              @FirstName nvarchar(50),
                              @LastName nvarchar(50) as
begin
    if @CustomerID IN (SELECT CustomerID FROM Company)
        insert into dbo.Employee (CustomerID, EmployeeFirstName, EmployeeLastName)
        values (@CustomerID, @FirstName, @LastName);
    else
        RETURN 'Inserting employee for individual customer is impossible, add customer as company if you want him to have employee'
end
GO

CREATE PROCEDURE create_order @CustomerID int,
                              @OrderCompletionDate datetime,
                              @OrderStatusID int,
                              @PaymentStatusID int,
                              @DurationTime time AS
BEGIN
    IF (
            EXISTS(SELECT * FROM [OrderStatus] WHERE OrderStatusID = @OrderStatusID)
            AND EXISTS(SELECT * FROM [PaymentStatus] WHERE PaymentStatusID = @PaymentStatusID)
            AND @DurationTime <= (FORMAT(DATEADD(hh, 12, '00:00:00'), 'hh:mm tt'))
        )

    INSERT INTO [dbo].[Order] (OrderDate, OrderStatusID, PaymentStatusID, CustomerID, OrderCompletionDate, OrderSum, DurationTime, InvoiceID)
    VALUES (GETDATE(), @OrderStatusID, @PaymentStatusID, @CustomerID, @OrderCompletionDate, 0, @DurationTime, null);

END
GO








create procedure dbo.cancel_order @OrderID int as
begin
    if ((select OrderStatusID from [Order] where OrderID=@OrderID) in (1,3))
        update [Order] set OrderStatusID=2
            where OrderID = @OrderID
end
go

-- Dodaje pracownika do zamówienia (jeżeli nie istnieje to go dodaje)
create procedure dbo.add_employee_to_order
    @OrderID int,
    @FirstName nvarchar(50),
    @LastName nvarchar(50)
as
begin
    Declare @EmployeeID int
    if Exists (select EmployeeID from Employee E where E.EmployeeLastName=@LastName and E.EmployeeFirstName=@FirstName) begin
        select top 1 @EmployeeID=EmployeeID from Employee E where E.EmployeeLastName=@LastName and E.EmployeeFirstName=@FirstName
        INSERT INTO EmployeeDetails(EmployeeID, OrderID) values (@EmployeeID, @OrderID)
    end --if
    else begin
        Insert Into Employee(CustomerID, EmployeeFirstName, EmployeeLastName) values ((select C.CustomerID from Customer C inner join [Order] o on C.CustomerID = o.CustomerID where OrderID=@OrderID), @FirstName, @LastName)
        exec dbo.add_employee_to_order @OrderID, @FirstName, @LastName
    end -- else
end
go

--generowanie raportów dot. rabatów dla klienta indywidualnego oraz firm
create procedure dbo.statystyki_klient @CustomerID int
as
begin
    ;
    with order_disc_money as (
        select [Order].OrderID, sum(BasePrice * Quantity) no_disc
        from [Order]
                 join OrderDetails od on [Order].OrderID = od.OrderID
        group by [Order].OrderID
    )

    select [Order].OrderID,
           OrderDate,
           OrderSum,
           OrderSum - odm.no_disc       as discount_value,
           1 - (odm.no_disc / OrderSum) as disc_mult
    from [Order]
             join order_disc_money odm on [Order].OrderID = odm.OrderID
    where CustomerID = @CustomerID
      and PaymentStatusID = 2
end
go



--informowanie o konieczności zmian w menu
-- jeśli liczba pozycji menu, których data dodania do menu jest mniejsza lub równa od
--    obecnej daty pomniejszonej o 14 dni zwracana jest informacja o konieczności
--    zmiany menu

CREATE FUNCTION [dbo].need_change_menu(
)
    RETURNS BIT
AS
BEGIN
    DECLARE result BIT = 0
    IF (2*
        (SELECT COUNT(*)
        FROM Menu
        WHERE Menu.AddDate < DATEADD(day, -14, GETDATE()) and Menu.RemoveDate is null or Menu.RemoveDate > GETDATE()) >
        (SELECT COUNT(*)
        FROM Menu
        WHERE Menu.RemoveDate is null or Menu.RemoveDate > GETDATE()))
        SET result = 1
    RETURN result
END


--zapisanie informacji o rabacie przyznanym danemu klientowi
create procedure dbo.add_discount @CustomerID INT as
begin
    declare Z1 INT = 0
   select Z1 = count(*)
    from [Order]
    where CustomerID = @CustomerID and OrderSum > 30
    IF Z1 = 10
    insert into DiscountDetails (CustomerID, DiscountID, StartDate, EndDate, IsActive) values (@CustomerID,1,getdate(),null,1)
    select Z1 = sum(OrderSum)
    from [Order]
    where CustomerID = @CustomerID and OrderSum > 30
    IF Z1 = 1000
    insert into DiscountDetails (CustomerID, DiscountID, StartDate, EndDate, IsActive) values (@CustomerID,1,getdate(),dateadd(day,7,getdate()),1)
end
    -- generowanie listy potraw do przygotowania w danym dniu
    create procedure dbo.get_dishes_for_day @data Date
    as
    begin
        select o.OrderID, o.OrderCompletionDate, d.Name, od.Quantity
        from [Order] o
                 inner join OrderDetails OD on o.OrderID = OD.OrderID
                 inner join Dish d on OD.DishID = d.DishID
        where cast(OrderCompletionDate as Date) = @data
    end
go

--sprawdzenie czy data zamówienia jest odpowiednia
-- czy jest odpowiedni dzień
--  -  W dniach czwartek-piątek-sobota istnieje możliwość wcześniejszego zamówienia dań zawierających owoce morza.
--      Z uwagi na indywidualny import takie zamówienie winno być złożone maksymalnie do poniedziałku
--      poprzedzającego zamówienie. - już jest w triggerach


--Gets the discount for certain customer in certain date and returns it in @Multiplier output
create procedure get_discount_mult @CustomerID int,
                                   @Multiplier decimal(3, 2) output as
begin
    declare bestMultInPeriod int
    declare idxOfBestMultiplier int
    set @Multiplier = 0.00

    select top 1 @Multiplier = D.Multiplier
    from DiscountDetails
             join Discount D on DiscountDetails.DiscountID = D.DiscountID
    where CustomerID = @CustomerID
      and IsActive = 1
      and EndDate is not null
    order by D.Multiplier desc

    set bestMultInPeriod = @Multiplier

    select top 1 @Multiplier = MAX(@Multiplier, D.Multiplier), idxOfTmp = D.DiscountID
    from DiscountDetails
             join Discount D on DiscountDetails.DiscountID = D.DiscountID
    where CustomerID = @CustomerID
      and IsActive = 1
      and EndDate is null
    group by D.DiscountID, D.Multiplier
    order by D.Multiplier desc

    if @Multiplier != bestMultInPeriod
        update DiscountDetails set IsActive = 0 where DiscountID = idxOfBestMultiplier

end;
go
