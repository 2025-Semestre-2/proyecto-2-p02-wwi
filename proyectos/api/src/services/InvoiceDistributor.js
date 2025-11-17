// services/InvoiceDistributor.js
// Distribuye facturas y sus lineas desde WideWorldImporters hacia SJ y LIM,
// aplicando fragmentación por paridad (impar → SJ, par → Limón).
// Esta versión está limitada a procesar un máximo fijo de 2000 facturas.

require('dotenv').config();
const sql = require('mssql');

// Limite fijo
const MAX_INVOICES = 1000;

class InvoiceDistributor {
    constructor() {
        this.configs = {
            corporativo: {
                server: 'localhost',
                port: 1444,
                database: process.env.DB_CORP_SOURCE || 'WideWorldImporters',
                user: process.env.DB_CORP_USER,
                password: process.env.DB_CORP_PASSWORD,
                options: {
                    encrypt: false,
                    trustServerCertificate: true
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
                    trustServerCertificate: true
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
                    trustServerCertificate: true
                }
            }
        };
    }

    // ==========================================================
    // DISTRIBUIR FACTURAS
    // ==========================================================
    async distributeInvoices() {
        let corpPool, sjPool, limPool;

        try {
            console.log('=== Distribucion de facturas ===');
            console.log(`Procesando máximo de ${MAX_INVOICES} facturas`);

            // Conexión
            corpPool = await new sql.ConnectionPool(this.configs.corporativo).connect();
            sjPool   = await new sql.ConnectionPool(this.configs.sanJose).connect();
            limPool  = await new sql.ConnectionPool(this.configs.limon).connect();

            // ============================
            // 1. Extraer facturas (limitado)
            // ============================
            console.log('Leyendo facturas (TOP 1000) desde corporativo...');

            const invoicesResult = await corpPool.request().query(`
                SELECT TOP (${MAX_INVOICES})
                    InvoiceID, CustomerID, BillToCustomerID, OrderID,
                    DeliveryMethodID, ContactPersonID, AccountsPersonID,
                    SalespersonPersonID, PackedByPersonID, InvoiceDate,
                    CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason,
                    Comments, DeliveryInstructions, InternalComments,
                    TotalDryItems, TotalChillerItems, DeliveryRun, RunPosition,
                    ReturnedDeliveryData, ConfirmedDeliveryTime,
                    ConfirmedReceivedBy, LastEditedBy, LastEditedWhen
                FROM Sales.Invoices
                WHERE IsCreditNote = 0
                ORDER BY InvoiceID ASC;
            `);

            const invoices = invoicesResult.recordset;
            console.log(`Facturas obtenidas: ${invoices.length}`);

            if (invoices.length === 0) {
                return { success: true, message: "No hay facturas para procesar" };
            }

            // ============================
            // 2. Extraer líneas
            // ============================
            const idsList = invoices.map(f => f.InvoiceID).join(',');

            console.log("Leyendo líneas asociadas...");

            const linesResult = await corpPool.request().query(`
                SELECT InvoiceLineID, InvoiceID, StockItemID, Description,
                    PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount,
                    LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen
                FROM Sales.InvoiceLines
                WHERE InvoiceID IN (${idsList})
                ORDER BY InvoiceLineID;
            `);

            const lines = linesResult.recordset;
            console.log(`Líneas obtenidas: ${lines.length}`);

            // Mapear líneas por factura
            const linesMap = new Map();
            for (const ln of lines) {
                if (!linesMap.has(ln.InvoiceID)) linesMap.set(ln.InvoiceID, []);
                linesMap.get(ln.InvoiceID).push(ln);
            }

            // ============================
            // 3. Particionar por regla
            // ============================
            const invoicesSJ  = invoices.filter(f => f.InvoiceID % 2 === 1);
            const invoicesLIM = invoices.filter(f => f.InvoiceID % 2 === 0);

            console.log(`→ San Jose: ${invoicesSJ.length} facturas`);
            console.log(`→ Limon   : ${invoicesLIM.length} facturas`);

            // ============================
            // 4. Insertar
            // ============================
            let sjInv = 0, sjLines = 0;
            let limInv = 0, limLines = 0;

            // --- San José ---
            for (let f of invoicesSJ) {
                const ok = await this.insertInvoice(sjPool, f, "Sales.Invoices_SJ");
                if (ok) sjInv++;

                for (let ln of (linesMap.get(f.InvoiceID) || [])) {
                    if (await this.insertInvoiceLine(sjPool, ln, "Sales.InvoiceLines_SJ")) {
                        sjLines++;
                    }
                }
            }

            // --- Limón ---
            for (let f of invoicesLIM) {
                const ok = await this.insertInvoice(limPool, f, "Sales.Invoices_LIM");
                if (ok) limInv++;

                for (let ln of (linesMap.get(f.InvoiceID) || [])) {
                    if (await this.insertInvoiceLine(limPool, ln, "Sales.InvoiceLines_LIM")) {
                        limLines++;
                    }
                }
            }

            // ============================
            // 5. Resumen
            // ============================
            console.log('=== Distribución completada ===');
            console.log(`SJ:  Facturas ${sjInv} | Líneas ${sjLines}`);
            console.log(`LIM: Facturas ${limInv} | Líneas ${limLines}`);

            return {
                success: true,
                message: "Distribución de facturas completada",
                data: {
                    sourceInvoices: invoices.length,
                    sourceLines: lines.length,
                    sanJoseInvoices: sjInv,
                    sanJoseLines: sjLines,
                    limonInvoices: limInv,
                    limonLines: limLines
                }
            };

        } catch (error) {
            console.error("Error distribuyendo facturas:", error.message);
            return { success: false, error: error.message };
        } finally {
            if (corpPool) corpPool.close();
            if (sjPool) sjPool.close();
            if (limPool) limPool.close();
        }
    }

