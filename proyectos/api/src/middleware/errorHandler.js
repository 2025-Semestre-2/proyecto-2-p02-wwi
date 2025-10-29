const errorHandler = (err, req, res, next) => {
    console.error('Error Stack:', err.stack);

    // Error de SQL Server
    if (err.name === 'ConnectionError' || err.name === 'RequestError') {
        return res.status(500).json({
            success: false,
            message: 'Error de base de datos',
            error: process.env.NODE_ENV === 'development' ? err.message : 'Error interno del servidor'
        });
    }

    // Error de validación
    if (err.name === 'ValidationError') {
        return res.status(400).json({
            success: false,
            message: 'Error de validación',
            error: err.message
        });
    }

    // Error por defecto
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Error interno del servidor',
        error: process.env.NODE_ENV === 'development' ? err.stack : 'Error interno del servidor'
    });
};

const notFound = (req, res, next) => {
    const error = new Error(`Ruta no encontrada - ${req.originalUrl}`);
    error.status = 404;
    next(error);
};

module.exports = {
    errorHandler,
    notFound
};
