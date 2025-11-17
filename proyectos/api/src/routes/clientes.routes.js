const express = require('express');
const router = express.Router();
const controller = require('../controllers/clientes.controller');

router.get('/', controller.getClientesConsolidados);
router.get('/sanjose', controller.getClientesSanJose);
router.get('/limon', controller.getClientesLimon);
router.get('/:id', controller.getClienteById);

module.exports = router;
