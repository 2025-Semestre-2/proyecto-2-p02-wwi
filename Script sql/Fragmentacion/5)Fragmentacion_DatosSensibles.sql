/*
================================================================================
PROYECTO 2 - FRAGMENTACIÓN DE DATOS: DATOS SENSIBLES DE CLIENTES - CORREGIDO
================================================================================
Estrategia: FRAGMENTACIÓN VERTICAL
- Datos públicos: Nombre, categoría, delivery info → Sucursales
- Datos sensibles: Email, teléfono, fax, límite de crédito → Corporativo
- Reconstrucción: JOIN mediante CustomerID
================================================================================
*/

USE WWI_Corporativo;
GO

-- ========================================
-- 1) TABLA DE DATOS SENSIBLES EN CORPORATIVO
-- ========================================
IF OBJECT_ID('Sales.Customers_Sensitive', 'U') IS NOT NULL
    DROP TABLE Sales.Customers_Sensitive;
GO

CREATE TABLE Sales.Customers_Sensitive (
    CustomerID          INT NOT NULL PRIMARY KEY,
    
    -- Información de contacto (SENSIBLE)
    PhoneNumber         NVARCHAR(20) NOT NULL,
    FaxNumber           NVARCHAR(20) NOT NULL,
    WebsiteURL          NVARCHAR(256) NOT NULL,
    
    -- Información financiera (SENSIBLE)
    CreditLimit         DECIMAL(18,2) NULL,
    AccountOpenedDate   DATE NOT NULL,
    StandardDiscountPercentage DECIMAL(18,3) NOT NULL,
    IsStatementSent     BIT NOT NULL,
    IsOnCreditHold      BIT NOT NULL,
    PaymentDays         INT NOT NULL,
    
    -- Dirección postal (SENSIBLE)
    DeliveryAddressLine1 NVARCHAR(60) NOT NULL,
    DeliveryAddressLine2 NVARCHAR(60) NULL,
    DeliveryPostalCode  NVARCHAR(10) NOT NULL,
    PostalAddressLine1  NVARCHAR(60) NOT NULL,
    PostalAddressLine2  NVARCHAR(60) NULL,
    PostalPostalCode    NVARCHAR(10) NOT NULL,
    
    -- Auditoría
    LastEditedBy        INT NOT NULL,
    ValidFrom           DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    ValidTo             DATETIME2(7) NOT NULL DEFAULT CAST('9999-12-31 23:59:59.9999999' AS DATETIME2(7))
);
GO

CREATE NONCLUSTERED INDEX IX_Customers_Sensitive_CreditLimit ON Sales.Customers_Sensitive(CreditLimit);
CREATE NONCLUSTERED INDEX IX_Customers_Sensitive_OnCreditHold ON Sales.Customers_Sensitive(IsOnCreditHold);
GO

PRINT '✅ Tabla Sales.Customers_Sensitive creada en WWI_Corporativo';
GO


-- ========================================
-- 2) VISTA CONSOLIDADA CON DATOS COMPLETOS
-- ========================================
IF OBJECT_ID('Sales.vw_Customers_Complete', 'V') IS NOT NULL
    DROP VIEW Sales.vw_Customers_Complete;
GO

CREATE VIEW Sales.vw_Customers_Complete AS
-- Clientes de San José con datos sensibles
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
    'San José' AS Sucursal,
    -- Datos sensibles desde Corporativo
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
    c.LastEditedBy,
    c.ValidFrom,
    c.ValidTo
FROM WWI_Sucursal_SJ.Sales.Customers_SJ c
LEFT JOIN Sales.Customers_Sensitive s ON c.CustomerID = s.CustomerID

UNION ALL

-- Clientes de Limón con datos sensibles
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
    'Limón' AS Sucursal,
    -- Datos sensibles desde Corporativo
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
    c.LastEditedBy,
    c.ValidFrom,
    c.ValidTo
FROM WWI_Sucursal_LIM.Sales.Customers_LIM c
LEFT JOIN Sales.Customers_Sensitive s ON c.CustomerID = s.CustomerID;
GO

PRINT '✅ Vista Sales.vw_Customers_Complete creada';
GO


