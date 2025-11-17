// db/exec.js
const { getConnectionBySucursal, getCorporativoConnection, sql } = require('./database');

async function execProc(procName, params={}, {sucursal='corporativo'} = {}) {
  const pool = sucursal === 'corporativo'
    ? await getCorporativoConnection()
    : await getConnectionBySucursal(sucursal);

  const request = pool.request();
  for (const [name, def] of Object.entries(params)) {
    request.input(name, def.type, def.value);
  }
  const result = await request.execute(procName);
  return result.recordset ?? [];
}

async function execQuery(query, inputs={}, {sucursal='corporativo'} = {}) {
  const pool = sucursal === 'corporativo'
    ? await getCorporativoConnection()
    : await getConnectionBySucursal(sucursal);

  const request = pool.request();
  for (const [name, def] of Object.entries(inputs)) {
    request.input(name, def.type, def.value);
  }
  const result = await request.query(query);
  return result.recordset ?? [];
}

module.exports = {
  execProc, execQuery, sql
};
