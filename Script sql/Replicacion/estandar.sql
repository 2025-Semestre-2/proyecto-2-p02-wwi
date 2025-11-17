-- =============================================
-- CONFIGURACIÓN DISTRIBUIDOR - TRANSACCIONAL
-- =============================================
USE [master];
GO

SET NOCOUNT ON;

PRINT '=== CONFIGURANDO DISTRIBUIDOR TRANSACCIONAL ===';

-- 1. CONFIGURAR DISTRIBUIDOR
DECLARE @distributor SYSNAME;
SELECT @distributor = @@SERVERNAME;

PRINT '   Nombre del distribuidor: ' + @distributor;

-- Eliminar distribuidor existente si existe
IF EXISTS (SELECT * FROM sys.servers WHERE is_distributor = 1)
BEGIN
    PRINT '   Eliminando distribuidor existente...';
    EXEC sp_dropdistributor @no_checks = 1;
END

EXEC sp_adddistributor 
    @distributor = @distributor, 
    @password = N'WideWorld2024!';
PRINT '   Distribuidor configurado';

-- 2. CREAR BASE DE DISTRIBUCIÓN
PRINT '2. Creando base de distribución...';
EXEC sp_adddistributiondb 
    @database = N'distribution', 
    @data_folder = N'/var/opt/mssql/data',
    @log_folder = N'/var/opt/mssql/data',       
    @log_file_size = 2,                         
    @min_distretention = 0,                     
    @max_distretention = 72,                    
    @history_retention = 48,                    
    @deletebatchsize_xact = 5000,               
    @deletebatchsize_cmd = 2000,                
    @security_mode = 1;
PRINT '   Base distribution creada';

-- 3. CONFIGURAR CARPETA DE SNAPSHOTS
PRINT '3. Configurando carpeta de snapshots...';
USE [distribution];
GO

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'UIProperties' AND type = 'U') 
    CREATE TABLE UIProperties(id INT);

IF EXISTS (SELECT * FROM ::fn_listextendedproperty('SnapshotFolder', 'user', 'dbo', 'table', 'UIProperties', NULL, NULL)) 
    EXEC sp_updateextendedproperty N'SnapshotFolder', N'/var/opt/mssql/ReplData', 'user', dbo, 'table', 'UIProperties';
ELSE 
    EXEC sp_addextendedproperty N'SnapshotFolder', N'/var/opt/mssql/ReplData', 'user', dbo, 'table', 'UIProperties';
PRINT '   Snapshot folder configurado';

-- 4. CONFIGURAR PUBLICADOR
PRINT '4. Configurando publicador...';
USE [master];
GO

DECLARE @publisher SYSNAME;
SELECT @publisher = @@SERVERNAME;

EXEC sp_adddistpublisher 
    @publisher = @publisher, 
    @distribution_db = N'distribution', 
    @security_mode = 0,
    @login = N'sa', 
    @password = N'WideWorld2024!',
    @working_directory = N'/var/opt/mssql/ReplData',
    @trusted = N'false';
PRINT '   Publicador configurado';

PRINT '=== CONFIGURACIÓN DE DISTRIBUIDOR COMPLETADA ===';
GO



-- Paso2

-- =============================================
-- CREACIÓN DE PUBLICACIÓN TRANSACCIONAL
-- =============================================
USE [WWI_Sucursal_SJ];
GO

SET NOCOUNT ON;

PRINT '=== CREANDO PUBLICACIÓN TRANSACCIONAL ===';

-- 1. ELIMINAR PUBLICACIÓN EXISTENTE SI HAY
IF EXISTS (SELECT 1 FROM syspublications WHERE name = 'WWI_Transactional_SJ')
BEGIN
    PRINT '   Eliminando publicación existente...';
    EXEC sp_dropsubscription @publication = N'WWI_Transactional_SJ', @subscriber = N'all';
    EXEC sp_droppublication @publication = N'WWI_Transactional_SJ';
END

