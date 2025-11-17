-- ============================================================================
-- VERIFICACIÓN DE PRERREQUISITOS
-- ============================================================================
SET NOCOUNT ON;

PRINT '=== VERIFICANDO PRERREQUISITOS PARA REPLICACIÓN ===';

-- Verificar SQL Server Agent
DECLARE @AgentStatus VARCHAR(20);
SELECT @AgentStatus = 
    CASE 
        WHEN status = 4 THEN 'CORRIENDO'
        ELSE 'DETENIDO'
    END
FROM sys.dm_server_services 
WHERE servicename LIKE 'SQL Server Agent%';

PRINT 'SQL Server Agent: ' + @AgentStatus;

-- Verificar tablas requeridas
DECLARE @TablasCount INT;
SELECT @TablasCount = COUNT(*)
FROM sys.tables 
WHERE name IN ('StockItems','Colors','PackageTypes','StockGroups',
               'Suppliers','SupplierCategories','CustomerCategories',
               'BuyingGroups','StockItemHoldings','StockItemStockGroups');

PRINT 'Tablas para replicación: ' + CAST(@TablasCount AS VARCHAR) + '/10';

-- Verificar Primary Keys
DECLARE @TablasSinPK INT;
SELECT @TablasSinPK = COUNT(*)
FROM sys.tables t
LEFT JOIN sys.indexes i ON t.object_id = i.object_id AND i.is_primary_key = 1
WHERE t.name IN ('StockItems','Colors','PackageTypes','StockGroups',
                 'Suppliers','SupplierCategories','CustomerCategories',
                 'BuyingGroups','StockItemHoldings','StockItemStockGroups')
AND i.object_id IS NULL;

PRINT 'Tablas sin Primary Key: ' + CAST(@TablasSinPK AS VARCHAR);

IF @AgentStatus = 'CORRIENDO' AND @TablasCount = 10 AND @TablasSinPK = 0
    PRINT 'TODOS LOS PRERREQUISITOS CUMPLIDOS';
ELSE
    PRINT 'VERIFICAR PRERREQUISITOS ANTES DE CONTINUAR';
GO


-- ============================================================================
-- DESHABILITAR SYSTEM_VERSIONING - VERSIÓN MEJORADA
-- ============================================================================
SET NOCOUNT ON;

PRINT '=== DESHABILITANDO SYSTEM_VERSIONING EN TABLAS TEMPORALES ===';

DECLARE @TablasTemporales TABLE (SchemaName SYSNAME, TableName SYSNAME, Orden INT);
INSERT INTO @TablasTemporales VALUES
    ('Warehouse', 'StockItems', 1),
    ('Warehouse', 'Colors', 2),
    ('Warehouse', 'PackageTypes', 3),
    ('Warehouse', 'StockGroups', 4),
    ('Purchasing', 'Suppliers', 5),
    ('Purchasing', 'SupplierCategories', 6),
    ('Sales', 'CustomerCategories', 7),
    ('Sales', 'BuyingGroups', 8);

DECLARE @Schema SYSNAME, @Table SYSNAME, @Orden INT;
DECLARE @SQL NVARCHAR(MAX);

DECLARE cur_tablas CURSOR FOR 
SELECT SchemaName, TableName, Orden FROM @TablasTemporales ORDER BY Orden;

OPEN cur_tablas;
FETCH NEXT FROM cur_tablas INTO @Schema, @Table, @Orden;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Procesando: ' + @Schema + '.' + @Table;
    
    BEGIN TRY
        -- Verificar si la tabla existe y es temporal
        IF EXISTS (
            SELECT 1 FROM sys.tables 
            WHERE name = @Table AND schema_id = SCHEMA_ID(@Schema)
            AND temporal_type_desc != 'NON_TEMPORAL_TABLE'
        )
        BEGIN
            SET @SQL = 'ALTER TABLE [' + @Schema + '].[' + @Table + '] SET (SYSTEM_VERSIONING = OFF);';
            EXEC sp_executesql @SQL;
            PRINT '   Temporalidad deshabilitada';
        END
        ELSE
        BEGIN
            PRINT '   Tabla no existe o ya no es temporal';
        END
    END TRY
    BEGIN CATCH
        PRINT '   Error: ' + ERROR_MESSAGE();
    END CATCH;
    
    FETCH NEXT FROM cur_tablas INTO @Schema, @Table, @Orden;
END;

CLOSE cur_tablas;
DEALLOCATE cur_tablas;

