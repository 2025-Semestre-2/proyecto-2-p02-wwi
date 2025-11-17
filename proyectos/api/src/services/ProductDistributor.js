// services/ProductDistributor.js
// Distribuye productos desde WWI_Corporativo hacia las sucursales
// WWI_Sucursal_SJ y WWI_Sucursal_LIM usando fragmentacion funcional:
//  - IDs impares -> San Jose
//  - IDs pares   -> Limon

require('dotenv').config();
const sql = require('mssql');

class ProductDistributor {
    constructor() {
        // Configuracion directa a cada docker
        this.configs = {
            corporativo: {
                server: 'localhost',
                port: 1444,
                database: process.env.DB_CORP_DATABASE || 'WWI_Corporativo',
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
                database: process.env.DB_SJ_DATABASE || 'WWI_Sucursal_SJ',
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
                database: process.env.DB_LIM_DATABASE || 'WWI_Sucursal_LIM',
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

    // ===== Flujo principal =====
    async distributeProducts() {
        let corpPool, sjPool, limPool;

        try {
            console.log('=== Distribucion de productos ===');

            // 1. Conectar a los tres servidores
            console.log('Conectando a servidores SQL...');
            corpPool = await new sql.ConnectionPool(this.configs.corporativo).connect();
            sjPool   = await new sql.ConnectionPool(this.configs.sanJose).connect();
            limPool  = await new sql.ConnectionPool(this.configs.limon).connect();
            console.log('Conexiones establecidas.\n');

            // 2. Obtener productos desde el catalogo maestro en corporativo
            console.log('Leyendo productos desde Warehouse.StockItems_Master...');
            const result = await corpPool.request().query(`
                SELECT
                    StockItemID, StockItemName, SupplierID, ColorID,
                    UnitPackageID, OuterPackageID, Brand, Size,
                    LeadTimeDays, QuantityPerOuter, IsChillerStock,
                    Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
                    TypicalWeightPerUnit, MarketingComments, InternalComments,
                    LastEditedBy
                FROM Warehouse.StockItems_Master
                WHERE IsActive = 1
                ORDER BY StockItemID;
            `);


            const products = result.recordset;
            console.log(`Productos encontrados en maestro: ${products.length}`);

            if (!products.length) {
                return {
                    success: true,
                    message: 'No hay productos activos en el catalogo maestro',
                    data: { master: 0, sanJose: 0, limon: 0, total: 0 },
                    timestamp: new Date().toISOString()
                };
            }

            // 3. Particionar por regla funcional
            const productsSJ  = products.filter(p => p.StockItemID % 2 === 1);
            const productsLIM = products.filter(p => p.StockItemID % 2 === 0);

            console.log(`Productos para San Jose (impares): ${productsSJ.length}`);
            console.log(`Productos para Limon (pares): ${productsLIM.length}`);

            // 4. Insertar en San Jose
            let insertedSJ = 0;
            for (const p of productsSJ) {
                if (await this.insertProduct(sjPool, p, 'SJ')) {
                    insertedSJ++;
                }
            }

            // 5. Insertar en Limon
            let insertedLIM = 0;
            for (const p of productsLIM) {
                if (await this.insertProduct(limPool, p, 'LIM')) {
                    insertedLIM++;
                }
            }

            console.log('Distribucion completada.');
            console.log(`Insertados en SJ:  ${insertedSJ}`);
            console.log(`Insertados en LIM: ${insertedLIM}`);

            return {
                success: true,
                message: 'Distribucion completada exitosamente',
                data: {
                    master: products.length,
                    sanJose: insertedSJ,
                    limon: insertedLIM,
                    total: products.length
                },
                timestamp: new Date().toISOString()
            };

        } catch (error) {
            console.error('Error en la distribucion:', error.message);
            return {
                success: false,
                message: 'Error en la distribucion',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        } finally {
            if (corpPool) await corpPool.close();
            if (sjPool)   await sjPool.close();
            if (limPool)  await limPool.close();
        }
    }

    // ===== Insercion en sucursales =====
    async insertProduct(pool, product, sucursal) {
        const tableName = sucursal === 'SJ'
            ? 'Warehouse.StockItems_SJ'
            : 'Warehouse.StockItems_LIM';

        const query = `
            IF NOT EXISTS (
                SELECT 1 FROM ${tableName} WHERE StockItemID = @StockItemID
            )
            BEGIN
                INSERT INTO ${tableName} (
                    StockItemID, StockItemName, SupplierID, ColorID,
                    UnitPackageID, OuterPackageID, Brand, Size,
                    LeadTimeDays, QuantityPerOuter, IsChillerStock,
                    Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
                    TypicalWeightPerUnit, MarketingComments, InternalComments,
                    LastEditedBy
                ) VALUES (
                    @StockItemID, @StockItemName, @SupplierID, @ColorID,
                    @UnitPackageID, @OuterPackageID, @Brand, @Size,
                    @LeadTimeDays, @QuantityPerOuter, @IsChillerStock,
                    @Barcode, @TaxRate, @UnitPrice, @RecommendedRetailPrice,
                    @TypicalWeightPerUnit, @MarketingComments, @InternalComments,
                    @LastEditedBy
                );

                SELECT 1 AS Inserted;
            END
            ELSE
            BEGIN
                SELECT 0 AS Inserted;
            END
        `;

        try {
            const result = await pool.request()
                .input('StockItemID', sql.Int,        product.StockItemID)
                .input('StockItemName', sql.NVarChar, product.StockItemName)
                .input('SupplierID',    sql.Int,      product.SupplierID)
                .input('ColorID',       sql.Int,      product.ColorID)
                .input('UnitPackageID', sql.Int,      product.UnitPackageID)
                .input('OuterPackageID',sql.Int,      product.OuterPackageID)
                .input('Brand',         sql.NVarChar, product.Brand)
                .input('Size',          sql.NVarChar, product.Size)
                .input('LeadTimeDays',  sql.Int,      product.LeadTimeDays)
                .input('QuantityPerOuter', sql.Int,   product.QuantityPerOuter)
                .input('IsChillerStock',  sql.Bit,    product.IsChillerStock)
                .input('Barcode',       sql.NVarChar, product.Barcode)
                .input('TaxRate',       sql.Decimal(18,3), product.TaxRate)
                .input('UnitPrice',     sql.Decimal(18,2), product.UnitPrice)
                .input('RecommendedRetailPrice', sql.Decimal(18,2), product.RecommendedRetailPrice)
                .input('TypicalWeightPerUnit',   sql.Decimal(18,3), product.TypicalWeightPerUnit)
                .input('MarketingComments', sql.NVarChar, product.MarketingComments)
                .input('InternalComments',  sql.NVarChar, product.InternalComments)
                .input('LastEditedBy',      sql.Int,      product.LastEditedBy)
                .query(query);

            return result.recordset[0].Inserted === 1;
        } catch (error) {
            console.log(`  Error insertando producto ${product.StockItemID} en ${sucursal}: ${error.message}`);
            return false;
        }
    }
}

module.exports = ProductDistributor;
