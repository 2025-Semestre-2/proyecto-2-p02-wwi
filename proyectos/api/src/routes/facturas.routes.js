// routes/facturas.routes.js
const express = require('express');
const router = express.Router();
const { execProc, sql } = require('../db/exec');

router.get('/', async (req, res) => {
  try {
    const { desde=null, hasta=null, page=1, pageSize=50 } = req.query;
    const rows = await execProc('Sales.sp_Api_GetFacturas', {
      desde:    { type: sql.Date, value: desde },
      hasta:    { type: sql.Date, value: hasta },
      page:     { type: sql.Int,  value: Number(page) || 1 },
      pageSize: { type: sql.Int,  value: Number(pageSize) || 50 }
    }, { sucursal: 'corporativo' });

    res.json({ data: rows });
  } catch (err) {
    console.error('GET /facturas', err);
    res.status(500).json({ error: 'Error al obtener facturas' });
  }
});

module.exports = router;
