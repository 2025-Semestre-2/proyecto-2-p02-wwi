-- =====================================================
-- Procedimientos Almacenados COMPLETOS - Módulo de Clientes
-- Wide World Importers Database
-- Proyecto 1 - Bases de Datos 2
-- =====================================================

USE WideWorldImporters;
GO

-- =====================================================
-- sp_GetClientesCompleto
-- Obtiene la lista COMPLETA de clientes con toda la información necesaria para la tabla
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetClientesCompleto
    @SearchText NVARCHAR(100) = NULL,
    @OrderBy NVARCHAR(50) = 'CustomerName',
    @OrderDirection NVARCHAR(4) = 'ASC',
    @PageNumber INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    DECLARE @SQL NVARCHAR(MAX);
    
    SET @SQL = '
    SELECT 
        -- Información básica del cliente
        c.CustomerID,
        c.CustomerName,
        cc.CustomerCategoryName AS Categoria,
        dm.DeliveryMethodName AS MetodoEntrega,
        
        -- Información de contacto básica para la tabla
        c.PhoneNumber,
        c.FaxNumber,
        c.WebsiteURL,
        
        -- Información de ubicación para la tabla
        dc.CityName AS CiudadEntrega,
        dsp.StateProvinceName AS EstadoEntrega,
        dco.CountryName AS PaisEntrega,
        
        -- Información financiera
        c.CreditLimit,
        c.AccountOpenedDate,
        c.PaymentDays,
        c.StandardDiscountPercentage,
        
        -- Estado del cliente
        CASE 
            WHEN c.IsOnCreditHold = 1 THEN ''En Hold de Crédito''
            ELSE ''Activo''
        END AS EstadoCredito,
        
        -- Información adicional para filtros
        bg.BuyingGroupName AS GrupoCompra,
        
        -- Contacto primario básico
        pc.FullName AS ContactoPrimarioNombre,
        pc.EmailAddress AS ContactoPrimarioEmail
        
    FROM Sales.Customers c
    INNER JOIN Sales.CustomerCategories cc ON c.CustomerCategoryID = cc.CustomerCategoryID
    INNER JOIN Application.DeliveryMethods dm ON c.DeliveryMethodID = dm.DeliveryMethodID
    LEFT JOIN Application.Cities dc ON c.DeliveryCityID = dc.CityID
    LEFT JOIN Application.StateProvinces dsp ON dc.StateProvinceID = dsp.StateProvinceID
    LEFT JOIN Application.Countries dco ON dsp.CountryID = dco.CountryID
    LEFT JOIN Sales.BuyingGroups bg ON c.BuyingGroupID = bg.BuyingGroupID
    LEFT JOIN Application.People pc ON c.PrimaryContactPersonID = pc.PersonID
    WHERE 1=1';
    
    -- Aplicar filtro de búsqueda si se proporciona
    IF @SearchText IS NOT NULL AND @SearchText != ''
    BEGIN
        SET @SQL = @SQL + ' AND (c.CustomerName LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%'' 
                              OR cc.CustomerCategoryName LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%''
                              OR dc.CityName LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%'')';
    END
    
    -- Aplicar ordenamiento seguro
    IF @OrderBy IN ('CustomerName', 'Categoria', 'MetodoEntrega', 'CiudadEntrega', 'CreditLimit', 'AccountOpenedDate')
    BEGIN
        SET @SQL = @SQL + ' ORDER BY ' + @OrderBy;
        
        IF @OrderDirection = 'DESC'
            SET @SQL = @SQL + ' DESC';
        ELSE
            SET @SQL = @SQL + ' ASC';
    END
    ELSE
    BEGIN
        SET @SQL = @SQL + ' ORDER BY c.CustomerName ASC';
    END
    
    -- Aplicar paginación
    SET @SQL = @SQL + ' OFFSET ' + CAST(@Offset AS NVARCHAR(10)) + ' ROWS FETCH NEXT ' + CAST(@PageSize AS NVARCHAR(10)) + ' ROWS ONLY';
    
    EXEC sp_executesql @SQL;
    
    -- Obtener total de registros para paginación
    DECLARE @CountSQL NVARCHAR(MAX);
    SET @CountSQL = '
    SELECT COUNT(*) AS TotalRegistros
    FROM Sales.Customers c
    INNER JOIN Sales.CustomerCategories cc ON c.CustomerCategoryID = cc.CustomerCategoryID
    LEFT JOIN Application.Cities dc ON c.DeliveryCityID = dc.CityID
    WHERE 1=1';
    
    IF @SearchText IS NOT NULL AND @SearchText != ''
    BEGIN
        SET @CountSQL = @CountSQL + ' AND (c.CustomerName LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%'' 
                                          OR cc.CustomerCategoryName LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%''
                                          OR dc.CityName LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%'')';
    END
    
    EXEC sp_executesql @CountSQL;
END
GO

