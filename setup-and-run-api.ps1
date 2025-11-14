param(
  [string]$CorpUser = "corp_analytics",
  [string]$CorpPass = "Corporativo#1",
  [string]$SjUser   = "admin_sj",
  [string]$SjPass   = "Administrador#SanJose",
  [string]$LimUser  = "admin_lim",
  [string]$LimPass  = "Administrador#Limon",
  [int]$Port = 3000,
  [switch]$RunSecuritySql,
  [string]$SaUser = "sa",
  [string]$SaPass = "WideWorld2024!"
)

Write-Host "== Configurando variables de entorno =="
$env:DB_CORP_USER = $CorpUser
$env:DB_CORP_PASSWORD = $CorpPass
$env:DB_SJ_USER = $SjUser
$env:DB_SJ_PASSWORD = $SjPass
$env:DB_LIM_USER = $LimUser
$env:DB_LIM_PASSWORD = $LimPass
$env:PORT = "$Port"

if (-not $env:DB_USER) { $env:DB_USER = $CorpUser }
if (-not $env:DB_PASSWORD) { $env:DB_PASSWORD = $CorpPass }
if (-not $env:DB_ENCRYPT) { $env:DB_ENCRYPT = "false" }
if (-not $env:DB_TRUST_SERVER_CERTIFICATE) { $env:DB_TRUST_SERVER_CERTIFICATE = "true" }

Write-Host "== Instalando dependencias (si faltan) =="

# cambiamos el cwd a la carpeta de la API
Push-Location "proyectos/api"
if (-not (Test-Path "node_modules")) {
  npm i express morgan mssql dotenv | Write-Host
}
Pop-Location

if ($RunSecuritySql) {
  if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    Write-Error "sqlcmd no encontrado. Instala SQLCMD o usa Azure Data Studio/SSMS para correr los .sql"
    exit 1
  }

  Write-Host "== Ejecutando scripts de seguridad (logins/roles/usuarios) =="

  $baseSql = "Script sql/Roles"
  $sql2 = Join-Path $baseSql "2)CrearLogins.sql"
  $sql3 = Join-Path $baseSql "3)CrearRoles.sql"
  $sql4 = Join-Path $baseSql "4)MapearUsuarios.sql"

  if (-not (Test-Path $sql2) -or -not (Test-Path $sql3) -or -not (Test-Path $sql4)) {
    Write-Warning "No se encontraron los .sql en $baseSql. Omitiendo ejecución."
  } else {
    & sqlcmd -S "localhost,1444" -U $SaUser -P $SaPass -i $sql2
    & sqlcmd -S "localhost,1444" -U $SaUser -P $SaPass -i $sql3
    & sqlcmd -S "localhost,1444" -U $SaUser -P $SaPass -i $sql4

    & sqlcmd -S "localhost,1445" -U $SaUser -P $SaPass -i $sql2
    & sqlcmd -S "localhost,1445" -U $SaUser -P $SaPass -i $sql3
    & sqlcmd -S "localhost,1445" -U $SaUser -P $SaPass -i $sql4

    & sqlcmd -S "localhost,1446" -U $SaUser -P $SaPass -i $sql2
    & sqlcmd -S "localhost,1446" -U $SaUser -P $SaPass -i $sql3
    & sqlcmd -S "localhost,1446" -U $SaUser -P $SaPass -i $sql4
  }
}

Write-Host "== Levantando API (proyectos/api/src/app.api.js) =="

Push-Location "proyectos/api"
$node = Start-Process -FilePath "node" -ArgumentList "src/app.api.js" -NoNewWindow -PassThru
Pop-Location

Start-Sleep -Seconds 2
try {
  $health = Invoke-RestMethod -Uri "http://localhost:$Port/health" -Method GET -TimeoutSec 10
  Write-Host "Salud API:" ($health | ConvertTo-Json -Depth 3)
} catch {
  Write-Warning "No se pudo consultar /health. Verifica logs de Node."
}

Write-Host "== Pruebas rapidas de endpoints =="

try {
  $clientes = Invoke-RestMethod -Uri "http://localhost:$Port/api/clientes?page=1&pageSize=2" -Method GET -TimeoutSec 30
  Write-Host "Clientes (2):" ($clientes | ConvertTo-Json -Depth 5)
} catch { Write-Warning "Fallo GET /api/clientes: $($_.Exception.Message)" }

try {
  $productos = Invoke-RestMethod -Uri "http://localhost:$Port/api/productos?page=1&pageSize=2" -Method GET -TimeoutSec 30
  Write-Host "Productos (2):" ($productos | ConvertTo-Json -Depth 5)
} catch { Write-Warning "Fallo GET /api/productos: $($_.Exception.Message)" }

Write-Host "API ejecutandose en http://localhost:$Port"
