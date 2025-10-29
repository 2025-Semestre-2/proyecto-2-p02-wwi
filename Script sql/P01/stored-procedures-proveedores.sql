-- =====================================================
-- Procedimientos Almacenados COMPLETOS - Módulo de Proveedores
-- Wide World Importers Database
-- Proyecto 1 - Bases de Datos 2
-- =====================================================

USE WideWorldImporters;
GO

-- =====================================================
-- sp_SearchSuppliers
-- Buscar proveedores con filtros avanzados y paginación
-- =====================================================
CREATE OR ALTER PROCEDURE sp_SearchSuppliers
    @SearchText NVARCHAR(100) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @OrderBy NVARCHAR(50) = 'SupplierName',
    @OrderDirection NVARCHAR(4) = 'ASC'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    DECLARE @SQL NVARCHAR(MAX);
    
    SET @SQL = '
    SELECT 
        s.SupplierID,
        s.SupplierName,
        sc.SupplierCategoryName,
        dm.DeliveryMethodName,
        s.SupplierReference,
        s.PhoneNumber,
        s.FaxNumber,
        s.WebsiteURL,
        s.BankAccountName,
        s.BankAccountBranch,
        s.BankAccountCode,
        s.BankAccountNumber,
        s.BankInternationalCode,
        s.PaymentDays,
        dc.CityName AS DeliveryCityName,
        dsp.StateProvinceName AS DeliveryStateProvinceName,
        dco.CountryName AS DeliveryCountryName,
        s.DeliveryAddressLine1,
        s.DeliveryAddressLine2,
        s.DeliveryPostalCode,
        dc.Location.Lat AS DeliveryLatitude,
        dc.Location.Long AS DeliveryLongitude,
        s.PostalAddressLine1,
        s.PostalAddressLine2,
        s.PostalPostalCode,
        pc.FullName AS PrimaryContactPerson,
        pc.PhoneNumber AS PrimaryContactPhone,
        pc.EmailAddress AS PrimaryContactEmail,
        ac.FullName AS AlternateContactPerson,
        ac.PhoneNumber AS AlternateContactPhone,
        ac.EmailAddress AS AlternateContactEmail
    FROM Purchasing.Suppliers s
    LEFT JOIN Purchasing.SupplierCategories sc ON s.SupplierCategoryID = sc.SupplierCategoryID
    LEFT JOIN Application.DeliveryMethods dm ON s.DeliveryMethodID = dm.DeliveryMethodID
    LEFT JOIN Application.Cities dc ON s.DeliveryCityID = dc.CityID
    LEFT JOIN Application.StateProvinces dsp ON dc.StateProvinceID = dsp.StateProvinceID
    LEFT JOIN Application.Countries dco ON dsp.CountryID = dco.CountryID
    LEFT JOIN Application.People pc ON s.PrimaryContactPersonID = pc.PersonID
    LEFT JOIN Application.People ac ON s.AlternateContactPersonID = ac.PersonID
    WHERE 1=1';

    -- Aplicar filtros de búsqueda
    IF @SearchText IS NOT NULL AND @SearchText != ''
    BEGIN
        SET @SQL = @SQL + ' AND (s.SupplierName LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%'' 
                              OR sc.SupplierCategoryName LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%''
                              OR s.SupplierReference LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%'')';
    END

    -- Aplicar ordenamiento seguro
    IF @OrderBy IN ('SupplierName', 'SupplierCategoryName', 'DeliveryMethodName', 'DeliveryCityName', 'PaymentDays')
    BEGIN
        SET @SQL = @SQL + ' ORDER BY ';
        SET @SQL = @SQL + CASE @OrderBy
            WHEN 'SupplierName' THEN 's.SupplierName'
            WHEN 'SupplierCategoryName' THEN 'sc.SupplierCategoryName'
            WHEN 'DeliveryMethodName' THEN 'dm.DeliveryMethodName'
            WHEN 'DeliveryCityName' THEN 'dc.CityName'
            WHEN 'PaymentDays' THEN 's.PaymentDays'
            ELSE 's.SupplierName'
        END;
        
        IF @OrderDirection = 'DESC'
            SET @SQL = @SQL + ' DESC';
        ELSE
            SET @SQL = @SQL + ' ASC';
    END
    ELSE
    BEGIN
        SET @SQL = @SQL + ' ORDER BY s.SupplierName ASC';
    END

    -- Aplicar paginación
    SET @SQL = @SQL + ' OFFSET ' + CAST(@Offset AS NVARCHAR(10)) + ' ROWS FETCH NEXT ' + CAST(@PageSize AS NVARCHAR(10)) + ' ROWS ONLY';
    
    EXEC sp_executesql @SQL;

    -- Obtener total de registros para paginación
    DECLARE @CountSQL NVARCHAR(MAX);
    SET @CountSQL = '
    SELECT COUNT(*) AS TotalRegistros
    FROM Purchasing.Suppliers s
    LEFT JOIN Purchasing.SupplierCategories sc ON s.SupplierCategoryID = sc.SupplierCategoryID
    WHERE 1=1';

    IF @SearchText IS NOT NULL AND @SearchText != ''
    BEGIN
        SET @CountSQL = @CountSQL + ' AND (s.SupplierName LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%'' 
                                          OR sc.SupplierCategoryName LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%''
                                          OR s.SupplierReference LIKE ''%' + REPLACE(@SearchText, '''', '''''') + '%'')';
    END

    EXEC sp_executesql @CountSQL;
END
GO

-- =====================================================
-- sp_GetSupplierDetails
-- Obtener detalles COMPLETOS de un proveedor específico
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetSupplierDetails
    @SupplierID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.SupplierID,
        s.SupplierName,
        s.SupplierReference,
        sc.SupplierCategoryName AS Categoria,
        dm.DeliveryMethodName AS MetodoEntrega,
        s.PaymentDays,
        s.PhoneNumber,
        s.FaxNumber,
        s.WebsiteURL,
        s.BankAccountName,
        s.BankAccountBranch,
        s.BankAccountCode,
        s.BankAccountNumber,
        s.BankInternationalCode,
        
        -- Dirección de Entrega
        s.DeliveryAddressLine1,
        s.DeliveryAddressLine2,
        s.DeliveryPostalCode,
        dc.CityName AS CiudadEntrega,
        dsp.StateProvinceName AS EstadoEntrega,
        dco.CountryName AS PaisEntrega,
        dc.Location.Lat AS LatitudEntrega,
        dc.Location.Long AS LongitudEntrega,
        
        -- Dirección Postal 
        s.PostalAddressLine1,
        s.PostalAddressLine2,
        s.PostalPostalCode,
        pc.CityName AS CiudadPostal,
        psp.StateProvinceName AS EstadoPostal,
        pco.CountryName AS PaisPostal,
        
        -- Contacto Primario 
        pcp.FullName AS ContactoPrimarioNombre,
        pcp.PreferredName AS ContactoPrimarioNombrePreferido,
        pcp.PhoneNumber AS ContactoPrimarioTelefono,
        pcp.FaxNumber AS ContactoPrimarioFax,
        pcp.EmailAddress AS ContactoPrimarioEmail,
        
        -- Contacto Alternativo 
        pca.FullName AS ContactoAlternativoNombre,
        pca.PreferredName AS ContactoAlternativoNombrePreferido,
        pca.PhoneNumber AS ContactoAlternativoTelefono,
        pca.FaxNumber AS ContactoAlternativoFax,
        pca.EmailAddress AS ContactoAlternativoEmail

    FROM Purchasing.Suppliers s
    LEFT JOIN Purchasing.SupplierCategories sc ON s.SupplierCategoryID = sc.SupplierCategoryID
    LEFT JOIN Application.DeliveryMethods dm ON s.DeliveryMethodID = dm.DeliveryMethodID
    
    -- Joins para dirección de entrega
    LEFT JOIN Application.Cities dc ON s.DeliveryCityID = dc.CityID
    LEFT JOIN Application.StateProvinces dsp ON dc.StateProvinceID = dsp.StateProvinceID
    LEFT JOIN Application.Countries dco ON dsp.CountryID = dco.CountryID
    
    -- Joins para dirección postal
    LEFT JOIN Application.Cities pc ON s.PostalCityID = pc.CityID
    LEFT JOIN Application.StateProvinces psp ON pc.StateProvinceID = psp.StateProvinceID
    LEFT JOIN Application.Countries pco ON psp.CountryID = pco.CountryID
    
    -- Joins para contactos
    LEFT JOIN Application.People pcp ON s.PrimaryContactPersonID = pcp.PersonID
    LEFT JOIN Application.People pca ON s.AlternateContactPersonID = pca.PersonID
    
    WHERE s.SupplierID = @SupplierID;
END
GO

-- =====================================================
-- sp_GetSupplierCategories
-- Obtener categorías de proveedores para filtros dinámicos
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetSupplierCategories
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        sc.SupplierCategoryID,
        sc.SupplierCategoryName,
        COUNT(s.SupplierID) AS CantidadProveedores
    FROM Purchasing.SupplierCategories sc
    LEFT JOIN Purchasing.Suppliers s ON sc.SupplierCategoryID = s.SupplierCategoryID
    GROUP BY sc.SupplierCategoryID, sc.SupplierCategoryName
    ORDER BY sc.SupplierCategoryName;
END
GO

-- =====================================================
-- sp_GetSuppliersEstadisticas
-- Estadísticas de proveedores con ROLLUP
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetSuppliersEstadisticas
    @SearchText NVARCHAR(100) = NULL,
    @Category NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        sc.SupplierCategoryName,
        COUNT(s.SupplierID) AS TotalProveedores,
        AVG(CAST(s.PaymentDays AS FLOAT)) AS DiasPromedioPago,
        COUNT(CASE WHEN s.WebsiteURL IS NOT NULL AND s.WebsiteURL != '' THEN 1 END) AS ProveedoresConSitioWeb,
        COUNT(CASE WHEN s.BankAccountNumber IS NOT NULL AND s.BankAccountNumber != '' THEN 1 END) AS ProveedoresConCuentaBancaria
        
    FROM Purchasing.Suppliers s
    LEFT JOIN Purchasing.SupplierCategories sc ON s.SupplierCategoryID = sc.SupplierCategoryID
    
    WHERE 1=1
        AND (@SearchText IS NULL OR @SearchText = '' OR s.SupplierName LIKE '%' + @SearchText + '%')
        AND (@Category IS NULL OR @Category = '' OR sc.SupplierCategoryName LIKE '%' + @Category + '%')
        
    GROUP BY ROLLUP(sc.SupplierCategoryName)
    
    ORDER BY 
        CASE WHEN sc.SupplierCategoryName IS NULL THEN 1 ELSE 0 END,
        TotalProveedores DESC,
        sc.SupplierCategoryName;
END
GO

-- =====================================================
-- sp_GetTopSuppliersByPaymentTerms
-- Top proveedores por términos de pago usando DENSE_RANK
-- =====================================================
CREATE OR ALTER PROCEDURE sp_GetTopSuppliersByPaymentTerms
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH SuppliersRanking AS (
        SELECT 
            s.SupplierID,
            s.SupplierName,
            sc.SupplierCategoryName,
            s.PaymentDays,
            s.WebsiteURL,
            dc.CityName AS CiudadEntrega,
            DENSE_RANK() OVER (
                ORDER BY s.PaymentDays ASC
            ) AS RankingPagos
            
        FROM Purchasing.Suppliers s
        LEFT JOIN Purchasing.SupplierCategories sc ON s.SupplierCategoryID = sc.SupplierCategoryID
        LEFT JOIN Application.Cities dc ON s.DeliveryCityID = dc.CityID
        WHERE s.PaymentDays IS NOT NULL
    )
    
    SELECT 
        RankingPagos,
        SupplierID,
        SupplierName,
        SupplierCategoryName,
        PaymentDays,
        WebsiteURL,
        CiudadEntrega
        
    FROM SuppliersRanking
    WHERE RankingPagos <= 15
    ORDER BY RankingPagos ASC;
END
GO

PRINT 'Procedimientos almacenados COMPLETOS para el módulo de Proveedores creados exitosamente.';
PRINT 'Procedimientos creados:';
PRINT '   - sp_SearchSuppliers (Búsqueda con filtros y paginación)';
PRINT '   - sp_GetSupplierDetails (Detalles completos del proveedor)';
PRINT '   - sp_GetSupplierCategories (Categorías para filtros)';
PRINT '   - sp_GetSuppliersEstadisticas (Estadísticas con ROLLUP)';
PRINT '   - sp_GetTopSuppliersByPaymentTerms (Top proveedores con DENSE_RANK)';
PRINT '';