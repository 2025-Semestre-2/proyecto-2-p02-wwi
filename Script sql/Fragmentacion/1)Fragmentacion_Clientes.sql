/*
================================================================================
PROYECTO 2 - FRAGMENTACIÓN DE DATOS: CLIENTES (CORREGIDO)
================================================================================
Estrategia: FRAGMENTACIÓN HORIZONTAL por ubicación geográfica
- San José: Clientes de provincias centrales (San José, Heredia, Alajuela, Cartago)
- Limón: Clientes de zona atlántica/norte (Limón, Guanacaste, Puntarenas)
- Corporativo: Vista consolidada de todos los clientes

SOLUCIÓN: En lugar de CHECK CONSTRAINTS con subconsultas, usamos:
1. Índices para performance
2. Control en el procedimiento de distribución
3. Triggers para evitar inserciones/actualizaciones incorrectas
================================================================================
*/

-- ========================================
-- 1) TABLA FRAGMENTADA EN SAN JOSÉ
-- ========================================
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

CREATE NONCLUSTERED INDEX IX_Customers_SJ_CityID ON Sales.Customers_SJ(DeliveryCityID);
CREATE NONCLUSTERED INDEX IX_Customers_SJ_CategoryID ON Sales.Customers_SJ(CustomerCategoryID);
GO

-- Trigger para validar región al insertar/actualizar
CREATE OR ALTER TRIGGER Sales.trg_Customers_SJ_ValidateRegion
ON Sales.Customers_SJ
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        INNER JOIN WideWorldImporters.Application.Cities city ON i.DeliveryCityID = city.CityID
        INNER JOIN WideWorldImporters.Application.StateProvinces sp ON city.StateProvinceID = sp.StateProvinceID
        WHERE sp.StateProvinceName NOT IN ('San José', 'Heredia', 'Alajuela', 'Cartago')
    )
    BEGIN
        RAISERROR('❌ Error: Solo se permiten clientes de San José, Heredia, Alajuela o Cartago en esta sucursal', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

PRINT '✅ Tabla Sales.Customers_SJ creada en WWI_Sucursal_SJ';
GO


-- ========================================
-- 2) TABLA FRAGMENTADA EN LIMÓN
-- ========================================
USE WWI_Sucursal_LIM;
GO

IF OBJECT_ID('Sales.Customers_LIM', 'U') IS NOT NULL
    DROP TABLE Sales.Customers_LIM;
GO

CREATE TABLE Sales.Customers_LIM (
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

CREATE NONCLUSTERED INDEX IX_Customers_LIM_CityID ON Sales.Customers_LIM(DeliveryCityID);
CREATE NONCLUSTERED INDEX IX_Customers_LIM_CategoryID ON Sales.Customers_LIM(CustomerCategoryID);
GO

-- Trigger para validar región al insertar/actualizar
CREATE OR ALTER TRIGGER Sales.trg_Customers_LIM_ValidateRegion
ON Sales.Customers_LIM
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        INNER JOIN WideWorldImporters.Application.Cities city ON i.DeliveryCityID = city.CityID
        INNER JOIN WideWorldImporters.Application.StateProvinces sp ON city.StateProvinceID = sp.StateProvinceID
        WHERE sp.StateProvinceName NOT IN ('Limón', 'Guanacaste', 'Puntarenas')
    )
    BEGIN
        RAISERROR('❌ Error: Solo se permiten clientes de Limón, Guanacaste o Puntarenas en esta sucursal', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

PRINT '✅ Tabla Sales.Customers_LIM creada en WWI_Sucursal_LIM';
GO


-- ========================================
-- 3) VISTA CONSOLIDADA EN CORPORATIVO
-- ========================================
USE WWI_Corporativo;
GO

IF OBJECT_ID('Sales.vw_Customers_Consolidated', 'V') IS NOT NULL
    DROP VIEW Sales.vw_Customers_Consolidated;
GO

CREATE VIEW Sales.vw_Customers_Consolidated AS
SELECT 
    CustomerID,
    CustomerName,
    BillToCustomerID,
    CustomerCategoryID,
    BuyingGroupID,
    PrimaryContactPersonID,
    AlternateContactPersonID,
    DeliveryMethodID,
    DeliveryCityID,
    PostalCityID,
    CreditLimit,
    AccountOpenedDate,
    StandardDiscountPercentage,
    IsStatementSent,
    IsOnCreditHold,
    PaymentDays,
    PhoneNumber,
    FaxNumber,
    DeliveryRun,
    RunPosition,
    WebsiteURL,
    DeliveryAddressLine1,
    DeliveryAddressLine2,
    DeliveryPostalCode,
    DeliveryLocation,
    PostalAddressLine1,
    PostalAddressLine2,
    PostalPostalCode,
    LastEditedBy,
    ValidFrom,
    ValidTo,
    'San José' AS Sucursal
FROM WWI_Sucursal_SJ.Sales.Customers_SJ

UNION ALL

SELECT 
    CustomerID,
    CustomerName,
    BillToCustomerID,
    CustomerCategoryID,
    BuyingGroupID,
    PrimaryContactPersonID,
    AlternateContactPersonID,
    DeliveryMethodID,
    DeliveryCityID,
    PostalCityID,
    CreditLimit,
    AccountOpenedDate,
    StandardDiscountPercentage,
    IsStatementSent,
    IsOnCreditHold,
    PaymentDays,
    PhoneNumber,
    FaxNumber,
    DeliveryRun,
    RunPosition,
    WebsiteURL,
    DeliveryAddressLine1,
    DeliveryAddressLine2,
    DeliveryPostalCode,
    DeliveryLocation,
    PostalAddressLine1,
    PostalAddressLine2,
    PostalPostalCode,
    LastEditedBy,
    ValidFrom,
    ValidTo,
    'Limón' AS Sucursal
