-- częstość zamawiania danego dania - redundant
CREATE VIEW dbo.frequency_of_orders_of_dish AS
(
SELECT DishID, count(*) AS AmountOfOrders
FROM OrderDetails
GROUP BY DishID)

-- suma dla firmy
CREATE VIEW dbo.sum_of_order_for_company AS
(
select C2.CompanyName, SUM(O.OrderSum) as sum
from [Order] [O]
         join Customer C on O.CustomerID = C.CustomerID
         join Company C2 on C.CustomerID = C2.CustomerID
GROUP BY C2.CompanyName
    )

-- suma dla indywidualnego klienta
CREATE VIEW dbo.sum_of_order_for_individual_customer AS
(
select CONCAT(IC.LastName,' ',IC.FirstName) AS name,SUM(O.OrderSum) as sum
from [Order] [O]
         join Customer C on O.CustomerID = C.CustomerID
        join IndividualCustomer IC on C.CustomerID = IC.CustomerID
GROUP BY CONCAT(IC.LastName,' ',IC.FirstName)
    )

-- rabaty dla firmy jednorazowe aktywne
CREATE VIEW dbo.active_discounts_for_companies_one_use AS
(
select C.CustomerID, C2.CompanyName,D.Multiplier,DD.StartDate
from Customer C
JOIN Company C2 on C.CustomerID = C2.CustomerID
JOIN DiscountDetails DD on C.CustomerID = DD.CustomerID
join Discount D on DD.DiscountID = D.DiscountID
WHERE DD.EndDate IS NULL AND DD.IsActive = 1)

-- rabaty dla firmy okresowe aktywne
CREATE VIEW dbo.active_discounts_for_companies_time_period AS
(
select C.CustomerID, C2.CompanyName,D.Multiplier,DD.StartDate,DD.EndDate
from Customer C
JOIN Company C2 on C.CustomerID = C2.CustomerID
JOIN DiscountDetails DD on C.CustomerID = DD.CustomerID
join Discount D on DD.DiscountID = D.DiscountID
WHERE DD.EndDate IS NOT NULL AND DD.IsActive = 1)

-- rabaty dla indywidualnego klienta jednorazowe aktywne
CREATE VIEW dbo.active_discounts_for_individual_one_use AS
(
select C.CustomerID, CONCAT(IC.LastName,' ',IC.FirstName) AS Name,D.Multiplier,DD.StartDate
from Customer C
JOIN IndividualCustomer IC on C.CustomerID = IC.CustomerID
JOIN DiscountDetails DD on C.CustomerID = DD.CustomerID
join Discount D on DD.DiscountID = D.DiscountID
WHERE DD.EndDate IS NULL AND DD.IsActive = 1)

-- rabaty dla indywidualnego klienta okresowe aktywne
CREATE VIEW dbo.active_discounts_for_individual_time_period AS
(
select C.CustomerID, CONCAT(IC.LastName,' ',IC.FirstName) AS Name,D.Multiplier,DD.StartDate,DD.EndDate
from Customer C
JOIN IndividualCustomer IC on C.CustomerID = IC.CustomerID
JOIN DiscountDetails DD on C.CustomerID = DD.CustomerID
join Discount D on DD.DiscountID = D.DiscountID
WHERE DD.EndDate IS NOT NULL AND DD.IsActive = 1)

