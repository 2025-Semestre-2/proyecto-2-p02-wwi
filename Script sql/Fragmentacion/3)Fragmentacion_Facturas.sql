/*
================================================================================
PROYECTO 2 - FRAGMENTACIÓN DE DATOS: FACTURAS (VENTAS) - VERSIÓN LIMPIA
================================================================================
Estrategia: FRAGMENTACIÓN HORIZONTAL por sucursal
- San José: Facturas emitidas en sucursal SJ
- Limón: Facturas emitidas en sucursal Limón
- Corporativo: Vista consolidada de todas las ventas
================================================================================
*/

USE WWI_Sucursal_SJ;
GO

-- ========================================
-- 1) TABLA FRAGMENTADA EN SAN JOSÉ
-- ========================================
IF OBJECT_ID('Sales.InvoiceLines_SJ', 'U') IS NOT NULL
    DROP TABLE Sales.InvoiceLines_SJ;
GO

IF OBJECT_ID('Sales.Invoices_SJ', 'U') IS NOT NULL
    DROP TABLE Sales.Invoices_SJ;
GO

CREATE TABLE Sales.Invoices_SJ (
    InvoiceID           INT NOT NULL PRIMARY KEY,
    CustomerID          INT NOT NULL,
    BillToCustomerID    INT NOT NULL,
    OrderID             INT NULL,
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
    CONSTRAINT CHK_Invoices_SJ CHECK (Sucursal = 'San José')
);
GO

CREATE NONCLUSTERED INDEX IX_Invoices_SJ_CustomerID ON Sales.Invoices_SJ(CustomerID);
CREATE NONCLUSTERED INDEX IX_Invoices_SJ_InvoiceDate ON Sales.Invoices_SJ(InvoiceDate);
CREATE NONCLUSTERED INDEX IX_Invoices_SJ_Date_Customer ON Sales.Invoices_SJ(InvoiceDate, CustomerID);
GO

CREATE TABLE Sales.InvoiceLines_SJ (
    InvoiceLineID       INT NOT NULL PRIMARY KEY,
    InvoiceID           INT NOT NULL,
    StockItemID         INT NOT NULL,
    Description         NVARCHAR(100) NOT NULL,
    PackageTypeID       INT NOT NULL,
    Quantity            INT NOT NULL,
    UnitPrice           DECIMAL(18,2) NULL,
    TaxRate             DECIMAL(18,3) NOT NULL,
    TaxAmount           DECIMAL(18,2) NOT NULL,
    LineProfit          DECIMAL(18,2) NOT NULL,
    ExtendedPrice       DECIMAL(18,2) NOT NULL,
    LastEditedBy        INT NOT NULL,
    LastEditedWhen      DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_InvoiceLines_SJ_Invoice FOREIGN KEY (InvoiceID) 
        REFERENCES Sales.Invoices_SJ(InvoiceID)
);
GO

CREATE NONCLUSTERED INDEX IX_InvoiceLines_SJ_InvoiceID ON Sales.InvoiceLines_SJ(InvoiceID);
CREATE NONCLUSTERED INDEX IX_InvoiceLines_SJ_StockItemID ON Sales.InvoiceLines_SJ(StockItemID);
GO

PRINT '✅ Tablas Sales.Invoices_SJ y InvoiceLines_SJ creadas en WWI_Sucursal_SJ';
GO


-- ========================================
-- 2) TABLA FRAGMENTADA EN LIMÓN
-- ========================================
USE WWI_Sucursal_LIM;
GO

IF OBJECT_ID('Sales.InvoiceLines_LIM', 'U') IS NOT NULL
    DROP TABLE Sales.InvoiceLines_LIM;
GO

IF OBJECT_ID('Sales.Invoices_LIM', 'U') IS NOT NULL
    DROP TABLE Sales.Invoices_LIM;
GO

CREATE TABLE Sales.Invoices_LIM (
    InvoiceID           INT NOT NULL PRIMARY KEY,
    CustomerID          INT NOT NULL,
    BillToCustomerID    INT NOT NULL,
    OrderID             INT NULL,
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
    Sucursal            NVARCHAR(50) NOT NULL DEFAULT 'Limón',
    CONSTRAINT CHK_Invoices_LIM CHECK (Sucursal = 'Limón')
);
GO