FROM WWI_Sucursal_LIM.Sales.Customers_LIM;
GO

PRINT '✅ Vista Sales.vw_Customers_Consolidated creada en WWI_Corporativo';
GO


-- ========================================
-- 4) PROCEDIMIENTO PARA DISTRIBUIR DATOS
-- ========================================
USE WWI_Corporativo;
GO

CREATE OR ALTER PROCEDURE Sales.sp_DistribuirClientes
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @clientes_sj INT = 0;
    DECLARE @clientes_lim INT = 0;
    DECLARE @clientes_sin_ubicacion INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Insertar clientes zona central en San José
        INSERT INTO WWI_Sucursal_SJ.Sales.Customers_SJ
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
            c.ValidTo
        FROM WideWorldImporters.Sales.Customers c
        INNER JOIN WideWorldImporters.Application.Cities city ON c.DeliveryCityID = city.CityID
        INNER JOIN WideWorldImporters.Application.StateProvinces sp ON city.StateProvinceID = sp.StateProvinceID
        WHERE sp.StateProvinceName IN ('San José', 'Heredia', 'Alajuela', 'Cartago')
        AND NOT EXISTS (
            SELECT 1 FROM WWI_Sucursal_SJ.Sales.Customers_SJ csj 
            WHERE csj.CustomerID = c.CustomerID
        );
        
        SET @clientes_sj = @@ROWCOUNT;
        PRINT CONCAT('✅ Insertados ', @clientes_sj, ' clientes en San José');
        
        -- Insertar clientes zona atlántica/norte en Limón
        INSERT INTO WWI_Sucursal_LIM.Sales.Customers_LIM
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
            c.ValidTo
        FROM WideWorldImporters.Sales.Customers c
        INNER JOIN WideWorldImporters.Application.Cities city ON c.DeliveryCityID = city.CityID
        INNER JOIN WideWorldImporters.Application.StateProvinces sp ON city.StateProvinceID = sp.StateProvinceID
        WHERE sp.StateProvinceName IN ('Limón', 'Guanacaste', 'Puntarenas')
        AND NOT EXISTS (
            SELECT 1 FROM WWI_Sucursal_LIM.Sales.Customers_LIM clim 
            WHERE clim.CustomerID = c.CustomerID
        );
        
        SET @clientes_lim = @@ROWCOUNT;
        PRINT CONCAT('✅ Insertados ', @clientes_lim, ' clientes en Limón');
        
        -- Verificar clientes sin ubicación válida
        SELECT @clientes_sin_ubicacion = COUNT(*)
        FROM WideWorldImporters.Sales.Customers c
        INNER JOIN WideWorldImporters.Application.Cities city ON c.DeliveryCityID = city.CityID
        INNER JOIN WideWorldImporters.Application.StateProvinces sp ON city.StateProvinceID = sp.StateProvinceID
        WHERE sp.StateProvinceName NOT IN ('San José', 'Heredia', 'Alajuela', 'Cartago', 'Limón', 'Guanacaste', 'Puntarenas');
        
        IF @clientes_sin_ubicacion > 0
        BEGIN
            PRINT CONCAT('⚠️  Advertencia: ', @clientes_sin_ubicacion, ' clientes con ubicaciones fuera de las provincias definidas');
        END
        
        COMMIT TRANSACTION;
        
        -- Verificación final
        DECLARE @total_sj INT = (SELECT COUNT(*) FROM WWI_Sucursal_SJ.Sales.Customers_SJ);
        DECLARE @total_lim INT = (SELECT COUNT(*) FROM WWI_Sucursal_LIM.Sales.Customers_LIM);
        DECLARE @total_consolidado INT = (SELECT COUNT(*) FROM Sales.vw_Customers_Consolidated);
        DECLARE @total_original INT = (SELECT COUNT(*) FROM WideWorldImporters.Sales.Customers);
        
        PRINT '';
        PRINT '═══════════════════════ RESUMEN FRAGMENTACIÓN ═══════════════════════';
        PRINT CONCAT('📍 Clientes en San José:     ', @total_sj);
        PRINT CONCAT('📍 Clientes en Limón:        ', @total_lim);
        PRINT CONCAT('📊 Total consolidado:        ', @total_consolidado);
        PRINT CONCAT('📦 Total original (WWI):     ', @total_original);
        PRINT CONCAT('⚠️  Clientes no asignados:   ', @clientes_sin_ubicacion);
        PRINT '═════════════════════════════════════════════════════════════════════';
        
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

PRINT '✅ Procedimiento Sales.sp_DistribuirClientes creado';
PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '🚀 PARA EJECUTAR LA DISTRIBUCIÓN:';
PRINT '   EXEC WWI_Corporativo.Sales.sp_DistribuirClientes;';
PRINT '';
PRINT '📋 PARA VERIFICAR LOS DATOS:';
PRINT '   SELECT * FROM WWI_Corporativo.Sales.vw_Customers_Consolidated;';
PRINT '   SELECT Sucursal, COUNT(*) AS Total FROM WWI_Corporativo.Sales.vw_Customers_Consolidated GROUP BY Sucursal;';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO

EXEC WWI_Corporativo.Sales.sp_DistribuirClientes;