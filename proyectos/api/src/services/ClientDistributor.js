// src/services/ClientDistributor.js
// Distribuye TODOS los clientes a AMBAS sucursales (San José y Limón)
// Sin filtrado por provincia - Catálogo completo en cada sucursal

require('dotenv').config();
const sql = require('mssql');

class ClientDistributor {
    constructor() {
        this.configs = {
            corporativo: {
                server: 'localhost',
                port: 1444,
                database: process.env.DB_CORP_DATABASE || 'WWI_Corporativo',
                user: process.env.DB_CORP_USER,
                password: process.env.DB_CORP_PASSWORD,
                requestTimeout: 120000,
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
                requestTimeout: 120000,
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
                requestTimeout: 120000,
                options: {
                    encrypt: false,
                    trustServerCertificate: true,
                    enableArithAbort: true
                }
            }
        };
    }

    async insertCustomer(pool, customer, sucursal) {
        const tableName = (sucursal === 'SJ')
            ? 'Sales.Customers_SJ'
            : 'Sales.Customers_LIM';

        // 1) Verificar si ya existe
        try {
            const existsReq = pool.request();
            existsReq.timeout = 120000;

            const existsRes = await existsReq
                .input('CustomerID', sql.Int, customer.CustomerID)
                .query(`SELECT 1 AS Existe FROM ${tableName} WHERE CustomerID = @CustomerID;`);

            if (existsRes.recordset.length > 0) {
                return { success: false, reason: 'duplicate' };
            }
        } catch (error) {
            return { success: false, reason: 'error', error: error.message };
        }

        // 2) INSERT en la tabla fragmentada
        const insertQuery = `
            INSERT INTO ${tableName} (
                CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID,
                BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID,
                DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit,
                AccountOpenedDate, StandardDiscountPercentage, IsStatementSent,
                IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber,
                DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1,
                DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation,
                PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy
            )
            VALUES (
                @CustomerID, @CustomerName, @BillToCustomerID, @CustomerCategoryID,
                @BuyingGroupID, @PrimaryContactPersonID, @AlternateContactPersonID,
                @DeliveryMethodID, @DeliveryCityID, @PostalCityID, @CreditLimit,
                @AccountOpenedDate, @StandardDiscountPercentage, @IsStatementSent,
                @IsOnCreditHold, @PaymentDays, @PhoneNumber, @FaxNumber,
                @DeliveryRun, @RunPosition, @WebsiteURL, @DeliveryAddressLine1,
                @DeliveryAddressLine2, @DeliveryPostalCode, NULL,
                @PostalAddressLine1, @PostalAddressLine2, @PostalPostalCode, @LastEditedBy
            );
        `;

        try {
            const insertReq = pool.request();
            insertReq.timeout = 120000;

            await insertReq
                .input('CustomerID', sql.Int, customer.CustomerID)
                .input('CustomerName', sql.NVarChar(100), customer.CustomerName)
                .input('BillToCustomerID', sql.Int, customer.BillToCustomerID)
                .input('CustomerCategoryID', sql.Int, customer.CustomerCategoryID)
                .input('BuyingGroupID', sql.Int, customer.BuyingGroupID)
                .input('PrimaryContactPersonID', sql.Int, customer.PrimaryContactPersonID)
                .input('AlternateContactPersonID', sql.Int, customer.AlternateContactPersonID)
                .input('DeliveryMethodID', sql.Int, customer.DeliveryMethodID)
                .input('DeliveryCityID', sql.Int, customer.DeliveryCityID)
                .input('PostalCityID', sql.Int, customer.PostalCityID)
                .input('CreditLimit', sql.Decimal(18,2), customer.CreditLimit)
                .input('AccountOpenedDate', sql.Date, customer.AccountOpenedDate)
                .input('StandardDiscountPercentage', sql.Decimal(18,3), customer.StandardDiscountPercentage)
                .input('IsStatementSent', sql.Bit, customer.IsStatementSent)
                .input('IsOnCreditHold', sql.Bit, customer.IsOnCreditHold)
                .input('PaymentDays', sql.Int, customer.PaymentDays)
                .input('PhoneNumber', sql.NVarChar(20), customer.PhoneNumber)
                .input('FaxNumber', sql.NVarChar(20), customer.FaxNumber)
                .input('DeliveryRun', sql.NVarChar(5), customer.DeliveryRun)
                .input('RunPosition', sql.NVarChar(5), customer.RunPosition)
                .input('WebsiteURL', sql.NVarChar(256), customer.WebsiteURL)
                .input('DeliveryAddressLine1', sql.NVarChar(60), customer.DeliveryAddressLine1)
                .input('DeliveryAddressLine2', sql.NVarChar(60), customer.DeliveryAddressLine2)
                .input('DeliveryPostalCode', sql.NVarChar(10), customer.DeliveryPostalCode)
                .input('PostalAddressLine1', sql.NVarChar(60), customer.PostalAddressLine1)
                .input('PostalAddressLine2', sql.NVarChar(60), customer.PostalAddressLine2)
                .input('PostalPostalCode', sql.NVarChar(10), customer.PostalPostalCode)
                .input('LastEditedBy', sql.Int, customer.LastEditedBy)
                .query(insertQuery);

            return { success: true };
        } catch (error) {
            // Trigger puede rechazar - deshabilitar triggers si es necesario
            if (error.message.includes('trigger') || error.message.includes('Solo se permiten')) {
                return { 
                    success: false, 
                    reason: 'trigger_rejected',
                    error: error.message
                };
            }
            
            return { success: false, reason: 'error', error: error.message };
        }
    }

