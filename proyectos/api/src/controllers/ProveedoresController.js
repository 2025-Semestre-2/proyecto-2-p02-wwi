const DatabaseService = require('../services/DatabaseService');

class ProveedoresController {
    async getProveedores(req, res) {
    try {
        console.log('ProveedoresController: Obteniendo proveedores con parámetros:', req.query);
        
        const {
            search = '',
            page = 1,
            pageSize = 20,
            category = '',
            orderBy = 'SupplierName',
            orderDirection = 'ASC'
        } = req.query;

        const result = await DatabaseService.executeStoredProcedure('sp_SearchSuppliers', {
            SearchText: search || null,
            PageNumber: parseInt(page),
            PageSize: parseInt(pageSize),
            OrderBy: orderBy,
            OrderDirection: orderDirection
        });

        console.log('ProveedoresController: Resultado de la base de datos:', {
            hasData: result.data && result.data.length > 0,
            recordsets: result.data ? result.data.length : 0
        });

        // CORRECCIÓN: Manejar correctamente los múltiples recordsets
        let proveedores = [];
        let totalRecords = 0;

        if (result.data && Array.isArray(result.data)) {
            // El stored procedure devuelve 2 recordsets:
            // result.data[0] = proveedores
            // result.data[1] = total de registros
            if (result.data.length > 0) {
                proveedores = result.data[0] || [];
            }
            if (result.data.length > 1 && result.data[1] && result.data[1].length > 0) {
                totalRecords = result.data[1][0].TotalRegistros || 0;
            }
        }

        console.log('ProveedoresController: Datos procesados:', {
            proveedoresCount: proveedores.length,
            totalRecords: totalRecords
        });

        // CORRECCIÓN: Enviar la estructura que espera el frontend
        res.json({
            success: true,
            data: {
                proveedores: proveedores,
                totalRecords: totalRecords
            },
            message: 'Proveedores obtenidos exitosamente'
        });
    } catch (error) {
        console.error('Error en ProveedoresController.getProveedores:', error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener los proveedores',
            error: error.message
        });
    }
}

    async getProveedorById(req, res) {
        try {
            console.log('ProveedoresController: Obteniendo proveedor por ID:', req.params.id);
            
            const { id } = req.params;
            
            if (!id || isNaN(parseInt(id))) {
                return res.status(400).json({
                    success: false,
                    message: 'ID de proveedor inválido'
                });
            }

            const result = await DatabaseService.executeStoredProcedure('sp_GetSupplierDetails', {
                SupplierID: parseInt(id)
            });

            console.log('ProveedoresController: Resultado de detalles:', {
                hasData: result.data && result.data.length > 0,
                dataLength: result.data.length
            });

            if (!result.data || result.data.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Proveedor no encontrado'
                });
            }

            res.json({
                success: true,
                data: Array.isArray(result.data) && Array.isArray(result.data[0]) ? result.data[0][0] : result.data[0],
                message: 'Detalles del proveedor obtenidos exitosamente'
            });
        } catch (error) {
            console.error('Error en ProveedoresController.getProveedorById:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener los detalles del proveedor',
                error: error.message
            });
        }
    }

    async getSupplierCategories(req, res) {
        try {
            console.log('ProveedoresController: Obteniendo categorías de proveedores');
            
            const result = await DatabaseService.executeStoredProcedure('sp_GetSupplierCategories', {});

            res.json({
                success: true,
                data: Array.isArray(result.data) && Array.isArray(result.data[0]) ? result.data[0] : result.data,
                message: 'Categorías de proveedores obtenidas exitosamente'
            });
        } catch (error) {
            console.error('Error en ProveedoresController.getSupplierCategories:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener las categorías de proveedores',
                error: error.message
            });
        }
    }

    async getProveedoresEstadisticas(req, res) {
        try {
            console.log('ProveedoresController: Obteniendo estadísticas de proveedores');
            
            const {
                searchText = '',
                category = ''
            } = req.query;

            const result = await DatabaseService.executeStoredProcedure('sp_GetSuppliersEstadisticas', {
                SearchText: searchText || null,
                Category: category || null
            });

            res.json({
                success: true,
                data: result.data,
                message: 'Estadísticas de proveedores obtenidas exitosamente'
            });
        } catch (error) {
            console.error('Error en ProveedoresController.getProveedoresEstadisticas:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener las estadísticas de proveedores',
                error: error.message
            });
        }
    }

    async getTopProveedoresByPaymentTerms(req, res) {
        try {
            console.log('ProveedoresController: Obteniendo top proveedores por términos de pago');
            
            const result = await DatabaseService.executeStoredProcedure('sp_GetTopSuppliersByPaymentTerms', {});

            res.json({
                success: true,
                data: result.data,
                message: 'Top proveedores por términos de pago obtenidos exitosamente'
            });
        } catch (error) {
            console.error('Error en ProveedoresController.getTopProveedoresByPaymentTerms:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener el top de proveedores por términos de pago',
                error: error.message
            });
        }
    }
}

module.exports = new ProveedoresController();
