const express = require('express');
const ProveedoresController = require('../controllers/ProveedoresController');

const router = express.Router();

// GET /api/proveedores - Buscar proveedores con filtros y paginación
router.get('/', ProveedoresController.getProveedores);

// GET /api/proveedores/categories - Obtener categorías de proveedores
router.get('/categories', ProveedoresController.getSupplierCategories);

// GET /api/proveedores/estadisticas - Obtener estadísticas de proveedores
router.get('/estadisticas', ProveedoresController.getProveedoresEstadisticas);

// GET /api/proveedores/top-payment-terms - Obtener top proveedores por términos de pago
router.get('/top-payment-terms', ProveedoresController.getTopProveedoresByPaymentTerms);

// GET /api/proveedores/:id - Obtener proveedor por ID
router.get('/:id', ProveedoresController.getProveedorById);

module.exports = router;
