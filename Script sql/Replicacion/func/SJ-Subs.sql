-- En sanjose, verificar el estado de la suscripción
USE [WWI_Sucursal_SJ];
EXEC sp_helpsubscription @publication = N'WWI_Productos_P2P_SJ';

EXEC sp_addsubscription 
    @publication = N'WWI_Productos_P2P_SJ',
    @subscriber = N'wwi-limon',
    @destination_db = N'WWI_Sucursal_LIM',          
    @subscription_type = N'Push',                   
    @sync_type = N'replication support only',       
    @article = N'all',                              
    @update_mode = N'read only',                    
    @subscriber_type = 0;

EXEC sp_addpushsubscription_agent 
    @publication = N'WWI_Productos_P2P_SJ',
    @subscriber = N'wwi-limon',
    @subscriber_db = N'WWI_Sucursal_LIM',
    @job_login = NULL,                              
    @job_password = NULL,
    @subscriber_security_mode = 1,                  
    @frequency_type = 64,                           -- Ejecución continua
    @frequency_interval = 0,
    @frequency_relative_interval = 0,
    @frequency_recurrence_factor = 0,
    @frequency_subday = 0,
    @frequency_subday_interval = 0,
    @active_start_time_of_day = 0,
    @active_end_time_of_day = 235959,
    @active_start_date = 20251116,                  
    @active_end_date = 99991231,                    
    @enabled_for_syncmgr = N'False',
    @dts_package_location = N'Distributor';


INSERT INTO Warehouse.Colors (ColorID, ColorName, LastEditedBy)
VALUES (9999, 'Test P2P desde SJ', 1);

SELECT ColorID, ColorName, LastEditedBy
FROM Warehouse.Colors
WHERE ColorID = 9999;

DELETE FROM Warehouse.Colors 
WHERE ColorID = 9999;


-- Ver detalles completos del servidor LIMON
SELECT 
    srvname AS 'ServerName',
    datasource AS 'DataSource', 
    providername AS 'Provider',
    dataaccess AS 'DataAccess',
    rpc AS 'RPC',
    rpcout AS 'RPCOut'
FROM sys.sysservers 
WHERE srvname = 'LIMON';


-- Eliminar la suscripción que usa LIMON
EXEC sp_dropsubscription 
    @publication = N'WWI_Productos_P2P_SJ',
    @subscriber = N'all',
    @destination_db = N'WWI_Sucursal_LIM',
    @article = N'all'; 
PRINT 'Suscripción de replicación eliminada';

-- Eliminar todos los logins asociados al servidor LIMON
EXEC sp_droplinkedsrvlogin @rmtsrvname = 'LIMON', @locallogin = NULL;
PRINT 'Logins vinculados eliminados';

-- Eliminar el servidor
EXEC sp_dropserver 'LIMON';
PRINT 'Servidor LIMON eliminado';

-- CREAR NUEVO CON NOMBRE DE CONTENEDOR
EXEC sp_addlinkedserver 
    @server = N'LIMON', 
    @srvproduct = N'',
    @provider = N'SQLNCLI', 
    @datasrc = N'wwi-limon';  -- ← NOMBRE DEL CONTENEDOR en la red Docker

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = N'LIMON', 
    @useself = N'False', 
    @locallogin = NULL, 
    @rmtuser = N'sa', 
    @rmtpassword = N'WideWorld2024!';


-- 3. CONFIGURAR OPCIONES PARA REPLICACIÓN
EXEC sp_serveroption @server = N'LIMON', @optname = 'data access', @optvalue = 'true';
EXEC sp_serveroption @server = N'LIMON', @optname = 'rpc', @optvalue = 'true';
EXEC sp_serveroption @server = N'LIMON', @optname = 'rpc out', @optvalue = 'true';
EXEC sp_serveroption @server = N'LIMON', @optname = 'remote proc transaction promotion', @optvalue = 'false';

-- 4. VERIFICAR CONEXIÓN
EXEC sp_testlinkedserver @server = N'all';
-- 5. PROBAR CONSULTA REMOTA
SELECT * FROM [LIMON].master.sys.databases;