CREATE NONCLUSTERED INDEX IX_Invoices_LIM_CustomerID ON Sales.Invoices_LIM(CustomerID);
CREATE NONCLUSTERED INDEX IX_Invoices_LIM_InvoiceDate ON Sales.Invoices_LIM(InvoiceDate);
CREATE NONCLUSTERED INDEX IX_Invoices_LIM_Date_Customer ON Sales.Invoices_LIM(InvoiceDate, CustomerID);
GO

CREATE TABLE Sales.InvoiceLines_LIM (
    InvoiceLineID       INT NOT NULL PRIMARY KEY,
    InvoiceID           INT NOT NULL,
    StockItemID         INT NOT NULL,
    Description         NVARCHAR(100) NOT NULL,
    PackageTypeID       INT NOT NULL,
    Quantity            INT NOT NULL,
    UnitPrice           DECIMAL(18,2) NULL,
    TaxRate             DECIMAL(18,3) NOT NULL,
    TaxAmount           DECIMAL(18,2) NOT NULL,
    LineProfit          DECIMAL(18,2) NOT NULL,
    ExtendedPrice       DECIMAL(18,2) NOT NULL,
    LastEditedBy        INT NOT NULL,
    LastEditedWhen      DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_InvoiceLines_LIM_Invoice FOREIGN KEY (InvoiceID) 
        REFERENCES Sales.Invoices_LIM(InvoiceID)
);
GO

CREATE NONCLUSTERED INDEX IX_InvoiceLines_LIM_InvoiceID ON Sales.InvoiceLines_LIM(InvoiceID);
CREATE NONCLUSTERED INDEX IX_InvoiceLines_LIM_StockItemID ON Sales.InvoiceLines_LIM(StockItemID);
GO

PRINT '✅ Tablas Sales.Invoices_LIM y InvoiceLines_LIM creadas en WWI_Sucursal_LIM';
GO


-- ========================================
-- 3) VISTAS CONSOLIDADAS EN CORPORATIVO
-- ========================================
USE WWI_Corporativo;
GO

IF OBJECT_ID('Sales.vw_Invoices_Consolidated', 'V') IS NOT NULL
    DROP VIEW Sales.vw_Invoices_Consolidated;
GO

CREATE VIEW Sales.vw_Invoices_Consolidated AS
SELECT InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID,
       ContactPersonID, AccountsPersonID, SalespersonPersonID, PackedByPersonID,
       InvoiceDate, CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason,
       Comments, DeliveryInstructions, InternalComments, TotalDryItems,
       TotalChillerItems, DeliveryRun, RunPosition, ReturnedDeliveryData,
       ConfirmedDeliveryTime, ConfirmedReceivedBy, LastEditedBy, LastEditedWhen, Sucursal
FROM WWI_Sucursal_SJ.Sales.Invoices_SJ
UNION ALL
SELECT InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID,
       ContactPersonID, AccountsPersonID, SalespersonPersonID, PackedByPersonID,
       InvoiceDate, CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason,
       Comments, DeliveryInstructions, InternalComments, TotalDryItems,
       TotalChillerItems, DeliveryRun, RunPosition, ReturnedDeliveryData,
       ConfirmedDeliveryTime, ConfirmedReceivedBy, LastEditedBy, LastEditedWhen, Sucursal
FROM WWI_Sucursal_LIM.Sales.Invoices_LIM;
GO

IF OBJECT_ID('Sales.vw_InvoiceLines_Consolidated', 'V') IS NOT NULL
    DROP VIEW Sales.vw_InvoiceLines_Consolidated;
GO

CREATE VIEW Sales.vw_InvoiceLines_Consolidated AS
SELECT il.InvoiceLineID, il.InvoiceID, il.StockItemID, il.Description, il.PackageTypeID,
       il.Quantity, il.UnitPrice, il.TaxRate, il.TaxAmount, il.LineProfit,
       il.ExtendedPrice, il.LastEditedBy, il.LastEditedWhen, i.Sucursal