    // ============================================
    // Insertar factura
    // ============================================
    async insertInvoice(pool, inv, tableName) {
        const query = `
            IF NOT EXISTS (SELECT 1 FROM ${tableName} WHERE InvoiceID = @InvoiceID)
                INSERT INTO ${tableName} (
                    InvoiceID, CustomerID, BillToCustomerID, OrderID,
                    DeliveryMethodID, ContactPersonID, AccountsPersonID,
                    SalespersonPersonID, PackedByPersonID, InvoiceDate,
                    CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason,
                    Comments, DeliveryInstructions, InternalComments,
                    TotalDryItems, TotalChillerItems, DeliveryRun, RunPosition,
                    ReturnedDeliveryData, ConfirmedDeliveryTime,
                    ConfirmedReceivedBy, LastEditedBy
                )
                VALUES (
                    @InvoiceID, @CustomerID, @BillToCustomerID, @OrderID,
                    @DeliveryMethodID, @ContactPersonID, @AccountsPersonID,
                    @SalespersonPersonID, @PackedByPersonID, @InvoiceDate,
                    @CustomerPurchaseOrderNumber, @IsCreditNote, @CreditNoteReason,
                    @Comments, @DeliveryInstructions, @InternalComments,
                    @TotalDryItems, @TotalChillerItems, @DeliveryRun, @RunPosition,
                    @ReturnedDeliveryData, @ConfirmedDeliveryTime,
                    @ConfirmedReceivedBy, @LastEditedBy
                );
        `;

        try {
            await pool.request()
                .input("InvoiceID", sql.Int, inv.InvoiceID)
                .input("CustomerID", sql.Int, inv.CustomerID)
                .input("BillToCustomerID", sql.Int, inv.BillToCustomerID)
                .input("OrderID", sql.Int, inv.OrderID)
                .input("DeliveryMethodID", sql.Int, inv.DeliveryMethodID)
                .input("ContactPersonID", sql.Int, inv.ContactPersonID)
                .input("AccountsPersonID", sql.Int, inv.AccountsPersonID)
                .input("SalespersonPersonID", sql.Int, inv.SalespersonPersonID)
                .input("PackedByPersonID", sql.Int, inv.PackedByPersonID)
                .input("InvoiceDate", sql.Date, inv.InvoiceDate)
                .input("CustomerPurchaseOrderNumber", sql.NVarChar, inv.CustomerPurchaseOrderNumber)
                .input("IsCreditNote", sql.Bit, inv.IsCreditNote)
                .input("CreditNoteReason", sql.NVarChar, inv.CreditNoteReason)
                .input("Comments", sql.NVarChar, inv.Comments)
                .input("DeliveryInstructions", sql.NVarChar, inv.DeliveryInstructions)
                .input("InternalComments", sql.NVarChar, inv.InternalComments)
                .input("TotalDryItems", sql.Int, inv.TotalDryItems)
                .input("TotalChillerItems", sql.Int, inv.TotalChillerItems)
                .input("DeliveryRun", sql.NVarChar, inv.DeliveryRun)
                .input("RunPosition", sql.NVarChar, inv.RunPosition)
                .input("ReturnedDeliveryData", sql.NVarChar, inv.ReturnedDeliveryData)
                .input("ConfirmedDeliveryTime", sql.DateTime2, inv.ConfirmedDeliveryTime)
                .input("ConfirmedReceivedBy", sql.NVarChar, inv.ConfirmedReceivedBy)
                .input("LastEditedBy", sql.Int, inv.LastEditedBy)
                .query(query);

            return true;
        } catch (err) {
            console.log(`Error insertando factura ${inv.InvoiceID}: ${err.message}`);
            return false;
        }
    }

    // ============================================
    // Insertar línea
    // ============================================
    async insertInvoiceLine(pool, ln, tableName) {
        const query = `
            IF NOT EXISTS (SELECT 1 FROM ${tableName} WHERE InvoiceLineID = @InvoiceLineID)
                INSERT INTO ${tableName} (
                    InvoiceLineID, InvoiceID, StockItemID, Description,
                    PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount,
                    LineProfit, ExtendedPrice, LastEditedBy
                )
                VALUES (
                    @InvoiceLineID, @InvoiceID, @StockItemID, @Description,
                    @PackageTypeID, @Quantity, @UnitPrice, @TaxRate, @TaxAmount,
                    @LineProfit, @ExtendedPrice, @LastEditedBy
                );
        `;

        try {
            await pool.request()
                .input("InvoiceLineID", sql.Int, ln.InvoiceLineID)
                .input("InvoiceID", sql.Int, ln.InvoiceID)
                .input("StockItemID", sql.Int, ln.StockItemID)
                .input("Description", sql.NVarChar, ln.Description)
                .input("PackageTypeID", sql.Int, ln.PackageTypeID)
                .input("Quantity", sql.Int, ln.Quantity)
                .input("UnitPrice", sql.Decimal(18,2), ln.UnitPrice)
                .input("TaxRate", sql.Decimal(18,3), ln.TaxRate)
                .input("TaxAmount", sql.Decimal(18,2), ln.TaxAmount)
                .input("LineProfit", sql.Decimal(18,2), ln.LineProfit)
                .input("ExtendedPrice", sql.Decimal(18,2), ln.ExtendedPrice)
                .input("LastEditedBy", sql.Int, ln.LastEditedBy)
                .query(query);

            return true;
        } catch (err) {
            console.log(`Error insertando línea ${ln.InvoiceLineID}: ${err.message}`);
            return false;
        }
    }
}

module.exports = InvoiceDistributor;
