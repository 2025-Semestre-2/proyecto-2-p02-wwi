const db = require('../config/database');

exports.getClientesConsolidados = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const pageSize = parseInt(req.query.pageSize) || 10;
        const offset = (page - 1) * pageSize;

        const pool = await db.connect('corporativo');
        const result = await pool.request()
            .input('offset', db.sql.Int, offset)
            .input('pageSize', db.sql.Int, pageSize)
            .query(`SELECT CustomerID, CustomerName, Sucursal FROM Sales.vw_Customers_Consolidated 
                    ORDER BY CustomerID OFFSET @offset ROWS FETCH NEXT @pageSize ROWS ONLY`);

        const count = await pool.request().query('SELECT COUNT(*) as total FROM Sales.vw_Customers_Consolidated');

        res.json({
            success: true,
            data: result.recordset,
            pagination: {
                page, pageSize,
                total: count.recordset[0].total,
                totalPages: Math.ceil(count.recordset[0].total / pageSize)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getClientesSanJose = async (req, res) => {
    try {
        const pool = await db.connect('sanJose');
        const result = await pool.request().query('SELECT TOP 50 * FROM Sales.Customers_SJ');
        res.json({ success: true, sucursal: 'San Jose', data: result.recordset });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getClientesLimon = async (req, res) => {
    try {
        const pool = await db.connect('limon');
        const result = await pool.request().query('SELECT TOP 50 * FROM Sales.Customers_LIM');
        res.json({ success: true, sucursal: 'Limon', data: result.recordset });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getClienteById = async (req, res) => {
    try {
        const pool = await db.connect('corporativo');
        const result = await pool.request()
            .input('id', db.sql.Int, req.params.id)
            .query('SELECT * FROM Sales.vw_Customers_Consolidated WHERE CustomerID = @id');
        
        if (result.recordset.length === 0) {
            return res.status(404).json({ success: false, error: 'Cliente no encontrado' });
        }
        res.json({ success: true, data: result.recordset[0] });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};
