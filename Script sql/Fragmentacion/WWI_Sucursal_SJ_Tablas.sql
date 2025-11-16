/* ============================================================================
   PROYECTO 2 - FRAGMENTACION DE DATOS
   SCRIPT UNIFICADO PARA LA SUCURSAL SAN JOSE
   Base: WWI_Sucursal_SJ
   Contiene:
     - Clientes  (Sales.Customers_SJ)
     - Productos (Warehouse.StockItems_SJ)
     - Facturas  (Sales.Invoices_SJ, Sales.InvoiceLines_SJ)
     - Ordenes de compra (Purchasing.PurchaseOrders_SJ, Purchasing.PurchaseOrderLines_SJ)
   ============================================================================ */

-----------------------------
-- 1) CLIENTES - SAN JOSE
-----------------------------
USE WWI_Sucursal_SJ;
GO

IF OBJECT_ID('Sales.Customers_SJ', 'U') IS NOT NULL
    DROP TABLE Sales.Customers_SJ;
GO

CREATE TABLE Sales.Customers_SJ (
    CustomerID          INT NOT NULL PRIMARY KEY,
    CustomerName        NVARCHAR(100) NOT NULL,
    BillToCustomerID    INT NOT NULL,
    CustomerCategoryID  INT NOT NULL,
    BuyingGroupID       INT NULL,
    PrimaryContactPersonID INT NOT NULL,
    AlternateContactPersonID INT NULL,
    DeliveryMethodID    INT NOT NULL,
    DeliveryCityID      INT NOT NULL,
    PostalCityID        INT NOT NULL,
    CreditLimit         DECIMAL(18,2) NULL,
    AccountOpenedDate   DATE NOT NULL,
    StandardDiscountPercentage DECIMAL(18,3) NOT NULL,
    IsStatementSent     BIT NOT NULL,
    IsOnCreditHold      BIT NOT NULL,
    PaymentDays         INT NOT NULL,
    PhoneNumber         NVARCHAR(20) NOT NULL,
    FaxNumber           NVARCHAR(20) NOT NULL,
    DeliveryRun         NVARCHAR(5) NULL,
    RunPosition         NVARCHAR(5) NULL,
    WebsiteURL          NVARCHAR(256) NOT NULL,
    DeliveryAddressLine1 NVARCHAR(60) NOT NULL,
    DeliveryAddressLine2 NVARCHAR(60) NULL,
    DeliveryPostalCode  NVARCHAR(10) NOT NULL,
    DeliveryLocation    GEOGRAPHY NULL,
    PostalAddressLine1  NVARCHAR(60) NOT NULL,
    PostalAddressLine2  NVARCHAR(60) NULL,
    PostalPostalCode    NVARCHAR(10) NOT NULL,
    LastEditedBy        INT NOT NULL,
    ValidFrom           DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    ValidTo             DATETIME2(7) NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'
);
GO

CREATE NONCLUSTERED INDEX IX_Customers_SJ_CategoryID 
    ON Sales.Customers_SJ(CustomerCategoryID);
GO

CREATE NONCLUSTERED INDEX IX_Customers_SJ_BuyingGroupID 
    ON Sales.Customers_SJ(BuyingGroupID);
GO

CREATE NONCLUSTERED INDEX IX_Customers_SJ_PrimaryContact 
    ON Sales.Customers_SJ(PrimaryContactPersonID);
GO

-- Trigger para validar region (provincias centrales)
CREATE OR ALTER TRIGGER Sales.trg_Customers_SJ_ValidateRegion
ON Sales.Customers_SJ
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN WideWorldImporters.Application.Cities city
            ON i.DeliveryCityID = city.CityID
        JOIN WideWorldImporters.Application.StateProvinces sp
            ON city.StateProvinceID = sp.StateProvinceID
        WHERE sp.StateProvinceName NOT IN ('San José', 'Heredia', 'Alajuela', 'Cartago')
    )
    BEGIN
        RAISERROR('Solo se permiten clientes de San José, Heredia, Alajuela o Cartago en WWI_Sucursal_SJ.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO


-----------------------------
-- 2) PRODUCTOS - SAN JOSE
-----------------------------
USE WWI_Sucursal_SJ;
GO

