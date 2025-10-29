const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

// Importar middlewares
const { errorHandler, notFound } = require('./middleware/errorHandler');

// Importar rutas
const indexRoutes = require('./routes/index');
const clientesRoutes = require('./routes/clientes');
const inventariosRoutes = require('./routes/inventarios');
const proveedoresRoutes = require('./routes/proveedores');
const ventasRoutes = require('./routes/ventas'); 
const estadisticasRoutes = require('./routes/estadisticas');

const app = express();
const PORT = process.env.PORT || 3001;

// Middlewares globales
app.use(helmet()); // Seguridad
app.use(morgan('combined')); // Logging
app.use(cors({
    origin: process.env.FRONTEND_URL || 'http://localhost:5173',
    credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Rutas
app.use('/api', indexRoutes);
app.use('/api/clientes', clientesRoutes);
app.use('/api/inventarios', inventariosRoutes);
app.use('/api/proveedores', proveedoresRoutes);
app.use('/api/ventas', ventasRoutes);
app.use('/api/estadisticas', estadisticasRoutes);

// Middleware para rutas no encontradas
app.use(notFound);

// Middleware de manejo de errores
app.use(errorHandler);

// Iniciar servidor
app.listen(PORT, () => {
    console.log(`Servidor ejecutándose en puerto ${PORT}`);
    console.log(`URL: http://localhost:${PORT}`);
    console.log(`URL: ${process.env.FRONTEND_URL || 'http://localhost:5173'}`);
    console.log(`Base de datos: ${process.env.DB_SERVER}:${process.env.DB_PORT}/${process.env.DB_NAME}`);
});

module.exports = app;
