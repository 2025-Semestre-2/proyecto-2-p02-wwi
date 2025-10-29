[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/TcpR1N0p)

# [NOMBRE DEL PROYECTO]
### Nombre y carné de los integrantes: 
Luis Trejos - 2022437816

### Estado del proyecto:

### Enlace del video:
Recordar que el video debe ser público para ser visto por el profesor


# Wide World Importers - Sistema de Consultas Web

### Nombre y carné de los integrantes: 
Luis Trejos - 2022437816


## Descripción del Proyecto

Sistema web desarrollado para consultar la base de datos **Wide World Importers** de Microsoft SQL Server. La aplicación permite realizar consultas avanzadas sobre clientes, proveedores, productos, ventas y estadísticas a través de una interfaz web moderna.

**Características principales:**
- Filtros avanzados por texto, rango de fechas, cantidades y montos.
- Ordenamiento ascendente/descendente en todas las tablas principales.
- Módulos de clientes, proveedores, productos, ventas y estadísticas con tablas interactivas.


## Tecnologías Utilizadas

- **Frontend**: React.js + Vite
- **Backend**: Node.js + Express.js
- **Base de Datos**: SQL Server (Wide World Importers)
- **Contenedores**: Docker para SQL Server
- **Procedimientos Almacenados**: T-SQL con técnicas avanzadas (ROLLUP, DENSE_RANK, Partitions)

## Arquitectura del Sistema

```
Frontend (React)     -> Presenta datos al usuario
API (Node.js)        -> Intermediario entre frontend y BD
Procedimientos       -> Toda la lógica de negocio
SQL Server          -> Almacenamiento y procesamiento
```

### Enlace del video:
(Será actualizado al finalizar el proyecto)

## Estructura del Repositorio

- **proyectos/**: Código fuente completo (Frontend + API)
- **Script sql/**: Procedimientos almacenados y scripts de prueba
- **codigo/**: Archivos SQL adicionales


### Estado actual del proyecto
- Todos los módulos principales implementados: clientes, proveedores, productos, ventas y estadísticas.
- Filtros y ordenamiento funcionales en todas las tablas.
- Documentación y scripts actualizados.

## Explicación Detallada del Código y Cumplimiento de Requisitos

Este sistema fue desarrollado siguiendo las instrucciones y requisitos del proyecto, asegurando la separación entre frontend, backend y base de datos, y centralizando la lógica de negocio en procedimientos almacenados. A continuación se detalla cómo se implementa cada módulo y funcionalidad:

### 1. Módulo de Clientes
- Página para consultar clientes con filtros acumulativos por nombre (texto libre).
- Tabla muestra nombre, categoría y método de entrega, ordenada alfabéticamente por defecto.
- Al seleccionar un cliente, se despliega una ventana con detalles completos (contactos, dirección, días de pago, sitio web, localización en mapa, etc.).
- Toda la información se obtiene mediante procedimientos almacenados y vistas.

### 2. Módulo de Proveedores
- Página para consultar proveedores con filtros acumulativos por nombre y categoría (texto libre).
- Tabla muestra nombre, categoría y método de entrega, ordenada alfabéticamente por defecto.
- Al seleccionar un proveedor, se despliega una ventana con detalles completos (contactos, dirección, banco, cuenta, días de pago, localización en mapa, etc.).
- Consultas implementadas mediante procedimientos almacenados.

### 3. Módulo de Inventarios (Productos)
- Página para consultar productos con filtros por nombre, grupo y cantidad (texto libre y rango).
- Tabla muestra nombre, grupo y cantidad en inventario.
- Al seleccionar un producto, se muestran detalles como proveedor, color, empaquetado, precio, cantidad disponible, ubicación, etc.
- Permite inserción, modificación y borrado de productos, cumpliendo con la gestión CRUD solicitada.

### 4. Módulo de Ventas
- Página para consultar ventas con filtros por número de factura, cliente (texto libre), fecha y monto (rango).
- Tabla muestra número de factura, fecha, cliente, método de entrega y monto.
- Al seleccionar una venta, se muestran detalles del encabezado y líneas de factura (productos, cantidades, precios, impuestos, totales).

### 5. Módulo de Estadísticas
- Estadísticas de compras y ventas agrupadas por proveedor/cliente y categoría, usando ROLLUP y filtros por texto.
- Top 5 productos más rentables, clientes con más facturas y proveedores con más órdenes, usando DENSE_RANK y particionamiento, con filtros por año o rango de años.

### 6. Backend (API Node.js/Express)
- Expone endpoints REST para cada módulo, recibiendo parámetros de filtrado y ordenamiento desde el frontend.
- No realiza lógica de negocio ni agrupaciones: solo transmite parámetros y resultados entre frontend y procedimientos almacenados.

### 7. Frontend (React.js + Vite)
- Componentes reutilizables para tablas, filtros y formularios.
- Validación de datos, mensajes de error claros y diseño responsivo.
- Uso de hooks para manejo de estado y efectos.

### 8. Base de Datos y Procedimientos
- Toda la lógica de consulta, filtrado, agrupación y estadística está implementada en procedimientos almacenados y vistas.
- Se utilizan técnicas avanzadas de SQL (ROLLUP, DENSE_RANK, particionamiento) según lo requerido.
- Scripts de ejemplo y pruebas incluidos en la carpeta `Script sql/`.