IF OBJECT_ID('Warehouse.StockItems_SJ', 'U') IS NOT NULL
    DROP TABLE Warehouse.StockItems_SJ;
GO

CREATE TABLE Warehouse.StockItems_SJ (
    StockItemID         INT NOT NULL PRIMARY KEY,
    StockItemName       NVARCHAR(100) NOT NULL,
    SupplierID          INT NOT NULL,
    ColorID             INT NULL,
    UnitPackageID       INT NOT NULL,
    OuterPackageID      INT NOT NULL,
    Brand               NVARCHAR(50) NULL,
    Size                NVARCHAR(20) NULL,
    LeadTimeDays        INT NOT NULL,
    QuantityPerOuter    INT NOT NULL,
    IsChillerStock      BIT NOT NULL,
    Barcode             NVARCHAR(50) NULL,
    TaxRate             DECIMAL(18,3) NOT NULL,
    UnitPrice           DECIMAL(18,2) NOT NULL,
    RecommendedRetailPrice DECIMAL(18,2) NULL,
    TypicalWeightPerUnit DECIMAL(18,3) NOT NULL,
    MarketingComments   NVARCHAR(MAX) NULL,
    InternalComments    NVARCHAR(MAX) NULL,
    CustomFields        NVARCHAR(MAX) NULL,
    Tags                NVARCHAR(MAX) NULL,
    LastEditedBy        INT NOT NULL,
    ValidFrom           DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    ValidTo             DATETIME2(7) NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'
);
GO

CREATE NONCLUSTERED INDEX IX_StockItems_SJ_SupplierID 
    ON Warehouse.StockItems_SJ(SupplierID);
GO

CREATE NONCLUSTERED INDEX IX_StockItems_SJ_UnitPrice 
    ON Warehouse.StockItems_SJ(UnitPrice);
GO


-----------------------------
-- 3) FACTURAS - SAN JOSE
-----------------------------
USE WWI_Sucursal_SJ;
GO

IF OBJECT_ID('Sales.Invoices_SJ', 'U') IS NOT NULL
    DROP TABLE Sales.Invoices_SJ;
GO

CREATE TABLE Sales.Invoices_SJ (
    InvoiceID           INT NOT NULL PRIMARY KEY,
    CustomerID          INT NOT NULL,
    BillToCustomerID    INT NOT NULL,
    OrderID             INT NOT NULL,
    DeliveryMethodID    INT NOT NULL,
    ContactPersonID     INT NOT NULL,
    AccountsPersonID    INT NOT NULL,
    SalespersonPersonID INT NOT NULL,
    PackedByPersonID    INT NOT NULL,
    InvoiceDate         DATE NOT NULL,
    CustomerPurchaseOrderNumber NVARCHAR(20) NULL,
    IsCreditNote        BIT NOT NULL,
    CreditNoteReason    NVARCHAR(MAX) NULL,
    Comments            NVARCHAR(MAX) NULL,
    DeliveryInstructions NVARCHAR(MAX) NULL,
    InternalComments    NVARCHAR(MAX) NULL,
    TotalDryItems       INT NOT NULL,
    TotalChillerItems   INT NOT NULL,
    DeliveryRun         NVARCHAR(5) NULL,
    RunPosition         NVARCHAR(5) NULL,
    ReturnedDeliveryData NVARCHAR(MAX) NULL,
    ConfirmedDeliveryTime DATETIME2(7) NULL,
    ConfirmedReceivedBy NVARCHAR(4000) NULL,
    LastEditedBy        INT NOT NULL,
    LastEditedWhen      DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    Sucursal            NVARCHAR(50) NOT NULL DEFAULT 'San José',
    CONSTRAINT CHK_Invoices_SJ_Sucursal CHECK (Sucursal = 'San José')
);
GO

CREATE NONCLUSTERED INDEX IX_Invoices_SJ_CustomerID 
    ON Sales.Invoices_SJ(CustomerID);
GO

CREATE NONCLUSTERED INDEX IX_Invoices_SJ_InvoiceDate 
    ON Sales.Invoices_SJ(InvoiceDate);
GO


IF OBJECT_ID('Sales.InvoiceLines_SJ', 'U') IS NOT NULL
    DROP TABLE Sales.InvoiceLines_SJ;
GO

