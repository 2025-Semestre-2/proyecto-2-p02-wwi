# Script simplificado para ejecutar el proyecto Wide World Importers

Write-Host "Iniciando Wide World Importers - Stack Completo" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Verificar Node.js
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Node.js no esta instalado." -ForegroundColor Red
    exit 1
}

# Navegar al directorio del proyecto
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

Write-Host "Directorio del proyecto: $projectRoot" -ForegroundColor Green

# Instalar dependencias de la API
Write-Host "`nConfigurando API..." -ForegroundColor Yellow
Set-Location "proyectos/api"

if (!(Test-Path "node_modules")) {
    Write-Host "Instalando dependencias de la API..." -ForegroundColor Yellow
    npm install
}

# Instalar dependencias del Frontend
Write-Host "`nConfigurando Frontend..." -ForegroundColor Yellow
Set-Location "../proyecto-bases"

if (!(Test-Path "node_modules")) {
    Write-Host "Instalando dependencias del Frontend..." -ForegroundColor Yellow
    npm install
}

# Volver al directorio raíz
Set-Location $projectRoot

Write-Host "`nConfiguracion completada!" -ForegroundColor Green
Write-Host "`nIniciando servicios..." -ForegroundColor Cyan

# Iniciar la API en background
Write-Host "Iniciando API en puerto 3001..." -ForegroundColor Green
$apiJob = Start-Job -ScriptBlock {
    Set-Location $using:projectRoot
    Set-Location "proyectos/api"
    npm start
}

# Esperar para que la API inicie
Start-Sleep -Seconds 3

# Mostrar información de conexión
Write-Host "`nInformacion de conexion:" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "API Backend:    http://localhost:3001" -ForegroundColor White
Write-Host "Frontend:       http://localhost:5173" -ForegroundColor White
Write-Host "Base de Datos:  localhost:1540 (WideWorldImporters)" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "`nPresione Ctrl+C para detener todos los servicios" -ForegroundColor Yellow

# Iniciar el frontend
Set-Location "proyectos/proyecto-bases"
try {
    npm run dev
} finally {
    Write-Host "`nDeteniendo servicios..." -ForegroundColor Yellow
    Stop-Job $apiJob -Force
    Remove-Job $apiJob -Force
    Write-Host "Servicios detenidos" -ForegroundColor Green
}
