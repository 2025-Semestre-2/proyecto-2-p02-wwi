# Script: Copiar Datos a WWI_Sucursal_LIM (Limon) - CON FRAGMENTACION HORIZONTAL
# Copia datos con fragmentacion por StateProvinceID >= 27
# Basado en paso3b-copiar-sanjose.ps1

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  COPIAR DATOS - WWI_SUCURSAL_LIM (LIMON)" -ForegroundColor Cyan
Write-Host "  CON FRAGMENTACION HORIZONTAL: StateProvinceID >= 27" -ForegroundColor Cyan
Write-Host "  Origen: localhost,1540 (WideWorldImporters P1)" -ForegroundColor Cyan
Write-Host "  Destino: localhost,1435 (WWI_Sucursal_LIM P2)" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Configuracion
$servidorOrigen = "localhost,1540"
$dbOrigen = "WideWorldImporters"
$passwordOrigen = "Admin1234*"

$servidorDestino = "localhost,1435"
$dbDestino = "WWI_Sucursal_LIM"
$passwordDestino = "WideWorld2024!"

$tempDir = "$env:TEMP\WWI_Transfer_Limon"
$logFile = "$PSScriptRoot\copiar-limon.log"

# Crear carpeta temporal
if (-not (Test-Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
}

Write-Host "Carpeta temporal: $tempDir" -ForegroundColor Gray
Write-Host "Archivo log: $logFile" -ForegroundColor Gray
Write-Host ""

# Limpiar log anterior
if (Test-Path $logFile) { Remove-Item $logFile }
"=== LOG INICIO: $(Get-Date) ===" | Out-File $logFile

# Funciones (mismas que San Jose)
function Log-Message {
    param([string]$mensaje, [string]$color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMsg = "[$timestamp] $mensaje"
    Write-Host $mensaje -ForegroundColor $color
    $logMsg | Out-File $logFile -Append
}

function Export-Table {
    param([string]$schema, [string]$tabla)
    $fullTable = "$schema.$tabla"
    $datFile = "$tempDir\$schema`_$tabla.dat"
    $fmtFile = "$tempDir\$schema`_$tabla.fmt"
    
    $queryExport = "SELECT * FROM [$schema].[$tabla]"
    
    bcp $queryExport queryout $datFile -S $servidorOrigen -d $dbOrigen -U sa -P $passwordOrigen -n -o "$tempDir\export_$schema`_$tabla.log"
    
    if ($LASTEXITCODE -eq 0) {
        return $true
    } else {
        Log-Message "  ERROR exportando $fullTable" "Red"
        return $false
    }
}

function Export-Table-Filtered {
    param([string]$schema, [string]$tabla, [string]$whereClause)
    $fullTable = "$schema.$tabla"
    $datFile = "$tempDir\$schema`_$tabla.dat"
    
    $queryExport = "SELECT * FROM [$schema].[$tabla] WHERE $whereClause"
    
    bcp "`"$queryExport`"" queryout $datFile -S $servidorOrigen -d $dbOrigen -U sa -P $passwordOrigen -n -o "$tempDir\export_$schema`_$tabla.log"
    
    if ($LASTEXITCODE -eq 0) {
        return $true
    } else {
        Log-Message "  ERROR exportando $fullTable con filtro" "Red"
        return $false
    }
}

function Import-Table {
    param([string]$schema, [string]$tabla)
    $fullTable = "$schema.$tabla"
    $datFile = "$tempDir\$schema`_$tabla.dat"
    
    if (-not (Test-Path $datFile)) {
        Log-Message "  SKIP: Archivo .dat no existe para $fullTable" "Yellow"
        return $false
    }
    
    # Deshabilitar SYSTEM_VERSIONING si es temporal table
    $sqlDisableVersioning = @"
USE [$dbDestino];
SET QUOTED_IDENTIFIER ON;
IF EXISTS (SELECT 1 FROM sys.tables WHERE schema_id = SCHEMA_ID('$schema') AND name = '$tabla' AND temporal_type = 2)
BEGIN
    ALTER TABLE [$schema].[$tabla] SET (SYSTEM_VERSIONING = OFF);
END
GO
"@
    $sqlFile = "$tempDir\disable_versioning_$schema`_$tabla.sql"
    $sqlDisableVersioning | Out-File $sqlFile -Encoding UTF8
    sqlcmd -S $servidorDestino -U sa -P $passwordDestino -i $sqlFile -b | Out-Null
    
    # Importar datos (usar formato DB.Schema.Table y flag -q para QUOTED_IDENTIFIER)
    bcp "$dbDestino.$schema.$tabla" in $datFile -S $servidorDestino -U sa -P $passwordDestino -n -b 5000 -q -o "$tempDir\import_$schema`_$tabla.log"
    
    $importExitoso = ($LASTEXITCODE -eq 0)
    
    # Rehabilitar SYSTEM_VERSIONING
    $sqlEnableVersioning = @"
USE [$dbDestino];
SET QUOTED_IDENTIFIER ON;
IF EXISTS (SELECT 1 FROM sys.tables WHERE schema_id = SCHEMA_ID('$schema') AND name = '$tabla' AND temporal_type = 0)
BEGIN
    ALTER TABLE [$schema].[$tabla] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [$schema].[${tabla}_Archive]));
END
GO
"@
    $sqlFile = "$tempDir\enable_versioning_$schema`_$tabla.sql"
    $sqlEnableVersioning | Out-File $sqlFile -Encoding UTF8
    sqlcmd -S $servidorDestino -U sa -P $passwordDestino -i $sqlFile -b | Out-Null
    
    return $importExitoso
}

