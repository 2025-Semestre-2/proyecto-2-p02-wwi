/* ============================================================================
   PROYECTO 2 - FRAGMENTACION DE DATOS
   SCRIPT UNIFICADO PARA CORPORATIVO (WWI_Corporativo)
   Contiene:
     - Tabla maestra de productos (Warehouse.StockItems_Master)
     - Tabla de datos sensibles de clientes (Sales.Customers_Sensitive)
     - Vistas consolidadas de:
         * Clientes
         * Clientes + datos sensibles
         * Facturas
         * Lineas de factura
         * Ordenes de compra
         * Lineas de orden de compra
         * Productos (catalogo + disponibilidad por sucursal)
   ============================================================================ */

-----------------------------
-- 0) CONTEXTO
-----------------------------
USE WWI_Corporativo;
GO


/* ============================================================================
   1) TABLA MAESTRA DE PRODUCTOS
      Warehouse.StockItems_Master
   ============================================================================ */

IF OBJECT_ID('Warehouse.StockItems_Master', 'U') IS NOT NULL
    DROP TABLE Warehouse.StockItems_Master;
GO

CREATE TABLE Warehouse.StockItems_Master (
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
    Photo               VARBINARY(MAX) NULL,
    CustomFields        NVARCHAR(MAX) NULL,
    Tags                NVARCHAR(MAX) NULL,
    SearchDetails       NVARCHAR(MAX) NULL,
    LastEditedBy        INT NOT NULL,
    ValidFrom           DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    ValidTo             DATETIME2(7) NOT NULL DEFAULT '9999-12-31 23:59:59.9999999',
    
    -- Metadatos de distribucion
    AvailableInSJ       BIT NOT NULL DEFAULT 0,
    AvailableInLIM      BIT NOT NULL DEFAULT 0,
    IsActive            BIT NOT NULL DEFAULT 1
);
GO

CREATE NONCLUSTERED INDEX IX_StockItems_Master_Name 
    ON Warehouse.StockItems_Master(StockItemName);

CREATE NONCLUSTERED INDEX IX_StockItems_Master_SupplierID 
    ON Warehouse.StockItems_Master(SupplierID);
GO


/* ============================================================================
   2) TABLA DE DATOS SENSIBLES DE CLIENTES
      Sales.Customers_Sensitive
   ============================================================================ */

IF OBJECT_ID('Sales.Customers_Sensitive', 'U') IS NOT NULL
    DROP TABLE Sales.Customers_Sensitive;
GO

CREATE TABLE Sales.Customers_Sensitive (
    CustomerID          INT NOT NULL PRIMARY KEY,
    
    -- Informacion de contacto (sensible)
    PhoneNumber         NVARCHAR(20) NOT NULL,
    FaxNumber           NVARCHAR(20) NOT NULL,
    WebsiteURL          NVARCHAR(256) NOT NULL,
    
    -- Informacion financiera (sensible)
    CreditLimit         DECIMAL(18,2) NULL,
    AccountOpenedDate   DATE NOT NULL,
    StandardDiscountPercentage DECIMAL(18,3) NOT NULL,
    IsStatementSent     BIT NOT NULL,
    IsOnCreditHold      BIT NOT NULL,
    PaymentDays         INT NOT NULL,
    
    -- Direcciones (sensible)
    DeliveryAddressLine1 NVARCHAR(60) NOT NULL,
    DeliveryAddressLine2 NVARCHAR(60) NULL,
    DeliveryPostalCode  NVARCHAR(10) NOT NULL,
    PostalAddressLine1  NVARCHAR(60) NOT NULL,
    PostalAddressLine2  NVARCHAR(60) NULL,
    PostalPostalCode    NVARCHAR(10) NOT NULL,
    
    -- Auditoria
    LastEditedBy        INT NOT NULL,
    ValidFrom           DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    ValidTo             DATETIME2(7) NOT NULL DEFAULT CAST('9999-12-31 23:59:59.9999999' AS DATETIME2(7))
);
GO

CREATE NONCLUSTERED INDEX IX_Customers_Sensitive_CreditLimit 
    ON Sales.Customers_Sensitive(CreditLimit);

CREATE NONCLUSTERED INDEX IX_Customers_Sensitive_OnCreditHold 
    ON Sales.Customers_Sensitive(IsOnCreditHold);
GO


/* ============================================================================
   3) VISTA CONSOLIDADA DE CLIENTES (NO SENSIBLE)
      Sales.vw_Customers_Consolidated
   ============================================================================ */

