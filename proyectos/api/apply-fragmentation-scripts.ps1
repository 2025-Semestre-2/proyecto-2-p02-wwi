param(
    [string]$SaUser = "sa",
    [string]$SaPassword = "WideWorld2024!"
)

$ErrorActionPreference = "Stop"

Write-Host "== INICIO: Aplicar scripts de fragmentacion ==" -ForegroundColor Yellow

# Ruta donde estan los .sql EXACTAMENTE en tu PC
$sqlPath = "C:\Users\Tayle\OneDrive\Documentos\GitHub\proyecto-2-p02-wwi\Script sql\Fragmentacion"

if (-not (Test-Path $sqlPath)) {
    throw "La carpeta de scripts SQL no existe: $sqlPath"
}

# Definir los servidores y sus scripts
$targets = @(
    @{
        Name     = "Corporativo"
        Server   = "localhost,1444"
        Database = "WWI_Corporativo"
        Script   = "WWI_Corporativo_TablasYVistas.sql"
    },
    @{
        Name     = "SanJose"
        Server   = "localhost,1445"
        Database = "WWI_Sucursal_SJ"
        Script   = "WWI_Sucursal_SJ_Tablas.sql"
    },
    @{
        Name     = "Limon"
        Server   = "localhost,1446"
        Database = "WWI_Sucursal_LIM"
        Script   = "WWI_Sucursal_LIM_Tablas.sql"
    }
)

foreach ($t in $targets) {

    $scriptFile = Join-Path $sqlPath $t.Script

    if (-not (Test-Path $scriptFile)) {
        throw "No se encuentra el script para $($t.Name): $scriptFile"
    }

    Write-Host ""
    Write-Host "== Aplicando script para $($t.Name) ==" -ForegroundColor Cyan
    Write-Host "   Servidor : $($t.Server)"
    Write-Host "   Base     : $($t.Database)"
    Write-Host "   Script   : $scriptFile"

    & sqlcmd `
        -S $t.Server `
        -d $t.Database `
        -U $SaUser `
        -P $SaPassword `
        -b `
        -i $scriptFile

    if ($LASTEXITCODE -ne 0) {
        throw "Error ejecutando el script $scriptFile en $($t.Name). Código: $LASTEXITCODE"
    }

    Write-Host "   OK: Script aplicado en $($t.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "== TODOS LOS SCRIPTS SE APLICARON CORRECTAMENTE ==" -ForegroundColor Green
