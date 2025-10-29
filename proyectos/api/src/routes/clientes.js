const express = require('express');
const ClientesController = require('../controllers/ClientesController');

const router = express.Router();

// GET /api/clientes - Obtener todos los clientes con filtros y paginación
router.get('/', ClientesController.getClientes);

// GET /api/clientes/categorias - Obtener categorías de clientes
router.get('/categorias', ClientesController.getCategorias);

// GET /api/clientes/estadisticas - Obtener estadísticas de clientes
router.get('/estadisticas', ClientesController.getClientesEstadisticas);

// GET /api/clientes/top-por-anio - Top 5 clientes por año
router.get('/top-por-anio', ClientesController.getTopClientesPorAnio);

// GET /api/clientes/:id - Obtener cliente por ID
router.get('/:id', ClientesController.getClienteById);

module.exports = router;