function Process-Table {
    param([string]$schema, [string]$tabla)
    $fullTable = "$schema.$tabla"
    Log-Message "  Procesando: $fullTable" "White"
    
    if (Export-Table $schema $tabla) {
        if (Import-Table $schema $tabla) {
            Log-Message "  OK: $fullTable copiado" "Green"
            return $true
        }
    }
    Log-Message "  FALLO: $fullTable" "Red"
    return $false
}

function Process-Table-Filtered {
    param([string]$schema, [string]$tabla, [string]$whereClause)
    $fullTable = "$schema.$tabla"
    Log-Message "  Procesando (filtrado): $fullTable" "White"
    
    if (Export-Table-Filtered $schema $tabla $whereClause) {
        if (Import-Table $schema $tabla) {
            Log-Message "  OK: $fullTable copiado (filtrado)" "Green"
            return $true
        }
    }
    Log-Message "  FALLO: $fullTable" "Red"
    return $false
}

# PASO 0: Limpiar datos existentes y preparar BD
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 0: Preparar base de datos Limon" "Cyan"
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

-- Limpiar tablas existentes
DELETE FROM [Sales].[SpecialDeals];
DELETE FROM [Sales].[CustomerTransactions];
DELETE FROM [Sales].[InvoiceLines];
DELETE FROM [Sales].[Invoices];
DELETE FROM [Sales].[OrderLines];
DELETE FROM [Sales].[Orders];
DELETE FROM [Sales].[Customers];
DELETE FROM [Sales].[CustomerCategories];
DELETE FROM [Sales].[BuyingGroups];
DELETE FROM [Purchasing].[SupplierTransactions];
DELETE FROM [Purchasing].[PurchaseOrderLines];
DELETE FROM [Purchasing].[PurchaseOrders];
DELETE FROM [Purchasing].[Suppliers];
DELETE FROM [Purchasing].[SupplierCategories];
DELETE FROM [Warehouse].[StockItemTransactions];
DELETE FROM [Warehouse].[StockItemHoldings];
DELETE FROM [Warehouse].[StockItemStockGroups];
DELETE FROM [Warehouse].[StockItems];
DELETE FROM [Warehouse].[StockGroups];
DELETE FROM [Warehouse].[PackageTypes];
DELETE FROM [Warehouse].[Colors];
DELETE FROM [Application].[People];
DELETE FROM [Application].[Cities];
DELETE FROM [Application].[StateProvinces];
DELETE FROM [Application].[Countries];
DELETE FROM [Application].[DeliveryMethods];
DELETE FROM [Application].[PaymentMethods];
DELETE FROM [Application].[TransactionTypes];
DELETE FROM [Application].[SystemParameters];
GO

