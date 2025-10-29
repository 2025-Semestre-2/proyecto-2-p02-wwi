-- =====================================================
-- Procedimientos Almacenados COMPLETOS - Módulo de Estadísticas
-- Wide World Importers Database
-- Proyecto 1 - Bases de Datos 2
-- =====================================================

USE WideWorldImporters;
GO

-- 1. Estadísticas de Compras a Proveedores con ROLLUP
CREATE OR ALTER PROCEDURE sp_GetEstadisticasComprasProveedores
    @SearchTextProveedor NVARCHAR(100) = NULL,
    @SearchTextCategoria NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        COALESCE(s.SupplierName, 'TOTAL GENERAL') AS NombreProveedor,
        COALESCE(sc.SupplierCategoryName, 'TOTAL') AS Categoria,
        MAX(poi.ExpectedUnitPricePerOuter * poi.OrderedOuters) AS MontoMaximoCompra,
        MIN(poi.ExpectedUnitPricePerOuter * poi.OrderedOuters) AS MontoMinimoCompra,
        AVG(poi.ExpectedUnitPricePerOuter * poi.OrderedOuters) AS MontoPromedioCompra,
        COUNT(DISTINCT po.PurchaseOrderID) AS CantidadOrdenes,
        SUM(poi.ExpectedUnitPricePerOuter * poi.OrderedOuters) AS MontoTotalCompra
    FROM Purchasing.PurchaseOrders po
    INNER JOIN Purchasing.PurchaseOrderLines poi ON po.PurchaseOrderID = poi.PurchaseOrderID
    INNER JOIN Purchasing.Suppliers s ON po.SupplierID = s.SupplierID
    INNER JOIN Purchasing.SupplierCategories sc ON s.SupplierCategoryID = sc.SupplierCategoryID
    WHERE (@SearchTextProveedor IS NULL OR s.SupplierName LIKE '%' + @SearchTextProveedor + '%')
        AND (@SearchTextCategoria IS NULL OR sc.SupplierCategoryName LIKE '%' + @SearchTextCategoria + '%')
    GROUP BY ROLLUP(s.SupplierName, sc.SupplierCategoryName)
    ORDER BY 
        CASE WHEN s.SupplierName IS NULL THEN 1 ELSE 0 END,
        MontoTotalCompra DESC;
END
GO

-- 2. Estadísticas de Ventas a Clientes con ROLLUP
CREATE OR ALTER PROCEDURE sp_GetEstadisticasVentasClientes
    @SearchTextCliente NVARCHAR(100) = NULL,
    @SearchTextCategoria NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        COALESCE(c.CustomerName, 'TOTAL GENERAL') AS NombreCliente,
        COALESCE(ct.CustomerCategoryName, 'TOTAL') AS Categoria,
        MAX(il.UnitPrice * il.Quantity) AS MontoMaximoVenta,
        MIN(il.UnitPrice * il.Quantity) AS MontoMinimoVenta,
        AVG(il.UnitPrice * il.Quantity) AS MontoPromedioVenta,
        COUNT(DISTINCT i.InvoiceID) AS CantidadFacturas,
        SUM(il.UnitPrice * il.Quantity) AS MontoTotalVenta
    FROM Sales.Invoices i
    INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
    INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
    INNER JOIN Sales.CustomerCategories ct ON c.CustomerCategoryID = ct.CustomerCategoryID
    WHERE (@SearchTextCliente IS NULL OR c.CustomerName LIKE '%' + @SearchTextCliente + '%')
        AND (@SearchTextCategoria IS NULL OR ct.CustomerCategoryName LIKE '%' + @SearchTextCategoria + '%')
    GROUP BY ROLLUP(c.CustomerName, ct.CustomerCategoryName)
    ORDER BY 
        CASE WHEN c.CustomerName IS NULL THEN 1 ELSE 0 END,
        MontoTotalVenta DESC;
END
GO

-- 3. Top 5 Productos Más Rentables por Año con DENSE_RANK
CREATE OR ALTER PROCEDURE sp_GetTopProductosRentables
    @Anio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    WITH ProductosRentables AS (
        SELECT 
            YEAR(i.InvoiceDate) AS Anio,
            si.StockItemName AS NombreProducto,
            SUM(il.Quantity * (il.UnitPrice - il.TaxAmount)) AS GananciaTotal,
            DENSE_RANK() OVER (
                PARTITION BY YEAR(i.InvoiceDate) 
                ORDER BY SUM(il.Quantity * (il.UnitPrice - il.TaxAmount)) DESC
            ) AS Ranking
        FROM Sales.Invoices i
        INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
        INNER JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID
        WHERE (@Anio IS NULL OR YEAR(i.InvoiceDate) = @Anio)
        GROUP BY YEAR(i.InvoiceDate), si.StockItemName
    )
    SELECT 
        Anio,
        NombreProducto,
        GananciaTotal,
        Ranking
    FROM ProductosRentables
    WHERE Ranking <= 5
    ORDER BY Anio DESC, Ranking ASC;
