USE WWI_Corporativo;

-- Insertar en catálogo maestro
INSERT INTO Warehouse.StockItems_Master (
    StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
    OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
    IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
    TypicalWeightPerUnit, MarketingComments, InternalComments, LastEditedBy,
    AvailableInSJ, AvailableInLIM, IsActive
)
SELECT
    si.StockItemID, si.StockItemName, si.SupplierID, si.ColorID, si.UnitPackageID,
    si.OuterPackageID, si.Brand, si.Size, si.LeadTimeDays, si.QuantityPerOuter,
    si.IsChillerStock, si.Barcode, si.TaxRate, si.UnitPrice, si.RecommendedRetailPrice,
    si.TypicalWeightPerUnit, si.MarketingComments, si.InternalComments, si.LastEditedBy,
    0, 0, 1
FROM WideWorldImporters.Warehouse.StockItems si
WHERE NOT EXISTS (
    SELECT 1 FROM Warehouse.StockItems_Master m 
    WHERE m.StockItemID = si.StockItemID
);

PRINT 'Productos insertados en catalogo maestro';

-- Distribuir a San José (IDs impares)
INSERT INTO WWI_Sucursal_SJ.Warehouse.StockItems_SJ (
    StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
    OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
    IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
    TypicalWeightPerUnit, MarketingComments, InternalComments, LastEditedBy,
    QuantityOnHand, BinLocation, LastStockTake
)
SELECT 
    si.StockItemID, si.StockItemName, si.SupplierID, si.ColorID, si.UnitPackageID,
    si.OuterPackageID, si.Brand, si.Size, si.LeadTimeDays, si.QuantityPerOuter,
    si.IsChillerStock, si.Barcode, si.TaxRate, si.UnitPrice, si.RecommendedRetailPrice,
    si.TypicalWeightPerUnit, si.MarketingComments, si.InternalComments, si.LastEditedBy,
    ISNULL(sh.QuantityOnHand, 10),
    'SJ-' + RIGHT('000' + CAST(si.StockItemID AS VARCHAR(10)), 3),
    GETDATE()
FROM WideWorldImporters.Warehouse.StockItems si
LEFT JOIN WideWorldImporters.Warehouse.StockItemHoldings sh ON si.StockItemID = sh.StockItemID
WHERE si.StockItemID % 2 = 1
AND NOT EXISTS (
    SELECT 1 FROM WWI_Sucursal_SJ.Warehouse.StockItems_SJ sj 
    WHERE sj.StockItemID = si.StockItemID
);

PRINT 'Productos distribuidos a San Jose';

-- Distribuir a Limón (IDs pares)
INSERT INTO WWI_Sucursal_LIM.Warehouse.StockItems_LIM (
    StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
    OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
    IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
    TypicalWeightPerUnit, MarketingComments, InternalComments, LastEditedBy,
    QuantityOnHand, BinLocation, LastStockTake
)
SELECT 
    si.StockItemID, si.StockItemName, si.SupplierID, si.ColorID, si.UnitPackageID,
    si.OuterPackageID, si.Brand, si.Size, si.LeadTimeDays, si.QuantityPerOuter,
    si.IsChillerStock, si.Barcode, si.TaxRate, si.UnitPrice, si.RecommendedRetailPrice,
    si.TypicalWeightPerUnit, si.MarketingComments, si.InternalComments, si.LastEditedBy,
    ISNULL(sh.QuantityOnHand, 15),
    'LIM-' + RIGHT('000' + CAST(si.StockItemID AS VARCHAR(10)), 3),
    GETDATE()
FROM WideWorldImporters.Warehouse.StockItems si
LEFT JOIN WideWorldImporters.Warehouse.StockItemHoldings sh ON si.StockItemID = sh.StockItemID
WHERE si.StockItemID % 2 = 0
AND NOT EXISTS (
    SELECT 1 FROM WWI_Sucursal_LIM.Warehouse.StockItems_LIM lim 
    WHERE lim.StockItemID = si.StockItemID
);

PRINT 'Productos distribuidos a Limon';

-- Actualizar flags de disponibilidad
UPDATE Warehouse.StockItems_Master
SET AvailableInSJ = CASE WHEN EXISTS (
        SELECT 1 FROM WWI_Sucursal_SJ.Warehouse.StockItems_SJ sj 
        WHERE sj.StockItemID = StockItems_Master.StockItemID
    ) THEN 1 ELSE 0 END,
    AvailableInLIM = CASE WHEN EXISTS (
        SELECT 1 FROM WWI_Sucursal_LIM.Warehouse.StockItems_LIM lim 
        WHERE lim.StockItemID = StockItems_Master.StockItemID
    ) THEN 1 ELSE 0 END;

PRINT 'Flags de disponibilidad actualizados';

-- Mostrar resumen
SELECT 
    COUNT(*) as TotalMaestro,
    SUM(CASE WHEN AvailableInSJ = 1 THEN 1 ELSE 0 END) as EnSanJose,
    SUM(CASE WHEN AvailableInLIM = 1 THEN 1 ELSE 0 END) as EnLimon
FROM Warehouse.StockItems_Master;