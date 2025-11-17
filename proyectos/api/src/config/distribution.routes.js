// routes/distribution.routes.js
const express = require('express');
const router = express.Router();
const ProductDistributor = require('../services/ProductDistributor');

/**
 * @route POST /api/distribucion/productos
 * @description Distribuye productos desde WideWorldImporters a las sucursales
 */
router.post('/productos', async (req, res) => {
    try {
        console.log('Solicitud recibida para distribución de productos');
        
        const distributor = new ProductDistributor();
        const result = await distributor.distributeProducts();
        
        if (result.success) {
            res.json({
                success: true,
                message: 'Distribución completada exitosamente',
                data: result.summary,
                timestamp: new Date().toISOString()
            });
        } else {
            res.status(500).json({
                success: false,
                message: 'Error en la distribución',
                error: result.error,
                timestamp: new Date().toISOString()
            });
        }
    } catch (error) {
        console.error('Error en endpoint de distribución:', error);
        res.status(500).json({
            success: false,
            message: 'Error interno del servidor',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

/**
 * @route GET /api/distribucion/estado
 * @description Obtiene el estado actual de la distribución
 */
router.get('/estado', async (req, res) => {
    try {
        const distributor = new ProductDistributor();
        const configs = distributor.configs;
        const sql = require('mssql');
        
        const status = {
            corporativo: { connected: false, count: 0 },
            sanJose: { connected: false, count: 0 },
            limon: { connected: false, count: 0 },
            timestamp: new Date().toISOString()
        };

        // Verificar Corporativo
        try {
            const corpPool = await sql.connect(configs.corporativo);
            const masterCount = await corpPool.request().query(
                'SELECT COUNT(*) as total FROM Warehouse.StockItems_Master'
            );
            status.corporativo = { 
                connected: true, 
                count: masterCount.recordset[0].total 
            };
            await corpPool.close();
        } catch (error) {
            status.corporativo.error = error.message;
        }

        // Verificar San José
        try {
            const sjPool = await sql.connect(configs.sanJose);
            const sjCount = await sjPool.request().query(
                'SELECT COUNT(*) as total FROM Warehouse.StockItems_SJ'
            );
            status.sanJose = { 
                connected: true, 
                count: sjCount.recordset[0].total 
            };
            await sjPool.close();
        } catch (error) {
            status.sanJose.error = error.message;
        }

        // Verificar Limón
        try {
            const limPool = await sql.connect(configs.limon);
            const limCount = await limPool.request().query(
                'SELECT COUNT(*) as total FROM Warehouse.StockItems_LIM'
            );
            status.limon = { 
                connected: true, 
                count: limCount.recordset[0].total 
            };
            await limPool.close();
        } catch (error) {
            status.limon.error = error.message;
        }

        res.json({
            success: true,
            data: status
        });
        
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route GET /api/distribucion/productos/consolidado
 * @description Obtiene vista consolidada de productos
 */
router.get('/productos/consolidado', async (req, res) => {
    try {
        const distributor = new ProductDistributor();
        const configs = distributor.configs;
        const sql = require('mssql');
        
        const corpPool = await sql.connect(configs.corporativo);
        const result = await corpPool.request().query(`
            SELECT 
                m.StockItemID,
                m.StockItemName,
                m.UnitPrice,
                m.AvailableInSJ,
                m.AvailableInLIM,
                CASE 
                    WHEN m.AvailableInSJ = 1 AND m.AvailableInLIM = 1 THEN 'Ambas'
                    WHEN m.AvailableInSJ = 1 THEN 'Solo San José'
                    WHEN m.AvailableInLIM = 1 THEN 'Solo Limón'
                    ELSE 'No disponible'
                END as Disponibilidad
            FROM Warehouse.StockItems_Master m
            ORDER BY m.StockItemID
        `);

        await corpPool.close();

        res.json({
            success: true,
            data: result.recordset,
            total: result.recordset.length,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

module.exports = router;