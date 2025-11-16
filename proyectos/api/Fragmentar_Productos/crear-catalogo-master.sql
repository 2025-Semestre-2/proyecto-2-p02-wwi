USE WWI_Corporativo;

IF OBJECT_ID('Warehouse.StockItems_Master', 'U') IS NOT NULL
    DROP TABLE Warehouse.StockItems_Master;

CREATE TABLE Warehouse.StockItems_Master (
    StockItemID INT NOT NULL PRIMARY KEY,
    StockItemName NVARCHAR(100) NOT NULL,
    SupplierID INT NOT NULL,
    ColorID INT NULL,
    UnitPackageID INT NOT NULL,
    OuterPackageID INT NOT NULL,
    Brand NVARCHAR(50) NULL,
    Size NVARCHAR(20) NULL,
    LeadTimeDays INT NOT NULL,
    QuantityPerOuter INT NOT NULL,
    IsChillerStock BIT NOT NULL,
    Barcode NVARCHAR(50) NULL,
    TaxRate DECIMAL(18,3) NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    RecommendedRetailPrice DECIMAL(18,2) NULL,
    TypicalWeightPerUnit DECIMAL(18,3) NOT NULL,
    MarketingComments NVARCHAR(MAX) NULL,
    InternalComments NVARCHAR(MAX) NULL,
    LastEditedBy INT NOT NULL,
    AvailableInSJ BIT NOT NULL DEFAULT 0,
    AvailableInLIM BIT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE NONCLUSTERED INDEX IX_StockItems_Master_Name ON Warehouse.StockItems_Master(StockItemName);

PRINT 'Tabla Warehouse.StockItems_Master creada en WWI_Corporativo';