IF OBJECT_ID('Sales.vw_Customers_Consolidated', 'V') IS NOT NULL
    DROP VIEW Sales.vw_Customers_Consolidated;
GO

CREATE VIEW Sales.vw_Customers_Consolidated AS
    -- Clientes de San Jose
    SELECT 
        c.CustomerID,
        c.CustomerName,
        c.BillToCustomerID,
        c.CustomerCategoryID,
        c.BuyingGroupID,
        c.PrimaryContactPersonID,
        c.AlternateContactPersonID,
        c.DeliveryMethodID,
        c.DeliveryCityID,
        c.PostalCityID,
        c.CreditLimit,
        c.AccountOpenedDate,
        c.StandardDiscountPercentage,
        c.IsStatementSent,
        c.IsOnCreditHold,
        c.PaymentDays,
        c.PhoneNumber,
        c.FaxNumber,
        c.DeliveryRun,
        c.RunPosition,
        c.WebsiteURL,
        c.DeliveryAddressLine1,
        c.DeliveryAddressLine2,
        c.DeliveryPostalCode,
        c.DeliveryLocation,
        c.PostalAddressLine1,
        c.PostalAddressLine2,
        c.PostalPostalCode,
        c.LastEditedBy,
        c.ValidFrom,
        c.ValidTo,
        N'San Jose' AS Sucursal
    FROM WWI_Sucursal_SJ.Sales.Customers_SJ c

    UNION ALL

    -- Clientes de Limon
    SELECT 
        c.CustomerID,
        c.CustomerName,
        c.BillToCustomerID,
        c.CustomerCategoryID,
        c.BuyingGroupID,
        c.PrimaryContactPersonID,
        c.AlternateContactPersonID,
        c.DeliveryMethodID,
        c.DeliveryCityID,
        c.PostalCityID,
        c.CreditLimit,
        c.AccountOpenedDate,
        c.StandardDiscountPercentage,
        c.IsStatementSent,
        c.IsOnCreditHold,
        c.PaymentDays,
        c.PhoneNumber,
        c.FaxNumber,
        c.DeliveryRun,
        c.RunPosition,
        c.WebsiteURL,
        c.DeliveryAddressLine1,
        c.DeliveryAddressLine2,
        c.DeliveryPostalCode,
        c.DeliveryLocation,
        c.PostalAddressLine1,
        c.PostalAddressLine2,
        c.PostalPostalCode,
        c.LastEditedBy,
        c.ValidFrom,
        c.ValidTo,
        N'Limon' AS Sucursal
    FROM WWI_Sucursal_LIM.Sales.Customers_LIM c;
GO


/* ============================================================================
   4) VISTA COMPLETA DE CLIENTES (NO SENSIBLE + SENSIBLE)
      Sales.vw_Customers_Complete
   ============================================================================ */

IF OBJECT_ID('Sales.vw_Customers_Complete', 'V') IS NOT NULL
    DROP VIEW Sales.vw_Customers_Complete;
GO

CREATE VIEW Sales.vw_Customers_Complete AS
    -- San Jose + datos sensibles
    SELECT 
        c.CustomerID,
        c.CustomerName,
        c.BillToCustomerID,
        c.CustomerCategoryID,
        c.BuyingGroupID,
        c.PrimaryContactPersonID,
        c.AlternateContactPersonID,
        c.DeliveryMethodID,
        c.DeliveryCityID,
        c.PostalCityID,
        N'San Jose' AS Sucursal,
        -- Sensible
        s.PhoneNumber,
        s.FaxNumber,
        s.WebsiteURL,
        s.CreditLimit,
        s.AccountOpenedDate,
        s.StandardDiscountPercentage,
        s.IsStatementSent,
        s.IsOnCreditHold,
        s.PaymentDays,
        s.DeliveryAddressLine1,
        s.DeliveryAddressLine2,
        s.DeliveryPostalCode,
        s.PostalAddressLine1,
        s.PostalAddressLine2,
        s.PostalPostalCode,
        s.LastEditedBy,
        s.ValidFrom,
        s.ValidTo
    FROM WWI_Sucursal_SJ.Sales.Customers_SJ c
    INNER JOIN Sales.Customers_Sensitive s
        ON c.CustomerID = s.CustomerID

    UNION ALL

    -- Limon + datos sensibles
    SELECT 
        c.CustomerID,
        c.CustomerName,
        c.BillToCustomerID,
        c.CustomerCategoryID,
        c.BuyingGroupID,
        c.PrimaryContactPersonID,
        c.AlternateContactPersonID,
        c.DeliveryMethodID,
        c.DeliveryCityID,
        c.PostalCityID,
        N'Limon' AS Sucursal,
        -- Sensible
        s.PhoneNumber,
        s.FaxNumber,
        s.WebsiteURL,
        s.CreditLimit,
        s.AccountOpenedDate,
        s.StandardDiscountPercentage,
        s.IsStatementSent,
        s.IsOnCreditHold,
        s.PaymentDays,
        s.DeliveryAddressLine1,
        s.DeliveryAddressLine2,
        s.DeliveryPostalCode,
        s.PostalAddressLine1,
        s.PostalAddressLine2,
        s.PostalPostalCode,
        s.LastEditedBy,
        s.ValidFrom,
        s.ValidTo
    FROM WWI_Sucursal_LIM.Sales.Customers_LIM c
    INNER JOIN Sales.Customers_Sensitive s
        ON c.CustomerID = s.CustomerID;
