/*
================================================================================
PROYECTO 2 - FRAGMENTACIÓN DE DATOS: ÓRDENES DE COMPRA
================================================================================
Estrategia: FRAGMENTACIÓN HORIZONTAL por sucursal
- San José: Órdenes de compra realizadas por sucursal SJ
- Limón: Órdenes de compra realizadas por sucursal Limón
- Corporativo: Vista consolidada de todas las compras
================================================================================
*/

USE WWI_Sucursal_SJ;
GO

-- ========================================
-- 1) TABLA FRAGMENTADA EN SAN JOSÉ
-- ========================================
IF OBJECT_ID('Purchasing.PurchaseOrders_SJ', 'U') IS NOT NULL
    DROP TABLE Purchasing.PurchaseOrders_SJ;
GO

CREATE TABLE Purchasing.PurchaseOrders_SJ (
    PurchaseOrderID     INT NOT NULL PRIMARY KEY,
    SupplierID          INT NOT NULL,
    OrderDate           DATE NOT NULL,
    DeliveryMethodID    INT NOT NULL,
    ContactPersonID     INT NOT NULL,
    ExpectedDeliveryDate DATE NULL,
    SupplierReference   NVARCHAR(20) NULL,
    IsOrderFinalized    BIT NOT NULL,
    Comments            NVARCHAR(MAX) NULL,
    InternalComments    NVARCHAR(MAX) NULL,
    LastEditedBy        INT NOT NULL,
    LastEditedWhen      DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Metadatos de sucursal
    Sucursal            NVARCHAR(50) NOT NULL DEFAULT 'San José',
    
    -- CONSTRAINT: Solo órdenes de San José
    CONSTRAINT CHK_PurchaseOrders_SJ CHECK (Sucursal = 'San José')
);
GO

CREATE NONCLUSTERED INDEX IX_PurchaseOrders_SJ_SupplierID ON Purchasing.PurchaseOrders_SJ(SupplierID);
CREATE NONCLUSTERED INDEX IX_PurchaseOrders_SJ_OrderDate ON Purchasing.PurchaseOrders_SJ(OrderDate);
CREATE NONCLUSTERED INDEX IX_PurchaseOrders_SJ_Date_Supplier ON Purchasing.PurchaseOrders_SJ(OrderDate, SupplierID);
GO

-- Tabla de líneas de orden de compra
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
    ExpectedUnitPricePerOuter DECIMAL(18,2) NULL,
    LastReceiptDate     DATE NULL,
    IsOrderLineFinalized BIT NOT NULL,
    LastEditedBy        INT NOT NULL,
    LastEditedWhen      DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    
    CONSTRAINT FK_PurchaseOrderLines_SJ_Order FOREIGN KEY (PurchaseOrderID) 
        REFERENCES Purchasing.PurchaseOrders_SJ(PurchaseOrderID)
);
GO

CREATE NONCLUSTERED INDEX IX_PurchaseOrderLines_SJ_OrderID ON Purchasing.PurchaseOrderLines_SJ(PurchaseOrderID);
CREATE NONCLUSTERED INDEX IX_PurchaseOrderLines_SJ_StockItemID ON Purchasing.PurchaseOrderLines_SJ(StockItemID);
GO

PRINT '✅ Tablas Purchasing.PurchaseOrders_SJ y PurchaseOrderLines_SJ creadas en WWI_Sucursal_SJ';
GO


-- ========================================
-- 2) TABLA FRAGMENTADA EN LIMÓN
-- ========================================
USE WWI_Sucursal_LIM;
GO

IF OBJECT_ID('Purchasing.PurchaseOrders_LIM', 'U') IS NOT NULL
    DROP TABLE Purchasing.PurchaseOrders_LIM;
GO

CREATE TABLE Purchasing.PurchaseOrders_LIM (
    PurchaseOrderID     INT NOT NULL PRIMARY KEY,
    SupplierID          INT NOT NULL,
    OrderDate           DATE NOT NULL,
    DeliveryMethodID    INT NOT NULL,
    ContactPersonID     INT NOT NULL,
    ExpectedDeliveryDate DATE NULL,
    SupplierReference   NVARCHAR(20) NULL,
    IsOrderFinalized    BIT NOT NULL,
    Comments            NVARCHAR(MAX) NULL,
    InternalComments    NVARCHAR(MAX) NULL,
    LastEditedBy        INT NOT NULL,
    LastEditedWhen      DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Metadatos de sucursal
    Sucursal            NVARCHAR(50) NOT NULL DEFAULT 'Limón',
    
    -- CONSTRAINT: Solo órdenes de Limón
    CONSTRAINT CHK_PurchaseOrders_LIM CHECK (Sucursal = 'Limón')
);
GO

