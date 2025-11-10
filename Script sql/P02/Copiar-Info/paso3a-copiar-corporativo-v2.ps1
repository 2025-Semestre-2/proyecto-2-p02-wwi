# Script: Copiar Datos a WWI_Corporativo - VERSION 2 CON ORDEN DE DEPENDENCIAS
# Copia tablas respetando Foreign Keys (orden correcto)

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  COPIAR DATOS - WWI_CORPORATIVO (VERSION 2)" -ForegroundColor Cyan
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
$logFile = "$PSScriptRoot\copiar-corporativo-v2.log"

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
    
    # Deshabilitar SYSTEM_VERSIONING antes de importar
    $sqlDisableVersioning = @"
USE [$dbDestino];
SET QUOTED_IDENTIFIER ON;
IF EXISTS (SELECT 1 FROM sys.tables WHERE schema_id = SCHEMA_ID('$schema') AND name = '$tabla' AND temporal_type = 2)
BEGIN
    ALTER TABLE [$schema].[$tabla] SET (SYSTEM_VERSIONING = OFF);
END
GO
"@
    $sqlFile = "$tempDir\disable_versioning_$schema.$tabla.sql"
    $sqlDisableVersioning | Out-File $sqlFile -Encoding UTF8
    sqlcmd -S $servidorDestino -U sa -P $passwordDestino -i $sqlFile -b | Out-Null
    
    # Importar datos
    $bcpImport = "bcp `"$dbDestino.$schema.$tabla`" in `"$archivo`" -S $servidorDestino -U sa -P `"$passwordDestino`" -n -q -b 1000 -h `"TABLOCK,CHECK_CONSTRAINTS`""
    
    try {
        $result = Invoke-Expression $bcpImport 2>&1
        if ($LASTEXITCODE -eq 0) {
            $rowCount = ($result | Select-String -Pattern "(\d+) rows copied").Matches.Groups[1].Value
            Log-Message "     Importado: $rowCount filas" "Green"
            
            # Rehabilitar SYSTEM_VERSIONING despues de importar
            $sqlEnableVersioning = @"
USE [$dbDestino];
SET QUOTED_IDENTIFIER ON;
IF EXISTS (SELECT 1 FROM sys.tables WHERE schema_id = SCHEMA_ID('$schema') AND name = '$tabla' AND temporal_type = 0)
BEGIN
    ALTER TABLE [$schema].[$tabla] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [$schema].[${tabla}_Archive]));
END
GO
"@
            $sqlFile = "$tempDir\enable_versioning_$schema.$tabla.sql"
            $sqlEnableVersioning | Out-File $sqlFile -Encoding UTF8
            sqlcmd -S $servidorDestino -U sa -P $passwordDestino -i $sqlFile -b | Out-Null
            
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

# PASO 0: Limpiar datos existentes
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 0: Limpiar datos existentes para evitar duplicados" "Cyan"
Log-Message "====================================================================" "Cyan"

$sqlLimpiar = @"
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

-- Limpiar tablas que ya tienen datos (solo las principales, sin Archive)
-- Usar DELETE porque TRUNCATE no funciona con FKs
DELETE FROM [Sales].[SpecialDeals];
DELETE FROM [Sales].[CustomerCategories];
DELETE FROM [Sales].[BuyingGroups];
DELETE FROM [Purchasing].[SupplierCategories];
DELETE FROM [Warehouse].[StockGroups];
DELETE FROM [Warehouse].[PackageTypes];
DELETE FROM [Warehouse].[Colors];
DELETE FROM [Application].[People];
GO

PRINT 'Tablas limpiadas correctamente';
GO
"@

$sqlFile = "$tempDir\limpiar.sql"
$sqlLimpiar | Out-File $sqlFile -Encoding UTF8

Log-Message "Limpiando datos existentes y deshabilitando FKs..." "Yellow"
sqlcmd -S $servidorDestino -U sa -P $passwordDestino -i $sqlFile -b

if ($LASTEXITCODE -eq 0) {
    Log-Message "Datos limpiados y FKs deshabilitadas" "Green"
} else {
    Log-Message "Error al limpiar datos" "Red"
    exit 1
}

# PASO 1: Copiar tablas BASE (sin dependencias externas)
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 1: Copiar tablas BASE (sin dependencias)" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasBase = @(
    @{Schema="Application"; Tabla="People"},           # Base para todo
    @{Schema="Warehouse"; Tabla="Colors"},             # Base
    @{Schema="Warehouse"; Tabla="PackageTypes"},       # Base
    @{Schema="Warehouse"; Tabla="StockGroups"},        # Base
    @{Schema="Purchasing"; Tabla="SupplierCategories"}, # Base
    @{Schema="Sales"; Tabla="BuyingGroups"},           # Base
    @{Schema="Sales"; Tabla="CustomerCategories"}      # Base
)

$exitososBase = 0
$fallidosBase = 0

foreach ($tabla in $tablasBase) {
    if (Process-Table -schema $tabla.Schema -tabla $tabla.Tabla) {
        $exitososBase++
    } else {
        $fallidosBase++
    }
}

Log-Message "" "White"
Log-Message "Resumen Base: $exitososBase exitosos, $fallidosBase fallidos" "White"

# PASO 2: Copiar tablas NIVEL 1 (dependen de tablas base)
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 2: Copiar tablas NIVEL 1" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasNivel1 = @(
    @{Schema="Application"; Tabla="TransactionTypes"},  # Depende de People
    @{Schema="Application"; Tabla="PaymentMethods"},    # Depende de People
    @{Schema="Application"; Tabla="DeliveryMethods"},   # Depende de People
    @{Schema="Application"; Tabla="Countries"}          # Depende de People
)

$exitososNivel1 = 0
$fallidosNivel1 = 0

foreach ($tabla in $tablasNivel1) {
    if (Process-Table -schema $tabla.Schema -tabla $tabla.Tabla) {
        $exitososNivel1++
    } else {
        $fallidosNivel1++
    }
}

Log-Message "" "White"
Log-Message "Resumen Nivel 1: $exitososNivel1 exitosos, $fallidosNivel1 fallidos" "White"

# PASO 3: Copiar tablas NIVEL 2 (dependen de nivel 1)
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 3: Copiar tablas NIVEL 2" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasNivel2 = @(
    @{Schema="Application"; Tabla="StateProvinces"},    # Depende de Countries, People
    @{Schema="Sales"; Tabla="SpecialDeals"}             # Depende de categorias
)

$exitososNivel2 = 0
$fallidosNivel2 = 0

foreach ($tabla in $tablasNivel2) {
    if (Process-Table -schema $tabla.Schema -tabla $tabla.Tabla) {
        $exitososNivel2++
    } else {
        $fallidosNivel2++
    }
}

Log-Message "" "White"
Log-Message "Resumen Nivel 2: $exitososNivel2 exitosos, $fallidosNivel2 fallidos" "White"

# PASO 4: Copiar tablas NIVEL 3 (dependen de nivel 2)
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 4: Copiar tablas NIVEL 3" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasNivel3 = @(
    @{Schema="Application"; Tabla="Cities"}             # Depende de StateProvinces, People
)

$exitososNivel3 = 0
$fallidosNivel3 = 0

foreach ($tabla in $tablasNivel3) {
    if (Process-Table -schema $tabla.Schema -tabla $tabla.Tabla) {
        $exitososNivel3++
    } else {
        $fallidosNivel3++
    }
}

Log-Message "" "White"
Log-Message "Resumen Nivel 3: $exitososNivel3 exitosos, $fallidosNivel3 fallidos" "White"

# PASO 5: Copiar tablas NIVEL 4 (Suppliers y Customers)
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 5: Copiar tablas NIVEL 4 (Suppliers y Customers)" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasNivel4 = @(
    @{Schema="Purchasing"; Tabla="Suppliers"},          # Depende de Cities, Categories, People
    @{Schema="Sales"; Tabla="Customers"}                # Depende de Cities, Categories, People
)

$exitososNivel4 = 0
$fallidosNivel4 = 0

foreach ($tabla in $tablasNivel4) {
    if (Process-Table -schema $tabla.Schema -tabla $tabla.Tabla) {
        $exitososNivel4++
    } else {
        $fallidosNivel4++
    }
}

Log-Message "" "White"
Log-Message "Resumen Nivel 4: $exitososNivel4 exitosos, $fallidosNivel4 fallidos" "White"

# PASO 6: Copiar tablas NIVEL 5 (StockItems y SystemParameters)
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 6: Copiar tablas NIVEL 5 (StockItems)" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasNivel5 = @(
    @{Schema="Warehouse"; Tabla="StockItems"},          # Depende de Suppliers, Colors, PackageTypes, People
    @{Schema="Application"; Tabla="SystemParameters"}   # Depende de Cities, People
)

$exitososNivel5 = 0
$fallidosNivel5 = 0

foreach ($tabla in $tablasNivel5) {
    if (Process-Table -schema $tabla.Schema -tabla $tabla.Tabla) {
        $exitososNivel5++
    } else {
        $fallidosNivel5++
    }
}

Log-Message "" "White"
Log-Message "Resumen Nivel 5: $exitososNivel5 exitosos, $fallidosNivel5 fallidos" "White"

# PASO 7: Copiar tablas NIVEL 6 (StockItemStockGroups, StockItemHoldings)
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 7: Copiar tablas NIVEL 6 (relaciones StockItems)" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasNivel6 = @(
    @{Schema="Warehouse"; Tabla="StockItemStockGroups"}, # Depende de StockItems, StockGroups
    @{Schema="Warehouse"; Tabla="StockItemHoldings"}     # Depende de StockItems
)

$exitososNivel6 = 0
$fallidosNivel6 = 0

foreach ($tabla in $tablasNivel6) {
    if (Process-Table -schema $tabla.Schema -tabla $tabla.Tabla) {
        $exitososNivel6++
    } else {
        $fallidosNivel6++
    }
}

Log-Message "" "White"
Log-Message "Resumen Nivel 6: $exitososNivel6 exitosos, $fallidosNivel6 fallidos" "White"

# PASO 8: Copiar tablas TRANSACCIONALES (Orders, PurchaseOrders)
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 8: Copiar tablas TRANSACCIONALES (ordenes)" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasTransaccionales = @(
    @{Schema="Sales"; Tabla="Orders"},                  # Depende de Customers, People
    @{Schema="Purchasing"; Tabla="PurchaseOrders"}      # Depende de Suppliers, DeliveryMethods, People
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

# PASO 9: Copiar tablas DETALLE (OrderLines, InvoiceLines, etc)
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 9: Copiar tablas DETALLE (lineas y transacciones)" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasDetalle = @(
    @{Schema="Sales"; Tabla="OrderLines"},              # Depende de Orders, StockItems
    @{Schema="Sales"; Tabla="Invoices"},                # Depende de Customers, Orders, People
    @{Schema="Purchasing"; Tabla="PurchaseOrderLines"}  # Depende de PurchaseOrders, StockItems
)

$exitososDetalle = 0
$fallidosDetalle = 0

foreach ($tabla in $tablasDetalle) {
    if (Process-Table -schema $tabla.Schema -tabla $tabla.Tabla) {
        $exitososDetalle++
    } else {
        $fallidosDetalle++
    }
}

Log-Message "" "White"
Log-Message "Resumen Detalle: $exitososDetalle exitosos, $fallidosDetalle fallidos" "White"

# PASO 10: Copiar tablas FINALES (InvoiceLines, Transactions)
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 10: Copiar tablas FINALES" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasFinales = @(
    @{Schema="Sales"; Tabla="InvoiceLines"},            # Depende de Invoices, StockItems
    @{Schema="Sales"; Tabla="CustomerTransactions"},    # Depende de Customers, Invoices, TransactionTypes
    @{Schema="Purchasing"; Tabla="SupplierTransactions"}, # Depende de Suppliers, PurchaseOrders, TransactionTypes
    @{Schema="Warehouse"; Tabla="StockItemTransactions"}  # Depende de StockItems, Customers, Invoices, Suppliers
)

$exitososFinales = 0
$fallidosFinales = 0

foreach ($tabla in $tablasFinales) {
    if (Process-Table -schema $tabla.Schema -tabla $tabla.Tabla) {
        $exitososFinales++
    } else {
        $fallidosFinales++
    }
}

Log-Message "" "White"
Log-Message "Resumen Finales: $exitososFinales exitosos, $fallidosFinales fallidos" "White"

# PASO 11: Rehabilitar Foreign Keys y Triggers
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 11: Rehabilitar Foreign Keys y Triggers" "Cyan"
Log-Message "====================================================================" "Cyan"

$sqlFinalizacion = @"
USE [$dbDestino];
GO

-- Rehabilitar Foreign Keys
EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';
GO

-- Rehabilitar Triggers
EXEC sp_MSforeachtable 'ALTER TABLE ? ENABLE TRIGGER ALL';
GO

PRINT 'Foreign Keys y Triggers rehabilitados';
GO
"@

$sqlFile = "$tempDir\finalizacion.sql"
$sqlFinalizacion | Out-File $sqlFile -Encoding UTF8

Log-Message "Rehabilitando FKs y Triggers..." "Yellow"
sqlcmd -S $servidorDestino -U sa -P $passwordDestino -i $sqlFile -b

if ($LASTEXITCODE -eq 0) {
    Log-Message "FKs y Triggers rehabilitados" "Green"
} else {
    Log-Message "Advertencia al rehabilitar FKs y Triggers" "Yellow"
}

# PASO 12: Verificacion
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 12: Verificacion de datos copiados" "Cyan"
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
PRINT '';
PRINT '=== TABLAS CON MAS DATOS ===';
SELECT TOP 5
    s.name + '.' + t.name AS Tabla,
    p.rows AS Filas
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
  AND t.name NOT LIKE '%_Archive'
ORDER BY p.rows DESC;
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

$totalExitosos = $exitososBase + $exitososNivel1 + $exitososNivel2 + $exitososNivel3 + $exitososNivel4 + $exitososNivel5 + $exitososNivel6 + $exitososTrans + $exitososDetalle + $exitososFinales
$totalFallidos = $fallidosBase + $fallidosNivel1 + $fallidosNivel2 + $fallidosNivel3 + $fallidosNivel4 + $fallidosNivel5 + $fallidosNivel6 + $fallidosTrans + $fallidosDetalle + $fallidosFinales

Log-Message "Paso 1 - Base: $exitososBase exitosos" "Green"
Log-Message "Paso 2 - Nivel 1: $exitososNivel1 exitosos" "Green"
Log-Message "Paso 3 - Nivel 2: $exitososNivel2 exitosos" "Green"
Log-Message "Paso 4 - Nivel 3: $exitososNivel3 exitosos" "Green"
Log-Message "Paso 5 - Nivel 4: $exitososNivel4 exitosos" "Green"
Log-Message "Paso 6 - Nivel 5: $exitososNivel5 exitosos" "Green"
Log-Message "Paso 7 - Nivel 6: $exitososNivel6 exitosos" "Green"
Log-Message "Paso 8 - Transaccionales: $exitososTrans exitosos" "Green"
Log-Message "Paso 9 - Detalle: $exitososDetalle exitosos" "Green"
Log-Message "Paso 10 - Finales: $exitososFinales exitosos" "Green"
Log-Message "" "White"
Log-Message "TOTAL: $totalExitosos exitosos de 29 tablas" "White"

if ($totalFallidos -eq 0) {
    Log-Message "" "Green"
    Log-Message "PROCESO COMPLETADO EXITOSAMENTE!" "Green"
    Log-Message "Base de datos WWI_Corporativo lista con TODOS los datos" "Green"
} else {
    Log-Message "" "Yellow"
    Log-Message "PROCESO COMPLETADO CON $totalFallidos ADVERTENCIAS" "Yellow"
    Log-Message "Revisa el log para detalles: $logFile" "Yellow"
}

Log-Message "" "Gray"
Log-Message "Log completo guardado en: $logFile" "Gray"
Log-Message "Archivos temporales en: $tempDir" "Gray"

"=== LOG FIN: $(Get-Date) ===" | Out-File $logFile -Append

Write-Host ""
Write-Host "Presiona cualquier tecla para salir..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