-- ========================================
-- 3) PROCEDIMIENTO PARA DISTRIBUIR DATOS SENSIBLES
-- ========================================
CREATE OR ALTER PROCEDURE Sales.sp_DistribuirDatosSensibles
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @sensitive_count INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Extraer datos sensibles desde WideWorldImporters
        INSERT INTO Sales.Customers_Sensitive (
            CustomerID,
            PhoneNumber,
            FaxNumber,
            WebsiteURL,
            CreditLimit,
            AccountOpenedDate,
            StandardDiscountPercentage,
            IsStatementSent,
            IsOnCreditHold,
            PaymentDays,
            DeliveryAddressLine1,
            DeliveryAddressLine2,
            DeliveryPostalCode,
            PostalAddressLine1,
            PostalAddressLine2,
            PostalPostalCode,
            LastEditedBy,
            ValidFrom,
            ValidTo
        )
        SELECT 
            CustomerID,
            PhoneNumber,
            FaxNumber,
            WebsiteURL,
            CreditLimit,
            AccountOpenedDate,
            StandardDiscountPercentage,
            IsStatementSent,
            IsOnCreditHold,
            PaymentDays,
            DeliveryAddressLine1,
            DeliveryAddressLine2,
            DeliveryPostalCode,
            PostalAddressLine1,
            PostalAddressLine2,
            PostalPostalCode,
            LastEditedBy,
            ValidFrom,
            ValidTo
        FROM WideWorldImporters.Sales.Customers
        WHERE NOT EXISTS (
            SELECT 1 FROM Sales.Customers_Sensitive s 
            WHERE s.CustomerID = Customers.CustomerID
        );
        
        SET @sensitive_count = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        -- Verificación y resumen
        DECLARE @total_customers INT = (SELECT COUNT(*) FROM Sales.vw_Customers_Complete);
        DECLARE @customers_sj INT = (SELECT COUNT(*) FROM WWI_Sucursal_SJ.Sales.Customers_SJ);
        DECLARE @customers_lim INT = (SELECT COUNT(*) FROM WWI_Sucursal_LIM.Sales.Customers_LIM);
        DECLARE @total_sensitive INT = (SELECT COUNT(*) FROM Sales.Customers_Sensitive);
        DECLARE @avg_credit DECIMAL(18,2) = (
            SELECT AVG(CreditLimit) 
            FROM Sales.Customers_Sensitive 
            WHERE CreditLimit IS NOT NULL
        );
        DECLARE @on_hold INT = (
            SELECT COUNT(*) 
            FROM Sales.Customers_Sensitive 
            WHERE IsOnCreditHold = 1
        );
        DECLARE @high_credit INT = (
            SELECT COUNT(*) 
            FROM Sales.Customers_Sensitive 
            WHERE CreditLimit > 10000
        );
        
        PRINT '';
        PRINT '══════════════ RESUMEN FRAGMENTACIÓN DATOS SENSIBLES ══════════════';
        PRINT CONCAT('🔒 Registros sensibles insertados:    ', @sensitive_count);
        PRINT CONCAT('🔐 Total registros sensibles:         ', @total_sensitive);
        PRINT CONCAT('👥 Clientes públicos San José:        ', @customers_sj);
        PRINT CONCAT('👥 Clientes públicos Limón:           ', @customers_lim);
        PRINT CONCAT('📊 Total clientes consolidados:       ', @total_customers);
        PRINT CONCAT('💳 Límite de crédito promedio:        $', FORMAT(@avg_credit, 'N2'));
        PRINT CONCAT('⭐ Clientes con crédito > $10,000:    ', @high_credit);
        PRINT CONCAT('⚠️  Clientes en retención de crédito: ', @on_hold);
        PRINT '═══════════════════════════════════════════════════════════════════';
        PRINT '';
        PRINT '✅ ESTRATEGIA DE FRAGMENTACIÓN VERTICAL IMPLEMENTADA:';
        PRINT '   ├─ Datos públicos (nombre, categoría, ciudad) → Sucursales';
        PRINT '   ├─ Datos sensibles (contacto, finanzas, direcciones) → Corporativo';
        PRINT '   └─ Reconstrucción mediante CustomerID con Sales.vw_Customers_Complete';
        PRINT '';
        PRINT '🔐 SEGURIDAD:';
        PRINT '   ├─ Sucursales: Solo acceso a datos NO sensibles';
        PRINT '   ├─ Corporativo: Acceso completo a datos sensibles';
        PRINT '   └─ Vista pública: Datos sensibles ofuscados para consultas generales';
        
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

PRINT '✅ Procedimiento Sales.sp_DistribuirDatosSensibles creado';
GO


-- ========================================
-- 4) FUNCIÓN PARA VERIFICAR ACCESO A DATOS SENSIBLES
-- ========================================
CREATE OR ALTER FUNCTION Sales.fn_TieneAccesoDatosSensibles(
    @UserRole NVARCHAR(50)
)
RETURNS BIT
AS
BEGIN
    DECLARE @HasAccess BIT = 0;
    
    -- Solo administradores corporativos y analistas pueden ver datos sensibles
    IF @UserRole IN ('ADMINISTRADOR_CORPORATIVO', 'ANALITICA_CORPORATIVO', 'FINANZAS')
        SET @HasAccess = 1;
    
    RETURN @HasAccess;
END;
GO

PRINT '✅ Función Sales.fn_TieneAccesoDatosSensibles creada';
GO


