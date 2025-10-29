const DatabaseService = require('../services/DatabaseService');

class AppController {
    /**
     * Endpoint de salud de la aplicación
     */
    static async health(req, res, next) {
        try {
            const dbStatus = await DatabaseService.testConnection();
            
            res.json({
                success: true,
                message: 'API funcionando correctamente',
                timestamp: new Date().toISOString(),
                database: {
                    status: dbStatus ? 'connected' : 'disconnected',
                    message: dbStatus ? 'Conexión a la base de datos exitosa' : 'Error conectando a la base de datos'
                }
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Información general de la API
     */
    static async info(req, res, next) {
        try {
            res.json({
                success: true,
                data: {
                    name: 'Wide World Importers API',
                    version: '1.0.0',
                    description: 'API RESTful para el proyecto de bases de datos',
                    endpoints: {
                        clientes: '/api/clientes',
                        proveedores: '/api/proveedores',
                        productos: '/api/productos',
                        ventas: '/api/ventas',
                        estadisticas: '/api/estadisticas'
                    }
                },
                message: 'Información de la API obtenida exitosamente'
            });
        } catch (error) {
            next(error);
        }
    }
}

module.exports = AppController;
