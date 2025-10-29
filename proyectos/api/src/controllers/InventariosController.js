const DatabaseService = require('../services/DatabaseService');
const { sql } = require('../config/database');

class InventariosController {
    /**
     * Obtiene todos los productos con filtros opcionales y paginación
     */
    static async getStockItems(req, res, next) {
        try {
            const { 
                searchText, 
                minQuantity,
                maxQuantity,
                orderBy = 'StockItemName', 
                orderDirection = 'ASC',
                pageNumber = 1,
                pageSize = 20
            } = req.query;

            console.log('DEBUG: getStockItems llamado con parámetros:', { searchText, minQuantity, maxQuantity, orderBy, orderDirection, pageNumber, pageSize });

            const params = {};
            
            if (searchText) {
                params.SearchText = {
                    type: sql.NVarChar(100),
                    value: searchText
                };
            }

            if (minQuantity) {
                params.MinQuantity = {
                    type: sql.Int,
                    value: parseInt(minQuantity)
                };
            }

            if (maxQuantity) {
                params.MaxQuantity = {
                    type: sql.Int,
                    value: parseInt(maxQuantity)
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

            const result = await DatabaseService.executeStoredProcedure('sp_SearchStockItems', params);

            // DEBUG: Ver la estructura de los datos
            console.log('Estructura de result:', {
                success: result.success,
                dataType: typeof result.data,
                isArray: Array.isArray(result.data),
                dataLength: result.data ? result.data.length : 'N/A',
                firstElement: result.data && result.data[0] ? typeof result.data[0] : 'N/A'
            });

            // El procedimiento devuelve dos conjuntos de resultados: datos y total
            // Verificar si result.data es un array de conjuntos o un solo conjunto
            let productos, totalInfo;
            
            if (Array.isArray(result.data) && Array.isArray(result.data[0])) {
                // Múltiples conjuntos de resultados
                productos = result.data[0] || [];
                totalInfo = result.data[1] || [];
                console.log('Usando múltiples conjuntos - productos:', productos.length, 'total info:', totalInfo.length);
            } else {
                // Un solo conjunto de resultados (puede pasar si el SP no devuelve el total)
                productos = result.data || [];
                totalInfo = [];
                console.log('Usando un solo conjunto - productos:', productos.length);
            }
            
            const totalRegistros = totalInfo.length > 0 ? totalInfo[0].TotalRegistros : productos.length;

            res.json({
                success: true,
                data: productos,
                pagination: {
                    currentPage: parseInt(pageNumber),
                    pageSize: parseInt(pageSize),
                    totalRecords: totalRegistros,
                    totalPages: Math.ceil(totalRegistros / parseInt(pageSize))
                },
                message: 'Productos obtenidos exitosamente'
            });
        } catch (error) {
            console.error('Error en getStockItems:', error);
            next(error);
        }
    }

    /**
     * Obtiene un producto específico por ID con todos los detalles
     */
    static async getStockItemById(req, res, next) {
        try {
            const { id } = req.params;

            const params = {
                StockItemID: {
                    type: sql.Int,
                    value: parseInt(id)
                }
            };

            const result = await DatabaseService.executeStoredProcedure('sp_GetStockItemDetails', params);

            if (!result.data || result.data.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Producto no encontrado'
                });
            }

            res.json({
                success: true,
                data: result.data[0],
                message: 'Producto obtenido exitosamente'
            });
        } catch (error) {
            console.error('Error en getStockItemById:', error);
            next(error);
        }
    }

    /**
     * Obtiene estadísticas de inventario con ROLLUP
     */
    static async getInventariosEstadisticas(req, res, next) {
        try {
            const { searchText, stockGroup } = req.query;

            const params = {};
            
            if (searchText) {
                params.SearchText = {
                    type: sql.NVarChar(100),
                    value: searchText
                };
            }

            if (stockGroup) {
                params.StockGroup = {
                    type: sql.NVarChar(50),
                    value: stockGroup
                };
            }

            const result = await DatabaseService.executeStoredProcedure('sp_GetStockItemsEstadisticas', params);

            res.json({
                success: true,
                data: result.data,
                message: 'Estadísticas de inventario obtenidas exitosamente'
            });
        } catch (error) {
            console.error('Error en getInventariosEstadisticas:', error);
            next(error);
        }
    }

    /**
     * Obtiene el top 10 de productos más vendidos por año usando DENSE_RANK
     */
    static async getTopProductosPorVentas(req, res, next) {
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

            const result = await DatabaseService.executeStoredProcedure('sp_GetTopProductosPorVentas', params);

            res.json({
                success: true,
                data: result.data,
                message: 'Top productos por ventas obtenido exitosamente'
            });
        } catch (error) {
            console.error('Error en getTopProductosPorVentas:', error);
            next(error);
        }
    }

    /**
     * Obtiene los grupos de stock para filtros dinámicos
     */
    static async getStockGroups(req, res, next) {
        try {
            const result = await DatabaseService.executeStoredProcedure('sp_GetStockGroups');

            res.json({
                success: true,
                data: result.data,
                message: 'Grupos de stock obtenidos exitosamente'
            });
        } catch (error) {
            console.error('Error en getStockGroups:', error);
            next(error);
        }
    }
}

module.exports = InventariosController;