-- ========================================
-- 5) VISTA SEGURA SIN DATOS SENSIBLES (Para sucursales)
-- ========================================
CREATE OR ALTER VIEW Sales.vw_Customers_PublicOnly AS
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
    CASE 
        WHEN EXISTS (SELECT 1 FROM WWI_Sucursal_SJ.Sales.Customers_SJ sj WHERE sj.CustomerID = c.CustomerID) THEN 'San José'
        WHEN EXISTS (SELECT 1 FROM WWI_Sucursal_LIM.Sales.Customers_LIM lim WHERE lim.CustomerID = c.CustomerID) THEN 'Limón'
        ELSE 'Desconocido'
    END AS Sucursal,
    -- Datos sensibles OFUSCADOS
    '(***) ***-****' AS PhoneNumber,
    '(***) ***-****' AS FaxNumber,
    'http://www.******.com' AS WebsiteURL,
    NULL AS CreditLimit,
    s.AccountOpenedDate,
    NULL AS StandardDiscountPercentage,
    0 AS IsStatementSent,
    ISNULL(s.IsOnCreditHold, 0) AS IsOnCreditHold,
    0 AS PaymentDays,
    '*** [Confidencial] ***' AS DeliveryAddressLine1,
    NULL AS DeliveryAddressLine2,
    '****' AS DeliveryPostalCode,
    '*** [Confidencial] ***' AS PostalAddressLine1,
    NULL AS PostalAddressLine2,
    '****' AS PostalPostalCode
FROM (
    SELECT CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, 
           BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID,
           DeliveryMethodID, DeliveryCityID, PostalCityID
    FROM WWI_Sucursal_SJ.Sales.Customers_SJ
    UNION ALL
    SELECT CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID,
           BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID,
           DeliveryMethodID, DeliveryCityID, PostalCityID
    FROM WWI_Sucursal_LIM.Sales.Customers_LIM
) c
LEFT JOIN Sales.Customers_Sensitive s ON c.CustomerID = s.CustomerID;
GO

PRINT '✅ Vista Sales.vw_Customers_PublicOnly creada (datos sensibles ofuscados)';
GO


-- ========================================
-- 6) VISTA DE ANÁLISIS FINANCIERO (Solo Corporativo)
-- ========================================
CREATE OR ALTER VIEW Sales.vw_Customers_Financial_Analysis AS
SELECT 
    s.CustomerID,
    c.CustomerName,
    c.Sucursal,
    s.CreditLimit,
    s.StandardDiscountPercentage,
    s.IsOnCreditHold,
    s.PaymentDays,
    s.AccountOpenedDate,
    DATEDIFF(YEAR, s.AccountOpenedDate, GETDATE()) AS AñosComoCliente,
    CASE 
        WHEN s.CreditLimit IS NULL THEN 'Sin Crédito'
        WHEN s.CreditLimit < 5000 THEN 'Crédito Bajo'
        WHEN s.CreditLimit < 10000 THEN 'Crédito Medio'
        WHEN s.CreditLimit < 50000 THEN 'Crédito Alto'
        ELSE 'Crédito Premium'
    END AS NivelCredito,
    CASE 
        WHEN s.PaymentDays <= 7 THEN 'Pago Inmediato'
        WHEN s.PaymentDays <= 15 THEN 'Pago Rápido'
        WHEN s.PaymentDays <= 30 THEN 'Pago Normal'
        ELSE 'Pago Extendido'
    END AS CategoríaPago
FROM Sales.Customers_Sensitive s
INNER JOIN Sales.vw_Customers_Complete c ON s.CustomerID = c.CustomerID;
GO

PRINT '✅ Vista Sales.vw_Customers_Financial_Analysis creada';
GO


PRINT '';
PRINT '═══════════════════════════════════════════════════════════════════════';
PRINT '🚀 INSTRUCCIONES DE USO:';
PRINT '';
PRINT '1️⃣  DISTRIBUIR DATOS SENSIBLES:';
PRINT '   EXEC WWI_Corporativo.Sales.sp_DistribuirDatosSensibles;';
PRINT '';
PRINT '2️⃣  CONSULTAR DATOS COMPLETOS (Solo Corporativo):';
PRINT '   SELECT TOP 10 * FROM WWI_Corporativo.Sales.vw_Customers_Complete;';
PRINT '';
PRINT '3️⃣  CONSULTAR DATOS PÚBLICOS (Sucursales):';
PRINT '   SELECT TOP 10 * FROM WWI_Corporativo.Sales.vw_Customers_PublicOnly;';
PRINT '';
PRINT '4️⃣  ANÁLISIS FINANCIERO (Solo Corporativo):';
PRINT '   SELECT * FROM WWI_Corporativo.Sales.vw_Customers_Financial_Analysis';
PRINT '   WHERE IsOnCreditHold = 1 OR CreditLimit > 50000;';
PRINT '';
PRINT '5️⃣  VERIFICAR FRAGMENTACIÓN:';
PRINT '   -- Contar datos sensibles';
PRINT '   SELECT COUNT(*) AS TotalDatosSensibles FROM Sales.Customers_Sensitive;';
PRINT '   ';
PRINT '   -- Contar clientes por sucursal';
PRINT '   SELECT Sucursal, COUNT(*) AS Total ';
PRINT '   FROM Sales.vw_Customers_Complete GROUP BY Sucursal;';
PRINT '═══════════════════════════════════════════════════════════════════════';
GO