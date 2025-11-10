-- ============================================================================
-- SEQUENCES para generar IDs automáticos
-- ============================================================================
-- Estas sequences se usan en los DEFAULT constraints de las tablas
-- ============================================================================

USE WWI_Corporativo;
GO

-- Schema Sequences ya fue creado en tables.sql

-- Application Sequences
CREATE SEQUENCE [Sequences].[CityID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[CountryID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[DeliveryMethodID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[PaymentMethodID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[PersonID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[StateProvinceID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[SystemParameterID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[TransactionTypeID] START WITH 1 INCREMENT BY 1;
GO

-- Purchasing Sequences
CREATE SEQUENCE [Sequences].[PurchaseOrderID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[PurchaseOrderLineID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[SupplierID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[SupplierCategoryID] START WITH 1 INCREMENT BY 1;
GO

-- Sales Sequences
CREATE SEQUENCE [Sequences].[BuyingGroupID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[CustomerID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[CustomerCategoryID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[InvoiceID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[InvoiceLineID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[OrderID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[OrderLineID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[SpecialDealID] START WITH 1 INCREMENT BY 1;
GO

-- Warehouse Sequences
CREATE SEQUENCE [Sequences].[ColorID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[PackageTypeID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[StockGroupID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[StockItemID] START WITH 1 INCREMENT BY 1;
GO
CREATE SEQUENCE [Sequences].[StockItemStockGroupID] START WITH 1 INCREMENT BY 1;
GO

-- Transaction Sequences (usadas por múltiples tablas)
CREATE SEQUENCE [Sequences].[TransactionID] START WITH 1 INCREMENT BY 1;
GO

PRINT 'Sequences creadas exitosamente en WWI_Corporativo';
GO
