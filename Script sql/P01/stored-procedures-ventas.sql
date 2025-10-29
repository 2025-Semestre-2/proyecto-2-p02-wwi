-- =====================================================
-- Procedimientos Almacenados COMPLETOS - Módulo de Ventas
-- Wide World Importers Database
-- Proyecto 1 - Bases de Datos 2
-- =====================================================

USE WideWorldImporters;
GO

-- =====================================================
-- sp_SearchSales
-- Buscar ventas (facturas) con filtros avanzados y paginación
-- =====================================================
CREATE OR ALTER PROCEDURE sp_SearchSales
    @SearchText NVARCHAR(100) = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @MinAmount DECIMAL(18,2) = NULL,
    @MaxAmount DECIMAL(18,2) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @OrderBy NVARCHAR(50) = 'CustomerName',
    @OrderDirection NVARCHAR(4) = 'ASC'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    DECLARE @OrderByClause NVARCHAR(200);

    -- Construir ORDER BY seguro
    SET @OrderByClause = 
        CASE 
            WHEN @OrderBy = 'CustomerName' THEN 'c.CustomerName'
            WHEN @OrderBy = 'InvoiceDate' THEN 'i.InvoiceDate'
            WHEN @OrderBy = 'TotalAmount' THEN 'TotalAmount'
            ELSE 'c.CustomerName'
        END + ' ' + 
        CASE WHEN @OrderDirection IN ('ASC', 'DESC') THEN @OrderDirection ELSE 'ASC' END;

    -- Consulta principal con paginación
    WITH InvoiceTotals AS (
        SELECT 
            i.InvoiceID,
            SUM(il.ExtendedPrice) AS TotalAmount
        FROM Sales.Invoices i
        INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
        GROUP BY i.InvoiceID
    )
    SELECT 
        i.InvoiceID,
        i.InvoiceDate,
        c.CustomerName,
        dm.DeliveryMethodName,
        it.TotalAmount,
        i.CustomerPurchaseOrderNumber,
        cp.FullName AS ContactPersonName,
        sp.FullName AS SalespersonName,
        i.DeliveryInstructions
    FROM Sales.Invoices i
    INNER JOIN InvoiceTotals it ON i.InvoiceID = it.InvoiceID
    INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
    INNER JOIN Application.DeliveryMethods dm ON i.DeliveryMethodID = dm.DeliveryMethodID
    INNER JOIN Application.People cp ON i.ContactPersonID = cp.PersonID
    INNER JOIN Application.People sp ON i.SalespersonPersonID = sp.PersonID
    WHERE 
        (@SearchText IS NULL OR 
         c.CustomerName LIKE '%' + @SearchText + '%')
        AND (@StartDate IS NULL OR i.InvoiceDate >= @StartDate)
        AND (@EndDate IS NULL OR i.InvoiceDate <= @EndDate)
        AND (@MinAmount IS NULL OR it.TotalAmount >= @MinAmount)
        AND (@MaxAmount IS NULL OR it.TotalAmount <= @MaxAmount)
    ORDER BY 
        CASE WHEN @OrderByClause IS NOT NULL THEN 1 ELSE 1 END
    OFFSET @Offset ROWS 
    FETCH NEXT @PageSize ROWS ONLY;

    -- Total count
    WITH InvoiceTotals AS (
        SELECT 
            i.InvoiceID,
            SUM(il.ExtendedPrice) AS TotalAmount
        FROM Sales.Invoices i
        INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
        GROUP BY i.InvoiceID
    )
    SELECT COUNT(*) AS TotalCount
    FROM Sales.Invoices i
    INNER JOIN InvoiceTotals it ON i.InvoiceID = it.InvoiceID
    INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
    WHERE 
        (@SearchText IS NULL OR 
         c.CustomerName LIKE '%' + @SearchText + '%')
        AND (@StartDate IS NULL OR i.InvoiceDate >= @StartDate)
        AND (@EndDate IS NULL OR i.InvoiceDate <= @EndDate)
        AND (@MinAmount IS NULL OR it.TotalAmount >= @MinAmount)
        AND (@MaxAmount IS NULL OR it.TotalAmount <= @MaxAmount);
END;
GO

-- =====================================================
-- sp_GetInvoiceDetails
-- Obtener detalles completos de una venta (factura)
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetInvoiceDetails
    @InvoiceID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Encabezado de la factura
    SELECT 
        i.InvoiceID,
        i.InvoiceDate,
        c.CustomerID,
        c.CustomerName,
        bc.CustomerName AS BillToCustomerName,
        dm.DeliveryMethodName,
        i.CustomerPurchaseOrderNumber,
        cp.FullName AS ContactPersonName,
        ap.FullName AS AccountsPersonName,
        sp.FullName AS SalespersonName,
        pp.FullName AS PackedByPersonName,
        i.IsCreditNote,
        i.CreditNoteReason,
        i.Comments,
        i.DeliveryInstructions,
        i.InternalComments,
        i.TotalDryItems,
        i.TotalChillerItems,
        i.DeliveryRun,
        i.RunPosition,
        i.ConfirmedDeliveryTime,
        i.ConfirmedReceivedBy
    FROM Sales.Invoices i
    INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
    INNER JOIN Sales.Customers bc ON i.BillToCustomerID = bc.CustomerID
    INNER JOIN Application.DeliveryMethods dm ON i.DeliveryMethodID = dm.DeliveryMethodID
    INNER JOIN Application.People cp ON i.ContactPersonID = cp.PersonID
    INNER JOIN Application.People ap ON i.AccountsPersonID = ap.PersonID
    INNER JOIN Application.People sp ON i.SalespersonPersonID = sp.PersonID
    INNER JOIN Application.People pp ON i.PackedByPersonID = pp.PersonID
    WHERE i.InvoiceID = @InvoiceID;

    -- Líneas de la factura
    SELECT 
        il.InvoiceLineID,
        il.StockItemID,
        si.StockItemName,
        il.Description,
        pt.PackageTypeName,
        il.Quantity,
        il.UnitPrice,
        il.TaxRate,
        il.TaxAmount,
        il.LineProfit,
        il.ExtendedPrice
    FROM Sales.InvoiceLines il
    INNER JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID
    INNER JOIN Warehouse.PackageTypes pt ON il.PackageTypeID = pt.PackageTypeID
    WHERE il.InvoiceID = @InvoiceID
    ORDER BY il.InvoiceLineID;
END;
GO

PRINT 'Procedimientos almacenados COMPLETOS para el módulo de Ventas creados exitosamente.';
PRINT 'Procedimientos creados:';
PRINT '   - sp_SearchSales (Búsqueda con filtros y paginación)';
PRINT '   - sp_GetInvoiceDetails (Detalles completos de la factura)';
PRINT '';
