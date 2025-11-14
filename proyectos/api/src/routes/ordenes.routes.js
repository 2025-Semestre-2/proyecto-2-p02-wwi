// routes/ordenes.routes.js
const express = require('express');
const router = express.Router();
const { execProc, sql } = require('../db/exec');

router.get('/', async (req, res) => {
  try {
    const { proveedorId=null, page=1, pageSize=50 } = req.query;
    const rows = await execProc('Purchasing.sp_Api_GetOrdenesCompra', {
      proveedorId: { type: sql.Int, value: proveedorId ? Number(proveedorId) : null },
      page:        { type: sql.Int, value: Number(page) || 1 },
      pageSize:    { type: sql.Int, value: Number(pageSize) || 50 }
    }, { sucursal: 'corporativo' });

    res.json({ data: rows });
  } catch (err) {
    console.error('GET /ordenes-compra', err);
    res.status(500).json({ error: 'Error al obtener ordenes de compra' });
  }
});

module.exports = router;