GO


/* ============================================================================
   5) VISTAS CONSOLIDADAS DE FACTURAS
      Sales.vw_Invoices_Consolidated
      Sales.vw_InvoiceLines_Consolidated
   ============================================================================ */

IF OBJECT_ID('Sales.vw_Invoices_Consolidated', 'V') IS NOT NULL
    DROP VIEW Sales.vw_Invoices_Consolidated;
GO

CREATE VIEW Sales.vw_Invoices_Consolidated AS
    SELECT 
        InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID,
        ContactPersonID, AccountsPersonID, SalespersonPersonID, PackedByPersonID,
        InvoiceDate, CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason,
        Comments, DeliveryInstructions, InternalComments, TotalDryItems,
        TotalChillerItems, DeliveryRun, RunPosition, ReturnedDeliveryData,
        ConfirmedDeliveryTime, ConfirmedReceivedBy, LastEditedBy, LastEditedWhen,
        Sucursal
    FROM WWI_Sucursal_SJ.Sales.Invoices_SJ

    UNION ALL

    SELECT 
        InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID,
        ContactPersonID, AccountsPersonID, SalespersonPersonID, PackedByPersonID,
        InvoiceDate, CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason,
        Comments, DeliveryInstructions, InternalComments, TotalDryItems,
        TotalChillerItems, DeliveryRun, RunPosition, ReturnedDeliveryData,
        ConfirmedDeliveryTime, ConfirmedReceivedBy, LastEditedBy, LastEditedWhen,
        Sucursal
    FROM WWI_Sucursal_LIM.Sales.Invoices_LIM;
GO


IF OBJECT_ID('Sales.vw_InvoiceLines_Consolidated', 'V') IS NOT NULL
    DROP VIEW Sales.vw_InvoiceLines_Consolidated;
GO

CREATE VIEW Sales.vw_InvoiceLines_Consolidated AS
    SELECT 
        il.InvoiceLineID,
        il.InvoiceID,
        il.StockItemID,
        il.Description,
        il.PackageTypeID,
        il.Quantity,
        il.UnitPrice,
        il.TaxRate,
        il.TaxAmount,
        il.LineProfit,
        il.ExtendedPrice,
        il.LastEditedBy,
        il.LastEditedWhen,
        i.Sucursal
    FROM WWI_Sucursal_SJ.Sales.InvoiceLines_SJ il
    INNER JOIN WWI_Sucursal_SJ.Sales.Invoices_SJ i 
        ON il.InvoiceID = i.InvoiceID

    UNION ALL

    SELECT 
        il.InvoiceLineID,
        il.InvoiceID,
        il.StockItemID,
        il.Description,
        il.PackageTypeID,
        il.Quantity,
        il.UnitPrice,
        il.TaxRate,
        il.TaxAmount,
        il.LineProfit,
        il.ExtendedPrice,
        il.LastEditedBy,
        il.LastEditedWhen,
        i.Sucursal
    FROM WWI_Sucursal_LIM.Sales.InvoiceLines_LIM il
    INNER JOIN WWI_Sucursal_LIM.Sales.Invoices_LIM i 
        ON il.InvoiceID = i.InvoiceID;
GO


/* ============================================================================
   6) VISTAS CONSOLIDADAS DE ORDENES DE COMPRA
      Purchasing.vw_PurchaseOrders_Consolidated
      Purchasing.vw_PurchaseOrderLines_Consolidated
   ============================================================================ */

