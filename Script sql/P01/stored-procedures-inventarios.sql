-- =====================================================
-- Procedimientos Almacenados COMPLETOS - Módulo de Inventarios
-- Wide World Importers Database
-- Proyecto 1 - Bases de Datos 2
-- =====================================================

USE WideWorldImporters;
GO

-- =====================================================
-- sp_SearchStockItems
-- Buscar productos con filtros avanzados y paginación
-- =====================================================
CREATE OR ALTER PROCEDURE sp_SearchStockItems
    @SearchText NVARCHAR(100) = NULL,
    @MinQuantity INT = NULL,
    @MaxQuantity INT = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @OrderBy NVARCHAR(50) = 'StockItemName',
    @OrderDirection NVARCHAR(4) = 'ASC'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    DECLARE @SQL NVARCHAR(MAX);
    
    SET @SQL = '
    SELECT 
        si.StockItemID,
        si.StockItemName,
        sg.StockGroupName,
        sih.QuantityOnHand,
        si.Brand,
        si.Size,
        si.UnitPrice,
        si.RecommendedRetailPrice,
        si.TaxRate,
        c.ColorName,
        sup.SupplierName,
        pt_unit.PackageTypeName AS UnitPackageType,
        pt_outer.PackageTypeName AS OuterPackageType,
        si.QuantityPerOuter,
        si.Barcode,
        si.IsChillerStock,
        si.LeadTimeDays,
        sih.BinLocation,
        si.SearchDetails,
        si.Tags,
        sih.ReorderLevel,
        sih.TargetStockLevel,
        sih.LastCostPrice
    FROM Warehouse.StockItems si
    LEFT JOIN Warehouse.StockItemHoldings sih ON si.StockItemID = sih.StockItemID
    LEFT JOIN Warehouse.StockItemStockGroups sisg ON si.StockItemID = sisg.StockItemID
    LEFT JOIN Warehouse.StockGroups sg ON sisg.StockGroupID = sg.StockGroupID
    LEFT JOIN Warehouse.Colors c ON si.ColorID = c.ColorID
    LEFT JOIN Purchasing.Suppliers sup ON si.SupplierID = sup.SupplierID
    LEFT JOIN Warehouse.PackageTypes pt_unit ON si.UnitPackageID = pt_unit.PackageTypeID
    LEFT JOIN Warehouse.PackageTypes pt_outer ON si.OuterPackageID = pt_outer.PackageTypeID
    WHERE 1=1';

    -- Aplicar filtros de búsqueda
    IF @SearchText IS NOT NULL AND @SearchText != ''
    BEGIN
        SET @SQL = @SQL + ' AND (si.StockItemName LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%'' 
                              OR sg.StockGroupName LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%''
                              OR si.Brand LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%''
                              OR si.SearchDetails LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%'')';
    END

    IF @MinQuantity IS NOT NULL
    BEGIN
        SET @SQL = @SQL + ' AND sih.QuantityOnHand >= ' + CAST(@MinQuantity AS NVARCHAR(10));
    END

    IF @MaxQuantity IS NOT NULL
    BEGIN
        SET @SQL = @SQL + ' AND sih.QuantityOnHand <= ' + CAST(@MaxQuantity AS NVARCHAR(10));
    END

    -- Aplicar ordenamiento seguro
    IF @OrderBy IN ('StockItemName', 'StockGroupName', 'QuantityOnHand', 'UnitPrice', 'Brand', 'SupplierName')
    BEGIN
        SET @SQL = @SQL + ' ORDER BY ';
        SET @SQL = @SQL + CASE @OrderBy
            WHEN 'StockItemName' THEN 'si.StockItemName'
            WHEN 'StockGroupName' THEN 'sg.StockGroupName'
            WHEN 'QuantityOnHand' THEN 'sih.QuantityOnHand'
            WHEN 'UnitPrice' THEN 'si.UnitPrice'
            WHEN 'Brand' THEN 'si.Brand'
            WHEN 'SupplierName' THEN 'sup.SupplierName'
            ELSE 'si.StockItemName'
        END;
        
        IF @OrderDirection = 'DESC'
            SET @SQL = @SQL + ' DESC';
        ELSE
            SET @SQL = @SQL + ' ASC';
    END
    ELSE
    BEGIN
        SET @SQL = @SQL + ' ORDER BY si.StockItemName ASC';
    END

    -- Aplicar paginación
    SET @SQL = @SQL + ' OFFSET ' + CAST(@Offset AS NVARCHAR(10)) + ' ROWS FETCH NEXT ' + CAST(@PageSize AS NVARCHAR(10)) + ' ROWS ONLY';
    
    EXEC sp_executesql @SQL;

    -- Obtener total de registros para paginación
    DECLARE @CountSQL NVARCHAR(MAX);
    SET @CountSQL = '
    SELECT COUNT(*) AS TotalRegistros
    FROM Warehouse.StockItems si
    LEFT JOIN Warehouse.StockItemHoldings sih ON si.StockItemID = sih.StockItemID
    LEFT JOIN Warehouse.StockItemStockGroups sisg ON si.StockItemID = sisg.StockItemID
    LEFT JOIN Warehouse.StockGroups sg ON sisg.StockGroupID = sg.StockGroupID
    WHERE 1=1';

    IF @SearchText IS NOT NULL AND @SearchText != ''
    BEGIN
        SET @CountSQL = @CountSQL + ' AND (si.StockItemName LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%'' 
                                          OR sg.StockGroupName LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%''
                                          OR si.Brand LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%''
                                          OR si.SearchDetails LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%'')';
    END

    IF @MinQuantity IS NOT NULL
    BEGIN
        SET @CountSQL = @CountSQL + ' AND sih.QuantityOnHand >= ' + CAST(@MinQuantity AS NVARCHAR(10));
    END

    IF @MaxQuantity IS NOT NULL
    BEGIN
        SET @CountSQL = @CountSQL + ' AND sih.QuantityOnHand <= ' + CAST(@MaxQuantity AS NVARCHAR(10));
    END

    EXEC sp_executesql @CountSQL;
