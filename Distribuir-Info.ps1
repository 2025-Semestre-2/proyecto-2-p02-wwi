# run-distribution.ps1
# Ejecuta los endpoints de distribucion de la API

param(
    [int]$ApiPort = 3000,
    [switch]$SoloProductos,
    [switch]$SoloClientes,
    [switch]$SoloFacturas
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

function Call-Endpoint {
    param(
        [string]$Method,
        [string]$Url,
        [string]$Descripcion
    )

    Write-Host ""
    Write-Color "== $Descripcion ==" "Info"
    Write-Host "   $Method $Url"

    try {
        $result = & curl.exe -s -X $Method $Url
        Write-Host $result
        Write-Color "OK: $Descripcion ejecutado" "Ok"
    } catch {
        Write-Color "[ERROR] Fallo al llamar $Url : $($_.Exception.Message)" "Error"
    }
}

$baseUrl = "http://localhost:$ApiPort/api/distribucion"

# Log de que endpoints se van a correr
if (-not ($SoloProductos -or $SoloClientes -or $SoloFacturas)) {
    Write-Color "No se especifico ningun switch, se ejecutaran: productos, clientes y facturas." "Warn"
}

# Productos
if ($SoloProductos -or -not ($SoloProductos -or $SoloClientes -or $SoloFacturas)) {
    Call-Endpoint -Method "POST" -Url "$baseUrl/productos" -Descripcion "Distribucion de productos"
}

# Clientes
if ($SoloClientes -or -not ($SoloProductos -or $SoloClientes -or $SoloFacturas)) {
    Call-Endpoint -Method "POST" -Url "$baseUrl/clientes" -Descripcion "Distribucion de clientes"
}

# Facturas (si aun no esta listo, este bloque lo puedes comentar)
if ($SoloFacturas -or -not ($SoloProductos -or $SoloClientes -or $SoloFacturas)) {
    Call-Endpoint -Method "POST" -Url "$baseUrl/facturas" -Descripcion "Distribucion de facturas"
}

# Estado final
Write-Host ""
Write-Color "== Consultando estado final de distribucion ==" "Info"
try {
    $estado = & curl.exe -s "$baseUrl/estado"
    Write-Host $estado
    Write-Color "OK: Estado obtenido" "Ok"
} catch {
    Write-Color "[ERROR] No se pudo obtener /estado : $($_.Exception.Message)" "Error"
}
