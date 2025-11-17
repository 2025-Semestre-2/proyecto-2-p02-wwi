const sql = require('mssql');

const baseConfig = {
    options: {
        encrypt: process.env.DB_ENCRYPT === 'true',
        trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE === 'true',
        enableArithAbort: true
    },
    pool: { max: 10, min: 0, idleTimeoutMillis: 30000 }
};

const dbConfigs = {
    corporativo: {
        server: process.env.DB_CORP_SERVER,
        database: process.env.DB_CORP_DATABASE,
        user: process.env.DB_CORP_USER,
        password: process.env.DB_CORP_PASSWORD,
        ...baseConfig
    },
    sanJose: {
        server: process.env.DB_SJ_SERVER,
        database: process.env.DB_SJ_DATABASE,
        user: process.env.DB_SJ_USER,
        password: process.env.DB_SJ_PASSWORD,
        ...baseConfig
    },
    limon: {
        server: process.env.DB_LIM_SERVER,
        database: process.env.DB_LIM_DATABASE,
        user: process.env.DB_LIM_USER,
        password: process.env.DB_LIM_PASSWORD,
        ...baseConfig
    }
};

const pools = { corporativo: null, sanJose: null, limon: null };

async function connect(dbName) {
    if (!pools[dbName]) {
        console.log(`Conectando a ${dbName}...`);
        pools[dbName] = await sql.connect(dbConfigs[dbName]);
        console.log(`OK: ${dbName}`);
    }
    return pools[dbName];
}

async function closeAll() {
    for (const [name, pool] of Object.entries(pools)) {
        if (pool) {
            await pool.close();
            console.log(`Cerrado: ${name}`);
        }
    }
}

module.exports = { connect, closeAll, sql };
