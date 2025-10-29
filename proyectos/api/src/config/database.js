const sql = require('mssql');
require('dotenv').config();

const config = {
    server: process.env.DB_SERVER,
    port: parseInt(process.env.DB_PORT),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    options: {
        encrypt: process.env.DB_ENCRYPT === 'true',
        trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE === 'true',
        enableArithAbort: true,
        requestTimeout: 30000,
        connectionTimeout: 30000
    },
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30000
    }
};

let pool;

const getConnection = async () => {
    try {
        if (!pool) {
            pool = await sql.connect(config);
            console.log('Conectado exitosamente a SQL Server');
        }
        return pool;
    } catch (error) {
        console.error('Error conectando a la base de datos:', error);
        throw error;
    }
};

const closeConnection = async () => {
    try {
        if (pool) {
            await pool.close();
            pool = null;
            console.log('Conexión cerrada');
        }
    } catch (error) {
        console.error('Error cerrando la conexión:', error);
    }
};

module.exports = {
    getConnection,
    closeConnection,
    sql
};
