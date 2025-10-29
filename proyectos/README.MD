# Código del Proyecto - Wide World Importers

Esta carpeta contiene todo el código fuente del proyecto, incluyendo frontend, backend y configuración de contenedores.


## Estructura

### `api/` - Backend API
- **Tecnología**: Node.js + Express.js + SQL Server
- **Puerto**: 3001
- **Funcionalidad**: API RESTful que se conecta a la base de datos a través de procedimientos almacenados

### `proyecto-bases/` - Frontend Web
- **Tecnología**: React.js + Vite
- **Puerto**: 5173
- **Funcionalidad**: Interfaz de usuario para consultas y visualización de datos
- **Módulos implementados**:
	- Clientes: filtros por nombre, categoría, orden asc/desc
	- Proveedores: filtros por nombre, categoría, orden asc/desc
	- Productos: filtros por nombre, grupo, cantidad, orden asc/desc
	- Ventas: filtros por cliente, fecha, monto, orden asc/desc
	- Estadísticas: filtros avanzados y ordenamiento


## Instrucciones de Ejecución

### 1. Iniciar el API
```bash
cd api/
npm install
npm run dev
```

### 2. Iniciar el Frontend
```bash
cd proyecto-bases/
npm install  
npm run dev
```


## URLs de Acceso
- **Frontend**: http://localhost:5173
- **API**: http://localhost:3001
- **Base de Datos**: 1540

## Estado actual
- Todos los módulos y filtros implementados.
- Ordenamiento ascendente/descendente en todas las tablas.

