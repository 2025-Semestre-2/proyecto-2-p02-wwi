/*
================================================================================
PROYECTO 2 - FRAGMENTACIÓN DE DATOS: PRODUCTOS (INVENTARIO) - CORREGIDO
================================================================================
Estrategia: FRAGMENTACIÓN HÍBRIDA (Horizontal + Vertical)
- San José: Productos con stock > 0 en zona central
- Limón: Productos con stock > 0 en zona atlántica  
- Corporativo: Catálogo completo (datos maestros sin stock)
================================================================================
*/

USE WWI_Sucursal_SJ;
GO

-- ========================================
-- 1) TABLA FRAGMENTADA EN SAN JOSÉ
-- ========================================
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
    Photo               VARBINARY(MAX) NULL,
    CustomFields        NVARCHAR(MAX) NULL,
    Tags                NVARCHAR(MAX) NULL,
    SearchDetails       NVARCHAR(MAX) NOT NULL,
    LastEditedBy        INT NOT NULL,
    ValidFrom           DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    ValidTo             DATETIME2(7) NOT NULL DEFAULT '9999-12-31 23:59:59.9999999',
    
    -- CAMPOS DE INVENTARIO LOCAL
    QuantityOnHand      INT NOT NULL DEFAULT 0,
    BinLocation         NVARCHAR(20) NULL,
    LastStockTake       DATETIME2 NULL,
    
    -- CONSTRAINT: Solo productos con stock en esta sucursal
    CONSTRAINT CHK_StockItems_SJ_Quantity CHECK (QuantityOnHand >= 0)
);
GO

CREATE NONCLUSTERED INDEX IX_StockItems_SJ_Name ON Warehouse.StockItems_SJ(StockItemName);
CREATE NONCLUSTERED INDEX IX_StockItems_SJ_SupplierID ON Warehouse.StockItems_SJ(SupplierID);
CREATE NONCLUSTERED INDEX IX_StockItems_SJ_Stock ON Warehouse.StockItems_SJ(QuantityOnHand) WHERE QuantityOnHand > 0;
GO

PRINT '✅ Tabla Warehouse.StockItems_SJ creada en WWI_Sucursal_SJ';
GO


-- ========================================
-- 2) TABLA FRAGMENTADA EN LIMÓN
-- ========================================
USE WWI_Sucursal_LIM;
GO

IF OBJECT_ID('Warehouse.StockItems_LIM', 'U') IS NOT NULL
    DROP TABLE Warehouse.StockItems_LIM;
GO

CREATE TABLE Warehouse.StockItems_LIM (
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
    SearchDetails       NVARCHAR(MAX) NOT NULL,
    LastEditedBy        INT NOT NULL,
    ValidFrom           DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    ValidTo             DATETIME2(7) NOT NULL DEFAULT '9999-12-31 23:59:59.9999999',
    
    -- CAMPOS DE INVENTARIO LOCAL
    QuantityOnHand      INT NOT NULL DEFAULT 0,
    BinLocation         NVARCHAR(20) NULL,
    LastStockTake       DATETIME2 NULL,
    
    -- CONSTRAINT: Solo productos con stock en esta sucursal
    CONSTRAINT CHK_StockItems_LIM_Quantity CHECK (QuantityOnHand >= 0)
);
GO

CREATE NONCLUSTERED INDEX IX_StockItems_LIM_Name ON Warehouse.StockItems_LIM(StockItemName);
CREATE NONCLUSTERED INDEX IX_StockItems_LIM_SupplierID ON Warehouse.StockItems_LIM(SupplierID);
CREATE NONCLUSTERED INDEX IX_StockItems_LIM_Stock ON Warehouse.StockItems_LIM(QuantityOnHand) WHERE QuantityOnHand > 0;
GO

PRINT '✅ Tabla Warehouse.StockItems_LIM creada en WWI_Sucursal_LIM';
GO


-- ========================================
-- 3) CATÁLOGO MAESTRO EN CORPORATIVO
-- ========================================
USE WWI_Corporativo;
GO

