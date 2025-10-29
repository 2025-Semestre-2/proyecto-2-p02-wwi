const express = require('express');
const router = express.Router();
const InventariosController = require('../controllers/InventariosController');

/**
 * @route GET /api/inventarios
 * @description Obtiene todos los productos con filtros opcionales y paginación
 * @query {string} searchText - Texto para buscar en nombre o descripción del producto
 * @query {number} minQuantity - Cantidad mínima en stock
 * @query {number} maxQuantity - Cantidad máxima en stock
 * @query {string} orderBy - Campo para ordenar (StockItemName, QuantityOnHand, etc.)
 * @query {string} orderDirection - Dirección del orden (ASC, DESC)
 * @query {number} pageNumber - Número de página (por defecto: 1)
 * @query {number} pageSize - Tamaño de página (por defecto: 20)
 */
router.get('/', InventariosController.getStockItems);

/**
 * @route GET /api/inventarios/estadisticas
 * @description Obtiene estadísticas de inventario con ROLLUP
 * @query {string} searchText - Filtro por texto en nombre del producto
 * @query {string} stockGroup - Filtro por grupo de stock
 */
router.get('/estadisticas', InventariosController.getInventariosEstadisticas);

/**
 * @route GET /api/inventarios/top-productos
 * @description Obtiene el top 10 de productos más vendidos usando DENSE_RANK
 * @query {number} anioInicio - Año de inicio para el rango
 * @query {number} anioFin - Año de fin para el rango
 */
router.get('/top-productos', InventariosController.getTopProductosPorVentas);

/**
 * @route GET /api/inventarios/stock-groups
 * @description Obtiene todos los grupos de stock para filtros dinámicos
 */
router.get('/stock-groups', InventariosController.getStockGroups);

/**
 * @route GET /api/inventarios/:id
 * @description Obtiene un producto específico por ID con todos los detalles
 * @param {number} id - ID del producto
 */
router.get('/:id', InventariosController.getStockItemById);

module.exports = router;