-- =====================================================
-- sp_GetClienteDetallesCompleto
-- Obtiene los detalles COMPLETOS de un cliente específico según las especificaciones
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetClienteDetallesCompleto
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        -- Información básica del cliente
        c.CustomerID,
        c.CustomerName AS NombreCliente,
        cc.CustomerCategoryName AS Categoria,
        bg.BuyingGroupName AS GrupoCompra,
        
        -- Cliente para facturar (BillToCustomerID)
        bc.CustomerName AS ClienteFacturacion,
        
        -- Método de entrega
        dm.DeliveryMethodName AS MetodoEntrega,
        
        -- Información de entrega y ubicación
        dc.CityName AS CiudadEntrega,
        dsp.StateProvinceName AS EstadoEntrega,
        dco.CountryName AS PaisEntrega,
        c.DeliveryPostalCode AS CodigoPostalEntrega,
        c.DeliveryAddressLine1 AS DireccionEntrega1,
        c.DeliveryAddressLine2 AS DireccionEntrega2,
        
        -- Información postal
        pc.CityName AS CiudadPostal,
        psp.StateProvinceName AS EstadoPostal,
        pco.CountryName AS PaisPostal,
        c.PostalPostalCode AS CodigoPostalPostal,
        c.PostalAddressLine1 AS DireccionPostal1,
        c.PostalAddressLine2 AS DireccionPostal2,
        
        -- Información de contacto
        c.PhoneNumber AS Telefono,
        c.FaxNumber AS Fax,
        c.WebsiteURL AS SitioWeb,
        
        -- Información de pago
        c.PaymentDays AS DiasGraciaPago,
        c.CreditLimit AS LimiteCredito,
        c.AccountOpenedDate AS FechaAperturaCuenta,
        c.StandardDiscountPercentage AS PorcentajeDescuentoEstandar,
        
        -- Estado
        CASE 
            WHEN c.IsOnCreditHold = 1 THEN 'En Hold de Crédito'
            ELSE 'Activo'
        END AS EstadoCredito,
        
        c.IsStatementSent AS EnviaEstados,
        
        -- Contacto Primario COMPLETO
        pcp.FullName AS ContactoPrimarioNombre,
        pcp.PreferredName AS ContactoPrimarioNombrePreferido,
        pcp.PhoneNumber AS ContactoPrimarioTelefono,
        pcp.FaxNumber AS ContactoPrimarioFax,
        pcp.EmailAddress AS ContactoPrimarioEmail,
        
        -- Contacto Alternativo COMPLETO
        pca.FullName AS ContactoAlternativoNombre,
        pca.PreferredName AS ContactoAlternativoNombrePreferido,
        pca.PhoneNumber AS ContactoAlternativoTelefono,
        pca.FaxNumber AS ContactoAlternativoFax,
        pca.EmailAddress AS ContactoAlternativoEmail,
        
        -- Coordenadas para mapa (usando .Lat y .Long que SÍ funcionan)
        dc.Location.Lat AS LatitudEntrega,
        dc.Location.Long AS LongitudEntrega
        
    FROM Sales.Customers c
    INNER JOIN Sales.CustomerCategories cc ON c.CustomerCategoryID = cc.CustomerCategoryID
    LEFT JOIN Sales.BuyingGroups bg ON c.BuyingGroupID = bg.BuyingGroupID
    LEFT JOIN Sales.Customers bc ON c.BillToCustomerID = bc.CustomerID
    INNER JOIN Application.DeliveryMethods dm ON c.DeliveryMethodID = dm.DeliveryMethodID
    
    -- Joins para dirección de entrega
    LEFT JOIN Application.Cities dc ON c.DeliveryCityID = dc.CityID
    LEFT JOIN Application.StateProvinces dsp ON dc.StateProvinceID = dsp.StateProvinceID
    LEFT JOIN Application.Countries dco ON dsp.CountryID = dco.CountryID
    
    -- Joins para dirección postal
    LEFT JOIN Application.Cities pc ON c.PostalCityID = pc.CityID
    LEFT JOIN Application.StateProvinces psp ON pc.StateProvinceID = psp.StateProvinceID
    LEFT JOIN Application.Countries pco ON psp.CountryID = pco.CountryID
    
    -- Joins para contactos
    LEFT JOIN Application.People pcp ON c.PrimaryContactPersonID = pcp.PersonID
    LEFT JOIN Application.People pca ON c.AlternateContactPersonID = pca.PersonID
    
    WHERE c.CustomerID = @CustomerID;
END
GO