-- 2. CREAR NUEVA PUBLICACIÓN TRANSACCIONAL
PRINT '   Creando nueva publicación transaccional...';
EXEC sp_addpublication 
    @publication = N'WWI_Transactional_SJ',
    @description = N'Transactional publication from San Jose to Limon',
    @sync_method = N'native',
    @repl_freq = N'continuous',
    @status = N'active',
    @allow_push = N'true',
    @allow_pull = N'false',
    @allow_anonymous = N'false',
    @independent_agent = N'true',
    @immediate_sync = N'true',
    @replicate_ddl = 1,
    @allow_initialize_from_backup = N'false',
    @enabled_for_internet = N'false',
    @allow_sync_tran = N'false',
    @autogen_sync_procs = N'false',
    @retention = 72;

PRINT '   Publicación transaccional creada';

-- 3. HABILITAR LA BASE DE DATOS PARA PUBLICACIÓN
PRINT '   Habilitando base de datos para publicación...';
EXEC sp_replicationdboption 
    @dbname = N'WWI_Sucursal_SJ',
    @optname = N'publish',
    @value = N'true';
PRINT '   Base de datos habilitada para publicación';
GO


-- Paso 3

-- =============================================
-- AGREGAR ARTÍCULOS CON FILTRADO PARA TABLAS TEMPORALES
-- =============================================
USE [WWI_Sucursal_SJ];
GO

SET NOCOUNT ON;

PRINT '=== AGREGANDO ARTÍCULOS A LA PUBLICACION ===';

-- DEFINIR TABLAS A REPLICAR Y SU TIPO
DECLARE @TablasConfig TABLE (
    SchemaName SYSNAME,
    TableName SYSNAME, 
    IsTemporal BIT,
    ProcessingOrder INT
);

INSERT INTO @TablasConfig VALUES
    ('Warehouse', 'Colors', 1, 1),
    ('Warehouse', 'PackageTypes', 1, 2),
    ('Warehouse', 'StockGroups', 1, 3),
    ('Sales', 'BuyingGroups', 1, 4),
    ('Sales', 'CustomerCategories', 1, 5),
    ('Purchasing', 'SupplierCategories', 1, 6),
    ('Purchasing', 'Suppliers', 1, 7),
    ('Warehouse', 'StockItems', 1, 8),
    ('Warehouse', 'StockItemHoldings', 0, 9),
    ('Warehouse', 'StockItemStockGroups', 0, 10);

-- VARIABLES PARA EL CURSOR
DECLARE @SchemaName SYSNAME, @TableName SYSNAME, @IsTemporal BIT, @Order INT;
DECLARE @SQL NVARCHAR(MAX);

DECLARE tabla_cursor CURSOR FOR 
SELECT SchemaName, TableName, IsTemporal, ProcessingOrder 
FROM @TablasConfig 
ORDER BY ProcessingOrder;

