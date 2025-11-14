/*
================================================================================
FRAGMENTACIÓN DE CLIENTES - CORPORATIVO
================================================================================
Base de datos: WWI_Corporativo
Contiene: Vistas consolidadas y procedimientos de distribución
================================================================================
*/

USE WWI_Corporativo;
GO

-- ========================================
-- VISTA CONSOLIDADA
-- ========================================
IF OBJECT_ID('Sales.vw_Customers_Consolidated', 'V') IS NOT NULL
    DROP VIEW Sales.vw_Customers_Consolidated;
GO

CREATE VIEW Sales.vw_Customers_Consolidated AS
SELECT 
    CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID,
    PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID,
    DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate,
    StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays,
    PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL,
    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation,
    PostalAddressLine1, PostalAddressLine2, PostalPostalCode,
    LastEditedBy, ValidFrom, ValidTo,
    'San José' AS Sucursal
FROM WWI_Sucursal_SJ.Sales.Customers_SJ

UNION ALL

SELECT 
    CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID,
    PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID,
    DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate,
    StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays,
    PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL,
    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation,
    PostalAddressLine1, PostalAddressLine2, PostalPostalCode,
    LastEditedBy, ValidFrom, ValidTo,
    'Limón' AS Sucursal
FROM WWI_Sucursal_LIM.Sales.Customers_LIM;
GO

PRINT '✅ Vista Sales.vw_Customers_Consolidated creada';
GO


-- ========================================
-- PROCEDIMIENTO DE DISTRIBUCIÓN
-- ========================================
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
            c.CustomerID, c.CustomerName, c.BillToCustomerID, c.CustomerCategoryID,
            c.BuyingGroupID, c.PrimaryContactPersonID, c.AlternateContactPersonID,
            c.DeliveryMethodID, c.DeliveryCityID, c.PostalCityID, c.CreditLimit,
            c.AccountOpenedDate, c.StandardDiscountPercentage, c.IsStatementSent,
            c.IsOnCreditHold, c.PaymentDays, c.PhoneNumber, c.FaxNumber,
            c.DeliveryRun, c.RunPosition, c.WebsiteURL, c.DeliveryAddressLine1,
            c.DeliveryAddressLine2, c.DeliveryPostalCode, c.DeliveryLocation,
            c.PostalAddressLine1, c.PostalAddressLine2, c.PostalPostalCode,
            c.LastEditedBy, c.ValidFrom, c.ValidTo
        FROM WideWorldImporters.Sales.Customers c
        INNER JOIN WideWorldImporters.Application.Cities city ON c.DeliveryCityID = city.CityID
        INNER JOIN WideWorldImporters.Application.StateProvinces sp ON city.StateProvinceID = sp.StateProvinceID
        WHERE sp.StateProvinceName IN ('San José', 'Heredia', 'Alajuela', 'Cartago')
        AND NOT EXISTS (SELECT 1 FROM WWI_Sucursal_SJ.Sales.Customers_SJ csj WHERE csj.CustomerID = c.CustomerID);
        
        SET @clientes_sj = @@ROWCOUNT;
        PRINT CONCAT('✅ Insertados ', @clientes_sj, ' clientes en San José');
        
        -- Insertar clientes zona atlántica/norte en Limón
        INSERT INTO WWI_Sucursal_LIM.Sales.Customers_LIM
        SELECT 
            c.CustomerID, c.CustomerName, c.BillToCustomerID, c.CustomerCategoryID,
            c.BuyingGroupID, c.PrimaryContactPersonID, c.AlternateContactPersonID,
            c.DeliveryMethodID, c.DeliveryCityID, c.PostalCityID, c.CreditLimit,
            c.AccountOpenedDate, c.StandardDiscountPercentage, c.IsStatementSent,
            c.IsOnCreditHold, c.PaymentDays, c.PhoneNumber, c.FaxNumber,
            c.DeliveryRun, c.RunPosition, c.WebsiteURL, c.DeliveryAddressLine1,
            c.DeliveryAddressLine2, c.DeliveryPostalCode, c.DeliveryLocation,
            c.PostalAddressLine1, c.PostalAddressLine2, c.PostalPostalCode,
            c.LastEditedBy, c.ValidFrom, c.ValidTo
        FROM WideWorldImporters.Sales.Customers c
        INNER JOIN WideWorldImporters.Application.Cities city ON c.DeliveryCityID = city.CityID
        INNER JOIN WideWorldImporters.Application.StateProvinces sp ON city.StateProvinceID = sp.StateProvinceID
        WHERE sp.StateProvinceName IN ('Limón', 'Guanacaste', 'Puntarenas')
        AND NOT EXISTS (SELECT 1 FROM WWI_Sucursal_LIM.Sales.Customers_LIM clim WHERE clim.CustomerID = c.CustomerID);
        
        SET @clientes_lim = @@ROWCOUNT;
        PRINT CONCAT('✅ Insertados ', @clientes_lim, ' clientes en Limón');
        
        -- Verificar clientes sin ubicación válida
        SELECT @clientes_sin_ubicacion = COUNT(*)
        FROM WideWorldImporters.Sales.Customers c
        INNER JOIN WideWorldImporters.Application.Cities city ON c.DeliveryCityID = city.CityID
        INNER JOIN WideWorldImporters.Application.StateProvinces sp ON city.StateProvinceID = sp.StateProvinceID
        WHERE sp.StateProvinceName NOT IN ('San José', 'Heredia', 'Alajuela', 'Cartago', 'Limón', 'Guanacaste', 'Puntarenas');
        
        IF @clientes_sin_ubicacion > 0
            PRINT CONCAT('⚠️  Advertencia: ', @clientes_sin_ubicacion, ' clientes fuera de las provincias definidas');
        
        COMMIT TRANSACTION;
        
        -- Verificación final
        DECLARE @total_sj INT = (SELECT COUNT(*) FROM WWI_Sucursal_SJ.Sales.Customers_SJ);
        DECLARE @total_lim INT = (SELECT COUNT(*) FROM WWI_Sucursal_LIM.Sales.Customers_LIM);
        DECLARE @total_consolidado INT = (SELECT COUNT(*) FROM Sales.vw_Customers_Consolidated);
        
        PRINT '';
        PRINT '=================== RESUMEN FRAGMENTACION CLIENTES ===================';
        PRINT CONCAT('📍 San José:          ', @total_sj);
        PRINT CONCAT('📍 Limón:             ', @total_lim);
        PRINT CONCAT('📊 Total consolidado: ', @total_consolidado);
        PRINT CONCAT('⚠️  No asignados:     ', @clientes_sin_ubicacion);
        PRINT '======================================================================';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT CONCAT('❌ ERROR: ', @Err);
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

PRINT '✅ Procedimiento Sales.sp_DistribuirClientes creado';
PRINT '';
PRINT 'Para ejecutar: EXEC Sales.sp_DistribuirClientes;';
PRINT 'Para verificar: SELECT Sucursal, COUNT(*) FROM Sales.vw_Customers_Consolidated GROUP BY Sucursal;';
GO