FROM WWI_Sucursal_SJ.Sales.InvoiceLines_SJ il
INNER JOIN WWI_Sucursal_SJ.Sales.Invoices_SJ i ON il.InvoiceID = i.InvoiceID
UNION ALL
SELECT il.InvoiceLineID, il.InvoiceID, il.StockItemID, il.Description, il.PackageTypeID,
       il.Quantity, il.UnitPrice, il.TaxRate, il.TaxAmount, il.LineProfit,
       il.ExtendedPrice, il.LastEditedBy, il.LastEditedWhen, i.Sucursal
FROM WWI_Sucursal_LIM.Sales.InvoiceLines_LIM il
INNER JOIN WWI_Sucursal_LIM.Sales.Invoices_LIM i ON il.InvoiceID = i.InvoiceID;
GO

CREATE OR ALTER VIEW Sales.vw_Sales_Summary AS
SELECT i.Sucursal, i.InvoiceDate, YEAR(i.InvoiceDate) AS Año, MONTH(i.InvoiceDate) AS Mes,
       COUNT(DISTINCT i.InvoiceID) AS NumeroFacturas, COUNT(DISTINCT i.CustomerID) AS ClientesUnicos,
       SUM(il.Quantity) AS UnidadesVendidas, SUM(il.ExtendedPrice) AS VentasBrutas,
       SUM(il.TaxAmount) AS TotalImpuestos, SUM(il.LineProfit) AS UtilidadTotal,
       AVG(il.ExtendedPrice) AS VentaPromedioPorLinea
FROM Sales.vw_Invoices_Consolidated i
INNER JOIN Sales.vw_InvoiceLines_Consolidated il ON i.InvoiceID = il.InvoiceID
WHERE i.IsCreditNote = 0
GROUP BY i.Sucursal, i.InvoiceDate, YEAR(i.InvoiceDate), MONTH(i.InvoiceDate);
GO

PRINT '✅ Vistas consolidadas creadas en WWI_Corporativo';
GO


