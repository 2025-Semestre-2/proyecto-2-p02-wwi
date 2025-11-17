/*
================================================================================
MIGRACIÓN CORPORATIVO: WideWorldImporters a WWI_Corporativo
================================================================================
*/
USE WWI_Corporativo;
GO

-- ========================================
-- 1) CATÁLOGO MAESTRO DE PRODUCTOS
-- ========================================
PRINT '=== MIGRANDO PRODUCTOS ===';

INSERT INTO Warehouse.StockItems_Master (
    StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
    OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
    IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
    TypicalWeightPerUnit, MarketingComments, InternalComments, LastEditedBy,
    AvailableInSJ, AvailableInLIM, IsActive
)
SELECT 
    StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
    OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
    IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
    TypicalWeightPerUnit, MarketingComments, InternalComments, LastEditedBy,
    1, 1, 1  -- Disponible en ambas sucursales
FROM WideWorldImporters.Warehouse.StockItems
WHERE NOT EXISTS (
    SELECT 1 FROM Warehouse.StockItems_Master m 
    WHERE m.StockItemID = StockItems.StockItemID
);

PRINT  CAST(@@ROWCOUNT AS VARCHAR) + ' productos migrados a catálogo maestro';

-- ========================================
-- 2) DATOS SENSIBLES DE CLIENTES
-- ========================================
PRINT '=== MIGRANDO DATOS SENSIBLES CLIENTES ===';

INSERT INTO Sales.Customers_Sensitive (
    CustomerID, PhoneNumber, FaxNumber, WebsiteURL, CreditLimit,
    AccountOpenedDate, StandardDiscountPercentage, IsStatementSent,
    IsOnCreditHold, PaymentDays, DeliveryAddressLine1, DeliveryAddressLine2,
    DeliveryPostalCode, PostalAddressLine1, PostalAddressLine2,
    PostalPostalCode, LastEditedBy, ValidFrom, ValidTo
)
SELECT 
    CustomerID, PhoneNumber, FaxNumber, WebsiteURL, CreditLimit,
    AccountOpenedDate, StandardDiscountPercentage, IsStatementSent,
    IsOnCreditHold, PaymentDays, DeliveryAddressLine1, DeliveryAddressLine2,
    DeliveryPostalCode, PostalAddressLine1, PostalAddressLine2,
    PostalPostalCode, LastEditedBy, ValidFrom, ValidTo
FROM WideWorldImporters.Sales.Customers
WHERE NOT EXISTS (
    SELECT 1 FROM Sales.Customers_Sensitive s 
    WHERE s.CustomerID = Customers.CustomerID
);

PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' registros sensibles migrados';

GO

-- ========================================
-- 5) RESUMEN FINAL
-- ========================================
PRINT '';
PRINT '══════════════════════ RESUMEN MIGRACIÓN ══════════════════════';

DECLARE @productos INT = (SELECT COUNT(*) FROM Warehouse.StockItems_Master);
PRINT 'Productos en catálogo maestro: ' + CAST(@productos AS VARCHAR);

DECLARE @sensibles INT = (SELECT COUNT(*) FROM Sales.Customers_Sensitive);
PRINT 'Datos sensibles clientes: ' + CAST(@sensibles AS VARCHAR);

PRINT '═══════════════════════════════════════════════════════════════';
GO