#Requires -Version 5.1
<#
.SYNOPSIS
    Configura y levanta la API distribuida con conexiones múltiples
.EXAMPLE
    .\setup-api-distribuida.ps1
    .\setup-api-distribuida.ps1 -RunSecurityScripts -TestEndpoints
#>

param(
    [string]$SaUser = "sa",
    [string]$SaPass = "WideWorld2024!",
    [string]$CorpUser = "corp_analytics",
    [string]$CorpPass = "Corporativo#1",
    [string]$SjUser = "admin_sj",
    [string]$SjPass = "Administrador#SanJose",
    [string]$LimUser = "admin_lim",
    [string]$LimPass = "Administrador#Limon",
    [int]$PortCorp = 1444,
    [int]$PortSJ = 1445,
    [int]$PortLim = 1446,
    [int]$ApiPort = 3000,
    [string]$ApiPath = "proyectos/api",
    [string]$SqlScriptsPath = "Script sql/Roles",
    [switch]$RunSecurityScripts,
    [switch]$TestEndpoints,
    [switch]$SkipDockerCheck,
    [switch]$ForceReinstall
)

function Write-ColorOutput {
    param([string]$Message, [string]$Type = 'Info')
    $color = @{ 'Success'='Green'; 'Info'='Cyan'; 'Warning'='Yellow'; 'Error'='Red' }[$Type]
    $prefix = @{ 'Success'='[OK]'; 'Info'='[INFO]'; 'Warning'='[WARN]'; 'Error'='[ERROR]' }[$Type]
    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

Write-Host "`n========================================"
Write-Host "  SETUP API DISTRIBUIDA - ESTRATEGIA 1"
Write-Host "  Conexiones Multiples Directas"
Write-Host "========================================`n"

# Verificar Node.js
if (-not (Test-CommandExists "node")) {
    Write-ColorOutput "Node.js no instalado. Descarga: https://nodejs.org" -Type Error
    exit 1
}
Write-ColorOutput "Node.js: $(node --version)" -Type Success

if (-not (Test-CommandExists "npm")) {
    Write-ColorOutput "npm no instalado" -Type Error
    exit 1
}
Write-ColorOutput "npm: $(npm --version)" -Type Success

# Verificar Docker
if (-not $SkipDockerCheck -and (Test-CommandExists "docker")) {
    Write-ColorOutput "Verificando contenedores Docker..." -Type Info
    $containers = docker ps --format "{{.Names}}" 2>$null | Select-String "wwi-"
    if ($containers) {
        $containers | ForEach-Object { Write-Host "  - $_" }
    }
}

Write-Host ""

# Crear directorios
Write-ColorOutput "Creando estructura..." -Type Info
$dirs = @("$ApiPath", "$ApiPath/src", "$ApiPath/src/config", "$ApiPath/src/routes", "$ApiPath/src/controllers", "$ApiPath/src/services")
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# package.json
$packageJson = @'
{
  "name": "api-wwi-distribuida",
  "version": "1.0.0",
  "description": "API distribuida WWI",
  "main": "src/app.js",
  "scripts": {
    "start": "node src/app.js",
    "dev": "nodemon src/app.js",
    "distribute": "node src/scripts/distribute-products.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mssql": "^10.0.1",
    "morgan": "^1.10.0",
    "dotenv": "^16.3.1",
    "cors": "^2.8.5"
  }
}
'@
$packageJson | Out-File "$ApiPath/package.json" -Encoding UTF8

# .env
$envContent = @"
PORT=$ApiPort
DB_ENCRYPT=false
DB_TRUST_SERVER_CERTIFICATE=true
DB_CORP_SERVER=localhost,$PortCorp
DB_CORP_DATABASE=WWI_Corporativo
DB_CORP_USER=$CorpUser
DB_CORP_PASSWORD=$CorpPass
DB_SJ_SERVER=localhost,$PortSJ
DB_SJ_DATABASE=WWI_Sucursal_SJ
DB_SJ_USER=$SjUser
DB_SJ_PASSWORD=$SjPass
DB_LIM_SERVER=localhost,$PortLim
DB_LIM_DATABASE=WWI_Sucursal_LIM
DB_LIM_USER=$LimUser
DB_LIM_PASSWORD=$LimPass
"@
$envContent | Out-File "$ApiPath/.env" -Encoding UTF8

# database.js
$dbConfig = @'
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
'@
$dbConfig | Out-File "$ApiPath/src/config/database.js" -Encoding UTF8

# app.js (ACTUALIZADO)
$appJs = @'
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

// ✅ NUEVO: Endpoints de distribución
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
            // ✅ NUEVOS endpoints
            distribucion: '/api/distribucion'
        }
    });
});

