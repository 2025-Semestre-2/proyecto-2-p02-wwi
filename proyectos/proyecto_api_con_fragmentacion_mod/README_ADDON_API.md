
# Addon API (no destructivo)

Se agregaron rutas y utilidades nuevas **sin borrar ni sobrescribir** archivos existentes.

## Archivos agregados
- `api/src/db/exec.js`
- `api/src/routes/clientes.routes.js`
- `api/src/routes/productos.routes.js`
- `api/src/routes/facturas.routes.js`
- `api/src/routes/ordenes.routes.js`
- `api/src/app.api.js`
- `.env.example`

## Como ejecutar (sin tocar tu app existente)
1. Copia `.env.example` a `.env` y ajusta credenciales si aplica.
2. Instala dependencias si hace falta:
   ```bash
   npm i express morgan mssql dotenv
   ```
3. Ejecuta el nuevo bootstrap:
   ```bash
   node api/src/app.api.js
   ```
4. Endpoints disponibles:
   - GET `http://localhost:3000/health`
   - GET `http://localhost:3000/api/clientes`
   - GET `http://localhost:3000/api/clientes/:id?role=ADMINISTRADOR_CORPORATIVO`
   - POST `http://localhost:3000/api/clientes`
   - PATCH `http://localhost:3000/api/clientes/:id/sensibles`
   - GET `http://localhost:3000/api/productos`
   - GET `http://localhost:3000/api/facturas`
   - GET `http://localhost:3000/api/ordenes-compra`

> Nota: Estos endpoints consumen los SP/vistas que definimos en SQL. Asegurate de haber creado los linked servers y SPs.
