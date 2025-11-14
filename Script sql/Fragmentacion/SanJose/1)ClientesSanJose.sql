/*
================================================================================
FRAGMENTACIÓN DE CLIENTES - SUCURSAL SAN JOSÉ
================================================================================
Base de datos: WWI_Sucursal_SJ
Contiene: Clientes de San José, Heredia, Alajuela, Cartago
================================================================================
*/

USE WWI_Sucursal_SJ;
GO

-- Eliminar tabla si existe
IF OBJECT_ID('Sales.Customers_SJ', 'U') IS NOT NULL
    DROP TABLE Sales.Customers_SJ;
GO

-- Crear tabla de clientes para San José
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

-- Índices
CREATE NONCLUSTERED INDEX IX_Customers_SJ_CityID ON Sales.Customers_SJ(DeliveryCityID);
CREATE NONCLUSTERED INDEX IX_Customers_SJ_CategoryID ON Sales.Customers_SJ(CustomerCategoryID);
GO

-- Trigger para validar región
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
        RAISERROR('Error: Solo se permiten clientes de San José, Heredia, Alajuela o Cartago', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

PRINT '✅ Tabla Sales.Customers_SJ creada en WWI_Sucursal_SJ';
PRINT '   Regiones permitidas: San José, Heredia, Alajuela, Cartago';
GO