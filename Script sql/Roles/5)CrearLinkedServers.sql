USE master;
GO

-- limpiar por si quedaron mal
IF EXISTS (SELECT 1 FROM sys.servers WHERE name = 'WWI_SJ')
BEGIN
    EXEC sp_dropserver @server = N'WWI_SJ', @droplogins = 'droplogins';
END;

IF EXISTS (SELECT 1 FROM sys.servers WHERE name = 'WWI_LIM')
BEGIN
    EXEC sp_dropserver @server = N'WWI_LIM', @droplogins = 'droplogins';
END;
GO

-- LINKED SERVER SAN JOSE (usa nombre de contenedor y puerto interno 1433)
EXEC sp_addlinkedserver
    @server     = N'WWI_SJ',
    @srvproduct = N'',
    @provider   = N'MSOLEDBSQL',
    @datasrc    = N'wwi-sanjose,1433';

PRINT 'Linked Server WWI_SJ creado.';
GO

EXEC sp_serveroption @server = N'WWI_SJ', @optname = 'rpc out', @optvalue = 'true';
GO

-- LINKED SERVER LIMON
EXEC sp_addlinkedserver
    @server     = N'WWI_LIM',
    @srvproduct = N'',
    @provider   = N'MSOLEDBSQL',
    @datasrc    = N'wwi-limon,1433';

PRINT 'Linked Server WWI_LIM creado.';
GO

EXEC sp_serveroption @server = N'WWI_LIM', @optname = 'rpc out', @optvalue = 'true';
GO

-- MAPEOS DE LOGIN (igual que antes)
EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = N'WWI_SJ',
    @useself    = 'false',
    @locallogin = N'corp_analytics',
    @rmtuser    = N'admin_sj',
    @rmtpassword= N'Administrador#SanJose';
GO

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = N'WWI_LIM',
    @useself    = 'false',
    @locallogin = N'corp_analytics',
    @rmtuser    = N'admin_lim',
    @rmtpassword= N'Administrador#Limon';
GO

PRINT 'Linked Servers y mapeos recreados correctamente.';
GO