IF OBJECT_ID('Warehouse.StockItems_Master', 'U') IS NOT NULL
    DROP TABLE Warehouse.StockItems_Master;
GO

-- Catálogo completo SIN información de stock local
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
    SearchDetails       NVARCHAR(MAX) NOT NULL,
    LastEditedBy        INT NOT NULL,
    ValidFrom           DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    ValidTo             DATETIME2(7) NOT NULL DEFAULT '9999-12-31 23:59:59.9999999',
    
    -- Metadatos de distribución
    AvailableInSJ       BIT NOT NULL DEFAULT 0,
    AvailableInLIM      BIT NOT NULL DEFAULT 0,
    IsActive            BIT NOT NULL DEFAULT 1
);
GO

CREATE NONCLUSTERED INDEX IX_StockItems_Master_Name ON Warehouse.StockItems_Master(StockItemName);
CREATE NONCLUSTERED INDEX IX_StockItems_Master_SupplierID ON Warehouse.StockItems_Master(SupplierID);
GO

PRINT '✅ Tabla Warehouse.StockItems_Master creada en WWI_Corporativo';
GO


-- ========================================
-- 4) VISTA CONSOLIDADA DE INVENTARIO
-- ========================================
CREATE OR ALTER VIEW Warehouse.vw_StockItems_Consolidated AS
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
    
    -- Stock por sucursal
    ISNULL(sj.QuantityOnHand, 0) AS Stock_SJ,
    ISNULL(lim.QuantityOnHand, 0) AS Stock_LIM,
    ISNULL(sj.QuantityOnHand, 0) + ISNULL(lim.QuantityOnHand, 0) AS Stock_Total,
    
    -- Disponibilidad
    CASE WHEN sj.StockItemID IS NOT NULL THEN 1 ELSE 0 END AS EnSJ,
    CASE WHEN lim.StockItemID IS NOT NULL THEN 1 ELSE 0 END AS EnLIM,
    
    m.IsActive
FROM Warehouse.StockItems_Master m
LEFT JOIN WWI_Sucursal_SJ.Warehouse.StockItems_SJ sj ON m.StockItemID = sj.StockItemID
LEFT JOIN WWI_Sucursal_LIM.Warehouse.StockItems_LIM lim ON m.StockItemID = lim.StockItemID;
GO

PRINT '✅ Vista Warehouse.vw_StockItems_Consolidated creada en WWI_Corporativo';
GO