-- ========================================
-- 4) PROCEDIMIENTO PARA DISTRIBUIR FACTURAS
-- ========================================
CREATE OR ALTER PROCEDURE Sales.sp_DistribuirFacturas
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @inv_sj INT = 0, @inv_lim INT = 0, @lin_sj INT = 0, @lin_lim INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        INSERT INTO WWI_Sucursal_SJ.Sales.Invoices_SJ
        SELECT InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID,
               ContactPersonID, AccountsPersonID, SalespersonPersonID, PackedByPersonID,
               InvoiceDate, CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason,
               Comments, DeliveryInstructions, InternalComments, TotalDryItems,
               TotalChillerItems, DeliveryRun, RunPosition, ReturnedDeliveryData,
               ConfirmedDeliveryTime, ConfirmedReceivedBy, LastEditedBy, LastEditedWhen, 'San José'
        FROM WideWorldImporters.Sales.Invoices
        WHERE InvoiceID % 2 = 1 AND NOT EXISTS (SELECT 1 FROM WWI_Sucursal_SJ.Sales.Invoices_SJ sj WHERE sj.InvoiceID = Invoices.InvoiceID);
        SET @inv_sj = @@ROWCOUNT;
        
        INSERT INTO WWI_Sucursal_SJ.Sales.InvoiceLines_SJ
        SELECT il.InvoiceLineID, il.InvoiceID, il.StockItemID, il.Description, il.PackageTypeID,
               il.Quantity, il.UnitPrice, il.TaxRate, il.TaxAmount, il.LineProfit, il.ExtendedPrice,
               il.LastEditedBy, il.LastEditedWhen
        FROM WideWorldImporters.Sales.InvoiceLines il
        INNER JOIN WWI_Sucursal_SJ.Sales.Invoices_SJ i ON il.InvoiceID = i.InvoiceID
        WHERE NOT EXISTS (SELECT 1 FROM WWI_Sucursal_SJ.Sales.InvoiceLines_SJ sj WHERE sj.InvoiceLineID = il.InvoiceLineID);
        SET @lin_sj = @@ROWCOUNT;
        
        INSERT INTO WWI_Sucursal_LIM.Sales.Invoices_LIM
        SELECT InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID,
               ContactPersonID, AccountsPersonID, SalespersonPersonID, PackedByPersonID,
               InvoiceDate, CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason,
               Comments, DeliveryInstructions, InternalComments, TotalDryItems,
               TotalChillerItems, DeliveryRun, RunPosition, ReturnedDeliveryData,
               ConfirmedDeliveryTime, ConfirmedReceivedBy, LastEditedBy, LastEditedWhen, 'Limón'
        FROM WideWorldImporters.Sales.Invoices
        WHERE InvoiceID % 2 = 0 AND NOT EXISTS (SELECT 1 FROM WWI_Sucursal_LIM.Sales.Invoices_LIM lim WHERE lim.InvoiceID = Invoices.InvoiceID);
        SET @inv_lim = @@ROWCOUNT;
        
        INSERT INTO WWI_Sucursal_LIM.Sales.InvoiceLines_LIM
        SELECT il.InvoiceLineID, il.InvoiceID, il.StockItemID, il.Description, il.PackageTypeID,
               il.Quantity, il.UnitPrice, il.TaxRate, il.TaxAmount, il.LineProfit, il.ExtendedPrice,
               il.LastEditedBy, il.LastEditedWhen
        FROM WideWorldImporters.Sales.InvoiceLines il
        INNER JOIN WWI_Sucursal_LIM.Sales.Invoices_LIM i ON il.InvoiceID = i.InvoiceID
        WHERE NOT EXISTS (SELECT 1 FROM WWI_Sucursal_LIM.Sales.InvoiceLines_LIM lim WHERE lim.InvoiceLineID = il.InvoiceLineID);
        SET @lin_lim = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        DECLARE @tot_inv INT = (SELECT COUNT(*) FROM Sales.vw_Invoices_Consolidated);
        DECLARE @tot_lin INT = (SELECT COUNT(*) FROM Sales.vw_InvoiceLines_Consolidated);
        DECLARE @amt_sj DECIMAL(18,2) = (SELECT ISNULL(SUM(ExtendedPrice), 0) FROM WWI_Sucursal_SJ.Sales.InvoiceLines_SJ);
        DECLARE @amt_lim DECIMAL(18,2) = (SELECT ISNULL(SUM(ExtendedPrice), 0) FROM WWI_Sucursal_LIM.Sales.InvoiceLines_LIM);
        DECLARE @prf_sj DECIMAL(18,2) = (SELECT ISNULL(SUM(LineProfit), 0) FROM WWI_Sucursal_SJ.Sales.InvoiceLines_SJ);
        DECLARE @prf_lim DECIMAL(18,2) = (SELECT ISNULL(SUM(LineProfit), 0) FROM WWI_Sucursal_LIM.Sales.InvoiceLines_LIM);
        
        PRINT '';
        PRINT '=================== RESUMEN FRAGMENTACION FACTURAS ===================';
        PRINT CONCAT('San Jose - Facturas: ', @inv_sj, ' | Lineas: ', @lin_sj);
        PRINT CONCAT('  Ventas: $', FORMAT(@amt_sj, 'N2'), ' | Utilidad: $', FORMAT(@prf_sj, 'N2'));
        PRINT CONCAT('Limon - Facturas: ', @inv_lim, ' | Lineas: ', @lin_lim);
        PRINT CONCAT('  Ventas: $', FORMAT(@amt_lim, 'N2'), ' | Utilidad: $', FORMAT(@prf_lim, 'N2'));
        PRINT CONCAT('TOTAL - Facturas: ', @tot_inv, ' | Lineas: ', @tot_lin);
        PRINT CONCAT('  Ventas: $', FORMAT(@amt_sj + @amt_lim, 'N2'), ' | Utilidad: $', FORMAT(@prf_sj + @prf_lim, 'N2'));
        PRINT '======================================================================';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT CONCAT('ERROR: ', @Err);
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

PRINT '✅ Procedimiento Sales.sp_DistribuirFacturas creado';
PRINT '';
PRINT 'EJECUTAR: EXEC WWI_Corporativo.Sales.sp_DistribuirFacturas;';
GO

EXEC WWI_Corporativo.Sales.sp_DistribuirFacturas;