PRINT 'Base de datos preparada para Limon';
GO
"@

$sqlFile = "$tempDir\preparacion.sql"
$sqlPreparacion | Out-File $sqlFile -Encoding UTF8

Log-Message "Preparando base de datos..." "Yellow"
sqlcmd -S $servidorDestino -U sa -P $passwordDestino -i $sqlFile -b

if ($LASTEXITCODE -eq 0) {
    Log-Message "Base de datos preparada correctamente" "Green"
} else {
    Log-Message "ERROR preparando base de datos" "Red"
    exit 1
}

# PASO 1-5: Copiar catalogos completos (igual que San Jose)
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 1: Copiar tablas BASE (catalogo completo)" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasBase = @(
    @{Schema="Warehouse"; Tabla="Colors"},
    @{Schema="Warehouse"; Tabla="PackageTypes"},
    @{Schema="Warehouse"; Tabla="StockGroups"},
    @{Schema="Sales"; Tabla="BuyingGroups"},
    @{Schema="Sales"; Tabla="CustomerCategories"},
    @{Schema="Purchasing"; Tabla="SupplierCategories"},
    @{Schema="Application"; Tabla="DeliveryMethods"},
    @{Schema="Application"; Tabla="PaymentMethods"},
    @{Schema="Application"; Tabla="TransactionTypes"},
    @{Schema="Application"; Tabla="SystemParameters"}
)

$exitososBase = 0
$fallidosBase = 0

foreach ($item in $tablasBase) {
    if (Process-Table $item.Schema $item.Tabla) {
        $exitososBase++
    } else {
        $fallidosBase++
    }
}

Log-Message "" "White"
Log-Message "Resumen Base: $exitososBase exitosos, $fallidosBase fallidos" "White"

Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 2: Copiar tablas NIVEL 1 (catalogo geografico completo)" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasNivel1 = @(
    @{Schema="Application"; Tabla="Countries"},
    @{Schema="Application"; Tabla="StateProvinces"}
)

$exitososNivel1 = 0
$fallidosNivel1 = 0

foreach ($item in $tablasNivel1) {
    if (Process-Table $item.Schema $item.Tabla) {
        $exitososNivel1++
    } else {
        $fallidosNivel1++
    }
}

Log-Message "" "White"
Log-Message "Resumen Nivel 1: $exitososNivel1 exitosos, $fallidosNivel1 fallidos" "White"

Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 3: Copiar tablas NIVEL 2 (ciudades y personas completas)" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasNivel2 = @(
    @{Schema="Application"; Tabla="Cities"},
    @{Schema="Application"; Tabla="People"}
)

$exitososNivel2 = 0
$fallidosNivel2 = 0

foreach ($item in $tablasNivel2) {
    if (Process-Table $item.Schema $item.Tabla) {
        $exitososNivel2++
    } else {
        $fallidosNivel2++
    }
}

Log-Message "" "White"
Log-Message "Resumen Nivel 2: $exitososNivel2 exitosos, $fallidosNivel2 fallidos" "White"

Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 4: Copiar tablas NIVEL 3 (proveedores y productos completos)" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasNivel3 = @(
    @{Schema="Purchasing"; Tabla="Suppliers"},
    @{Schema="Warehouse"; Tabla="StockItems"}
)

$exitososNivel3 = 0
$fallidosNivel3 = 0

