const DatabaseService = require('../services/DatabaseService');
const { sql } = require('../config/database');

class ClientesController {
    /**
     * Obtiene todos los clientes con filtros opcionales y paginación
     */
    static async getClientes(req, res, next) {
        try {
            const { 
                searchText, 
                orderBy = 'CustomerName', 
                orderDirection = 'ASC',
                pageNumber = 1,
                pageSize = 20
            } = req.query;

            console.log('DEBUG: getClientes llamado con parámetros:', { searchText, orderBy, orderDirection, pageNumber, pageSize });

            const params = {};
            
            if (searchText) {
                params.SearchText = {
                    type: sql.NVarChar(100),
                    value: searchText
                };
            }

            params.OrderBy = {
                type: sql.NVarChar(50),
                value: orderBy
            };

            params.OrderDirection = {
                type: sql.NVarChar(4),
                value: orderDirection
            };

            params.PageNumber = {
                type: sql.Int,
                value: parseInt(pageNumber)
            };

            params.PageSize = {
                type: sql.Int,
                value: parseInt(pageSize)
            };

            const result = await DatabaseService.executeStoredProcedure('sp_GetClientesCompleto', params);

            // El procedimiento devuelve dos conjuntos de resultados: datos y total
            // Verificar si result.data es un array de conjuntos o un solo conjunto
            let clientes, totalInfo;
            if (Array.isArray(result.data) && Array.isArray(result.data[0])) {
                // Múltiples conjuntos de resultados
                clientes = result.data[0] || [];
                totalInfo = result.data[1] || [];
            } else {
                // Un solo conjunto de resultados (puede pasar si el SP no devuelve el total)
                clientes = result.data || [];
                totalInfo = [];
            }

            // DEBUG: Imprimir clientes que se van a enviar al frontend
            console.log('--- API: LISTA DE CLIENTES A ENVIAR ---');
            clientes.forEach((c, idx) => {
                console.log(`#${idx + 1}`);
                Object.entries(c).forEach(([key, value]) => {
                    if (typeof value === 'object' && value !== null) {
                        console.log(`  ${key}:`);
                        Object.entries(value).forEach(([k, v]) => {
                            console.log(`    ${k}: ${v}`);
                        });
                    } else {
                        console.log(`  ${key}: ${value}`);
                    }
                });
            });
            console.log('---------------------------------------');

            const totalRegistros = totalInfo.length > 0 ? totalInfo[0].TotalRegistros : clientes.length;

            res.json({
                success: true,
                data: clientes,
                pagination: {
                    currentPage: parseInt(pageNumber),
                    pageSize: parseInt(pageSize),
                    totalRecords: totalRegistros,
                    totalPages: Math.ceil(totalRegistros / parseInt(pageSize))
                },
                message: 'Clientes obtenidos exitosamente'
            });
        } catch (error) {
            console.error('Error en getClientes:', error);
            next(error);
        }
    }

    /**
     * Obtiene un cliente específico por ID con todos los detalles
     */
    static async getClienteById(req, res, next) {
        try {
            const { id } = req.params;

            const params = {
                CustomerID: {
                    type: sql.Int,
                    value: parseInt(id)
                }
            };

            const result = await DatabaseService.executeStoredProcedure('sp_GetClienteDetallesCompleto', params);

            if (!result.data || result.data.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Cliente no encontrado'
                });
            }

            // DEBUG: Imprimir detalles del cliente que se va a enviar al frontend
            const cliente = result.data[0];
            console.log('--- API: DETALLES DEL CLIENTE A ENVIAR ---');
            Object.entries(cliente).forEach(([key, value]) => {
                if (typeof value === 'object' && value !== null) {
                    console.log(`  ${key}:`);
                    Object.entries(value).forEach(([k, v]) => {
                        console.log(`    ${k}: ${v}`);
                    });
                } else {
                    console.log(`  ${key}: ${value}`);
                }
            });
            console.log('------------------------------------------');

            res.json({
                success: true,
                data: cliente,
                message: 'Cliente obtenido exitosamente'
            });
        } catch (error) {
            console.error('Error en getClienteById:', error);
            next(error);
        }
    }

    /**
     * Obtiene estadísticas de ventas por cliente con ROLLUP
     */
    static async getClientesEstadisticas(req, res, next) {
        try {
            const { searchText, categoria } = req.query;

            const params = {};
            
            if (searchText) {
                params.SearchText = {
                    type: sql.NVarChar(100),
                    value: searchText
                };
            }

            if (categoria) {
                params.Categoria = {
                    type: sql.NVarChar(50),
                    value: categoria
                };
            }

            const result = await DatabaseService.executeStoredProcedure('sp_GetClientesEstadisticasCompleto', params);

            res.json({
                success: true,
                data: result.data,
                message: 'Estadísticas de clientes obtenidas exitosamente'
            });
        } catch (error) {
            console.error('Error en getClientesEstadisticas:', error);
            next(error);
        }
    }

    /**
     * Obtiene el top 5 de clientes con más facturas por año usando DENSE_RANK
     */
    static async getTopClientesPorAnio(req, res, next) {
        try {
            const { anioInicio, anioFin } = req.query;

            const params = {};
            
            if (anioInicio) {
                params.AnioInicio = {
                    type: sql.Int,
                    value: parseInt(anioInicio)
                };
            }

            if (anioFin) {
                params.AnioFin = {
                    type: sql.Int,
                    value: parseInt(anioFin)
                };
            }

            const result = await DatabaseService.executeStoredProcedure('sp_GetTopClientesPorAnioCompleto', params);

            res.json({
                success: true,
                data: result.data,
                message: 'Top clientes por año obtenido exitosamente'
            });
        } catch (error) {
            console.error('Error en getTopClientesPorAnio:', error);
            next(error);
        }
    }

    /**
     * Obtiene las categorías de clientes para filtros dinámicos
     */
    static async getCategorias(req, res, next) {
        try {
            const result = await DatabaseService.executeStoredProcedure('sp_GetCategoriasClientes');

            res.json({
                success: true,
                data: result.data,
                message: 'Categorías de clientes obtenidas exitosamente'
            });
        } catch (error) {
            console.error('Error en getCategorias:', error);
            next(error);
        }
    }
}

module.exports = ClientesController;
