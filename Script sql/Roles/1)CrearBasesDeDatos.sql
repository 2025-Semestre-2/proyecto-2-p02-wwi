USE master;
GO
DECLARE @dbCorp SYSNAME = N'WWI_Corporativo';
DECLARE @dbSJ   SYSNAME = N'WWI_Sucursal_SJ';
DECLARE @dbLIM  SYSNAME = N'WWI_Sucursal_LIM';

IF DB_ID(@dbCorp) IS NULL
BEGIN
    PRINT 'Creando base ' + @dbCorp;
    EXEC('CREATE DATABASE [' + @dbCorp + ']');
END
ELSE PRINT 'Base ya existe: ' + @dbCorp;

IF DB_ID(@dbSJ) IS NULL
BEGIN
    PRINT 'Creando base ' + @dbSJ;
    EXEC('CREATE DATABASE [' + @dbSJ + ']');
END
ELSE PRINT 'Base ya existe: ' + @dbSJ;

IF DB_ID(@dbLIM) IS NULL
BEGIN
    PRINT 'Creando base ' + @dbLIM;
    EXEC('CREATE DATABASE [' + @dbLIM + ']');
END
ELSE PRINT 'Base ya existe: ' + @dbLIM;
GO