    async distributeClients() {
        let corpPool, sjPool, limPool;

        try {
            console.log('\n========================================');
            console.log('DISTRIBUCION COMPLETA DE CLIENTES');
            console.log('Todos los clientes a ambas sucursales');
            console.log('========================================\n');

            // Conectar a los 3 servidores
            console.log('Conectando a bases de datos...');
            corpPool = await new sql.ConnectionPool(this.configs.corporativo).connect();
            sjPool   = await new sql.ConnectionPool(this.configs.sanJose).connect();
            limPool  = await new sql.ConnectionPool(this.configs.limon).connect();
            console.log('✅ Conexiones establecidas\n');

            // Obtener TODOS los clientes (sin filtro de provincia)
            console.log('Obteniendo clientes de WideWorldImporters...');
            const selectRequest = corpPool.request();
            selectRequest.timeout = 120000;

            const result = await selectRequest.query(`
                SELECT 
                    c.CustomerID, c.CustomerName, c.BillToCustomerID, c.CustomerCategoryID,
                    c.BuyingGroupID, c.PrimaryContactPersonID, c.AlternateContactPersonID,
                    c.DeliveryMethodID, c.DeliveryCityID, c.PostalCityID, c.CreditLimit,
                    c.AccountOpenedDate, c.StandardDiscountPercentage, c.IsStatementSent,
                    c.IsOnCreditHold, c.PaymentDays, c.PhoneNumber, c.FaxNumber,
                    c.DeliveryRun, c.RunPosition, c.WebsiteURL, c.DeliveryAddressLine1,
                    c.DeliveryAddressLine2, c.DeliveryPostalCode, c.PostalAddressLine1,
                    c.PostalAddressLine2, c.PostalPostalCode, c.LastEditedBy
                FROM WideWorldImporters.Sales.Customers c;
            `);

            const customers = result.recordset;
            console.log(`✅ Total de clientes obtenidos: ${customers.length}\n`);

            if (!customers.length) {
                console.log('⚠️  No hay clientes para distribuir\n');
                return {
                    success: true,
                    message: 'No hay clientes para distribuir',
                    summary: { totalOrigen: 0, sanJose: 0, limon: 0 }
                };
            }

            // ===========================================
            // INSERTAR EN SAN JOSÉ (TODOS LOS CLIENTES)
            // ===========================================
            console.log('========================================');
            console.log('INSERTANDO EN SAN JOSÉ');
            console.log('========================================');
            
            let insertedSJ = 0;
            let duplicatesSJ = 0;
            let errorsSJ = 0;
            let rejectedSJ = 0;

            for (let i = 0; i < customers.length; i++) {
                const c = customers[i];
                
                // Mostrar progreso cada 50 clientes
                if (i > 0 && i % 50 === 0) {
                    console.log(`  Progreso: ${i}/${customers.length} (${Math.round(i/customers.length*100)}%)`);
                }

                const result = await this.insertCustomer(sjPool, c, 'SJ');
                
                if (result.success) {
                    insertedSJ++;
                } else if (result.reason === 'duplicate') {
                    duplicatesSJ++;
                } else if (result.reason === 'trigger_rejected') {
                    rejectedSJ++;
                } else {
                    errorsSJ++;
                }
            }

            console.log(`\n✅ San José completado:`);
            console.log(`   Insertados:  ${insertedSJ}`);
            console.log(`   Duplicados:  ${duplicatesSJ}`);
            console.log(`   Rechazados:  ${rejectedSJ}`);
            console.log(`   Errores:     ${errorsSJ}\n`);

            // ===========================================
            // INSERTAR EN LIMÓN (TODOS LOS CLIENTES)
            // ===========================================
            console.log('========================================');
            console.log('INSERTANDO EN LIMÓN');
            console.log('========================================');
            
            let insertedLIM = 0;
            let duplicatesLIM = 0;
            let errorsLIM = 0;
            let rejectedLIM = 0;

            for (let i = 0; i < customers.length; i++) {
                const c = customers[i];
                
                // Mostrar progreso cada 50 clientes
                if (i > 0 && i % 50 === 0) {
                    console.log(`  Progreso: ${i}/${customers.length} (${Math.round(i/customers.length*100)}%)`);
                }

                const result = await this.insertCustomer(limPool, c, 'LIM');
                
                if (result.success) {
                    insertedLIM++;
                } else if (result.reason === 'duplicate') {
                    duplicatesLIM++;
                } else if (result.reason === 'trigger_rejected') {
                    rejectedLIM++;
                } else {
                    errorsLIM++;
                }
            }

            console.log(`\n✅ Limón completado:`);
            console.log(`   Insertados:  ${insertedLIM}`);
            console.log(`   Duplicados:  ${duplicatesLIM}`);
            console.log(`   Rechazados:  ${rejectedLIM}`);
            console.log(`   Errores:     ${errorsLIM}\n`);

            // ===========================================
            // RESUMEN FINAL
            // ===========================================
            console.log('========================================');
            console.log('RESUMEN FINAL');
            console.log('========================================');
            console.log(`Total clientes origen:     ${customers.length}`);
            console.log('');
            console.log('San José:');
            console.log(`  ✅ Insertados:           ${insertedSJ}`);
            console.log(`  ⏭️  Duplicados:           ${duplicatesSJ}`);
            console.log(`  ⚠️  Rechazados (trigger): ${rejectedSJ}`);
            console.log(`  ❌ Errores:              ${errorsSJ}`);
            console.log('');
            console.log('Limón:');
            console.log(`  ✅ Insertados:           ${insertedLIM}`);
            console.log(`  ⏭️  Duplicados:           ${duplicatesLIM}`);
            console.log(`  ⚠️  Rechazados (trigger): ${rejectedLIM}`);
            console.log(`  ❌ Errores:              ${errorsLIM}`);
            console.log('========================================\n');

            // Advertencia sobre triggers
            if (rejectedSJ > 0 || rejectedLIM > 0) {
                console.log('⚠️  NOTA: Algunos clientes fueron rechazados por triggers.');
                console.log('   Para copiar TODOS los clientes, deshabilita los triggers:');
                console.log('   USE WWI_Sucursal_SJ; DISABLE TRIGGER Sales.trg_Customers_SJ_ValidateRegion ON Sales.Customers_SJ;');
                console.log('   USE WWI_Sucursal_LIM; DISABLE TRIGGER Sales.trg_Customers_LIM_ValidateRegion ON Sales.Customers_LIM;\n');
            }

            return {
                success: true,
                message: 'Distribución completa exitosa',
                summary: {
                    totalOrigen: customers.length,
                    sanJose: {
                        insertados: insertedSJ,
                        duplicados: duplicatesSJ,
                        rechazados: rejectedSJ,
                        errores: errorsSJ
                    },
                    limon: {
                        insertados: insertedLIM,
                        duplicados: duplicatesLIM,
                        rechazados: rejectedLIM,
                        errores: errorsLIM
                    }
                },
                timestamp: new Date().toISOString()
            };

        } catch (error) {
            console.error('\n❌ ERROR EN LA DISTRIBUCIÓN:', error.message);
            console.error(error.stack);
            return {
                success: false,
                message: 'Error en la distribución de clientes',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        } finally {
            console.log('Cerrando conexiones...');
            if (corpPool) await corpPool.close();
            if (sjPool)   await sjPool.close();
            if (limPool)  await limPool.close();
            console.log('✅ Conexiones cerradas\n');
        }
    }
}

module.exports = ClientDistributor;