/* =======================================================
   6) PERMISOS PARA QUE LA API ACCEDA A VISTAS Y SPs
   ======================================================= */

USE WWI_Corporativo;
GO

/* ==========================================
   OPCIONAL: Rol propio para la API
   ========================================== */
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'API_APP')
    CREATE ROLE API_APP;
GO

-- Agregar el usuario de la API al rol
EXEC sp_addrolemember 'API_APP', 'corp_analytics';
GO


/* ==============================================================
   PERMISOS SOBRE VISTAS CONSOLIDADAS (CAMBIAR SCHEMA SI OCUPA)
   ============================================================== */

-- Si tus vistas viven en el esquema Corp, Api o dbo:
GRANT SELECT ON SCHEMA::Corp TO API_APP;
-- GRANT SELECT ON SCHEMA::Api TO API_APP;
-- GRANT SELECT ON SCHEMA::dbo TO API_APP;


/* ==============================================================
   PERMISOS SOBRE LOS PROCEDIMIENTOS DE API
   ============================================================== */

GRANT EXECUTE ON SCHEMA::Sales      TO API_APP;
GRANT EXECUTE ON SCHEMA::Warehouse  TO API_APP;
GRANT EXECUTE ON SCHEMA::Purchasing TO API_APP;


/* ==============================================================
   LISTA DE SP ESPECÍFICOS (opcional pero recomendado)
   ============================================================== */

-- Clientes
-- GRANT EXECUTE ON OBJECT::Sales.sp_Api_GetClientes            TO API_APP;
-- GRANT EXECUTE ON OBJECT::Sales.sp_Api_GetClienteById         TO API_APP;
-- GRANT EXECUTE ON OBJECT::Sales.sp_Api_UpsertClientePublico   TO API_APP;
-- GRANT EXECUTE ON OBJECT::Sales.sp_Api_UpdateClienteSensibles TO API_APP;

-- Productos
-- GRANT EXECUTE ON OBJECT::Warehouse.sp_Api_GetProductos       TO API_APP;

-- Facturas
-- GRANT EXECUTE ON OBJECT::Sales.sp_Api_GetFacturas            TO API_APP;

-- Órdenes de compra
-- GRANT EXECUTE ON OBJECT::Purchasing.sp_Api_GetOrdenesCompra  TO API_APP;

PRINT 'Permisos para API aplicados correctamente.';
GO
