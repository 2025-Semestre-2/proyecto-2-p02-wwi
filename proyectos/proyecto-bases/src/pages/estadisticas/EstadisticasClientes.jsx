import React, { useState, useEffect } from 'react';
import EstadisticasService from '../../services/estadisticasService';
import { Users, Search, RefreshCw, AlertCircle } from 'lucide-react';
import styles from './Estadisticas.module.css';

function EstadisticasClientes() {
  const [sortOrder, setSortOrder] = useState('desc'); // 'asc' | 'desc'
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [data, setData] = useState([]);
  const [filters, setFilters] = useState({
    searchTextCliente: '',
    searchTextCategoria: ''
  });
  // Filtros de rango
  const [minFacturas, setMinFacturas] = useState('');
  const [maxFacturas, setMaxFacturas] = useState('');
  const [minVentas, setMinVentas] = useState('');
  const [maxVentas, setMaxVentas] = useState('');

  const loadData = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const response = await EstadisticasService.getEstadisticasVentasClientes(filters);
      // Los datos pueden venir en response.data[0] (array doble)
      let rawData = response.data || response;
      if (Array.isArray(rawData) && rawData.length > 0 && Array.isArray(rawData[0])) {
        rawData = rawData[0];
      }
      // Filtrar solo los que NO son "TOTAL" en categoría
      const filteredData = Array.isArray(rawData)
        ? rawData.filter(row => (row.Categoria || row.categoria) !== 'TOTAL')
        : [];
      // Mapear los datos al formato esperado
      const processedData = filteredData.map(row => ({
        cliente: row.NombreCliente || row.nombreCliente || row.Cliente || row.cliente || 'N/A',
        categoria: row.Categoria || row.categoria || 'N/A',
        totalVentas: row.MontoTotalVenta ?? row.montoTotalVenta ?? row.TotalVentas ?? row.totalVentas ?? 0,
        cantidadFacturas: row.CantidadFacturas ?? row.cantidadFacturas ?? 0,
        moneda: row.Moneda || row.moneda || 'USD'
      }));
      setData(processedData);
    } catch (err) {
      setError('Error al cargar las estadísticas de clientes:' + (err.message || ''));
      setData([]);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleInputChange = (e) => {
    setFilters({ ...filters, [e.target.name]: e.target.value });
  };

  const handleSearch = (e) => {
    e.preventDefault();
    loadData();
  };

  const handleReset = () => {
    setFilters({ searchTextCliente: '', searchTextCategoria: '' });
    setTimeout(loadData, 0);
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('es-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2
    }).format(amount);
  };

  // Filtrado por rango en frontend
  let dataFiltrada = data.filter(row => {
    const facturas = Number(row.cantidadFacturas ?? row.CantidadFacturas ?? 0);
    const ventas = Number(row.totalVentas ?? row.MontoTotalVenta ?? row.TotalVentas ?? 0);
    let cumple = true;
    if (minFacturas !== '' && !isNaN(Number(minFacturas))) cumple = cumple && facturas >= Number(minFacturas);
    if (maxFacturas !== '' && !isNaN(Number(maxFacturas))) cumple = cumple && facturas <= Number(maxFacturas);
    if (minVentas !== '' && !isNaN(Number(minVentas))) cumple = cumple && ventas >= Number(minVentas);
    if (maxVentas !== '' && !isNaN(Number(maxVentas))) cumple = cumple && ventas <= Number(maxVentas);
    return cumple;
  });

  // Ordenar según el botón
  if (sortOrder === 'asc') {
    dataFiltrada = [...dataFiltrada].sort((a, b) => (a.cantidadFacturas ?? 0) - (b.cantidadFacturas ?? 0));
  } else {
    dataFiltrada = [...dataFiltrada].sort((a, b) => (b.cantidadFacturas ?? 0) - (a.cantidadFacturas ?? 0));
  }

  const handleSortToggle = () => {
    setSortOrder(prev => prev === 'desc' ? 'asc' : 'desc');
  };

  return (
    <section>
      <h2 className={styles.sectionTitle}>
        <Users size={22} /> Ventas a Clientes
      </h2>
  <form className={styles.filters} onSubmit={handleSearch}>
        <div className={styles.filterGroup}>
          <label>Cliente</label>
          <input
            className={styles.filterInput}
            type="text"
            name="searchTextCliente"
            value={filters.searchTextCliente}
            onChange={handleInputChange}
            placeholder="Buscar cliente..."
          />
        </div>
        <div className={styles.filterGroup}>
          <label>Categoría</label>
          <input
            className={styles.filterInput}
            type="text"
            name="searchTextCategoria"
            value={filters.searchTextCategoria}
            onChange={handleInputChange}
            placeholder="Buscar categoría..."
          />
        </div>
        <div className={styles.filterGroup}>
          <label>Cant. Facturas (min)</label>
          <input
            className={styles.filterInput}
            type="number"
            min="0"
            value={minFacturas}
            onChange={e => setMinFacturas(e.target.value)}
            placeholder="Mínimo"
          />
        </div>
        <div className={styles.filterGroup}>
          <label>Cant. Facturas (max)</label>
          <input
            className={styles.filterInput}
            type="number"
            min="0"
            value={maxFacturas}
            onChange={e => setMaxFacturas(e.target.value)}
            placeholder="Máximo"
          />
        </div>
        <div className={styles.filterGroup}>
          <label>Total Ventas (min)</label>
          <input
            className={styles.filterInput}
            type="number"
            min="0"
            value={minVentas}
            onChange={e => setMinVentas(e.target.value)}
            placeholder="Mínimo"
          />
        </div>
        <div className={styles.filterGroup}>
          <label>Total Ventas (max)</label>
          <input
            className={styles.filterInput}
            type="number"
            min="0"
            value={maxVentas}
            onChange={e => setMaxVentas(e.target.value)}
            placeholder="Máximo"
          />
        </div>
        <div className={styles.filterActions}>
          <button className={styles.searchButton} type="submit" disabled={isLoading}>
            <Search size={16} /> Buscar
          </button>
          <button className={styles.clearButton} type="button" onClick={handleReset} disabled={isLoading}>
            <RefreshCw size={16} /> Limpiar
          </button>
        </div>
      </form>
      <div style={{marginBottom:12}}>
        <button className={styles.searchButton} type="button" onClick={handleSortToggle}>
          Orden: {sortOrder === 'asc' ? 'Ascendente' : 'Descendente'}
        </button>
      </div>
      {isLoading ? (
        <div className={styles.loadingContainer}>
          <div className={styles.loadingSpinner}></div>
          <span className={styles.loadingText}>Cargando estadísticas...</span>
        </div>
      ) : error ? (
        <div className={styles.errorContainer}>
          <AlertCircle size={40} className={styles.errorIcon} />
          <h3 className={styles.errorTitle}>Error</h3>
          <p className={styles.errorMessage}>{error}</p>
          <button className={styles.searchButton} onClick={loadData}>
            <RefreshCw size={16} /> Reintentar
          </button>
        </div>
      ) : (
        <div style={{ overflowX: 'auto' }}>
          <table className={styles.table} style={{ width: '100%', minWidth: '700px' }}>
            <thead>
              <tr>
                <th>Cliente</th>
                <th>Categoría</th>
                <th>Cantidad Facturas</th>
                <th>Total Ventas</th>
              </tr>
            </thead>
            <tbody>
              {dataFiltrada.length > 0 ? dataFiltrada.map((row, idx) => (
                <tr key={idx}>
                  <td>{row.cliente}</td>
                  <td>{row.categoria}</td>
                  <td>{row.cantidadFacturas.toLocaleString('es-US')}</td>
                  <td>{formatCurrency(row.totalVentas)}</td>
                </tr>
              )) : (
                <tr><td colSpan={4} style={{ textAlign: 'center' }}>No hay datos para mostrar</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}

export default EstadisticasClientes;