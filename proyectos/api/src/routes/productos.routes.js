// routes/productos.routes.js
const express = require('express');
const router = express.Router();
const { execProc, sql } = require('../db/exec');

router.get('/', async (req, res) => {
  try {
    const { q=null, disponibleEn=null, page=1, pageSize=50 } = req.query;
    const rows = await execProc('Warehouse.sp_Api_GetProductos', {
      q:            { type: sql.NVarChar(100), value: q },
      disponibleEn: { type: sql.NVarChar(10),  value: disponibleEn },
      page:         { type: sql.Int,           value: Number(page) || 1 },
      pageSize:     { type: sql.Int,           value: Number(pageSize) || 50 }
    }, { sucursal: 'corporativo' });

    res.json({ data: rows });
  } catch (err) {
    console.error('GET /productos', err);
    res.status(500).json({ error: 'Error al obtener productos' });
  }
});

module.exports = router;
