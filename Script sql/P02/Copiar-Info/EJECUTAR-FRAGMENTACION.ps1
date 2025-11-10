# Script para ejecutar la fragmentacion de datos en San Jose y Limon
# Autor: Luis K
# Fecha: 10 de noviembre de 2025

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  EJECUTAR FRAGMENTACION - SAN JOSE Y LIMON" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

$scriptDir = $PSScriptRoot

Write-Host "IMPORTANTE: Este proceso ejecutara 2 scripts:" -ForegroundColor Yellow
Write-Host "  1. paso3b-copiar-sanjose.ps1 (StateProvinceID <= 26)" -ForegroundColor White
Write-Host "  2. paso3c-copiar-limon.ps1 (StateProvinceID >= 27)" -ForegroundColor White
Write-Host ""
Write-Host "Tiempo estimado: 15-20 minutos total" -ForegroundColor Yellow
Write-Host ""

$respuesta = Read-Host "Desea continuar? (S/N)"

if ($respuesta -ne "S" -and $respuesta -ne "s") {
    Write-Host "Proceso cancelado por el usuario" -ForegroundColor Red
    exit
}

# Paso 1: San Jose
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "  PASO 1: EJECUTANDO SAN JOSE..." -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host ""

$startTimeSJ = Get-Date
& "$scriptDir\paso3b-copiar-sanjose.ps1"
$endTimeSJ = Get-Date
$duracionSJ = $endTimeSJ - $startTimeSJ

Write-Host ""
Write-Host "San Jose completado en: $($duracionSJ.TotalMinutes.ToString('0.00')) minutos" -ForegroundColor Green
Write-Host ""

# Pausa entre scripts
Write-Host "Presione cualquier tecla para continuar con Limon..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Paso 2: Limon
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "  PASO 2: EJECUTANDO LIMON..." -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host ""

$startTimeLIM = Get-Date
& "$scriptDir\paso3c-copiar-limon.ps1"
$endTimeLIM = Get-Date
$duracionLIM = $endTimeLIM - $startTimeLIM

Write-Host ""
Write-Host "Limon completado en: $($duracionLIM.TotalMinutes.ToString('0.00')) minutos" -ForegroundColor Green
Write-Host ""

# Resumen final
$duracionTotal = ($endTimeLIM - $startTimeSJ)

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  RESUMEN FINAL" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "San Jose: $($duracionSJ.TotalMinutes.ToString('0.00')) minutos" -ForegroundColor White
Write-Host "Limon:    $($duracionLIM.TotalMinutes.ToString('0.00')) minutos" -ForegroundColor White
Write-Host "TOTAL:    $($duracionTotal.TotalMinutes.ToString('0.00')) minutos" -ForegroundColor Green
Write-Host ""
Write-Host "Logs generados:" -ForegroundColor White
Write-Host "  - copiar-sanjose.log" -ForegroundColor Gray
Write-Host "  - copiar-limon.log" -ForegroundColor Gray
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  FRAGMENTACION COMPLETADA!" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
