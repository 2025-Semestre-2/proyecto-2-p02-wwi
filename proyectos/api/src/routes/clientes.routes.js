// routes/clientes.routes.js
const express = require('express');
const router = express.Router();
const { execProc, sql } = require('../db/exec');

router.get('/', async (req, res) => {
  try {
    const { q=null, sucursal=null, page=1, pageSize=50, orderBy='CustomerName' } = req.query;
    const rows = await execProc('Sales.sp_Api_GetClientes', {
      q:         { type: sql.NVarChar(100), value: q },
      sucursal:  { type: sql.NVarChar(20),  value: sucursal },
      page:      { type: sql.Int,           value: Number(page)  || 1 },
      pageSize:  { type: sql.Int,           value: Number(pageSize) || 50 },
      orderBy:   { type: sql.NVarChar(50),  value: orderBy }
    }, { sucursal: 'corporativo' });
    res.json({ data: rows });
  } catch (err) {
    console.error('GET /clientes', err);
    res.status(500).json({ error: 'Error al obtener clientes' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const id = Number(req.params.id);
    const role = req.query.role || 'SUCURSAL';

    const rows = await execProc('Sales.sp_Api_GetClienteById', {
      CustomerID: { type: sql.Int, value: id },
      UserRole:   { type: sql.NVarChar(50), value: role }
    }, { sucursal: 'corporativo' });

    if (!rows.length) return res.status(404).json({ error: 'Cliente no encontrado' });
    res.json(rows[0]);
  } catch (err) {
    console.error('GET /clientes/:id', err);
    res.status(500).json({ error: 'Error al obtener cliente' });
  }
});

router.post('/', async (req, res) => {
  try {
    const b = req.body || {};
    const params = {
      CustomerID:                 { type: sql.Int,          value: b.CustomerID },
      CustomerName:               { type: sql.NVarChar(100),value: b.CustomerName },
      CustomerCategoryID:         { type: sql.Int,          value: b.CustomerCategoryID },
      PrimaryContactPersonID:     { type: sql.Int,          value: b.PrimaryContactPersonID },
      DeliveryMethodID:           { type: sql.Int,          value: b.DeliveryMethodID },
      DeliveryCityID:             { type: sql.Int,          value: b.DeliveryCityID },
      PostalCityID:               { type: sql.Int,          value: b.PostalCityID },
      BuyingGroupID:              { type: sql.Int,          value: b.BuyingGroupID ?? null },
      AlternateContactPersonID:   { type: sql.Int,          value: b.AlternateContactPersonID ?? null },
      BillToCustomerID:           { type: sql.Int,          value: b.BillToCustomerID },
      CreditLimit:                { type: sql.Decimal(18,2),value: b.CreditLimit ?? null },
      AccountOpenedDate:          { type: sql.Date,         value: b.AccountOpenedDate },
      StandardDiscountPercentage: { type: sql.Decimal(18,3),value: b.StandardDiscountPercentage ?? 0 },
      IsStatementSent:            { type: sql.Bit,          value: !!b.IsStatementSent },
      IsOnCreditHold:             { type: sql.Bit,          value: !!b.IsOnCreditHold },
      PaymentDays:                { type: sql.Int,          value: b.PaymentDays ?? 0 },
      WebsiteURL:                 { type: sql.NVarChar(256),value: b.WebsiteURL ?? '' },
      DeliveryAddressLine1:       { type: sql.NVarChar(60), value: b.DeliveryAddressLine1 },
      DeliveryAddressLine2:       { type: sql.NVarChar(60), value: b.DeliveryAddressLine2 ?? null },
      DeliveryPostalCode:         { type: sql.NVarChar(10), value: b.DeliveryPostalCode ?? '' },
      PostalAddressLine1:         { type: sql.NVarChar(60), value: b.PostalAddressLine1 ?? '' },
      PostalAddressLine2:         { type: sql.NVarChar(60), value: b.PostalAddressLine2 ?? null },
      PostalPostalCode:           { type: sql.NVarChar(10), value: b.PostalPostalCode ?? '' },
      LastEditedBy:               { type: sql.Int,          value: b.LastEditedBy ?? 1 }
    };

    const result = await execProc('Sales.sp_Api_UpsertClientePublico', params, { sucursal: 'corporativo' });
    res.status(201).json({ ok: true, result });
  } catch (err) {
    console.error('POST /clientes', err);
    if (/GENERATED ALWAYS/i.test(err.message)) {
      return res.status(400).json({ error: 'No inserte columnas GENERATED ALWAYS; omitalas del payload.' });
    }
    res.status(500).json({ error: 'Error al crear/actualizar cliente' });
  }
});

router.patch('/:id/sensibles', async (req, res) => {
  try {
    const id = Number(req.params.id);
    const role = (req.query.role || '').toString();
    if (!role) return res.status(403).json({ error: 'Role requerido' });

    const b = req.body || {};
    const rows = await execProc('Sales.sp_Api_UpdateClienteSensibles', {
      CustomerID:   { type: sql.Int, value: id },
      UserRole:     { type: sql.NVarChar(50), value: role },
      PhoneNumber:  { type: sql.NVarChar(20), value: b.PhoneNumber ?? null },
      FaxNumber:    { type: sql.NVarChar(20), value: b.FaxNumber ?? null },
      WebsiteURL:   { type: sql.NVarChar(256),value: b.WebsiteURL ?? null },
      CreditLimit:  { type: sql.Decimal(18,2),value: b.CreditLimit ?? null },
      PostalCode:   { type: sql.NVarChar(10), value: b.PostalPostalCode ?? null }
    }, { sucursal: 'corporativo' });

    res.json({ ok:true, result: rows });
  } catch (err) {
    console.error('PATCH /clientes/:id/sensibles', err);
    res.status(500).json({ error: 'Error al actualizar datos sensibles' });
  }
});

module.exports = router;
