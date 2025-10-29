
const express = require('express');
const EstadisticasController = require('../controllers/EstadisticasController');

const router = express.Router();

// 1. Compras a proveedores con ROLLUP
router.get('/proveedores/compras-rollup', EstadisticasController.getEstadisticasComprasProveedores);

// 2. Ventas a clientes con ROLLUP
router.get('/clientes/ventas-rollup', EstadisticasController.getEstadisticasVentasClientes);

// 3. Top 5 productos más rentables por año
router.get('/productos/top-rentables', EstadisticasController.getTopProductosRentables);

// 4. Top 5 clientes con más facturas por año
router.get('/clientes/top-facturas', EstadisticasController.getTopClientesFacturas);

// 5. Top 5 proveedores con más órdenes de compra por año
router.get('/proveedores/top-ordenes', EstadisticasController.getTopProveedoresOrdenes);

// 6. Años disponibles
router.get('/anios-disponibles', EstadisticasController.getAniosDisponibles);

module.exports = router;
