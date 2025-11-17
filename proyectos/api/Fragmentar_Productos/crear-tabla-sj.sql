USE WWI_Sucursal_SJ;

IF OBJECT_ID('Warehouse.StockItems_SJ', 'U') IS NOT NULL
    DROP TABLE Warehouse.StockItems_SJ;

CREATE TABLE Warehouse.StockItems_SJ (
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
    QuantityOnHand INT NOT NULL DEFAULT 0,
    BinLocation NVARCHAR(20) NULL,
    LastStockTake DATETIME2 NULL,
    CONSTRAINT CHK_StockItems_SJ_Quantity CHECK (QuantityOnHand >= 0)
);

CREATE NONCLUSTERED INDEX IX_StockItems_SJ_Name ON Warehouse.StockItems_SJ(StockItemName);
CREATE NONCLUSTERED INDEX IX_StockItems_SJ_SupplierID ON Warehouse.StockItems_SJ(SupplierID);

PRINT 'Tabla Warehouse.StockItems_SJ creada en WWI_Sucursal_SJ';