-- Verificar estado final
PRINT '';
PRINT '=== VERIFICACIÓN FINAL ===';
SELECT 
    SCHEMA_NAME(t.schema_id) + '.' + t.name AS Tabla,
    t.temporal_type_desc AS Estado,
    CASE 
        WHEN t.temporal_type_desc = 'NON_TEMPORAL_TABLE' THEN 'Lista para replicación'
        ELSE 'Aún es temporal'
    END AS Resultado
FROM sys.tables t
WHERE t.name IN ('StockItems','Colors','PackageTypes','StockGroups',
                 'Suppliers','SupplierCategories','CustomerCategories','BuyingGroups')
ORDER BY t.name;

PRINT '=== DESHABILITACIÓN DE TEMPORALIDAD COMPLETADA ===';
GO







-- ============================================================================
-- CONFIGURACIÓN DE SERVIDORES VINCULADOS 
-- ============================================================================
SET NOCOUNT ON;

PRINT '=== CONFIGURANDO SERVIDORES VINCULADOS ===';

-- 1. SERVIDOR WWI-LIMON (Desde San José)
    EXEC sp_addlinkedserver 
        @server = N'WWI-LIMON', 
        @srvproduct = N'',
        @provider = N'SQLNCLI', 
        @datasrc = N'wwi-limon';

    EXEC sp_addlinkedsrvlogin 
        @rmtsrvname = N'WWI-LIMON', 
        @useself = N'False', 
        @locallogin = NULL, 
        @rmtuser = N'sa', 
        @rmtpassword = N'WideWorld2024!';

    EXEC sp_serveroption @server = N'WWI-LIMON', @optname = 'data access', @optvalue = 'true';
    EXEC sp_serveroption @server = N'WWI-LIMON', @optname = 'rpc', @optvalue = 'true';
    EXEC sp_serveroption @server = N'WWI-LIMON', @optname = 'rpc out', @optvalue = 'true';
    EXEC sp_serveroption @server = N'WWI-LIMON', @optname = 'remote proc transaction promotion', @optvalue = 'false';
    PRINT 'WWI-LIMON configurado';


-- 2. SERVIDOR WWI-SANJOSE (Desde Limón)

    EXEC sp_addlinkedserver 
        @server = N'WWI-SANJOSE', 
        @srvproduct = N'',
        @provider = N'SQLNCLI', 
        @datasrc = N'wwi-sanjose';

    EXEC sp_addlinkedsrvlogin 
        @rmtsrvname = N'WWI-SANJOSE', 
        @useself = N'False', 
        @locallogin = NULL, 
        @rmtuser = N'sa', 
        @rmtpassword = N'WideWorld2024!';

    EXEC sp_serveroption @server = N'WWI-SANJOSE', @optname = 'data access', @optvalue = 'true';
    EXEC sp_serveroption @server = N'WWI-SANJOSE', @optname = 'rpc', @optvalue = 'true';
    EXEC sp_serveroption @server = N'WWI-SANJOSE', @optname = 'rpc out', @optvalue = 'true';
    EXEC sp_serveroption @server = N'WWI-SANJOSE', @optname = 'remote proc transaction promotion', @optvalue = 'false';
    PRINT 'WWI-SANJOSE configurado';


-- 3. SERVIDOR WWI-CORPORATIVO (Desde cualquier sucursal)

    PRINT 'Creando servidor vinculado WWI-CORPORATIVO...';
    EXEC sp_addlinkedserver 
        @server = N'WWI-CORPORATIVO', 
        @srvproduct = N'',
        @provider = N'SQLNCLI', 
        @datasrc = N'wwi-corporativo';

    EXEC sp_addlinkedsrvlogin 
        @rmtsrvname = N'WWI-CORPORATIVO', 
        @useself = N'False', 
        @locallogin = NULL, 
        @rmtuser = N'sa', 
        @rmtpassword = N'WideWorld2024!';

    EXEC sp_serveroption @server = N'WWI-CORPORATIVO', @optname = 'data access', @optvalue = 'true';
    EXEC sp_serveroption @server = N'WWI-CORPORATIVO', @optname = 'rpc', @optvalue = 'true';
    EXEC sp_serveroption @server = N'WWI-CORPORATIVO', @optname = 'rpc out', @optvalue = 'true';
    EXEC sp_serveroption @server = N'WWI-CORPORATIVO', @optname = 'remote proc transaction promotion', @optvalue = 'false';
    PRINT 'WWI-CORPORATIVO configurado';