END
GO

-- 4. Top 5 Clientes con Más Facturas por Año con DENSE_RANK
CREATE OR ALTER PROCEDURE sp_GetTopClientesFacturas
    @AnioInicio INT = NULL,
    @AnioFin INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    WITH ClientesFacturas AS (
        SELECT 
            YEAR(i.InvoiceDate) AS Anio,
            c.CustomerName AS NombreCliente,
            COUNT(DISTINCT i.InvoiceID) AS CantidadFacturas,
            SUM(il.UnitPrice * il.Quantity) AS MontoTotalFacturado,
            DENSE_RANK() OVER (
                PARTITION BY YEAR(i.InvoiceDate) 
                ORDER BY COUNT(DISTINCT i.InvoiceID) DESC, SUM(il.UnitPrice * il.Quantity) DESC
            ) AS Ranking
        FROM Sales.Invoices i
        INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
        INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
        WHERE (@AnioInicio IS NULL OR YEAR(i.InvoiceDate) >= @AnioInicio)
            AND (@AnioFin IS NULL OR YEAR(i.InvoiceDate) <= @AnioFin)
        GROUP BY YEAR(i.InvoiceDate), c.CustomerName
    )
    SELECT 
        Anio,
        NombreCliente,
        CantidadFacturas,
        MontoTotalFacturado,
        Ranking
    FROM ClientesFacturas
    WHERE Ranking <= 5
    ORDER BY Anio DESC, Ranking ASC;
END
GO

-- 5. Top 5 Proveedores con Más Órdenes de Compra por Año con DENSE_RANK
CREATE OR ALTER PROCEDURE sp_GetTopProveedoresOrdenes
    @AnioInicio INT = NULL,
    @AnioFin INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    WITH ProveedoresOrdenes AS (
        SELECT 
            YEAR(po.OrderDate) AS Anio,
            s.SupplierName AS NombreProveedor,
            COUNT(DISTINCT po.PurchaseOrderID) AS CantidadOrdenesCompra,
            SUM(poi.ExpectedUnitPricePerOuter * poi.OrderedOuters) AS MontoTotal,
            DENSE_RANK() OVER (
                PARTITION BY YEAR(po.OrderDate) 
                ORDER BY COUNT(DISTINCT po.PurchaseOrderID) DESC, SUM(poi.ExpectedUnitPricePerOuter * poi.OrderedOuters) DESC
            ) AS Ranking
        FROM Purchasing.PurchaseOrders po
        INNER JOIN Purchasing.PurchaseOrderLines poi ON po.PurchaseOrderID = poi.PurchaseOrderID
        INNER JOIN Purchasing.Suppliers s ON po.SupplierID = s.SupplierID
        WHERE (@AnioInicio IS NULL OR YEAR(po.OrderDate) >= @AnioInicio)
            AND (@AnioFin IS NULL OR YEAR(po.OrderDate) <= @AnioFin)
        GROUP BY YEAR(po.OrderDate), s.SupplierName
    )
    SELECT 
        Anio,
        NombreProveedor,
        CantidadOrdenesCompra,
        MontoTotal,
        Ranking
    FROM ProveedoresOrdenes
    WHERE Ranking <= 5
    ORDER BY Anio DESC, Ranking ASC;
END
GO

-- 6. Procedimiento para obtener años disponibles
CREATE OR ALTER PROCEDURE sp_GetAniosDisponibles
AS
BEGIN
    SET NOCOUNT ON;

    -- Años de ventas
    SELECT DISTINCT YEAR(InvoiceDate) AS Anio
    FROM Sales.Invoices
    UNION
    -- Años de compras
    SELECT DISTINCT YEAR(OrderDate) AS Anio
    FROM Purchasing.PurchaseOrders
    ORDER BY Anio DESC;
END
GO

PRINT 'Procedimientos almacenados COMPLETOS para el módulo de Estadísticas creados exitosamente.';
PRINT 'Procedimientos creados:';
PRINT '   - sp_GetEstadisticasComprasProveedores (Estadísticas compras a proveedores con ROLLUP)';
PRINT '   - sp_GetEstadisticasVentasClientes (Estadísticas ventas a clientes con ROLLUP)';
PRINT '   - sp_GetTopProductosRentables (Top 5 productos más rentables por año)';
PRINT '   - sp_GetTopClientesFacturas (Top 5 clientes con más facturas por año)';
PRINT '   - sp_GetTopProveedoresOrdenes (Top 5 proveedores con más órdenes por año)';
PRINT '   - sp_GetAniosDisponibles (Años disponibles en ventas y compras)';
PRINT '';
