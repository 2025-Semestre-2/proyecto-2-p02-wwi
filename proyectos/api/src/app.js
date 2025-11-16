require('dotenv').config();
const express = require('express');
const morgan = require('morgan');
const cors = require('cors');
const db = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Routes existentes
app.use('/api/clientes', require('./routes/clientes.routes'));
app.use('/api/productos', require('./routes/productos.routes'));

// âœ… NUEVO: Endpoints de distribuciÃ³n
app.use('/api/distribucion', require('./routes/distribution.routes'));

app.get('/health', async (req, res) => {
    const status = { 
        api: 'OK', 
        timestamp: new Date().toISOString(), 
        databases: {} 
    };
    
    for (const dbName of ['corporativo', 'sanJose', 'limon']) {
        try {
            const pool = await db.connect(dbName);
            const result = await pool.request().query('SELECT 1 as test');
            status.databases[dbName] = result.recordset[0].test === 1 ? 'OK' : 'ERROR';
        } catch (error) {
            status.databases[dbName] = 'ERROR';
        }
    }
    res.json(status);
});

app.get('/', (req, res) => {
    res.json({
        message: 'API WWI Distribuida',
        version: '1.0.0',
        endpoints: {
            health: '/health',
            clientes: '/api/clientes',
            productos: '/api/productos',
            // âœ… NUEVOS endpoints
            distribucion: '/api/distribucion'
        }
    });
});

app.listen(PORT, () => {
    console.log(`\nAPI corriendo en http://localhost:${PORT}`);
    console.log(`Health: http://localhost:${PORT}/health`);
    console.log(`DistribuciÃ³n: http://localhost:${PORT}/api/distribucion/estado\n`);
});

process.on('SIGINT', async () => {
    console.log('\nCerrando...');
    await db.closeAll();
    process.exit(0);
});