IF OBJECT_ID('Purchasing.vw_PurchaseOrders_Consolidated', 'V') IS NOT NULL
    DROP VIEW Purchasing.vw_PurchaseOrders_Consolidated;
GO

CREATE VIEW Purchasing.vw_PurchaseOrders_Consolidated AS
    SELECT 
        PurchaseOrderID,
        SupplierID,
        OrderDate,
        DeliveryMethodID,
        ContactPersonID,
        ExpectedDeliveryDate,
        SupplierReference,
        IsOrderFinalized,
        Comments,
        InternalComments,
        LastEditedBy,
        LastEditedWhen,
        Sucursal
    FROM WWI_Sucursal_SJ.Purchasing.PurchaseOrders_SJ

    UNION ALL

    SELECT 
        PurchaseOrderID,
        SupplierID,
        OrderDate,
        DeliveryMethodID,
        ContactPersonID,
        ExpectedDeliveryDate,
        SupplierReference,
        IsOrderFinalized,
        Comments,
        InternalComments,
        LastEditedBy,
        LastEditedWhen,
        Sucursal
    FROM WWI_Sucursal_LIM.Purchasing.PurchaseOrders_LIM;
GO


IF OBJECT_ID('Purchasing.vw_PurchaseOrderLines_Consolidated', 'V') IS NOT NULL
    DROP VIEW Purchasing.vw_PurchaseOrderLines_Consolidated;
GO

CREATE VIEW Purchasing.vw_PurchaseOrderLines_Consolidated AS
    SELECT 
        pol.PurchaseOrderLineID,
        pol.PurchaseOrderID,
        pol.StockItemID,
        pol.OrderedOuters,
        pol.Description,
        pol.ReceivedOuters,
        pol.PackageTypeID,
        pol.ExpectedUnitPricePerOuter,
        pol.LastReceiptDate,
        pol.IsOrderLineFinalized,
        pol.LastEditedBy,
        pol.LastEditedWhen,
        po.Sucursal
    FROM WWI_Sucursal_SJ.Purchasing.PurchaseOrderLines_SJ pol
    INNER JOIN WWI_Sucursal_SJ.Purchasing.PurchaseOrders_SJ po
        ON pol.PurchaseOrderID = po.PurchaseOrderID

    UNION ALL

    SELECT 
        pol.PurchaseOrderLineID,
        pol.PurchaseOrderID,
        pol.StockItemID,
        pol.OrderedOuters,
        pol.Description,
        pol.ReceivedOuters,
        pol.PackageTypeID,
        pol.ExpectedUnitPricePerOuter,
        pol.LastReceiptDate,
        pol.IsOrderLineFinalized,
        pol.LastEditedBy,
        pol.LastEditedWhen,
        po.Sucursal
    FROM WWI_Sucursal_LIM.Purchasing.PurchaseOrderLines_LIM pol
    INNER JOIN WWI_Sucursal_LIM.Purchasing.PurchaseOrders_LIM po
        ON pol.PurchaseOrderID = po.PurchaseOrderID;
GO


/* ============================================================================
   7) VISTA CONSOLIDADA DE PRODUCTOS (CATALOGO + DISPONIBILIDAD)
      Warehouse.vw_StockItems_Consolidated
   ============================================================================ */

IF OBJECT_ID('Warehouse.vw_StockItems_Consolidated', 'V') IS NOT NULL
    DROP VIEW Warehouse.vw_StockItems_Consolidated;
GO

CREATE VIEW Warehouse.vw_StockItems_Consolidated AS
    SELECT 
        m.StockItemID,
        m.StockItemName,
        m.SupplierID,
        m.ColorID,
        m.UnitPackageID,
        m.OuterPackageID,
        m.Brand,
        m.Size,
        m.TaxRate,
        m.UnitPrice,
        m.RecommendedRetailPrice,
        m.IsActive,
        -- Flags de presencia por sucursal (basado en tablas fragmentadas)
        CASE WHEN sj.StockItemID IS NOT NULL THEN 1 ELSE 0 END AS EnSJ,
        CASE WHEN lim.StockItemID IS NOT NULL THEN 1 ELSE 0 END AS EnLIM
    FROM Warehouse.StockItems_Master m
    LEFT JOIN WWI_Sucursal_SJ.Warehouse.StockItems_SJ sj
        ON sj.StockItemID = m.StockItemID
    LEFT JOIN WWI_Sucursal_LIM.Warehouse.StockItems_LIM lim
        ON lim.StockItemID = m.StockItemID;
GO