END
GO

-- =====================================================
-- sp_GetStockItemDetails
-- Obtener detalles COMPLETOS de un producto específico
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetStockItemDetails
    @StockItemID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        si.StockItemID,
        si.StockItemName,
        si.SupplierID,
        sup.SupplierName,
        si.ColorID,
        c.ColorName,
        si.UnitPackageID,
        pt_unit.PackageTypeName AS UnitPackageType,
        si.OuterPackageID,
        pt_outer.PackageTypeName AS OuterPackageType,
        si.Brand,
        si.Size,
        si.LeadTimeDays,
        si.QuantityPerOuter,
        si.IsChillerStock,
        si.Barcode,
        si.TaxRate,
        si.UnitPrice,
        si.RecommendedRetailPrice,
        si.TypicalWeightPerUnit,
        si.MarketingComments,
        si.InternalComments,
        si.Photo,
        si.CustomFields,
        si.Tags,
        si.SearchDetails,
        sih.QuantityOnHand,
        sih.BinLocation,
        sih.LastStocktakeQuantity,
        sih.LastCostPrice,
        sih.ReorderLevel,
        sih.TargetStockLevel,
        si.LastEditedBy,
        si.ValidFrom,
        si.ValidTo,
        -- Información adicional del grupo de stock
        STRING_AGG(sg.StockGroupName, ', ') AS StockGroups
    FROM Warehouse.StockItems si
    LEFT JOIN Purchasing.Suppliers sup ON si.SupplierID = sup.SupplierID
    LEFT JOIN Warehouse.Colors c ON si.ColorID = c.ColorID
    LEFT JOIN Warehouse.PackageTypes pt_unit ON si.UnitPackageID = pt_unit.PackageTypeID
    LEFT JOIN Warehouse.PackageTypes pt_outer ON si.OuterPackageID = pt_outer.PackageTypeID
    LEFT JOIN Warehouse.StockItemHoldings sih ON si.StockItemID = sih.StockItemID
    LEFT JOIN Warehouse.StockItemStockGroups sisg ON si.StockItemID = sisg.StockItemID
    LEFT JOIN Warehouse.StockGroups sg ON sisg.StockGroupID = sg.StockGroupID
    WHERE si.StockItemID = @StockItemID
    GROUP BY 
        si.StockItemID, si.StockItemName, si.SupplierID, sup.SupplierName,
        si.ColorID, c.ColorName, si.UnitPackageID, pt_unit.PackageTypeName,
        si.OuterPackageID, pt_outer.PackageTypeName, si.Brand, si.Size,
        si.LeadTimeDays, si.QuantityPerOuter, si.IsChillerStock, si.Barcode,
        si.TaxRate, si.UnitPrice, si.RecommendedRetailPrice, si.TypicalWeightPerUnit,
        si.MarketingComments, si.InternalComments, si.Photo, si.CustomFields,
        si.Tags, si.SearchDetails, sih.QuantityOnHand, sih.BinLocation,
        sih.LastStocktakeQuantity, sih.LastCostPrice, sih.ReorderLevel,
        sih.TargetStockLevel, si.LastEditedBy, si.ValidFrom, si.ValidTo;
END
GO

