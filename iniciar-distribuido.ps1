# Iniciar servicios distribuidos
Write-Host "Iniciando 3 servidores SQL Server..." -ForegroundColor Cyan

docker-compose -f docker-compose-distribuido.yml up -d

Write-Host "`nEsperando a que los servidores esten listos..." -ForegroundColor Yellow
Start-Sleep -Seconds 45

# Verificar estado
Write-Host "`nEstado de los contenedores:" -ForegroundColor Green
docker ps --filter "name=wwi-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host "`n=== SERVIDORES LISTOS ===" -ForegroundColor Green
Write-Host "Corporativo: localhost,1433" -ForegroundColor White
Write-Host "San Jose:    localhost,1434" -ForegroundColor White
Write-Host "Limon:       localhost,1435" -ForegroundColor White
Write-Host "`nUsuario: sa" -ForegroundColor White
Write-Host "Password: WideWorld2024!" -ForegroundColor White