foreach ($item in $tablasNivel3) {
    if (Process-Table $item.Schema $item.Tabla) {
        $exitososNivel3++
    } else {
        $fallidosNivel3++
    }
}

Log-Message "" "White"
Log-Message "Resumen Nivel 3: $exitososNivel3 exitosos, $fallidosNivel3 fallidos" "White"

Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 5: Copiar tablas NIVEL 4 (stock groups y holdings)" "Cyan"
Log-Message "====================================================================" "Cyan"

$tablasNivel4 = @(
    @{Schema="Warehouse"; Tabla="StockItemStockGroups"},
    @{Schema="Warehouse"; Tabla="StockItemHoldings"}
)

$exitososNivel4 = 0
$fallidosNivel4 = 0

foreach ($item in $tablasNivel4) {
    if (Process-Table $item.Schema $item.Tabla) {
        $exitososNivel4++
    } else {
        $fallidosNivel4++
    }
}

Log-Message "" "White"
Log-Message "Resumen Nivel 4: $exitososNivel4 exitosos, $fallidosNivel4 fallidos" "White"

# ===========================================================================================
# PASO 6-16: FRAGMENTACION HORIZONTAL - LIMON (StateProvinceID >= 27)
# ===========================================================================================
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 6: FRAGMENTACION - Clientes de Limon (StateProvinceID >= 27)" "Cyan"
Log-Message "====================================================================" "Cyan"

$filtroLimon = "DeliveryCityID IN (SELECT CityID FROM Application.Cities WHERE StateProvinceID >= 27)"

if (Process-Table-Filtered "Sales" "Customers" $filtroLimon) {
    Log-Message "OK: Sales.Customers fragmentado (Limon)" "Green"
} else {
    Log-Message "FALLO: Sales.Customers" "Red"
}

Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 7: FRAGMENTACION - Ordenes de Limon" "Cyan"
Log-Message "====================================================================" "Cyan"

$filtroOrders = "CustomerID IN (SELECT CustomerID FROM Sales.Customers WHERE DeliveryCityID IN (SELECT CityID FROM Application.Cities WHERE StateProvinceID >= 27))"

if (Process-Table-Filtered "Sales" "Orders" $filtroOrders) {
    Log-Message "OK: Sales.Orders fragmentado (Limon)" "Green"
} else {
    Log-Message "FALLO: Sales.Orders" "Red"
}

Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 8: FRAGMENTACION - Facturas de Limon" "Cyan"
Log-Message "====================================================================" "Cyan"

$filtroInvoices = "CustomerID IN (SELECT CustomerID FROM Sales.Customers WHERE DeliveryCityID IN (SELECT CityID FROM Application.Cities WHERE StateProvinceID >= 27))"

if (Process-Table-Filtered "Sales" "Invoices" $filtroInvoices) {
    Log-Message "OK: Sales.Invoices fragmentado (Limon)" "Green"
} else {
    Log-Message "FALLO: Sales.Invoices" "Red"
}

Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 9: FRAGMENTACION - Lineas de Ordenes de Limon" "Cyan"
Log-Message "====================================================================" "Cyan"

$filtroOrderLines = "OrderID IN (SELECT OrderID FROM Sales.Orders WHERE CustomerID IN (SELECT CustomerID FROM Sales.Customers WHERE DeliveryCityID IN (SELECT CityID FROM Application.Cities WHERE StateProvinceID >= 27)))"

if (Process-Table-Filtered "Sales" "OrderLines" $filtroOrderLines) {
    Log-Message "OK: Sales.OrderLines fragmentado (Limon)" "Green"
} else {
    Log-Message "FALLO: Sales.OrderLines" "Red"
}

Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 10: FRAGMENTACION - Lineas de Facturas de Limon" "Cyan"
Log-Message "====================================================================" "Cyan"

