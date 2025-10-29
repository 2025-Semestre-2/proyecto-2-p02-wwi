const express = require('express');
const AppController = require('../controllers/AppController');

const router = express.Router();

// GET /api/health - Endpoint de salud de la aplicación
router.get('/health', AppController.health);

// GET /api/info - Información general de la API
router.get('/info', AppController.info);

module.exports = router;
