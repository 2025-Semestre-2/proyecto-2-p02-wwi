// app.api.js
const express = require('express');
const morgan = require('morgan');

const clientes = require('./routes/clientes.routes');
const productos = require('./routes/productos.routes');
const facturas  = require('./routes/facturas.routes');
const ordenes   = require('./routes/ordenes.routes');

const app = express();
app.use(express.json());
app.use(morgan('dev'));

app.get('/health', (req,res)=> res.json({ ok: true, ts: new Date().toISOString() }));

app.use('/api/clientes', clientes);
app.use('/api/productos', productos);
app.use('/api/facturas',  facturas);
app.use('/api/ordenes-compra', ordenes);

app.use((req,res)=> res.status(404).json({ error:'No encontrado'}));

const PORT = process.env.PORT || 3000;
app.listen(PORT, ()=> console.log(`API (nuevo bootstrap) en http://localhost:${PORT}`));