app.listen(PORT, () => {
    console.log(`\nAPI corriendo en http://localhost:${PORT}`);
    console.log(`Health: http://localhost:${PORT}/health`);
    console.log(`Distribución: http://localhost:${PORT}/api/distribucion/estado\n`);
});

process.on('SIGINT', async () => {
    console.log('\nCerrando...');
    await db.closeAll();
    process.exit(0);
});
'@
$appJs | Out-File "$ApiPath/src/app.js" -Encoding UTF8

# distribution.routes.js (NUEVO)
$distributionRoutes = @'
const express = require('express');
const router = express.Router();
const ProductDistributor = require('../services/ProductDistributor');

/**
 * @route POST /api/distribucion/productos
 * @description Distribuye productos desde WideWorldImporters a las sucursales
 */
router.post('/productos', async (req, res) => {
    try {
        console.log('📨 Solicitud recibida para distribución de productos');
        
        const distributor = new ProductDistributor();
        const result = await distributor.distributeProducts();
        
        if (result.success) {
            res.json({
                success: true,
                message: 'Distribución completada exitosamente',
                data: result.summary,
                timestamp: new Date().toISOString()
            });
        } else {
            res.status(500).json({
                success: false,
                message: 'Error en la distribución',
                error: result.error,
                timestamp: new Date().toISOString()
            });
        }
    } catch (error) {
        console.error('❌ Error en endpoint de distribución:', error);
        res.status(500).json({
            success: false,
            message: 'Error interno del servidor',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

/**
 * @route GET /api/distribucion/estado
 * @description Obtiene el estado actual de la distribución
 */
router.get('/estado', async (req, res) => {
    try {
        const distributor = new ProductDistributor();
        const configs = distributor.configs;
        const sql = require('mssql');
        
        const status = {
            corporativo: { connected: false, count: 0 },
            sanJose: { connected: false, count: 0 },
            limon: { connected: false, count: 0 },
            timestamp: new Date().toISOString()
        };

        // Verificar Corporativo
        try {
            const corpPool = await sql.connect(configs.corporativo);
            const masterCount = await corpPool.request().query(
                'SELECT COUNT(*) as total FROM Warehouse.StockItems_Master'
            );
            status.corporativo = { 
                connected: true, 
                count: masterCount.recordset[0].total 
            };
            await corpPool.close();
        } catch (error) {
            status.corporativo.error = error.message;
        }

        // Verificar San José
        try {
            const sjPool = await sql.connect(configs.sanJose);
            const sjCount = await sjPool.request().query(
                'SELECT COUNT(*) as total FROM Warehouse.StockItems'
            );
            status.sanJose = { 
                connected: true, 
                count: sjCount.recordset[0].total 
            };
            await sjPool.close();
        } catch (error) {
            status.sanJose.error = error.message;
        }

        // Verificar Limón
        try {
            const limPool = await sql.connect(configs.limon);
            const limCount = await limPool.request().query(
                'SELECT COUNT(*) as total FROM Warehouse.StockItems'
            );
            status.limon = { 
                connected: true, 
                count: limCount.recordset[0].total 
            };
            await limPool.close();
        } catch (error) {
            status.limon.error = error.message;
        }

        res.json({
            success: true,
            data: status
        });
        
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @route GET /api/distribucion/productos/consolidado
 * @description Obtiene vista consolidada de productos
 */
router.get('/productos/consolidado', async (req, res) => {
    try {
        const distributor = new ProductDistributor();
        const configs = distributor.configs;
        const sql = require('mssql');
        
        const corpPool = await sql.connect(configs.corporativo);
        const result = await corpPool.request().query(`
            SELECT 
                m.StockItemID,
                m.StockItemName,
                m.UnitPrice,
                m.AvailableInSJ,
                m.AvailableInLIM,
                CASE 
                    WHEN m.AvailableInSJ = 1 AND m.AvailableInLIM = 1 THEN 'Ambas'
                    WHEN m.AvailableInSJ = 1 THEN 'Solo San José'
                    WHEN m.AvailableInLIM = 1 THEN 'Solo Limón'
                    ELSE 'No disponible'
                END as Disponibilidad
            FROM Warehouse.StockItems_Master m
            ORDER BY m.StockItemID
        `);

        await corpPool.close();

        res.json({
            success: true,
            data: result.recordset,
            total: result.recordset.length,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

module.exports = router;
'@
$distributionRoutes | Out-File "$ApiPath/src/routes/distribution.routes.js" -Encoding UTF8

# ProductDistributor.js (NUEVO)
$productDistributor = @'
require('dotenv').config();
const sql = require('mssql');

class ProductDistributor {
    constructor() {
        this.configs = {
            corporativo: {
                server: 'localhost',
                port: 1444,
                database: process.env.DB_CORP_DATABASE,
                user: process.env.DB_CORP_USER,
                password: process.env.DB_CORP_PASSWORD,
                options: { 
                    encrypt: false, 
                    trustServerCertificate: true,
                    enableArithAbort: true
                }
            },
            sanJose: {
                server: 'localhost', 
                port: 1445,
                database: process.env.DB_SJ_DATABASE,
                user: process.env.DB_SJ_USER,
                password: process.env.DB_SJ_PASSWORD,
                options: { 
                    encrypt: false, 
                    trustServerCertificate: true,
                    enableArithAbort: true
                }
            },
            limon: {
                server: 'localhost',
                port: 1446, 
                database: process.env.DB_LIM_DATABASE,
                user: process.env.DB_LIM_USER,
                password: process.env.DB_LIM_PASSWORD,
                options: { 
                    encrypt: false, 
                    trustServerCertificate: true,
                    enableArithAbort: true
                }
            }
        };
    }

    async distributeProducts() {
        let corpPool, sjPool, limPool;
        
        try {
            console.log('🚀 Iniciando distribución de productos...\n');
            
            // Conectar a todos los servidores
            console.log('🔌 Conectando a servidores...');
            corpPool = await sql.connect(this.configs.corporativo);
            sjPool = await sql.connect(this.configs.sanJose);
            limPool = await sql.connect(this.configs.limon);
            console.log('✅ Conexiones establecidas\n');

            // Obtener datos maestros
            console.log('📦 Obteniendo catálogo maestro...');
            const masterProducts = await corpPool.request()
                .query(`
                    SELECT TOP 10 
                        si.StockItemID, si.StockItemName, si.SupplierID, si.ColorID,
                        si.UnitPackageID, si.OuterPackageID, si.Brand, si.Size,
                        si.LeadTimeDays, si.QuantityPerOuter, si.IsChillerStock,
                        si.Barcode, si.TaxRate, si.UnitPrice, si.RecommendedRetailPrice,
                        si.TypicalWeightPerUnit, si.MarketingComments, si.InternalComments,
                        si.LastEditedBy, ISNULL(sh.QuantityOnHand, 0) as QuantityOnHand
                    FROM WideWorldImporters.Warehouse.StockItems si
                    LEFT JOIN WideWorldImporters.Warehouse.StockItemHoldings sh 
                        ON si.StockItemID = sh.StockItemID
                    ORDER BY si.StockItemID
                `);

            console.log(`✅ Encontrados ${masterProducts.recordset.length} productos\n`);

            // Crear tabla maestra si no existe
            await this.createMasterTable(corpPool);

            // Distribuir productos
            const productsSJ = masterProducts.recordset.filter(p => p.StockItemID % 2 === 1);
            const productsLIM = masterProducts.recordset.filter(p => p.StockItemID % 2 === 0);
            
            console.log(`📍 Distribuyendo ${productsSJ.length} productos a San José...`);
            let insertedSJ = 0;
            for (const product of productsSJ) {
                if (await this.insertProduct(sjPool, product, 'SJ')) insertedSJ++;
            }

            console.log(`📍 Distribuyendo ${productsLIM.length} productos a Limón...`);
            let insertedLIM = 0;
            for (const product of productsLIM) {
                if (await this.insertProduct(limPool, product, 'LIM')) insertedLIM++;
            }

            // Actualizar catálogo maestro
            console.log('🔄 Actualizando catálogo maestro...');
            const insertedMaster = await this.updateMasterCatalog(corpPool, masterProducts.recordset);

            console.log('\n🎉 Distribución completada exitosamente!');

            return {
                success: true,
                summary: {
                    master: insertedMaster,
                    sanJose: insertedSJ,
                    limon: insertedLIM,
                    total: insertedSJ + insertedLIM
                }
            };

        } catch (error) {
            console.error('❌ Error en la distribución:', error.message);
            return {
                success: false,
                error: error.message
            };
        } finally {
            if (corpPool) await corpPool.close();
            if (sjPool) await sjPool.close(); 
            if (limPool) await limPool.close();
        }
    }

    async createMasterTable(corpPool) {
        const createTableQuery = `
            IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockItems_Master')
            CREATE TABLE Warehouse.StockItems_Master (
                StockItemID INT PRIMARY KEY,
                StockItemName NVARCHAR(100) NOT NULL,
                SupplierID INT,
                ColorID INT,
                UnitPackageID INT,
                OuterPackageID INT,
                Brand NVARCHAR(50),
                Size NVARCHAR(20),
                LeadTimeDays INT,
                QuantityPerOuter INT,
                IsChillerStock BIT,
                Barcode NVARCHAR(50),
                TaxRate DECIMAL(18,3),
                UnitPrice DECIMAL(18,2),
                RecommendedRetailPrice DECIMAL(18,2),
                TypicalWeightPerUnit DECIMAL(18,3),
                MarketingComments NVARCHAR(MAX),
                InternalComments NVARCHAR(MAX),
                LastEditedBy INT,
                AvailableInSJ BIT DEFAULT 0,
                AvailableInLIM BIT DEFAULT 0,
                IsActive BIT DEFAULT 1,
                CreatedDate DATETIME2 DEFAULT GETDATE()
            )
        `;
        await corpPool.request().query(createTableQuery);
    }

    async insertProduct(pool, product, sucursal) {
        try {
            const query = `
                IF NOT EXISTS (SELECT 1 FROM Warehouse.StockItems WHERE StockItemID = @StockItemID)
                INSERT INTO Warehouse.StockItems (
                    StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
                    OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
                    IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
                    TypicalWeightPerUnit, MarketingComments, InternalComments, LastEditedBy
                ) VALUES (
                    @StockItemID, @StockItemName, @SupplierID, @ColorID, @UnitPackageID,
                    @OuterPackageID, @Brand, @Size, @LeadTimeDays, @QuantityPerOuter,
                    @IsChillerStock, @Barcode, @TaxRate, @UnitPrice, @RecommendedRetailPrice,
                    @TypicalWeightPerUnit, @MarketingComments, @InternalComments, @LastEditedBy
                )
            `;

            const result = await pool.request()
                .input('StockItemID', sql.Int, product.StockItemID)
                .input('StockItemName', sql.NVarChar, product.StockItemName)
                .input('SupplierID', sql.Int, product.SupplierID)
                .input('ColorID', sql.Int, product.ColorID)
                .input('UnitPackageID', sql.Int, product.UnitPackageID)
                .input('OuterPackageID', sql.Int, product.OuterPackageID)
                .input('Brand', sql.NVarChar, product.Brand)
                .input('Size', sql.NVarChar, product.Size)
                .input('LeadTimeDays', sql.Int, product.LeadTimeDays)
                .input('QuantityPerOuter', sql.Int, product.QuantityPerOuter)
                .input('IsChillerStock', sql.Bit, product.IsChillerStock)
                .input('Barcode', sql.NVarChar, product.Barcode)
                .input('TaxRate', sql.Decimal(18,3), product.TaxRate)
                .input('UnitPrice', sql.Decimal(18,2), product.UnitPrice)
                .input('RecommendedRetailPrice', sql.Decimal(18,2), product.RecommendedRetailPrice)
                .input('TypicalWeightPerUnit', sql.Decimal(18,3), product.TypicalWeightPerUnit)
                .input('MarketingComments', sql.NVarChar, product.MarketingComments)
                .input('InternalComments', sql.NVarChar, product.InternalComments)
                .input('LastEditedBy', sql.Int, product.LastEditedBy)
                .query(query);

            return result.rowsAffected[0] > 0;
        } catch (error) {
            console.log(`   ⚠️  Error insertando producto ${product.StockItemID} en ${sucursal}: ${error.message}`);
            return false;
        }
    }

    async updateMasterCatalog(corpPool, products) {
        let insertedCount = 0;
        
        for (const product of products) {
            try {
                const query = `
                    IF NOT EXISTS (SELECT 1 FROM Warehouse.StockItems_Master WHERE StockItemID = @StockItemID)
                    INSERT INTO Warehouse.StockItems_Master (
                        StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
                        OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
                        IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
                        TypicalWeightPerUnit, MarketingComments, InternalComments, LastEditedBy,
                        AvailableInSJ, AvailableInLIM
                    ) VALUES (
                        @StockItemID, @StockItemName, @SupplierID, @ColorID, @UnitPackageID,
                        @OuterPackageID, @Brand, @Size, @LeadTimeDays, @QuantityPerOuter,
                        @IsChillerStock, @Barcode, @TaxRate, @UnitPrice, @RecommendedRetailPrice,
                        @TypicalWeightPerUnit, @MarketingComments, @InternalComments, @LastEditedBy,
                        @AvailableInSJ, @AvailableInLIM
                    )
                `;

                const result = await corpPool.request()
                    .input('StockItemID', sql.Int, product.StockItemID)
                    .input('StockItemName', sql.NVarChar, product.StockItemName)
                    .input('SupplierID', sql.Int, product.SupplierID)
                    .input('ColorID', sql.Int, product.ColorID)
                    .input('UnitPackageID', sql.Int, product.UnitPackageID)
                    .input('OuterPackageID', sql.Int, product.OuterPackageID)
                    .input('Brand', sql.NVarChar, product.Brand)
                    .input('Size', sql.NVarChar, product.Size)
                    .input('LeadTimeDays', sql.Int, product.LeadTimeDays)
                    .input('QuantityPerOuter', sql.Int, product.QuantityPerOuter)
                    .input('IsChillerStock', sql.Bit, product.IsChillerStock)
                    .input('Barcode', sql.NVarChar, product.Barcode)
                    .input('TaxRate', sql.Decimal(18,3), product.TaxRate)
                    .input('UnitPrice', sql.Decimal(18,2), product.UnitPrice)
                    .input('RecommendedRetailPrice', sql.Decimal(18,2), product.RecommendedRetailPrice)
                    .input('TypicalWeightPerUnit', sql.Decimal(18,3), product.TypicalWeightPerUnit)
                    .input('MarketingComments', sql.NVarChar, product.MarketingComments)
                    .input('InternalComments', sql.NVarChar, product.InternalComments)
                    .input('LastEditedBy', sql.Int, product.LastEditedBy)
                    .input('AvailableInSJ', sql.Bit, product.StockItemID % 2 === 1)
                    .input('AvailableInLIM', sql.Bit, product.StockItemID % 2 === 0)
                    .query(query);

                if (result.rowsAffected[0] > 0) insertedCount++;
            } catch (error) {
                console.log(`   ⚠️  Error insertando producto ${product.StockItemID} en maestro: ${error.message}`);
            }
        }
        
        return insertedCount;
    }
}

module.exports = ProductDistributor;
'@
$productDistributor | Out-File "$ApiPath/src/services/ProductDistributor.js" -Encoding UTF8

# Los archivos existentes (clientes.routes.js, clientes.controller.js, productos.routes.js, productos.controller.js)
# se mantienen igual que en tu versión original...

Write-ColorOutput "Archivos creados" -Type Success

# Instalar dependencias
Write-ColorOutput "`nInstalando dependencias..." -Type Info
Push-Location $ApiPath
if ($ForceReinstall -and (Test-Path "node_modules")) {
    Remove-Item -Recurse -Force "node_modules"
}
if (-not (Test-Path "node_modules")) {
    npm install --silent
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "Dependencias instaladas" -Type Success
    }
}
Pop-Location

# Iniciar API
Write-ColorOutput "`nIniciando API en puerto $ApiPort...`n" -Type Info
Push-Location $ApiPath
Start-Process node -ArgumentList "src/app.js" -NoNewWindow
Pop-Location

Start-Sleep -Seconds 3

# Probar endpoints
if ($TestEndpoints) {
    Write-ColorOutput "`nProbando endpoints..." -Type Info
    try {
        $health = Invoke-RestMethod "http://localhost:$ApiPort/health"
        Write-ColorOutput "Health: $($health.api)" -Type Success
        
        # Probar nuevo endpoint de distribución
        $distStatus = Invoke-RestMethod "http://localhost:$ApiPort/api/distribucion/estado"
        Write-ColorOutput "Distribución: Conectado" -Type Success
    } catch {
        Write-ColorOutput "Error en health check" -Type Warning
    }
}

Write-Host "API lista en http://localhost:$ApiPort" -ForegroundColor Green
Write-Host "Presiona Ctrl+C para detener" -ForegroundColor Yellow

while ($true) { Start-Sleep -Seconds 1 }