$filtroInvoiceLines = "InvoiceID IN (SELECT InvoiceID FROM Sales.Invoices WHERE CustomerID IN (SELECT CustomerID FROM Sales.Customers WHERE DeliveryCityID IN (SELECT CityID FROM Application.Cities WHERE StateProvinceID >= 27)))"

if (Process-Table-Filtered "Sales" "InvoiceLines" $filtroInvoiceLines) {
    Log-Message "OK: Sales.InvoiceLines fragmentado (Limon)" "Green"
} else {
    Log-Message "FALLO: Sales.InvoiceLines" "Red"
}

Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 11: FRAGMENTACION - Transacciones de Clientes de Limon" "Cyan"
Log-Message "====================================================================" "Cyan"

$filtroCustomerTransactions = "CustomerID IN (SELECT CustomerID FROM Sales.Customers WHERE DeliveryCityID IN (SELECT CityID FROM Application.Cities WHERE StateProvinceID >= 27))"

if (Process-Table-Filtered "Sales" "CustomerTransactions" $filtroCustomerTransactions) {
    Log-Message "OK: Sales.CustomerTransactions fragmentado (Limon)" "Green"
} else {
    Log-Message "FALLO: Sales.CustomerTransactions" "Red"
}

Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 12: FRAGMENTACION - Special Deals de Limon" "Cyan"
Log-Message "====================================================================" "Cyan"

$filtroSpecialDeals = "CustomerID IN (SELECT CustomerID FROM Sales.Customers WHERE DeliveryCityID IN (SELECT CityID FROM Application.Cities WHERE StateProvinceID >= 27))"

if (Process-Table-Filtered "Sales" "SpecialDeals" $filtroSpecialDeals) {
    Log-Message "OK: Sales.SpecialDeals fragmentado (Limon)" "Green"
} else {
    Log-Message "FALLO: Sales.SpecialDeals" "Red"
}

Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 13: Copiar PurchaseOrders (completo - sin fragmentacion)" "Cyan"
Log-Message "====================================================================" "Cyan"

if (Process-Table "Purchasing" "PurchaseOrders") {
    Log-Message "OK: Purchasing.PurchaseOrders copiado completo" "Green"
} else {
    Log-Message "FALLO: Purchasing.PurchaseOrders" "Red"
}

Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 14: Copiar PurchaseOrderLines (completo)" "Cyan"
Log-Message "====================================================================" "Cyan"

if (Process-Table "Purchasing" "PurchaseOrderLines") {
    Log-Message "OK: Purchasing.PurchaseOrderLines copiado completo" "Green"
} else {
    Log-Message "FALLO: Purchasing.PurchaseOrderLines" "Red"
}

Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 15: Copiar SupplierTransactions (completo)" "Cyan"
Log-Message "====================================================================" "Cyan"

if (Process-Table "Purchasing" "SupplierTransactions") {
    Log-Message "OK: Purchasing.SupplierTransactions copiado completo" "Green"
} else {
    Log-Message "FALLO: Purchasing.SupplierTransactions" "Red"
}

Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO 16: FRAGMENTACION - StockItemTransactions de Limon" "Cyan"
Log-Message "====================================================================" "Cyan"

$filtroStockTrans = "CustomerID IN (SELECT CustomerID FROM Sales.Customers WHERE DeliveryCityID IN (SELECT CityID FROM Application.Cities WHERE StateProvinceID >= 27)) OR CustomerID IS NULL"

if (Process-Table-Filtered "Warehouse" "StockItemTransactions" $filtroStockTrans) {
    Log-Message "OK: Warehouse.StockItemTransactions fragmentado (Limon + NULL)" "Green"
} else {
    Log-Message "FALLO: Warehouse.StockItemTransactions" "Red"
}

# PASO FINAL: Rehabilitar FKs y triggers
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PASO FINAL: Rehabilitar Foreign Keys y Triggers" "Cyan"
Log-Message "====================================================================" "Cyan"

$sqlFinalizacion = @"
USE [$dbDestino];
GO

-- Rehabilitar Foreign Keys
EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';
GO

