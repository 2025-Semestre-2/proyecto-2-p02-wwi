-- =============================================
-- CONFIGURACIÓN DISTRIBUIDOR - CORREGIDA PARA DOCKER
-- =============================================

USE [master];
GO

SET NOCOUNT ON;

PRINT '=== CONFIGURANDO DISTRIBUIDOR PARA DOCKER ===';

-- 1. CONFIGURAR DISTRIBUIDOR
DECLARE @distributor SYSNAME;
SELECT @distributor = @@SERVERNAME;  -- 'sanjose'

PRINT '   Nombre del distribuidor: ' + @distributor;

EXEC sp_adddistributor 
    @distributor = @distributor, 
    @password = N'WideWorld2024!';  -- ← USAR TU PASSWORD ACTUAL
PRINT '   Distribuidor configurado';

-- 2. CREAR BASE DE DISTRIBUCIÓN (CORREGIDO)
PRINT '2. Creando base de distribución...';
EXEC sp_adddistributiondb 
    @database = N'distribution', 
    @data_folder = N'/var/opt/mssql/data',      -- Ruta Docker corregida
    @log_folder = N'/var/opt/mssql/data',       
    @log_file_size = 2,                         
    @min_distretention = 0,                     
    @max_distretention = 72,                    
    @history_retention = 48,                    
    @deletebatchsize_xact = 5000,               
    @deletebatchsize_cmd = 2000,                
    @security_mode = 1;                         -- ← CAMBIAR a SQL Server Authentication
PRINT '   Base distribution creada';

-- 3. CONFIGURAR CARPETA DE SNAPSHOTS
PRINT '3. Configurando carpeta de snapshots...';
USE [distribution];
GO

-- Crear tabla UIProperties si no existe
IF (NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'UIProperties' AND type = 'U')) 
    CREATE TABLE UIProperties(id INT);

-- Configurar SnapshotFolder
IF (EXISTS (SELECT * FROM ::fn_listextendedproperty('SnapshotFolder', 'user', 'dbo', 'table', 'UIProperties', NULL, NULL))) 
    EXEC sp_updateextendedproperty N'SnapshotFolder', N'/var/opt/mssql/ReplData', 'user', dbo, 'table', 'UIProperties';
ELSE 
    EXEC sp_addextendedproperty N'SnapshotFolder', N'/var/opt/mssql/ReplData', 'user', dbo, 'table', 'UIProperties';
PRINT '   Snapshot folder configurado';

-- 4. CONFIGURAR PUBLICADOR (IMPORTANTE: Usar SQL Server Auth)
PRINT '4. Configurando publicador...';
DECLARE @publisher SYSNAME;
SELECT @publisher = @@SERVERNAME;  -- 'sanjose'

-- 4. CONFIGURAR PUBLICADOR (CORREGIDO - AGREGAR LOGIN Y PASSWORD)
PRINT '4. Configurando publicador...';
DECLARE @publisher SYSNAME;
SELECT @publisher = @@SERVERNAME;  -- 'sanjose'

EXEC sp_adddistpublisher 
    @publisher = @publisher, 
    @distribution_db = N'distribution', 
    @security_mode = 0,                         -- SQL Server Authentication
    @login = N'sa',                             -- ← AGREGAR login
    @password = N'WideWorld2024!',              -- ← AGREGAR password
    @working_directory = N'/var/opt/mssql/ReplData',
    @trusted = N'false';
PRINT '   Publicador configurado';

PRINT '=== CONFIGURACIÓN DE DISTRIBUIDOR COMPLETADA ===';