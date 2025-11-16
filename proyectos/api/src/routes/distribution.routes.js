const express = require('express');
const router = express.Router();

const ProductDistributor = require('../services/ProductDistributor');
const ClientDistributor  = require('../services/ClientDistributor');
const InvoiceDistributor = require('../services/InvoiceDistributor');
const sql = require('mssql');

/**
 * @route POST /api/distribucion/productos
 * @description Distribuye productos desde WideWorldImporters a las sucursales
 */
router.post('/productos', async (req, res) => {
    try {
        console.log('Solicitud recibida para distribucion de productos');
        
        const distributor = new ProductDistributor();
        const result = await distributor.distributeProducts();
        
        if (result.success) {
            res.json({
                success: true,
                message: result.message,
                // ProductDistributor devuelve "data" con master, sanJose, limon, total
                data: result.data,
                timestamp: result.timestamp || new Date().toISOString()
            });
        } else {
            res.status(500).json({
                success: false,
                message: 'Error en la distribucion de productos',
                error: result.error,
                timestamp: result.timestamp || new Date().toISOString()
            });
        }
    } catch (error) {
        console.error('Error en endpoint de distribucion de productos:', error);
        res.status(500).json({
            success: false,
            message: 'Error interno del servidor',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

/**
 * @route POST /api/distribucion/clientes
 * @description Distribuye clientes desde corporativo a SJ y Limon
 */
router.post('/clientes', async (req, res) => {
    try {
        console.log('Solicitud recibida para distribucion de clientes');

        const distributor = new ClientDistributor();
        const result = await distributor.distributeClients();

        if (result.success) {
            res.json({
                success: true,
                message: result.message,
                data: result.summary,
                timestamp: result.timestamp || new Date().toISOString()
            });
        } else {
            res.status(500).json({
                success: false,
                message: result.message || 'Error en distribucion de clientes',
                error: result.error,
                timestamp: result.timestamp || new Date().toISOString()
            });
        }

    } catch (error) {
        console.error('Error en endpoint de distribucion de clientes:', error);
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
 * @description Obtiene el estado actual de la distribucion (productos + clientes)
 */
router.get('/estado', async (req, res) => {
    try {
        const distributor = new ProductDistributor(); // reusamos configs
        const configs = distributor.configs;
        
        const status = {
            corporativo: { connected: false, productos: 0, clientes: 0 },
            sanJose:     { connected: false, productos: 0, clientes: 0 },
            limon:       { connected: false, productos: 0, clientes: 0 },
            timestamp: new Date().toISOString()
        };

        // ===== Corporativo =====
        try {
            const corpPool = await sql.connect(configs.corporativo);

            // Productos en maestro
            const masterCount = await corpPool.request().query(
                'SELECT COUNT(*) AS total FROM Warehouse.StockItems_Master'
            );
            // Clientes en tabla normal
            const cliCount = await corpPool.request().query(
                'SELECT COUNT(*) AS total FROM Sales.Customers'
            );

            status.corporativo = { 
                connected: true, 
                productos: masterCount.recordset[0].total,
                clientes:  cliCount.recordset[0].total
            };

            await corpPool.close();
        } catch (error) {
            status.corporativo.error = error.message;
        }

        // ===== San Jose =====
        try {
            const sjPool = await sql.connect(configs.sanJose);

            // Productos: coincide con las tablas usadas en ProductDistributor
            const prodCount = await sjPool.request().query(
                'SELECT COUNT(*) AS total FROM Warehouse.StockItems_SJ'
            );
            // Clientes en tabla normal
            const cliCount = await sjPool.request().query(
                'SELECT COUNT(*) AS total FROM Sales.Customers'
            );

            status.sanJose = { 
                connected: true, 
                productos: prodCount.recordset[0].total,
                clientes:  cliCount.recordset[0].total
            };

            await sjPool.close();
        } catch (error) {
            status.sanJose.error = error.message;
        }

        // ===== Limon =====
        try {
            const limPool = await sql.connect(configs.limon);

            const prodCount = await limPool.request().query(
                'SELECT COUNT(*) AS total FROM Warehouse.StockItems_LIM'
            );
            const cliCount = await limPool.request().query(
                'SELECT COUNT(*) AS total FROM Sales.Customers'
            );

            status.limon = { 
                connected: true, 
                productos: prodCount.recordset[0].total,
                clientes:  cliCount.recordset[0].total
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
                    WHEN m.AvailableInSJ = 1 THEN 'Solo San Jose'
                    WHEN m.AvailableInLIM = 1 THEN 'Solo Limon'
                    ELSE 'No disponible'
                END AS Disponibilidad
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

router.post('/facturas', async (req, res) => {
    try {
        console.log('Solicitud recibida para distribucion de facturas');

        const distributor = new InvoiceDistributor();
        const result = await distributor.distributeInvoices();

        if (result.success) {
            const summary = result.summary || result.data || null;
            res.json({
                success: true,
                message: 'Distribucion de facturas completada exitosamente',
                data: summary,
                timestamp: new Date().toISOString()
            });
        } else {
            res.status(500).json({
                success: false,
                message: 'Error en la distribucion de facturas',
                error: result.error,
                timestamp: new Date().toISOString()
            });
        }

    } catch (error) {
        console.error('Error en endpoint de distribucion de facturas:', error);
        res.status(500).json({
            success: false,
            message: 'Error interno del servidor',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});
module.exports = router;