CREATE TABLE Sales.InvoiceLines_SJ (
    InvoiceLineID       INT NOT NULL PRIMARY KEY,
    InvoiceID           INT NOT NULL,
    StockItemID         INT NOT NULL,
    Description         NVARCHAR(100) NOT NULL,
    PackageTypeID       INT NOT NULL,
    Quantity            INT NOT NULL,
    UnitPrice           DECIMAL(18,2) NOT NULL,
    TaxRate             DECIMAL(18,3) NOT NULL,
    TaxAmount           DECIMAL(18,2) NOT NULL,
    LineProfit          DECIMAL(18,2) NOT NULL,
    ExtendedPrice       DECIMAL(18,2) NOT NULL,
    LastEditedBy        INT NOT NULL,
    LastEditedWhen      DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE NONCLUSTERED INDEX IX_InvoiceLines_SJ_InvoiceID 
    ON Sales.InvoiceLines_SJ(InvoiceID);
GO

CREATE NONCLUSTERED INDEX IX_InvoiceLines_SJ_StockItemID 
    ON Sales.InvoiceLines_SJ(StockItemID);
GO


-----------------------------
-- 4) ORDENES DE COMPRA - SAN JOSE
-----------------------------
USE WWI_Sucursal_SJ;
GO

IF OBJECT_ID('Purchasing.PurchaseOrders_SJ', 'U') IS NOT NULL
    DROP TABLE Purchasing.PurchaseOrders_SJ;
GO

CREATE TABLE Purchasing.PurchaseOrders_SJ (
    PurchaseOrderID     INT NOT NULL PRIMARY KEY,
    SupplierID          INT NOT NULL,
    OrderDate           DATE NOT NULL,
    DeliveryMethodID    INT NOT NULL,
    ContactPersonID     INT NOT NULL,
    ExpectedDeliveryDate DATE NOT NULL,
    SupplierReference   NVARCHAR(20) NULL,
    IsOrderFinalized    BIT NOT NULL,
    Comments            NVARCHAR(MAX) NULL,
    InternalComments    NVARCHAR(MAX) NULL,
    LastEditedBy        INT NOT NULL,
    LastEditedWhen      DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    Sucursal            NVARCHAR(50) NOT NULL DEFAULT 'San José',
    CONSTRAINT CHK_PurchaseOrders_SJ CHECK (Sucursal = 'San José')
);
GO

CREATE NONCLUSTERED INDEX IX_PurchaseOrders_SJ_SupplierID 
    ON Purchasing.PurchaseOrders_SJ(SupplierID);
GO

CREATE NONCLUSTERED INDEX IX_PurchaseOrders_SJ_OrderDate 
    ON Purchasing.PurchaseOrders_SJ(OrderDate);
GO

CREATE NONCLUSTERED INDEX IX_PurchaseOrders_SJ_Date_Supplier 
    ON Purchasing.PurchaseOrders_SJ(OrderDate, SupplierID);
GO


IF OBJECT_ID('Purchasing.PurchaseOrderLines_SJ', 'U') IS NOT NULL
    DROP TABLE Purchasing.PurchaseOrderLines_SJ;
GO

CREATE TABLE Purchasing.PurchaseOrderLines_SJ (
    PurchaseOrderLineID INT NOT NULL PRIMARY KEY,
    PurchaseOrderID     INT NOT NULL,
    StockItemID         INT NOT NULL,
    OrderedOuters       INT NOT NULL,
    Description         NVARCHAR(100) NOT NULL,
    ReceivedOuters      INT NOT NULL,
    PackageTypeID       INT NOT NULL,
    ExpectedUnitPricePerOuter DECIMAL(18,2) NOT NULL,
    LastReceiptDate     DATE NULL,
    IsOrderLineFinalized BIT NOT NULL,
    LastEditedBy        INT NOT NULL,
    LastEditedWhen      DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE NONCLUSTERED INDEX IX_PurchaseOrderLines_SJ_PurchaseOrderID 
    ON Purchasing.PurchaseOrderLines_SJ(PurchaseOrderID);
GO

CREATE NONCLUSTERED INDEX IX_PurchaseOrderLines_SJ_StockItemID 
    ON Purchasing.PurchaseOrderLines_SJ(StockItemID);
GO