CREATE NONCLUSTERED INDEX IX_PurchaseOrders_LIM_SupplierID ON Purchasing.PurchaseOrders_LIM(SupplierID);
CREATE NONCLUSTERED INDEX IX_PurchaseOrders_LIM_OrderDate ON Purchasing.PurchaseOrders_LIM(OrderDate);
CREATE NONCLUSTERED INDEX IX_PurchaseOrders_LIM_Date_Supplier ON Purchasing.PurchaseOrders_LIM(OrderDate, SupplierID);
GO

-- Tabla de líneas de orden de compra
IF OBJECT_ID('Purchasing.PurchaseOrderLines_LIM', 'U') IS NOT NULL
    DROP TABLE Purchasing.PurchaseOrderLines_LIM;
GO

CREATE TABLE Purchasing.PurchaseOrderLines_LIM (
    PurchaseOrderLineID INT NOT NULL PRIMARY KEY,
    PurchaseOrderID     INT NOT NULL,
    StockItemID         INT NOT NULL,
    OrderedOuters       INT NOT NULL,
    Description         NVARCHAR(100) NOT NULL,
    ReceivedOuters      INT NOT NULL,
    PackageTypeID       INT NOT NULL,
    ExpectedUnitPricePerOuter DECIMAL(18,2) NULL,
    LastReceiptDate     DATE NULL,
    IsOrderLineFinalized BIT NOT NULL,
    LastEditedBy        INT NOT NULL,
    LastEditedWhen      DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    
    CONSTRAINT FK_PurchaseOrderLines_LIM_Order FOREIGN KEY (PurchaseOrderID) 
        REFERENCES Purchasing.PurchaseOrders_LIM(PurchaseOrderID)
);
GO

CREATE NONCLUSTERED INDEX IX_PurchaseOrderLines_LIM_OrderID ON Purchasing.PurchaseOrderLines_LIM(PurchaseOrderID);
CREATE NONCLUSTERED INDEX IX_PurchaseOrderLines_LIM_StockItemID ON Purchasing.PurchaseOrderLines_LIM(StockItemID);
GO

PRINT '✅ Tablas Purchasing.PurchaseOrders_LIM y PurchaseOrderLines_LIM creadas en WWI_Sucursal_LIM';
GO


-- ========================================
-- 3) VISTAS CONSOLIDADAS EN CORPORATIVO
-- ========================================
USE WWI_Corporativo;
GO

-- Vista de órdenes de compra consolidadas
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

-- Vista de líneas de orden de compra consolidadas
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
INNER JOIN WWI_Sucursal_SJ.Purchasing.PurchaseOrders_SJ po ON pol.PurchaseOrderID = po.PurchaseOrderID

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
INNER JOIN WWI_Sucursal_LIM.Purchasing.PurchaseOrders_LIM po ON pol.PurchaseOrderID = po.PurchaseOrderID;
GO

PRINT '✅ Vistas consolidadas creadas en WWI_Corporativo';
GO


