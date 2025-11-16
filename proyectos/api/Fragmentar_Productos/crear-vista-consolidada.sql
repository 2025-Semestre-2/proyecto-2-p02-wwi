USE WWI_Corporativo;
GO

IF OBJECT_ID('Warehouse.vw_StockItems_Consolidated', 'V') IS NOT NULL
    DROP VIEW Warehouse.vw_StockItems_Consolidated;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE VIEW Warehouse.vw_StockItems_Consolidated AS
SELECT 
    m.StockItemID,
    m.StockItemName,
    m.SupplierID,
    m.ColorID,
    m.UnitPackageID,
    m.OuterPackageID,
    m.Brand,
    m.Size,
    m.TaxRate,
    m.UnitPrice,
    m.RecommendedRetailPrice,
    ISNULL(sj.QuantityOnHand, 0) AS Stock_SJ,
    ISNULL(lim.QuantityOnHand, 0) AS Stock_LIM,
    ISNULL(sj.QuantityOnHand, 0) + ISNULL(lim.QuantityOnHand, 0) AS Stock_Total,
    CASE WHEN sj.StockItemID IS NOT NULL THEN 1 ELSE 0 END AS EnSJ,
    CASE WHEN lim.StockItemID IS NOT NULL THEN 1 ELSE 0 END AS EnLIM,
    m.IsActive
FROM Warehouse.StockItems_Master m
LEFT JOIN WWI_Sucursal_SJ.Warehouse.StockItems_SJ sj ON m.StockItemID = sj.StockItemID
LEFT JOIN WWI_Sucursal_LIM.Warehouse.StockItems_LIM lim ON m.StockItemID = lim.StockItemID;
GO

PRINT 'Vista Warehouse.vw_StockItems_Consolidada creada';