# Script: Copiar Datos a WWI_Corporativo - VERSION FINAL
# Copia TODAS las tablas del Proyecto 1 al Corporativo
# Respeta orden de dependencias (Foreign Keys)

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  COPIAR DATOS - WWI_CORPORATIVO" -ForegroundColor Cyan
Write-Host "  Orden correcto respetando Foreign Keys" -ForegroundColor Cyan
Write-Host "  Origen: localhost,1540 (WideWorldImporters P1)" -ForegroundColor Cyan
Write-Host "  Destino: localhost,1433 (WWI_Corporativo P2)" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Configuracion
$servidorOrigen = "localhost,1540"
$dbOrigen = "WideWorldImporters"
$passwordOrigen = "Admin1234*"

$servidorDestino = "localhost,1433"
$dbDestino = "WWI_Corporativo"
$passwordDestino = "WideWorld2024!"

$tempDir = "$env:TEMP\WWI_Transfer_Corporativo"
$logFile = "$PSScriptRoot\copiar-corporativo-simple.log"

# Crear carpeta temporal
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

Write-Host "Carpeta temporal: $tempDir" -ForegroundColor Gray
Write-Host "Archivo log: $logFile" -ForegroundColor Gray
Write-Host ""

# Limpiar log anterior
if (Test-Path $logFile) { Remove-Item $logFile }
"=== LOG INICIO: $(Get-Date) ===" | Out-File $logFile

# Funciones
function Log-Message {
    param([string]$message, [string]$color = "White")
    Write-Host $message -ForegroundColor $color
    $message | Out-File $logFile -Append
}