-- ========================================
-- 4) PROCEDIMIENTO PARA DISTRIBUIR ÓRDENES
-- ========================================
CREATE OR ALTER PROCEDURE Purchasing.sp_DistribuirOrdenesCompra
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Distribuir órdenes de compra a San José (50% - IDs impares)
        INSERT INTO WWI_Sucursal_SJ.Purchasing.PurchaseOrders_SJ
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
            'San José' AS Sucursal
        FROM WideWorldImporters.Purchasing.PurchaseOrders
        WHERE PurchaseOrderID % 2 = 1  -- IDs impares a San José
        AND NOT EXISTS (
            SELECT 1 FROM WWI_Sucursal_SJ.Purchasing.PurchaseOrders_SJ sj 
            WHERE sj.PurchaseOrderID = PurchaseOrders.PurchaseOrderID
        );
        
        DECLARE @orders_sj INT = @@ROWCOUNT;
        PRINT CONCAT('✅ Insertadas ', @orders_sj, ' órdenes de compra en San José');
        
        -- Distribuir líneas de orden a San José
        INSERT INTO WWI_Sucursal_SJ.Purchasing.PurchaseOrderLines_SJ
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
            pol.LastEditedWhen
        FROM WideWorldImporters.Purchasing.PurchaseOrderLines pol
        INNER JOIN WWI_Sucursal_SJ.Purchasing.PurchaseOrders_SJ po ON pol.PurchaseOrderID = po.PurchaseOrderID
        WHERE NOT EXISTS (
            SELECT 1 FROM WWI_Sucursal_SJ.Purchasing.PurchaseOrderLines_SJ sj 
            WHERE sj.PurchaseOrderLineID = pol.PurchaseOrderLineID
        );
        
        DECLARE @lines_sj INT = @@ROWCOUNT;
        PRINT CONCAT('✅ Insertadas ', @lines_sj, ' líneas de orden en San José');
        
        -- Distribuir órdenes de compra a Limón (50% - IDs pares)
        INSERT INTO WWI_Sucursal_LIM.Purchasing.PurchaseOrders_LIM
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
            'Limón' AS Sucursal
        FROM WideWorldImporters.Purchasing.PurchaseOrders
        WHERE PurchaseOrderID % 2 = 0  -- IDs pares a Limón
        AND NOT EXISTS (
            SELECT 1 FROM WWI_Sucursal_LIM.Purchasing.PurchaseOrders_LIM lim 
            WHERE lim.PurchaseOrderID = PurchaseOrders.PurchaseOrderID
        );
        
        DECLARE @orders_lim INT = @@ROWCOUNT;
        PRINT CONCAT('✅ Insertadas ', @orders_lim, ' órdenes de compra en Limón');
        
        -- Distribuir líneas de orden a Limón
        INSERT INTO WWI_Sucursal_LIM.Purchasing.PurchaseOrderLines_LIM
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
            pol.LastEditedWhen
        FROM WideWorldImporters.Purchasing.PurchaseOrderLines pol
        INNER JOIN WWI_Sucursal_LIM.Purchasing.PurchaseOrders_LIM po ON pol.PurchaseOrderID = po.PurchaseOrderID
        WHERE NOT EXISTS (
            SELECT 1 FROM WWI_Sucursal_LIM.Purchasing.PurchaseOrderLines_LIM lim 
            WHERE lim.PurchaseOrderLineID = pol.PurchaseOrderLineID
        );
        
        DECLARE @lines_lim INT = @@ROWCOUNT;
        PRINT CONCAT('✅ Insertadas ', @lines_lim, ' líneas de orden en Limón');
        
        COMMIT TRANSACTION;
        
        -- Verificación y resumen
        DECLARE @total_orders INT = (SELECT COUNT(*) FROM Purchasing.vw_PurchaseOrders_Consolidated);
        DECLARE @total_lines INT = (SELECT COUNT(*) FROM Purchasing.vw_PurchaseOrderLines_Consolidated);
        DECLARE @total_amount_sj DECIMAL(18,2) = (
            SELECT SUM(OrderedOuters * ExpectedUnitPricePerOuter) 
            FROM WWI_Sucursal_SJ.Purchasing.PurchaseOrderLines_SJ
        );
        DECLARE @total_amount_lim DECIMAL(18,2) = (
            SELECT SUM(OrderedOuters * ExpectedUnitPricePerOuter) 
            FROM WWI_Sucursal_LIM.Purchasing.PurchaseOrderLines_LIM
        );
        
        PRINT '';
        PRINT '================ RESUMEN FRAGMENTACIÓN ÓRDENES COMPRA ================';
        PRINT CONCAT('📍 Órdenes en San José: ', @orders_sj, 
                     ' (Total compras: $', FORMAT(@total_amount_sj, 'N2'), ')');
        PRINT CONCAT('📍 Órdenes en Limón: ', @orders_lim, 
                     ' (Total compras: $', FORMAT(@total_amount_lim, 'N2'), ')');
        PRINT CONCAT('📄 Total órdenes consolidadas: ', @total_orders);
        PRINT CONCAT('📋 Total líneas de orden: ', @total_lines);
        PRINT '======================================================================';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

PRINT '✅ Procedimiento Purchasing.sp_DistribuirOrdenesCompra creado';
PRINT '';
PRINT '🔹 EJECUTAR: EXEC WWI_Corporativo.Purchasing.sp_DistribuirOrdenesCompra;';
GO
