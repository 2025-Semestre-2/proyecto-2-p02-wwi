const db = require('../config/database');

exports.getProductosConsolidados = async (req, res) => {
    try {
        const pool = await db.connect('corporativo');
        const result = await pool.request().query(
            'SELECT TOP 50 * FROM Warehouse.vw_StockItems_Consolidated WHERE IsActive = 1'
        );
        res.json({ success: true, data: result.recordset });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getProductosSanJose = async (req, res) => {
    try {
        const pool = await db.connect('sanJose');
        const result = await pool.request().query('SELECT TOP 50 * FROM Warehouse.StockItems_SJ');
        res.json({ success: true, sucursal: 'San Jose', data: result.recordset });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getProductosLimon = async (req, res) => {
    try {
        const pool = await db.connect('limon');
        const result = await pool.request().query('SELECT TOP 50 * FROM Warehouse.StockItems_LIM');
        res.json({ success: true, sucursal: 'Limon', data: result.recordset });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};
