/*
================================================================================
FRAGMENTACIÓN DE CLIENTES - SUCURSAL LIMÓN
================================================================================
Base de datos: WWI_Sucursal_LIM
Contiene: Clientes de Limón, Guanacaste, Puntarenas
================================================================================
*/

USE WWI_Sucursal_LIM;
GO

-- Eliminar tabla si existe
IF OBJECT_ID('Sales.Customers_LIM', 'U') IS NOT NULL
    DROP TABLE Sales.Customers_LIM;
GO

-- Crear tabla de clientes para Limón
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

-- Índices
CREATE NONCLUSTERED INDEX IX_Customers_LIM_CityID ON Sales.Customers_LIM(DeliveryCityID);
CREATE NONCLUSTERED INDEX IX_Customers_LIM_CategoryID ON Sales.Customers_LIM(CustomerCategoryID);
GO

-- Trigger para validar región
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
        RAISERROR('Error: Solo se permiten clientes de Limón, Guanacaste o Puntarenas', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

PRINT '✅ Tabla Sales.Customers_LIM creada en WWI_Sucursal_LIM';
PRINT '   Regiones permitidas: Limón, Guanacaste, Puntarenas';
GO