-- =====================================================
-- sp_GetClientesEstadisticasCompleto
-- Obtiene estadísticas COMPLETAS de ventas por cliente con ROLLUP según especificaciones
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetClientesEstadisticasCompleto
    @SearchText NVARCHAR(100) = NULL,
    @Categoria NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ISNULL(c.CustomerName, 'TOTAL GENERAL') AS Cliente,
        ISNULL(cc.CustomerCategoryName, 'TODAS LAS CATEGORÍAS') AS Categoria,
        COUNT(i.InvoiceID) AS CantidadFacturas,
        ISNULL(MAX(il.ExtendedPrice), 0) AS MontoMasAlto,
        ISNULL(MIN(il.ExtendedPrice), 0) AS MontoMasBajo,
        ISNULL(AVG(il.ExtendedPrice), 0) AS VentaPromedio,
        ISNULL(SUM(il.ExtendedPrice), 0) AS TotalVentas,
        ISNULL(MAX(i.InvoiceDate), '1900-01-01') AS UltimaVenta,
        CASE 
            WHEN MAX(i.InvoiceDate) IS NOT NULL 
            THEN DATEDIFF(DAY, MAX(i.InvoiceDate), GETDATE())
            ELSE NULL 
        END AS DiasDesdeUltimaVenta
        
    FROM Sales.Customers c
    INNER JOIN Sales.CustomerCategories cc ON c.CustomerCategoryID = cc.CustomerCategoryID
    LEFT JOIN Sales.Invoices i ON c.CustomerID = i.CustomerID
    LEFT JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
    
    WHERE 1=1
        AND (@SearchText IS NULL OR @SearchText = '' OR c.CustomerName LIKE '%' + @SearchText + '%')
        AND (@Categoria IS NULL OR @Categoria = '' OR cc.CustomerCategoryName LIKE '%' + @Categoria + '%')
        
    GROUP BY ROLLUP(c.CustomerName, cc.CustomerCategoryName)
    
    ORDER BY 
        CASE WHEN c.CustomerName IS NULL THEN 1 ELSE 0 END,
        TotalVentas DESC,
        c.CustomerName,
        CASE WHEN cc.CustomerCategoryName IS NULL THEN 1 ELSE 0 END,
        cc.CustomerCategoryName;
END
GO

-- =====================================================
-- sp_GetTopClientesPorAnioCompleto
-- Top 5 clientes con más facturas por año usando DENSE_RANK según especificaciones
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetTopClientesPorAnioCompleto
    @AnioInicio INT = NULL,
    @AnioFin INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Si no se especifican años, usar un rango por defecto
    IF @AnioInicio IS NULL
        SELECT @AnioInicio = MIN(YEAR(InvoiceDate)) FROM Sales.Invoices;
    
    IF @AnioFin IS NULL
        SELECT @AnioFin = MAX(YEAR(InvoiceDate)) FROM Sales.Invoices;
    
    WITH ClientesRanking AS (
        SELECT 
            YEAR(i.InvoiceDate) AS Anio,
            c.CustomerID,
            c.CustomerName,
            cc.CustomerCategoryName AS Categoria,
            COUNT(i.InvoiceID) AS CantidadFacturas,
            SUM(il.ExtendedPrice) AS MontoTotalFacturado,
            DENSE_RANK() OVER (
                PARTITION BY YEAR(i.InvoiceDate) 
                ORDER BY COUNT(i.InvoiceID) DESC, SUM(il.ExtendedPrice) DESC
            ) AS Ranking
            
        FROM Sales.Customers c
        INNER JOIN Sales.CustomerCategories cc ON c.CustomerCategoryID = cc.CustomerCategoryID
        INNER JOIN Sales.Invoices i ON c.CustomerID = i.CustomerID
        INNER JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
        
        WHERE YEAR(i.InvoiceDate) BETWEEN @AnioInicio AND @AnioFin
            
        GROUP BY 
            YEAR(i.InvoiceDate),
            c.CustomerID,
            c.CustomerName,
            cc.CustomerCategoryName
    )
    
    SELECT 
        Anio,
        Ranking,
        CustomerID,
        CustomerName,
        Categoria,
        CantidadFacturas,
        MontoTotalFacturado,
        FORMAT(MontoTotalFacturado, 'C', 'en-US') AS MontoFormateado,
        CAST(ROUND((MontoTotalFacturado * 100.0) / SUM(MontoTotalFacturado) OVER (PARTITION BY Anio), 2) AS DECIMAL(5,2)) AS PorcentajeDelTotal
        
    FROM ClientesRanking
    WHERE Ranking <= 5
    ORDER BY Anio DESC, Ranking ASC;
END
GO

-- =====================================================
-- sp_GetCategoriasClientes
-- Obtiene las categorías de clientes para filtros dinámicos
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetCategoriasClientes
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        cc.CustomerCategoryID,
        cc.CustomerCategoryName,
        COUNT(c.CustomerID) AS CantidadClientes
    FROM Sales.CustomerCategories cc
    LEFT JOIN Sales.Customers c ON cc.CustomerCategoryID = c.CustomerCategoryID
    GROUP BY cc.CustomerCategoryID, cc.CustomerCategoryName
    ORDER BY cc.CustomerCategoryName;
END
GO

PRINT 'Procedimientos almacenados COMPLETOS para el módulo de Clientes creados exitosamente.';
PRINT 'Procedimientos creados:';
PRINT '   - sp_GetClientesCompleto (Lista con paginación y filtros)';
PRINT '   - sp_GetClienteDetallesCompleto (Detalles completos con mapa)';
PRINT '   - sp_GetClientesEstadisticasCompleto (Estadísticas con ROLLUP)';
PRINT '   - sp_GetTopClientesPorAnioCompleto (Top 5 con DENSE_RANK)';
PRINT '   - sp_GetCategoriasClientes (Categorías para filtros dinámicos)';
PRINT '';