function Export-Table {
    param([string]$schema, [string]$tabla)
    
    $archivo = "$tempDir\$schema.$tabla.dat"
    Log-Message "  Exportando [$schema].[$tabla]..." "Yellow"
    
    $bcpExport = "bcp `"$dbOrigen.$schema.$tabla`" out `"$archivo`" -S $servidorOrigen -U sa -P `"$passwordOrigen`" -n -q"
    
    try {
        $result = Invoke-Expression $bcpExport 2>&1
        if ($LASTEXITCODE -eq 0) {
            $fileSize = (Get-Item $archivo).Length
            $fileSizeKB = [math]::Round($fileSize / 1KB, 2)
            Log-Message "     Exportado: $fileSizeKB KB" "Green"
            return $true
        } else {
            Log-Message "     Error en exportacion: $result" "Red"
            return $false
        }
    } catch {
        Log-Message "     Excepcion: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Import-Table {
    param([string]$schema, [string]$tabla)
    
    $archivo = "$tempDir\$schema.$tabla.dat"
    
    if (-not (Test-Path $archivo)) {
        Log-Message "     Archivo no existe: $archivo" "Red"
        return $false
    }
    
    Log-Message "  Importando [$schema].[$tabla]..." "Cyan"
    
    $bcpImport = "bcp `"$dbDestino.$schema.$tabla`" in `"$archivo`" -S $servidorDestino -U sa -P `"$passwordDestino`" -n -q -b 1000 -h `"TABLOCK,CHECK_CONSTRAINTS`""
    
    try {
        $result = Invoke-Expression $bcpImport 2>&1
        if ($LASTEXITCODE -eq 0) {
            $rowCount = ($result | Select-String -Pattern "(\d+) rows copied").Matches.Groups[1].Value
            Log-Message "     Importado: $rowCount filas" "Green"
            return $true
        } else {
            Log-Message "     Error en importacion: $result" "Red"
            return $false
        }
    } catch {
        Log-Message "     Excepcion: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Process-Table {
    param([string]$schema, [string]$tabla)
    
    Log-Message "" "White"
    Log-Message "Procesando: [$schema].[$tabla]" "White"
    
    $exported = Export-Table -schema $schema -tabla $tabla
    if ($exported) {
        $imported = Import-Table -schema $schema -tabla $tabla
        return $imported
    }
    return $false
}

# PASO 1: Preparar base de datos
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 1: Preparar base de datos destino" "Cyan"
Log-Message "====================================================================" "Cyan"

$sqlPreparacion = @"
USE [$dbDestino];
GO

SET QUOTED_IDENTIFIER ON;
GO

-- Deshabilitar triggers
EXEC sp_MSforeachtable 'ALTER TABLE ? DISABLE TRIGGER ALL';
GO

-- Deshabilitar todas las Foreign Keys
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

PRINT 'Triggers y Foreign Keys deshabilitados';
GO
"@

$sqlFile = "$tempDir\preparacion.sql"
$sqlPreparacion | Out-File $sqlFile -Encoding UTF8

Log-Message "Deshabilitando triggers y FKs..." "Yellow"
sqlcmd -S $servidorDestino -U sa -P $passwordDestino -i $sqlFile -b

if ($LASTEXITCODE -eq 0) {
    Log-Message "Base de datos preparada" "Green"
} else {
    Log-Message "Error al preparar base de datos" "Red"
    exit 1
}

# PASO 2: Copiar tablas de catalogo
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 2: Copiar tablas de catalogo" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasCatalogo = @(
    @{Schema="Application"; Tabla="Countries"},
    @{Schema="Application"; Tabla="StateProvinces"},
    @{Schema="Application"; Tabla="Cities"},
    @{Schema="Application"; Tabla="DeliveryMethods"},
    @{Schema="Application"; Tabla="PaymentMethods"},
    @{Schema="Application"; Tabla="TransactionTypes"},
    @{Schema="Application"; Tabla="People"},
    @{Schema="Warehouse"; Tabla="Colors"},
    @{Schema="Warehouse"; Tabla="PackageTypes"},
    @{Schema="Warehouse"; Tabla="StockGroups"},
    @{Schema="Warehouse"; Tabla="StockItems"},
    @{Schema="Warehouse"; Tabla="StockItemStockGroups"},
    @{Schema="Purchasing"; Tabla="SupplierCategories"},
    @{Schema="Purchasing"; Tabla="Suppliers"},
    @{Schema="Sales"; Tabla="BuyingGroups"},
    @{Schema="Sales"; Tabla="CustomerCategories"}
)

$exitososCatalogo = 0
$fallidosCatalogo = 0

foreach ($tabla in $tablasCatalogo) {
    if (Process-Table -schema $tabla.Schema -tabla $tabla.Tabla) {
        $exitososCatalogo++
    } else {
        $fallidosCatalogo++
    }
}

Log-Message "" "White"
Log-Message "Resumen Catalogos: $exitososCatalogo exitosos, $fallidosCatalogo fallidos" "White"

# PASO 3: Copiar tablas transaccionales
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 3: Copiar tablas transaccionales" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasTransaccionales = @(
    @{Schema="Sales"; Tabla="Customers"},
    @{Schema="Sales"; Tabla="Orders"},
    @{Schema="Sales"; Tabla="OrderLines"},
    @{Schema="Sales"; Tabla="Invoices"},
    @{Schema="Sales"; Tabla="InvoiceLines"},
    @{Schema="Sales"; Tabla="CustomerTransactions"},
    @{Schema="Sales"; Tabla="SpecialDeals"},
    @{Schema="Purchasing"; Tabla="PurchaseOrders"},
    @{Schema="Purchasing"; Tabla="PurchaseOrderLines"},
    @{Schema="Purchasing"; Tabla="SupplierTransactions"},
    @{Schema="Warehouse"; Tabla="StockItemHoldings"},
    @{Schema="Warehouse"; Tabla="StockItemTransactions"},
    @{Schema="Application"; Tabla="SystemParameters"}
)

$exitososTrans = 0
$fallidosTrans = 0

foreach ($tabla in $tablasTransaccionales) {
    if (Process-Table -schema $tabla.Schema -tabla $tabla.Tabla) {
        $exitososTrans++
    } else {
        $fallidosTrans++
    }
}

Log-Message "" "White"
Log-Message "Resumen Transaccionales: $exitososTrans exitosos, $fallidosTrans fallidos" "White"

# PASO 4: Rehabilitar triggers
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 4: Rehabilitar triggers" "Cyan"
Log-Message "====================================================================" "Cyan"

$sqlFinalizacion = @"
USE [$dbDestino];
GO
EXEC sp_MSforeachtable 'ALTER TABLE ? ENABLE TRIGGER ALL';
GO
PRINT 'Triggers rehabilitados';
GO
"@

$sqlFile = "$tempDir\finalizacion.sql"
$sqlFinalizacion | Out-File $sqlFile -Encoding UTF8

Log-Message "Rehabilitando triggers..." "Yellow"
sqlcmd -S $servidorDestino -U sa -P $passwordDestino -i $sqlFile -b

if ($LASTEXITCODE -eq 0) {
    Log-Message "Triggers rehabilitados" "Green"
} else {
    Log-Message "Advertencia al rehabilitar triggers" "Yellow"
}

# PASO 5: Verificacion
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 5: Verificacion de datos copiados" "Cyan"
Log-Message "====================================================================" "Cyan"

$sqlVerificacion = @"
USE [$dbDestino];
GO
SELECT 
    s.name AS Esquema,
    t.name AS Tabla,
    p.rows AS Filas
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE s.name IN ('Application', 'Warehouse', 'Purchasing', 'Sales')
  AND p.index_id IN (0,1)
  AND t.name NOT LIKE '%_Archive'
ORDER BY s.name, t.name;
GO
PRINT '';
PRINT '=== VERIFICACION APPLICATION.PEOPLE ===';
SELECT 
    COUNT(*) AS TotalPersonas,
    COUNT(PhoneNumber) AS ConTelefono,
    COUNT(FaxNumber) AS ConFax,
    COUNT(EmailAddress) AS ConEmail
FROM Application.People;
GO
"@

$sqlFile = "$tempDir\verificacion.sql"
$sqlVerificacion | Out-File $sqlFile -Encoding UTF8

Log-Message "Ejecutando verificacion..." "Yellow"
sqlcmd -S $servidorDestino -U sa -P $passwordDestino -i $sqlFile

# Resumen final
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "RESUMEN FINAL" "Cyan"
Log-Message "====================================================================" "Cyan"

$totalExitosos = $exitososCatalogo + $exitososTrans
$totalFallidos = $fallidosCatalogo + $fallidosTrans

Log-Message "Catalogos copiados: $exitososCatalogo / $($tablasCatalogo.Count)" "Green"
Log-Message "Transaccionales copiados: $exitososTrans / $($tablasTransaccionales.Count)" "Green"
Log-Message "TOTAL: $totalExitosos exitosos, $totalFallidos fallidos" "White"

if ($totalFallidos -eq 0) {
    Log-Message "" "Green"
    Log-Message "PROCESO COMPLETADO EXITOSAMENTE!" "Green"
    Log-Message "Base de datos WWI_Corporativo lista con TODOS los datos" "Green"
} else {
    Log-Message "" "Yellow"
    Log-Message "PROCESO COMPLETADO CON ADVERTENCIAS" "Yellow"
    Log-Message "Revisa el log para detalles: $logFile" "Yellow"
}

Log-Message "" "Gray"
Log-Message "Log completo guardado en: $logFile" "Gray"
Log-Message "Archivos temporales en: $tempDir" "Gray"

"=== LOG FIN: $(Get-Date) ===" | Out-File $logFile -Append

Write-Host ""
Write-Host "Presiona cualquier tecla para salir..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