-- ========================================
-- 5) PROCEDIMIENTO PARA DISTRIBUIR PRODUCTOS
-- ========================================
CREATE OR ALTER PROCEDURE Warehouse.sp_DistribuirProductos
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @total_sj INT = 0;
    DECLARE @total_lim INT = 0;
    DECLARE @total_master INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 1) Cargar catálogo maestro en Corporativo
        INSERT INTO Warehouse.StockItems_Master (
            StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
            OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
            IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
            TypicalWeightPerUnit, MarketingComments, InternalComments, Photo,
            CustomFields, Tags, SearchDetails, LastEditedBy, ValidFrom, ValidTo,
            AvailableInSJ, AvailableInLIM, IsActive
        )
        SELECT 
            StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
            OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
            IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
            TypicalWeightPerUnit, MarketingComments, InternalComments, Photo,
            CustomFields, Tags, SearchDetails, LastEditedBy, ValidFrom, ValidTo,
            0, 0, 1
        FROM WideWorldImporters.Warehouse.StockItems
        WHERE NOT EXISTS (
            SELECT 1 FROM Warehouse.StockItems_Master m 
            WHERE m.StockItemID = StockItems.StockItemID
        );
        
        SET @total_master = @@ROWCOUNT;
        PRINT CONCAT('✅ Insertados ', @total_master, ' productos en catálogo maestro');
        
        -- 2) Distribuir productos con stock a San José (Zona Central)
        INSERT INTO WWI_Sucursal_SJ.Warehouse.StockItems_SJ (
            StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
            OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
            IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
            TypicalWeightPerUnit, MarketingComments, InternalComments, Photo,
            CustomFields, Tags, SearchDetails, LastEditedBy, ValidFrom, ValidTo,
            QuantityOnHand, BinLocation, LastStockTake
        )
        SELECT 
            si.StockItemID, si.StockItemName, si.SupplierID, si.ColorID, si.UnitPackageID,
            si.OuterPackageID, si.Brand, si.Size, si.LeadTimeDays, si.QuantityPerOuter,
            si.IsChillerStock, si.Barcode, si.TaxRate, si.UnitPrice, si.RecommendedRetailPrice,
            si.TypicalWeightPerUnit, si.MarketingComments, si.InternalComments, si.Photo,
            si.CustomFields, si.Tags, si.SearchDetails, si.LastEditedBy, si.ValidFrom, si.ValidTo,
            ISNULL(sh.QuantityOnHand, 0),
            'A-' + RIGHT('000' + CAST(si.StockItemID AS VARCHAR(10)), 3),
            GETDATE()
        FROM WideWorldImporters.Warehouse.StockItems si
        LEFT JOIN WideWorldImporters.Warehouse.StockItemHoldings sh ON si.StockItemID = sh.StockItemID
        WHERE si.StockItemID % 2 = 1
        AND NOT EXISTS (
            SELECT 1 FROM WWI_Sucursal_SJ.Warehouse.StockItems_SJ sj 
            WHERE sj.StockItemID = si.StockItemID
        );
        
        SET @total_sj = @@ROWCOUNT;
        PRINT CONCAT('✅ Insertados ', @total_sj, ' productos en San José');
        
        -- 3) Distribuir productos con stock a Limón (Zona Atlántica)
        INSERT INTO WWI_Sucursal_LIM.Warehouse.StockItems_LIM (
            StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
            OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
            IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
            TypicalWeightPerUnit, MarketingComments, InternalComments, Photo,
            CustomFields, Tags, SearchDetails, LastEditedBy, ValidFrom, ValidTo,
            QuantityOnHand, BinLocation, LastStockTake
        )
        SELECT 
            si.StockItemID, si.StockItemName, si.SupplierID, si.ColorID, si.UnitPackageID,
            si.OuterPackageID, si.Brand, si.Size, si.LeadTimeDays, si.QuantityPerOuter,
            si.IsChillerStock, si.Barcode, si.TaxRate, si.UnitPrice, si.RecommendedRetailPrice,
            si.TypicalWeightPerUnit, si.MarketingComments, si.InternalComments, si.Photo,
            si.CustomFields, si.Tags, si.SearchDetails, si.LastEditedBy, si.ValidFrom, si.ValidTo,
            ISNULL(sh.QuantityOnHand, 0),
            'B-' + RIGHT('000' + CAST(si.StockItemID AS VARCHAR(10)), 3),
            GETDATE()
        FROM WideWorldImporters.Warehouse.StockItems si
        LEFT JOIN WideWorldImporters.Warehouse.StockItemHoldings sh ON si.StockItemID = sh.StockItemID
        WHERE si.StockItemID % 2 = 0
        AND NOT EXISTS (
            SELECT 1 FROM WWI_Sucursal_LIM.Warehouse.StockItems_LIM lim 
            WHERE lim.StockItemID = si.StockItemID
        );
        
        SET @total_lim = @@ROWCOUNT;
        PRINT CONCAT('✅ Insertados ', @total_lim, ' productos en Limón');
        
        -- 4) Actualizar flags de disponibilidad en catálogo maestro
        UPDATE Warehouse.StockItems_Master
        SET AvailableInSJ = CASE WHEN EXISTS (
                SELECT 1 FROM WWI_Sucursal_SJ.Warehouse.StockItems_SJ sj 
                WHERE sj.StockItemID = StockItems_Master.StockItemID
            ) THEN 1 ELSE 0 END,
            AvailableInLIM = CASE WHEN EXISTS (
                SELECT 1 FROM WWI_Sucursal_LIM.Warehouse.StockItems_LIM lim 
                WHERE lim.StockItemID = StockItems_Master.StockItemID
            ) THEN 1 ELSE 0 END;
        
        PRINT '✅ Actualizados flags de disponibilidad en catálogo maestro';
        
        COMMIT TRANSACTION;
        
        -- Verificación final
        DECLARE @total_consolidado INT = (SELECT COUNT(*) FROM Warehouse.vw_StockItems_Consolidated);
        DECLARE @stock_sj_total DECIMAL(18,2) = (
            SELECT ISNULL(SUM(QuantityOnHand * UnitPrice), 0)
            FROM WWI_Sucursal_SJ.Warehouse.StockItems_SJ
        );
        DECLARE @stock_lim_total DECIMAL(18,2) = (
            SELECT ISNULL(SUM(QuantityOnHand * UnitPrice), 0)
            FROM WWI_Sucursal_LIM.Warehouse.StockItems_LIM
        );
        DECLARE @items_sj_stock INT = (
            SELECT COUNT(*) FROM WWI_Sucursal_SJ.Warehouse.StockItems_SJ WHERE QuantityOnHand > 0
        );
        DECLARE @items_lim_stock INT = (
            SELECT COUNT(*) FROM WWI_Sucursal_LIM.Warehouse.StockItems_LIM WHERE QuantityOnHand > 0
        );
        
        PRINT '';
        PRINT '═══════════════════ RESUMEN FRAGMENTACIÓN PRODUCTOS ═══════════════════';
        PRINT CONCAT('📦 Productos en catálogo maestro:  ', @total_master);
        PRINT CONCAT('📍 Productos en San José:          ', @total_sj, ' (', @items_sj_stock, ' con stock)');
        PRINT CONCAT('   Valor inventario San José:      $', FORMAT(@stock_sj_total, 'N2'));
        PRINT CONCAT('📍 Productos en Limón:             ', @total_lim, ' (', @items_lim_stock, ' con stock)');
        PRINT CONCAT('   Valor inventario Limón:         $', FORMAT(@stock_lim_total, 'N2'));
        PRINT CONCAT('📊 Total productos únicos:         ', @total_consolidado);
        PRINT CONCAT('💰 Valor total inventario:         $', FORMAT(@stock_sj_total + @stock_lim_total, 'N2'));
        PRINT '═══════════════════════════════════════════════════════════════════════';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT '';
        PRINT '❌ ERROR EN LA DISTRIBUCIÓN:';
        PRINT CONCAT('   Mensaje: ', @ErrorMessage);
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

PRINT '✅ Procedimiento Warehouse.sp_DistribuirProductos creado';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '🚀 PARA EJECUTAR LA DISTRIBUCIÓN:';
PRINT '   EXEC WWI_Corporativo.Warehouse.sp_DistribuirProductos;';
PRINT '';
PRINT '📋 PARA VERIFICAR LOS DATOS:';
PRINT '   -- Ver resumen por sucursal';
PRINT '   SELECT ';
PRINT '       COUNT(*) AS TotalProductos,';
PRINT '       SUM(CASE WHEN EnSJ = 1 THEN 1 ELSE 0 END) AS EnSanJose,';
PRINT '       SUM(CASE WHEN EnLIM = 1 THEN 1 ELSE 0 END) AS EnLimon,';
PRINT '       SUM(Stock_Total) AS StockTotal';
PRINT '   FROM WWI_Corporativo.Warehouse.vw_StockItems_Consolidated;';
PRINT '';
PRINT '   -- Ver productos con más stock';
PRINT '   SELECT TOP 10 StockItemName, Stock_SJ, Stock_LIM, Stock_Total';
PRINT '   FROM WWI_Corporativo.Warehouse.vw_StockItems_Consolidated';
PRINT '   ORDER BY Stock_Total DESC;';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO
