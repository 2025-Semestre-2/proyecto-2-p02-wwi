const sql = require('mssql');
require('dotenv').config();

// ============================================================================
// CONFIGURACION DE BASES DE DATOS DISTRIBUIDAS - PROYECTO 2
// ============================================================================
// Tres bases de datos:
// 1. Corporativo (localhost:1433) - Datos consolidados + datos sensibles
// 2. San Jose (localhost:1434) - Sucursal con fragmentacion horizontal
// 3. Limon (localhost:1435) - Sucursal con fragmentacion horizontal
// ============================================================================

const baseConfig = {
    user: process.env.DB_USER || 'sa',
    password: process.env.DB_PASSWORD || 'WideWorld2024!',
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

// Configuraciones especificas por base de datos
const configs = {
    corporativo: {
        ...baseConfig,
        server: 'localhost',
        port: 1433,
        database: 'WWI_Corporativo'
    },
    sanjose: {
        ...baseConfig,
        server: 'localhost',
        port: 1434,
        database: 'WWI_Sucursal_SJ'
    },
    limon: {
        ...baseConfig,
        server: 'localhost',
        port: 1435,
        database: 'WWI_Sucursal_LIM'
    }
};

// Pools de conexiones (uno por cada base de datos)
const pools = {
    corporativo: null,
    sanjose: null,
    limon: null
};

/**
 * Obtiene una conexion a una base de datos especifica
 * @param {string} database - 'corporativo', 'sanjose', o 'limon'
 * @returns {Promise<sql.ConnectionPool>}
 */
const getConnection = async (database = 'corporativo') => {
    try {
        // Validar que el database sea valido
        if (!['corporativo', 'sanjose', 'limon'].includes(database)) {
            throw new Error(`Base de datos invalida: ${database}. Use: corporativo, sanjose o limon`);
        }

        // Si ya existe el pool, retornarlo
        if (pools[database]) {
            return pools[database];
        }

        // Crear nuevo pool
        pools[database] = await sql.connect(configs[database]);
        console.log(`Conectado a ${database.toUpperCase()} (${configs[database].server}:${configs[database].port})`);
        
        return pools[database];
    } catch (error) {
        console.error(`Error conectando a ${database}:`, error.message);
        throw error;
    }
};

/**
 * Obtiene conexion a CORPORATIVO (base de datos principal con datos consolidados)
 */
const getCorporativoConnection = async () => {
    return await getConnection('corporativo');
};

/**
 * Obtiene conexion a SAN JOSE (sucursal)
 */
const getSanJoseConnection = async () => {
    return await getConnection('sanjose');
};

/**
 * Obtiene conexion a LIMON (sucursal)
 */
const getLimonConnection = async () => {
    return await getConnection('limon');
};

/**
 * Obtiene conexion segun parametro de sucursal
 * @param {string} sucursal - 'corporativo', 'sanjose', 'limon', o 'consolidado'
 */
const getConnectionBySucursal = async (sucursal) => {
    // Si es consolidado o no especifica, usar corporativo
    if (!sucursal || sucursal === 'consolidado' || sucursal === 'corporativo') {
        return await getCorporativoConnection();
    }
    
    // Normalizar nombre de sucursal
    const sucursalNormalizada = sucursal.toLowerCase().replace(/\s+/g, '');
    
    if (sucursalNormalizada.includes('sanjose') || sucursalNormalizada.includes('sj')) {
        return await getSanJoseConnection();
    }
    
    if (sucursalNormalizada.includes('limon') || sucursalNormalizada.includes('lim')) {
        return await getLimonConnection();
    }
    
    // Por defecto, corporativo
    console.warn(`Sucursal '${sucursal}' no reconocida, usando Corporativo`);
    return await getCorporativoConnection();
};

/**
 * Cierra una conexion especifica o todas
 * @param {string} database - 'corporativo', 'sanjose', 'limon', o 'all' para cerrar todas
 */
const closeConnection = async (database = 'all') => {
    try {
        if (database === 'all') {
            // Cerrar todas las conexiones
            for (const [name, pool] of Object.entries(pools)) {
                if (pool) {
                    await pool.close();
                    pools[name] = null;
                    console.log(`Conexion cerrada: ${name.toUpperCase()}`);
                }
            }
        } else {
            // Cerrar conexion especifica
            if (pools[database]) {
                await pools[database].close();
                pools[database] = null;
                console.log(`Conexion cerrada: ${database.toUpperCase()}`);
            }
        }
    } catch (error) {
        console.error('Error cerrando conexiones:', error.message);
    }
};

module.exports = {
    // Funciones principales
    getConnection,              // Uso: await getConnection('corporativo')
    getCorporativoConnection,   // Uso: await getCorporativoConnection()
    getSanJoseConnection,       // Uso: await getSanJoseConnection()
    getLimonConnection,         // Uso: await getLimonConnection()
    getConnectionBySucursal,    // Uso: await getConnectionBySucursal(req.query.sucursal)
    closeConnection,
    
    // SQL object para queries
    sql,
    
    // Configs (para debugging)
    configs
};
