const express = require('express');
const VentasController = require('../controllers/VentasController');

const router = express.Router();


// GET /api/ventas - Obtener todas las ventas con filtros y paginación
router.get('/', VentasController.getVentas);

// GET /api/ventas/:id - Obtener venta por ID (factura)
router.get('/:id', VentasController.getVentaById);

module.exports = router;