-- =====================================================
-- sp_GetStockGroups
-- Obtener grupos de stock para filtros dinámicos
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetStockGroups
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        sg.StockGroupID,
        sg.StockGroupName,
        COUNT(sisg.StockItemID) AS CantidadProductos
    FROM Warehouse.StockGroups sg
    LEFT JOIN Warehouse.StockItemStockGroups sisg ON sg.StockGroupID = sisg.StockGroupID
    GROUP BY sg.StockGroupID, sg.StockGroupName
    ORDER BY sg.StockGroupName;
END
GO

-- =====================================================
-- sp_GetStockItemsEstadisticas
-- Estadísticas de inventario con ROLLUP
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetStockItemsEstadisticas
    @SearchText NVARCHAR(100) = NULL,
    @StockGroup NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        sg.StockGroupName,
        COUNT(si.StockItemID) AS TotalProductos,
        ISNULL(SUM(sih.QuantityOnHand), 0) AS CantidadTotalStock,
        ISNULL(SUM(sih.QuantityOnHand * si.UnitPrice), 0) AS ValorTotalInventario,
        ISNULL(AVG(si.UnitPrice), 0) AS PrecioPromedio,
        ISNULL(AVG(CAST(sih.QuantityOnHand AS FLOAT)), 0) AS StockPromedio
        
    FROM Warehouse.StockItems si
    LEFT JOIN Warehouse.StockItemHoldings sih ON si.StockItemID = sih.StockItemID
    LEFT JOIN Warehouse.StockItemStockGroups sisg ON si.StockItemID = sisg.StockItemID
    LEFT JOIN Warehouse.StockGroups sg ON sisg.StockGroupID = sg.StockGroupID
    
    WHERE 1=1
        AND (@SearchText IS NULL OR @SearchText = '' OR si.StockItemName LIKE '%' + @SearchText + '%')
        AND (@StockGroup IS NULL OR @StockGroup = '' OR sg.StockGroupName LIKE '%' + @StockGroup + '%')
        
    GROUP BY ROLLUP(sg.StockGroupName)
    
    ORDER BY 
        CASE WHEN sg.StockGroupName IS NULL THEN 1 ELSE 0 END,
        ValorTotalInventario DESC,
        sg.StockGroupName;
END
GO

-- =====================================================
-- sp_GetTopProductosPorVentas
-- Top 10 productos más vendidos usando DENSE_RANK
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetTopProductosPorVentas
    @AnioInicio INT = NULL,
    @AnioFin INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Si no se especifican años, usar un rango por defecto
    IF @AnioInicio IS NULL
        SELECT @AnioInicio = MIN(YEAR(il.LastEditedWhen)) FROM Sales.InvoiceLines il;
    
    IF @AnioFin IS NULL
        SELECT @AnioFin = MAX(YEAR(il.LastEditedWhen)) FROM Sales.InvoiceLines il;
    
    WITH ProductosRanking AS (
        SELECT 
            YEAR(i.InvoiceDate) AS Anio,
            si.StockItemID,
            si.StockItemName,
            SUM(il.Quantity) AS CantidadVendida,
            SUM(il.ExtendedPrice) AS IngresosTotales,
            AVG(il.UnitPrice) AS PrecioPromedio,
            COUNT(DISTINCT i.InvoiceID) AS TotalOrdenes,
            DENSE_RANK() OVER (
                PARTITION BY YEAR(i.InvoiceDate) 
                ORDER BY SUM(il.ExtendedPrice) DESC
            ) AS RankingVentas
            
        FROM Sales.InvoiceLines il
        INNER JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID
        INNER JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID
        
        WHERE YEAR(i.InvoiceDate) BETWEEN @AnioInicio AND @AnioFin
            
        GROUP BY 
            YEAR(i.InvoiceDate),
            si.StockItemID,
            si.StockItemName
    )
    
    SELECT 
        Anio,
        RankingVentas,
        StockItemID,
        StockItemName,
        CantidadVendida,
        IngresosTotales,
        PrecioPromedio,
        TotalOrdenes
        
    FROM ProductosRanking
    WHERE RankingVentas <= 10
    ORDER BY Anio DESC, RankingVentas ASC;
END
GO

PRINT 'Procedimientos almacenados COMPLETOS para el módulo de Inventarios creados exitosamente.';
PRINT 'Procedimientos creados:';
PRINT '   - sp_SearchStockItems (Búsqueda con filtros y paginación)';
PRINT '   - sp_GetStockItemDetails (Detalles completos del producto)';
PRINT '   - sp_GetStockGroups (Grupos de stock para filtros)';
PRINT '   - sp_GetStockItemsEstadisticas (Estadísticas con ROLLUP)';
PRINT '   - sp_GetTopProductosPorVentas (Top 10 con DENSE_RANK)';
PRINT '';