-- Rehabilitar triggers
EXEC sp_MSforeachtable 'ALTER TABLE ? ENABLE TRIGGER ALL';
GO

PRINT 'Foreign Keys y Triggers rehabilitados';
GO
"@

$sqlFile = "$tempDir\finalizacion.sql"
$sqlFinalizacion | Out-File $sqlFile -Encoding UTF8

Log-Message "Rehabilitando FKs y triggers..." "Yellow"
sqlcmd -S $servidorDestino -U sa -P $passwordDestino -i $sqlFile -b

if ($LASTEXITCODE -eq 0) {
    Log-Message "FKs y triggers rehabilitados correctamente" "Green"
} else {
    Log-Message "ADVERTENCIA: Algunos FKs/triggers no se rehabilitaron" "Yellow"
}

# VERIFICACION
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "VERIFICACION - Datos copiados a Limon" "Cyan"
Log-Message "====================================================================" "Cyan"

$sqlVerificacion = @"
USE [$dbDestino];
GO

PRINT '';
PRINT '=== RESUMEN DE DATOS EN LIMON ===';
PRINT '';

SELECT 'Sales.Customers' AS Tabla, COUNT(*) AS TotalFilas FROM Sales.Customers;
SELECT 'Sales.Orders' AS Tabla, COUNT(*) AS TotalFilas FROM Sales.Orders;
SELECT 'Sales.Invoices' AS Tabla, COUNT(*) AS TotalFilas FROM Sales.Invoices;
SELECT 'Sales.OrderLines' AS Tabla, COUNT(*) AS TotalFilas FROM Sales.OrderLines;
SELECT 'Sales.InvoiceLines' AS Tabla, COUNT(*) AS TotalFilas FROM Sales.InvoiceLines;
SELECT 'Sales.CustomerTransactions' AS Tabla, COUNT(*) AS TotalFilas FROM Sales.CustomerTransactions;
SELECT 'Warehouse.StockItems' AS Tabla, COUNT(*) AS TotalFilas FROM Warehouse.StockItems;
SELECT 'Warehouse.StockItemTransactions' AS Tabla, COUNT(*) AS TotalFilas FROM Warehouse.StockItemTransactions;
SELECT 'Application.People' AS Tabla, COUNT(*) AS TotalFilas FROM Application.People;

PRINT '';
PRINT '=== VERIFICACION: Clientes deben tener StateProvinceID >= 27 ===';
SELECT 
    MIN(sp.StateProvinceID) AS MinStateID,
    MAX(sp.StateProvinceID) AS MaxStateID,
    COUNT(DISTINCT cu.CustomerID) AS TotalClientes
FROM Sales.Customers cu
INNER JOIN Application.Cities c ON cu.DeliveryCityID = c.CityID
INNER JOIN Application.StateProvinces sp ON c.StateProvinceID = sp.StateProvinceID;

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

$totalExitosos = $exitososBase + $exitososNivel1 + $exitososNivel2 + $exitososNivel3 + $exitososNivel4 + 12
$totalFallidos = $fallidosBase + $fallidosNivel1 + $fallidosNivel2 + $fallidosNivel3 + $fallidosNivel4

Log-Message "Total tablas procesadas: $($totalExitosos + $totalFallidos)" "White"
Log-Message "Exitosas: $totalExitosos" "Green"
Log-Message "Fallidas: $totalFallidos" "Red"
Log-Message "" "White"
Log-Message "Fragmentacion: StateProvinceID >= 27 (Limon)" "Cyan"
Log-Message "Log completo: $logFile" "Gray"
Log-Message "Archivos temporales: $tempDir" "Gray"
Log-Message "" "White"
Log-Message "====================================================================" "Cyan"
Log-Message "PROCESO COMPLETADO" "Cyan"
Log-Message "====================================================================" "Cyan"

"=== LOG FIN: $(Get-Date) ===" | Out-File $logFile -Append
