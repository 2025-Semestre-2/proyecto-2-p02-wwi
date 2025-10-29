const DatabaseService = require('../services/DatabaseService');
const { sql } = require('../config/database');

class VentasController {
    /**
     * Obtiene todos los clientes con filtros opcionales y paginación
     */
    static async getVentas(req, res, next) {
        try {
            const { 
                searchText, 
                orderBy = 'CustomerName', 
                orderDirection = 'ASC',
                pageNumber = 1,
                pageSize = 20,
                startDate,
                endDate,
                minAmount,
                maxAmount
            } = req.query;

            console.log('DEBUG: getVentas llamado con parámetros:', { searchText, orderBy, orderDirection, pageNumber, pageSize, startDate, endDate, minAmount, maxAmount });

            const params = {};
            if (searchText) {
                params.SearchText = { type: sql.NVarChar(100), value: searchText };
            }
            if (startDate) {
                params.StartDate = { type: sql.Date, value: startDate };
            }
            if (endDate) {
                params.EndDate = { type: sql.Date, value: endDate };
            }
            if (minAmount) {
                params.MinAmount = { type: sql.Decimal(18,2), value: parseFloat(minAmount) };
            }
            if (maxAmount) {
                params.MaxAmount = { type: sql.Decimal(18,2), value: parseFloat(maxAmount) };
            }
            params.OrderBy = { type: sql.NVarChar(50), value: orderBy };
            params.OrderDirection = { type: sql.NVarChar(4), value: orderDirection };
            params.PageNumber = { type: sql.Int, value: parseInt(pageNumber) };
            params.PageSize = { type: sql.Int, value: parseInt(pageSize) };

            const result = await DatabaseService.executeStoredProcedure('sp_SearchSales', params);

            // El procedimiento devuelve dos conjuntos de resultados: datos y total
            let ventas, totalInfo;
            if (Array.isArray(result.data) && Array.isArray(result.data[0])) {
                ventas = result.data[0] || [];
                totalInfo = result.data[1] || [];
            } else {
                ventas = result.data || [];
                totalInfo = [];
            }

            // DEBUG: Imprimir ventas que se van a enviar al frontend
            console.log('--- API: LISTA DE VENTAS A ENVIAR ---');
            ventas.forEach((v, idx) => {
                console.log(`#${idx + 1}`);
                Object.entries(v).forEach(([key, value]) => {
                    console.log(`  ${key}: ${value}`);
                });
            });
            console.log('---------------------------------------');

            const totalRegistros = totalInfo.length > 0 ? (totalInfo[0].TotalCount || totalInfo[0].TotalRegistros) : ventas.length;

            res.json({
                success: true,
                data: ventas,
                pagination: {
                    currentPage: parseInt(pageNumber),
                    pageSize: parseInt(pageSize),
                    totalRecords: totalRegistros,
                    totalPages: Math.ceil(totalRegistros / parseInt(pageSize))
                },
                message: 'Ventas obtenidas exitosamente'
            });
        } catch (error) {
            console.error('Error en getVentas:', error);
            next(error);
        }
    }

    /**
     * Obtiene una venta específica (factura) por ID con todos los detalles
     */
    static async getVentaById(req, res, next) {
        try {
            const { id } = req.params;

            const params = {
                InvoiceID: {
                    type: sql.Int,
                    value: parseInt(id)
                }
            };

            const result = await DatabaseService.executeStoredProcedure('sp_GetInvoiceDetails', params);

            if (!result.data || result.data.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Venta no encontrada'
                });
            }

            // El procedimiento devuelve dos conjuntos: encabezado y líneas
            let encabezado, lineas;
            if (Array.isArray(result.data) && Array.isArray(result.data[0])) {
                encabezado = result.data[0][0] || {};
                lineas = result.data[1] || [];
            } else {
                encabezado = result.data[0] || {};
                lineas = [];
            }

            // DEBUG: Imprimir detalles de la venta
            console.log('--- API: DETALLES DE LA VENTA A ENVIAR ---');
            Object.entries(encabezado).forEach(([key, value]) => {
                if (typeof value === 'object' && value !== null) {
                    console.log(`  ${key}:`);
                    Object.entries(value).forEach(([k, v]) => {
                        console.log(`    ${k}: ${v}`);
                    });
                } else {
                    console.log(`  ${key}: ${value}`);
                }
            });
            console.log('--- LÍNEAS DE LA FACTURA ---');
            lineas.forEach((l, idx) => {
                console.log(`#${idx + 1}`);
                Object.entries(l).forEach(([key, value]) => {
                    console.log(`  ${key}: ${value}`);
                });
            });
            console.log('------------------------------------------');

            res.json({
                success: true,
                data: {
                    encabezado,
                    lineas
                },
                message: 'Venta obtenida exitosamente'
            });
        } catch (error) {
            console.error('Error en getVentaById:', error);
            next(error);
        }
    }




}

module.exports = VentasController;
