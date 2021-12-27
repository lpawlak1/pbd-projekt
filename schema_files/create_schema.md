```sql
-- tables
-- Table: City
CREATE TABLE City
(
    CityID    int           NOT NULL IDENTITY (1,1),
    CityName  nvarchar(255) NULL,
    IsActive  bit           NOT NULL default 1,
    CountryID int           NOT NULL,
    CONSTRAINT City_pk PRIMARY KEY (CityID)
);

-- Table: Company
CREATE TABLE Company
(
    CustomerID  int NOT NULL,
    NIP         int NOT NULL UNIQUE CHECK(NIP LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    REGON       int NULL,
    KRS         int NULL,
    CompanyName int NOT NULL UNIQUE,
    CONSTRAINT Company_pk PRIMARY KEY (CustomerID)
);

-- Table: Country
CREATE TABLE Country
(
    CountryID   int           NOT NULL IDENTITY (1,1),
    CountryName nvarchar(255) NOT NULL UNIQUE,
    IsActive    bit           NOT NULL,
    CONSTRAINT Country_pk PRIMARY KEY (CountryID)
);

-- Table: Customer
CREATE TABLE Customer
(
    CustomerID int          NOT NULL IDENTITY (1,1),
    Email      nvarchar(50) NOT NULL UNIQUE CHECK(EMAIL LIKE N'%[@]%[.]%'),
    Phone      nvarchar(50) NULL CHECK(Phone LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    CityID     int          NOT NULL,
    Address    nvarchar(50) NOT NULL,
    PostalCode nvarchar(50) NOT NULL CHECK(PostalCode LIKE '[0-9][0-9]-[0-9][0-9][0-9]'),
    CONSTRAINT Customer_pk PRIMARY KEY (CustomerID)
);

-- Table: Discount
CREATE TABLE Discount
(
    DiscountID int           NOT NULL IDENTITY (1,1),
    Multiplier DECIMAL(3, 2) NOT NULL CHECK (Multiplier >= 0 and Multiplier <= 1),
    CONSTRAINT Discount_pk PRIMARY KEY (DiscountID)
);

-- Table: DiscountDetails
CREATE TABLE DiscountDetails
(
    CustomerID int  NOT NULL,
    DiscountID int  NOT NULL,
    StartDate  date NOT NULL,
    EndDate    date NULL,
    IsActive   bit  NULL,
    CONSTRAINT DiscountDetails_pk PRIMARY KEY (CustomerID, DiscountID)
);

-- Table: Dish
CREATE TABLE Dish
(
    DishID      int           NOT NULL IDENTITY (1,1),
    Name        nvarchar(255) NOT NULL,
    IsSeafood   bit           NOT NULL,
    Price       money         NOT NULL check (Price > 0),
    IsAvailable bit           NOT NULL,
    CONSTRAINT Dish_pk PRIMARY KEY (DishID)
);

-- Table: Employee
CREATE TABLE Employee
(
    EmployeeID        int          NOT NULL IDENTITY (1,1),
    CustomerID        int          NOT NULL,
    EmployeeFirstName nvarchar(50) NOT NULL,
    EmployeeLastName  nvarchar(50) NOT NULL,
    CONSTRAINT Employee_pk PRIMARY KEY (EmployeeID)
);

-- Table: EmployeeDetails
CREATE TABLE EmployeeDetails
(
    EmployeeID int NOT NULL,
    OrderID    int NOT NULL,
    CONSTRAINT EmployeeDetails_pk PRIMARY KEY (EmployeeID, OrderID)
);

-- Table: IndividualCustomer
CREATE TABLE IndividualCustomer
(
    CustomerID int          NOT NULL,
    FirstName  nvarchar(50) NOT NULL,
    LastName   nvarchar(50) NOT NULL,
    CONSTRAINT IndividualCustomer_pk PRIMARY KEY (CustomerID)
);

-- Table: Invoice
CREATE TABLE Invoice
(
    InvoiceID       int          NOT NULL IDENTITY (1,1),
    InvoiceNum      nvarchar(50) NOT NULL,
    InvoiceDate     date         NOT NULL,
    DueDate         date         NOT NULL,
    CustomerID      int          NOT NULL,
    PaymentStatusID int          NOT NULL,
    CountryName     nvarchar(50) NOT NULL,
    CityName        nvarchar(50) NOT NULL,
    Address         nvarchar(50) NOT NULL,
    PostalCode      nvarchar(50) NOT NULL,
    CONSTRAINT Invoice_pk PRIMARY KEY (InvoiceID)
);

-- Table: Menu
CREATE TABLE Menu
(
    MenuID     int  NOT NULL IDENTITY (1,1),
    DishID     int  NOT NULL,
    AddDate    date NOT NULL default getdate(),
    RemoveDate date NULL CHECK(AddDate < RemoveDate OR RemoveDate IS NULL),
    CONSTRAINT Menu_pk PRIMARY KEY (MenuID)
);

-- Table: Order
CREATE TABLE "Order"
(
    OrderID             int      NOT NULL IDENTITY (1,1),
    CustomerID          int      NOT NULL,
    OrderDate           datetime NOT NULL default getdate(),
    OrderCompletionDate datetime NOT NULL check (OrderCompletionDate >= getdate()),
    OrderStatusID       int      NOT NULL default 1,
    PaymentStatusID     int      NOT NULL default 1,
    InvoiceID           int      NOT NULL,
    OrderSum            money    NOT NULL check (OrderSum > 0),
    DurationTime        time     NULL,
    CONSTRAINT Order_ak_1 UNIQUE (OrderStatusID),
    CONSTRAINT Order_pk PRIMARY KEY (OrderID)
);

-- Table: OrderDetails
CREATE TABLE OrderDetails
(
    OrderID   int   NOT NULL,
    DishID    int   NOT NULL,
    BasePrice money NOT NULL check (BasePrice > 0),
    Quantity  int   NOT NULL check (Quantity >= 1),
    CONSTRAINT OrderDetails_pk PRIMARY KEY (OrderID, DishID)
);

-- Table: OrderStatus
CREATE TABLE OrderStatus
(
    OrderStatusID   int          NOT NULL IDENTITY (1,1),
    OrderStatusName nvarchar(50) NOT NULL,
    CONSTRAINT OrderStatus_pk PRIMARY KEY (OrderStatusID)
);

-- Table: PaymentStatus
CREATE TABLE PaymentStatus
(
    PaymentStatusID   int          NOT NULL IDENTITY (1,1),
    PaymentStatusName nvarchar(50) NOT NULL,
    CONSTRAINT PaymentStatus_pk PRIMARY KEY (PaymentStatusID)
);

-- Table: Reservation
CREATE TABLE Reservation
(
    OrderID int NOT NULL,
    TableID int NOT NULL,
    CONSTRAINT Reservation_pk PRIMARY KEY (TableID, OrderID)
);

-- Table: Table
CREATE TABLE "Table"
(
    TableID     int NOT NULL IDENTITY (1,1),
    ChairAmount int NOT NULL check (ChairAmount >= 2),
    isActive    bit NOT NULL default 1,
    CONSTRAINT Table_pk PRIMARY KEY (TableID)
);

-- foreign keys
-- Reference: Company_Customer (table: Company)
ALTER TABLE Company
    ADD CONSTRAINT Company_Customer
        FOREIGN KEY (CustomerID)
            REFERENCES Customer (CustomerID);

-- Reference: Customer_City (table: Customer)
ALTER TABLE Customer
    ADD CONSTRAINT Customer_City
        FOREIGN KEY (CityID)
            REFERENCES City (CityID);

-- Reference: DiscountDetails_Customer (table: DiscountDetails)
ALTER TABLE DiscountDetails
    ADD CONSTRAINT DiscountDetails_Customer
        FOREIGN KEY (CustomerID)
            REFERENCES Customer (CustomerID);

-- Reference: DiscountDetails_Discount (table: DiscountDetails)
ALTER TABLE DiscountDetails
    ADD CONSTRAINT DiscountDetails_Discount
        FOREIGN KEY (DiscountID)
            REFERENCES Discount (DiscountID);

-- Reference: EmployeeDetails_Employee (table: EmployeeDetails)
ALTER TABLE EmployeeDetails
    ADD CONSTRAINT EmployeeDetails_Employee
        FOREIGN KEY (EmployeeID)
            REFERENCES Employee (EmployeeID);

-- Reference: Employee_Company (table: Employee)
ALTER TABLE Employee
    ADD CONSTRAINT Employee_Company
        FOREIGN KEY (CustomerID)
            REFERENCES Company (CustomerID);

-- Reference: IndCustomer_Customer (table: IndividualCustomer)
ALTER TABLE IndividualCustomer
    ADD CONSTRAINT IndCustomer_Customer
        FOREIGN KEY (CustomerID)
            REFERENCES Customer (CustomerID);

-- Reference: Invoice_Customer (table: Invoice)
ALTER TABLE Invoice
    ADD CONSTRAINT Invoice_Customer
        FOREIGN KEY (CustomerID)
            REFERENCES Customer (CustomerID);

-- Reference: Invoice_Order (table: Order)
ALTER TABLE "Order"
    ADD CONSTRAINT Invoice_Order
        FOREIGN KEY (InvoiceID)
            REFERENCES Invoice (InvoiceID);

-- Reference: Menu_Dish (table: Menu)
ALTER TABLE Menu
    ADD CONSTRAINT Menu_Dish
        FOREIGN KEY (DishID)
            REFERENCES Dish (DishID);

-- Reference: OrderDetails_Dish (table: OrderDetails)
ALTER TABLE OrderDetails
    ADD CONSTRAINT OrderDetails_Dish
        FOREIGN KEY (DishID)
            REFERENCES Dish (DishID);

-- Reference: OrderDetails_Order (table: OrderDetails)
ALTER TABLE OrderDetails
    ADD CONSTRAINT OrderDetails_Order
        FOREIGN KEY (OrderID)
            REFERENCES "Order" (OrderID);

-- Reference: Order_EmployeeDetails (table: EmployeeDetails)
ALTER TABLE EmployeeDetails
    ADD CONSTRAINT Order_EmployeeDetails
        FOREIGN KEY (OrderID)
            REFERENCES "Order" (OrderID);

-- Reference: Order_OrderStatus (table: Order)
ALTER TABLE "Order"
    ADD CONSTRAINT Order_OrderStatus
        FOREIGN KEY (OrderStatusID)
            REFERENCES OrderStatus (OrderStatusID);

-- Reference: PaymentStatus_Invoice (table: Invoice)
ALTER TABLE Invoice
    ADD CONSTRAINT PaymentStatus_Invoice
        FOREIGN KEY (PaymentStatusID)
            REFERENCES PaymentStatus (PaymentStatusID);

-- Reference: PaymentStatus_Order (table: Order)
ALTER TABLE "Order"
    ADD CONSTRAINT PaymentStatus_Order
        FOREIGN KEY (PaymentStatusID)
            REFERENCES PaymentStatus (PaymentStatusID);

-- Reference: Reservation_Customer (table: Order)
ALTER TABLE "Order"
    ADD CONSTRAINT Reservation_Customer
        FOREIGN KEY (CustomerID)
            REFERENCES Customer (CustomerID);

-- Reference: Reservation_Order (table: Reservation)
ALTER TABLE Reservation
    ADD CONSTRAINT Reservation_Order
        FOREIGN KEY (OrderID)
            REFERENCES "Order" (OrderID);

-- Reference: Reservation_Table (table: Reservation)
ALTER TABLE Reservation
    ADD CONSTRAINT Reservation_Table
        FOREIGN KEY (TableID)
            REFERENCES "Table" (TableID);
```
