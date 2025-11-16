# create-fragmentation-tables.ps1
# Aplica los scripts de tablas/vistas de fragmentacion en los 3 dockers

param(
    [string]$SaUser    = "sa",
    [string]$SaPassword = "WideWorld2024!",
    [int]$PortCorp     = 1444,
    [int]$PortSJ       = 1445,
    [int]$PortLim      = 1446
)

$ErrorActionPreference = "Stop"

function Write-Color {
    param([string]$Msg, [string]$Type = "Info")
    $color = @{
        Info    = "Cyan"
        Ok      = "Green"
        Warn    = "Yellow"
        Error   = "Red"
    }[$Type]
    Write-Host $Msg -ForegroundColor $color
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

Write-Host ""
Write-Color "== APLICAR SCRIPTS DE TABLAS/VISTAS DE FRAGMENTACION ==" "Info"

if (-not (Test-CommandExists "sqlcmd")) {
    Write-Color "[ERROR] sqlcmd no encontrado. Instala las herramientas de SQLCMD." "Error"
    exit 1
}

# Carpeta donde estan los scripts .sql de fragmentacion
# (segun tu screenshot)
$SqlFolder = Join-Path $PSScriptRoot "Script sql\Fragmentacion"

if (-not (Test-Path $SqlFolder)) {
    Write-Color "[ERROR] No se encontro la carpeta de scripts: $SqlFolder" "Error"
    exit 1
}

$targets = @(
    @{
        Name     = "Corporativo"
        Server   = "localhost,$PortCorp"
        Database = "WWI_Corporativo"
        Script   = "WWI_Corporativo_TablasYVistas.sql"
    },
    @{
        Name     = "San Jose"
        Server   = "localhost,$PortSJ"
        Database = "WWI_Sucursal_SJ"
        Script   = "WWI_Sucursal_SJ_Tablas.sql"
    },
    @{
        Name     = "Limon"
        Server   = "localhost,$PortLim"
        Database = "WWI_Sucursal_LIM"
        Script   = "WWI_Sucursal_LIM_Tablas.sql"
    }
)

foreach ($t in $targets) {
    $scriptFile = Join-Path $SqlFolder $t.Script

    if (-not (Test-Path $scriptFile)) {
        Write-Color "[ERROR] No se encuentra el script para $($t.Name): $scriptFile" "Error"
        exit 1
    }

    Write-Host ""
    Write-Color "== Aplicando script para $($t.Name) ==" "Info"
    Write-Host "   Servidor: $($t.Server)"
    Write-Host "   Base    : $($t.Database)"
    Write-Host "   Script  : $scriptFile"

    & sqlcmd `
        -S $t.Server `
        -d $t.Database `
        -U $SaUser `
        -P $SaPassword `
        -b `
        -i $scriptFile

    if ($LASTEXITCODE -ne 0) {
        Write-Color "[ERROR] Fallo ejecutando $scriptFile en $($t.Name). Codigo: $LASTEXITCODE" "Error"
        exit 1
    }

    Write-Color "OK: Script aplicado en $($t.Name)" "Ok"
}


$CambiarProv = Join-Path $SqlFolder "CambiarProvincias.sql"

if (Test-Path $CambiarProv) {
    Write-Host ""
    Write-Color "== Ejecutando CambiarProvincias.sql en WideWorldImporters (Corporativo) ==" "Info"

    & sqlcmd `
        -S "localhost,$PortCorp" `
        -d "WideWorldImporters" `
        -U $SaUser `
        -P $SaPassword `
        -b `
        -i $CambiarProv

    if ($LASTEXITCODE -ne 0) {
        Write-Color "[ERROR] Fallo CambiarProvincias.sql en WideWorldImporters. Codigo: $LASTEXITCODE" "Error"
        exit 1
    }

    Write-Color "OK: CambiarProvincias aplicado en WideWorldImporters" "Ok"
} else {
    Write-Color "[WARN] CambiarProvincias.sql no encontrado, se omite." "Warn"
}

Write-Host ""
Write-Color "== TODOS LOS SCRIPTS SE APLICARON CORRECTAMENTE ==" "Ok"
