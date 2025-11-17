const express = require('express');
const router = express.Router();
const controller = require('../controllers/productos.controller');

router.get('/', controller.getProductosConsolidados);
router.get('/sanjose', controller.getProductosSanJose);
router.get('/limon', controller.getProductosLimon);

module.exports = router;
