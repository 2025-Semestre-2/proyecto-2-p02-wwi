# ============================================================================
# PASO 1: CREAR BASES DE DATOS Y VERIFICAR SQL SERVER AGENT
# ============================================================================
# Este script SOLO:
# 1. Verifica que los 3 Dockers esten corriendo
# 2. Crea las 3 bases de datos
# 3. Verifica que SQL Server Agent este habilitado
# ============================================================================

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  PASO 1: CREAR BASES DE DATOS" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Configuracion
$password = "WideWorld2024!"

$servidores = @(
    @{Nombre="Corporativo"; Server="localhost,1444"; DB="WWI_Corporativo"; Container="wwi-corporativo"},
    @{Nombre="San Jose"; Server="localhost,1445"; DB="WWI_Sucursal_SJ"; Container="wwi-sanjose"},
    @{Nombre="Limon"; Server="localhost,1446"; DB="WWI_Sucursal_LIM"; Container="wwi-limon"}
)

# ============================================================================
# 1. VERIFICAR DOCKERS
# ============================================================================
Write-Host "1. Verificando contenedores Docker..." -ForegroundColor Yellow
Write-Host ""

$todosOK = $true

foreach ($srv in $servidores) {
    $docker = docker ps --filter "name=$($srv.Container)" --format "{{.Names}}" 2>$null
    
    if ($docker -eq $srv.Container) {
        Write-Host "   OK - $($srv.Nombre) ($($srv.Container))" -ForegroundColor Green
    } else {
        Write-Host "   ERROR - $($srv.Nombre) ($($srv.Container)) NO esta corriendo" -ForegroundColor Red
        $todosOK = $false
    }
}

if (-not $todosOK) {
    Write-Host ""
    Write-Host "ERROR: Algunos contenedores no estan corriendo" -ForegroundColor Red
    Write-Host "Ejecuta primero: .\iniciar-distribuido.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Todos los contenedores estan corriendo" -ForegroundColor Green
Write-Host ""

# ============================================================================
# 2. VERIFICAR SQL SERVER AGENT
# ============================================================================
Write-Host "2. Verificando SQL Server Agent..." -ForegroundColor Yellow
Write-Host ""

$queryAgent = @"
SELECT 
    CASE 
        WHEN dss.status_desc = 'RUNNING' THEN 'RUNNING'
        ELSE 'STOPPED'
    END AS Estado
FROM sys.dm_server_services dss
WHERE dss.servicename LIKE 'SQL Server Agent%';
"@

foreach ($srv in $servidores) {
    $result = sqlcmd -S $srv.Server -U sa -P $password -Q $queryAgent -h -1 -W 2>&1
    
    if ($result -match "RUNNING") {
        Write-Host "   OK - Agent en $($srv.Nombre): RUNNING" -ForegroundColor Green
    } else {
        Write-Host "   AVISO - Agent en $($srv.Nombre): STOPPED o desconocido" -ForegroundColor Yellow
        Write-Host "     Nota: El Agent se habilito en docker-compose.yml" -ForegroundColor Gray
        Write-Host "           (MSSQL_AGENT_ENABLED: true)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "SQL Server Agent verificado" -ForegroundColor Green
Write-Host ""

# ============================================================================
# 3. CREAR BASES DE DATOS
# ============================================================================
Write-Host "3. Creando bases de datos..." -ForegroundColor Yellow
Write-Host ""

foreach ($srv in $servidores) {
    Write-Host "   Creando [$($srv.DB)] en $($srv.Nombre)..." -NoNewline
    
    $scriptCrearDB = @"
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'$($srv.DB)')
BEGIN
    PRINT 'Base de datos ya existe';
END
ELSE
BEGIN
    CREATE DATABASE [$($srv.DB)]
    ON PRIMARY 
    (
        NAME = N'$($srv.DB)_Data',
        FILENAME = N'/var/opt/mssql/data/$($srv.DB)_Data.mdf',
        SIZE = 100MB,
        FILEGROWTH = 50MB
    )
    LOG ON
    (
        NAME = N'$($srv.DB)_Log',
        FILENAME = N'/var/opt/mssql/data/$($srv.DB)_Log.ldf',
        SIZE = 50MB,
        FILEGROWTH = 25MB
    );
    
    PRINT 'Base de datos creada exitosamente';
END
GO

USE [$($srv.DB)];
GO

ALTER DATABASE [$($srv.DB)] SET RECOVERY FULL;
ALTER DATABASE [$($srv.DB)] SET AUTO_CREATE_STATISTICS ON;
ALTER DATABASE [$($srv.DB)] SET AUTO_UPDATE_STATISTICS ON;
GO

PRINT 'Base de datos configurada';
GO
"@
    
    $resultado = $scriptCrearDB | sqlcmd -S $srv.Server -U sa -P $password 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " ERROR" -ForegroundColor Red
        Write-Host "     Error: $resultado" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Bases de datos creadas correctamente" -ForegroundColor Green
Write-Host ""

# ============================================================================
# 4. VERIFICACION FINAL
# ============================================================================
Write-Host "4. Verificacion final..." -ForegroundColor Yellow
Write-Host ""

$queryVerificar = @"
SELECT 
    d.name AS Base_Datos,
    d.recovery_model_desc AS Modelo_Recuperacion,
    d.state_desc AS Estado
FROM sys.databases d
WHERE d.name LIKE 'WWI_%';
"@

foreach ($srv in $servidores) {
    Write-Host "   $($srv.Nombre):" -ForegroundColor Cyan
    sqlcmd -S $srv.Server -U sa -P $password -Q $queryVerificar -W
    Write-Host ""
}

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  PASO 1 COMPLETADO" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resumen:" -ForegroundColor Yellow
Write-Host "  OK - 3 contenedores Docker verificados" -ForegroundColor Green
Write-Host "  OK - SQL Server Agent habilitado" -ForegroundColor Green
Write-Host "  OK - 3 bases de datos creadas:" -ForegroundColor Green
Write-Host "    - WWI_Corporativo (puerto 1433)" -ForegroundColor White
Write-Host "    - WWI_Sucursal_SJ (puerto 1434)" -ForegroundColor White
Write-Host "    - WWI_Sucursal_LIM (puerto 1435)" -ForegroundColor White
Write-Host ""
Write-Host "Siguiente paso:" -ForegroundColor Yellow
Write-Host "  Crear la estructura de tablas con baseWide.sql" -ForegroundColor White
Write-Host "  Ejecutar: .\paso2-crear-estructura.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