OPEN tabla_cursor;
FETCH NEXT FROM tabla_cursor INTO @SchemaName, @TableName, @IsTemporal, @Order;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '   Procesando: ' + @SchemaName + '.' + @TableName;
    
    BEGIN TRY
        IF @IsTemporal = 1
        BEGIN
            -- TABLAS TEMPORALES: USAR FILTRADO VERTICAL
            PRINT '      Tabla temporal, aplicando filtrado de columnas...';
            
            EXEC sp_addarticle 
                @publication = N'WWI_Transactional_SJ',
                @article = @TableName,
                @source_owner = @SchemaName,
                @source_object = @TableName,
                @type = N'logbased',
                @description = @TableName,
                @creation_script = NULL,
                @pre_creation_cmd = N'drop',
                @schema_option = 0x00000000080050DF,
                @identityrangemanagementoption = N'manual',
                @destination_table = @TableName,
                @destination_owner = @SchemaName,
                @vertical_partition = N'true';  -- HABILITAR FILTRADO VERTICAL

            -- AGREGAR COLUMNAS MANUALMENTE (EXCLUYENDO TEMPORALES)
            SET @SQL = N'
            DECLARE @col_name SYSNAME;
            DECLARE col_cursor CURSOR FOR 
            SELECT name FROM sys.columns 
            WHERE object_id = OBJECT_ID(''' + @SchemaName + '.' + @TableName + ''')
            AND name NOT IN (''ValidFrom'', ''ValidTo'')
            ORDER BY column_id;
            
            OPEN col_cursor;
            FETCH NEXT FROM col_cursor INTO @col_name;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC sp_articlecolumn 
                    @publication = N''WWI_Transactional_SJ'',
                    @article = N''' + @TableName + ''',
                    @column = @col_name,
                    @operation = N''add'';
                FETCH NEXT FROM col_cursor INTO @col_name;
            END;
            CLOSE col_cursor;
            DEALLOCATE col_cursor;';
            
            EXEC sp_executesql @SQL;
            PRINT '      OK - Tabla temporal configurada (columnas temporales excluidas)';
        END
        ELSE
        BEGIN
            -- TABLAS NO TEMPORALES: CONFIGURACION NORMAL
            PRINT '      Tabla normal, configuracion estandar...';
            
            EXEC sp_addarticle 
                @publication = N'WWI_Transactional_SJ',
                @article = @TableName,
                @source_owner = @SchemaName,
                @source_object = @TableName,
                @type = N'logbased',
                @description = @TableName,
                @creation_script = NULL,
                @pre_creation_cmd = N'drop',
                @schema_option = 0x00000000080050DF,
                @identityrangemanagementoption = N'manual',
                @destination_table = @TableName,
                @destination_owner = @SchemaName;
                
            PRINT '      OK - Tabla normal configurada';
        END
    END TRY
    BEGIN CATCH
        PRINT '      ERROR en ' + @SchemaName + '.' + @TableName + ': ' + ERROR_MESSAGE();
    END CATCH;
    
    FETCH NEXT FROM tabla_cursor INTO @SchemaName, @TableName, @IsTemporal, @Order;
END;

CLOSE tabla_cursor;
DEALLOCATE tabla_cursor;

PRINT '=== ARTICULOS AGREGADOS CORRECTAMENTE ===';
GO

--Paso 4 sub push

-- =============================================
-- CREACIÓN DE SUSCRIPCIÓN PUSH
-- =============================================
USE [WWI_Sucursal_SJ];
GO

SET NOCOUNT ON;

PRINT '=== CREANDO SUSCRIPCIÓN PUSH ===';

-- 1. VERIFICAR QUE EL SERVIDOR LINKED EXISTA
IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE name = 'WWI-LIMON')
BEGIN
    PRINT '   Creando servidor vinculado WWI-LIMON...';
    
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
    
    PRINT '   Servidor vinculado creado';
END

-- 2. CREAR LA SUSCRIPCIÓN
PRINT '   Creando suscripción push...';
EXEC sp_addsubscription 
    @publication = N'WWI_Transactional_SJ',
    @subscriber = N'WWI-LIMON',
    @destination_db = N'WWI_Sucursal_LIM',
    @subscription_type = N'Push',
    @sync_type = N'automatic',
    @article = N'all',
    @update_mode = N'read only',
    @subscriber_type = 0;

PRINT '   Suscripción creada';

-- 3. AGREGAR AGENTE DE DISTRIBUCIÓN PUSH
PRINT '   Configurando agente de distribución...';
EXEC sp_addpushsubscription_agent 
    @publication = N'WWI_Transactional_SJ',
    @subscriber = N'WWI-LIMON',
    @subscriber_db = N'WWI_Sucursal_LIM',
    @job_login = NULL,
    @job_password = NULL,
    @subscriber_security_mode = 0,
    @subscriber_login = N'sa',
    @subscriber_password = N'WideWorld2024!',
    @frequency_type = 64,
    @frequency_interval = 0,
    @frequency_relative_interval = 0,
    @frequency_recurrence_factor = 0,
    @frequency_subday = 0,
    @frequency_subday_interval = 0,
    @active_start_time_of_day = 0,
    @active_end_time_of_day = 235959,
    @active_start_date = 0,
    @active_end_date = 99991231,
    @enabled_for_syncmgr = N'False',
    @dts_package_location = N'Distributor';

PRINT '   Agente de distribución configurado';
PRINT '=== SUSCRIPCIÓN CREADA CORRECTAMENTE ===';
GO