const DatabaseService = require('../services/DatabaseService');
const { sql } = require('../config/database');

class EstadisticasController {
    // 1. Compras a proveedores con ROLLUP
    static async getEstadisticasComprasProveedores(req, res, next) {
        try {
            const { searchTextProveedor, searchTextCategoria } = req.query;
            const params = {};
            if (searchTextProveedor) {
                params.SearchTextProveedor = { type: sql.NVarChar(100), value: searchTextProveedor };
            }
            if (searchTextCategoria) {
                params.SearchTextCategoria = { type: sql.NVarChar(100), value: searchTextCategoria };
            }
            const result = await DatabaseService.executeStoredProcedure('sp_GetEstadisticasComprasProveedores', params);
            res.json({ success: true, data: result.data, message: 'Estadísticas de compras a proveedores obtenidas exitosamente' });
        } catch (error) {
            console.error('Error en getEstadisticasComprasProveedores:', error);
            next(error);
        }
    }

    // 2. Ventas a clientes con ROLLUP
    static async getEstadisticasVentasClientes(req, res, next) {
        try {
            const { searchTextCliente, searchTextCategoria } = req.query;
            const params = {};
            if (searchTextCliente) {
                params.SearchTextCliente = { type: sql.NVarChar(100), value: searchTextCliente };
            }
            if (searchTextCategoria) {
                params.SearchTextCategoria = { type: sql.NVarChar(100), value: searchTextCategoria };
            }
            const result = await DatabaseService.executeStoredProcedure('sp_GetEstadisticasVentasClientes', params);
            res.json({ success: true, data: result.data, message: 'Estadísticas de ventas a clientes obtenidas exitosamente' });
        } catch (error) {
            console.error('Error en getEstadisticasVentasClientes:', error);
            next(error);
        }
    }

    // 3. Top 5 productos más rentables por año
    static async getTopProductosRentables(req, res, next) {
        try {
            const { anio } = req.query;
            const params = {};
            if (anio) {
                params.Anio = { type: sql.Int, value: parseInt(anio) };
            }
            const result = await DatabaseService.executeStoredProcedure('sp_GetTopProductosRentables', params);
            res.json({ success: true, data: result.data, message: 'Top productos más rentables obtenido exitosamente' });
        } catch (error) {
            console.error('Error en getTopProductosRentables:', error);
            next(error);
        }
    }

    // 4. Top 5 clientes con más facturas por año
    static async getTopClientesFacturas(req, res, next) {
        try {
            const { anioInicio, anioFin } = req.query;
            const params = {};
            if (anioInicio) {
                params.AnioInicio = { type: sql.Int, value: parseInt(anioInicio) };
            }
            if (anioFin) {
                params.AnioFin = { type: sql.Int, value: parseInt(anioFin) };
            }
            const result = await DatabaseService.executeStoredProcedure('sp_GetTopClientesFacturas', params);
            res.json({ success: true, data: result.data, message: 'Top clientes con más facturas obtenido exitosamente' });
        } catch (error) {
            console.error('Error en getTopClientesFacturas:', error);
            next(error);
        }
    }

    // 5. Top 5 proveedores con más órdenes de compra por año
    static async getTopProveedoresOrdenes(req, res, next) {
        try {
            const { anioInicio, anioFin } = req.query;
            const params = {};
            if (anioInicio) {
                params.AnioInicio = { type: sql.Int, value: parseInt(anioInicio) };
            }
            if (anioFin) {
                params.AnioFin = { type: sql.Int, value: parseInt(anioFin) };
            }
            const result = await DatabaseService.executeStoredProcedure('sp_GetTopProveedoresOrdenes', params);
            res.json({ success: true, data: result.data, message: 'Top proveedores con más órdenes obtenido exitosamente' });
        } catch (error) {
            console.error('Error en getTopProveedoresOrdenes:', error);
            next(error);
        }
    }

    // 6. Años disponibles
    static async getAniosDisponibles(req, res, next) {
        try {
            const result = await DatabaseService.executeStoredProcedure('sp_GetAniosDisponibles');
            res.json({ success: true, data: result.data, message: 'Años disponibles obtenidos exitosamente' });
        } catch (error) {
            console.error('Error en getAniosDisponibles:', error);
            next(error);
        }
    }
}

module.exports = EstadisticasController;
