import React, { useState, useEffect } from 'react';
import EstadisticasService from '../../services/estadisticasService';
import { BarChart3, Search, RefreshCw, AlertCircle } from 'lucide-react';
import styles from './Estadisticas.module.css';

function EstadisticasProveedores() {
  const [sortOrder, setSortOrder] = useState('desc'); // 'asc' | 'desc'
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [estadisticas, setEstadisticas] = useState([]);
  const [filters, setFilters] = useState({
    searchTextProveedor: '',
    searchTextCategoria: ''
  });
  // Filtros de rango
  const [minOrdenes, setMinOrdenes] = useState('');
  const [maxOrdenes, setMaxOrdenes] = useState('');
  const [minTotal, setMinTotal] = useState('');
  const [maxTotal, setMaxTotal] = useState('');

  const loadEstadisticas = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const response = await EstadisticasService.getEstadisticasComprasProveedores(filters);
      // Los datos pueden venir en response.data[0] (array doble)
      let rawData = response.data || response;
      console.log('Raw data from API:', rawData);
      if (Array.isArray(rawData) && rawData.length > 0 && Array.isArray(rawData[0])) {
        rawData = rawData[0];
      }
      // Filtrar solo los que NO son "TOTAL" en categoría
      const filteredData = Array.isArray(rawData)
        ? rawData.filter(row => (row.Categoria || row.categoria) !== 'TOTAL')
        : [];
      // Mapear los datos al formato esperado
      const processedData = filteredData.map(row => ({
        proveedor: row.NombreProveedor || row.nombreProveedor || row.Proveedor || row.proveedor || 'N/A',
        categoria: row.Categoria || row.categoria || 'N/A',
        totalCompras: row.MontoTotalCompra ?? row.montoTotalCompra ?? row.TotalCompras ?? row.totalCompras ?? 0,
        cantidadOrdenes: row.CantidadOrdenes ?? row.cantidadOrdenes ?? 0,
        moneda: row.Moneda || row.moneda || 'USD'
      }));
      setEstadisticas(processedData);
    } catch (err) {
      setError('Error al cargar las estadísticas de proveedores.' + (err.message || ''));
      setEstadisticas([]);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadEstadisticas();
  }, []);

  const handleInputChange = (e) => {
    setFilters({ ...filters, [e.target.name]: e.target.value });
  };

  const handleSearch = (e) => {
    e.preventDefault();
    loadEstadisticas();
  };

  const handleReset = () => {
    setFilters({ searchTextProveedor: '', searchTextCategoria: '' });
    setTimeout(loadEstadisticas, 0);
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('es-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2
    }).format(amount);
  };

  // Filtrado por rango en frontend
  let estadisticasFiltradas = estadisticas.filter(row => {
    const ordenes = Number(row.cantidadOrdenes ?? row.CantidadOrdenes ?? 0);
    const total = Number(row.totalCompras ?? row.MontoTotalCompra ?? row.TotalCompras ?? 0);
    let cumple = true;
    if (minOrdenes !== '' && !isNaN(Number(minOrdenes))) cumple = cumple && ordenes >= Number(minOrdenes);
    if (maxOrdenes !== '' && !isNaN(Number(maxOrdenes))) cumple = cumple && ordenes <= Number(maxOrdenes);
    if (minTotal !== '' && !isNaN(Number(minTotal))) cumple = cumple && total >= Number(minTotal);
    if (maxTotal !== '' && !isNaN(Number(maxTotal))) cumple = cumple && total <= Number(maxTotal);
    return cumple;
  });

  // Ordenar según el botón
  if (sortOrder === 'asc') {
    estadisticasFiltradas = [...estadisticasFiltradas].sort((a, b) => (a.cantidadOrdenes ?? 0) - (b.cantidadOrdenes ?? 0));
  } else {
    estadisticasFiltradas = [...estadisticasFiltradas].sort((a, b) => (b.cantidadOrdenes ?? 0) - (a.cantidadOrdenes ?? 0));
  }

  const handleSortToggle = () => {
    setSortOrder(prev => prev === 'desc' ? 'asc' : 'desc');
  };

  return (
    <section>
      <h2 className={styles.sectionTitle}>
        <BarChart3 size={22} /> Compras a Proveedores
      </h2>
  <form className={styles.filters} onSubmit={handleSearch}>
        <div className={styles.filterGroup}>
          <label>Proveedor</label>
          <input
            className={styles.filterInput}
            type="text"
            name="searchTextProveedor"
            value={filters.searchTextProveedor}
            onChange={handleInputChange}
            placeholder="Buscar proveedor..."
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
          <label>Cant. Órdenes (min)</label>
          <input
            className={styles.filterInput}
            type="number"
            min="0"
            value={minOrdenes}
            onChange={e => setMinOrdenes(e.target.value)}
            placeholder="Mínimo"
          />
        </div>
        <div className={styles.filterGroup}>
          <label>Cant. Órdenes (max)</label>
          <input
            className={styles.filterInput}
            type="number"
            min="0"
            value={maxOrdenes}
            onChange={e => setMaxOrdenes(e.target.value)}
            placeholder="Máximo"
          />
        </div>
        <div className={styles.filterGroup}>
          <label>Total Compras (min)</label>
          <input
            className={styles.filterInput}
            type="number"
            min="0"
            value={minTotal}
            onChange={e => setMinTotal(e.target.value)}
            placeholder="Mínimo"
          />
        </div>
        <div className={styles.filterGroup}>
          <label>Total Compras (max)</label>
          <input
            className={styles.filterInput}
            type="number"
            min="0"
            value={maxTotal}
            onChange={e => setMaxTotal(e.target.value)}
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
          <button className={styles.searchButton} onClick={loadEstadisticas}>
            <RefreshCw size={16} /> Reintentar
          </button>
        </div>
      ) : (
        <div style={{ overflowX: 'auto' }}>
          <table className={styles.table} style={{ width: '100%', minWidth: '700px' }}>
            <thead>
              <tr>
                <th>Proveedor</th>
                <th>Categoría</th>
                <th>Cantidad Órdenes</th>
                <th>Total Compras</th>
                <th>Moneda</th>
              </tr>
            </thead>
            <tbody>
              {estadisticasFiltradas.length > 0 ? estadisticasFiltradas.map((row, idx) => (
                <tr key={idx}>
                  <td>{row.proveedor}</td>
                  <td>{row.categoria}</td>
                  <td>{row.cantidadOrdenes.toLocaleString('es-US')}</td>
                  <td>{formatCurrency(row.totalCompras)}</td>
                  <td>{row.moneda}</td>
                </tr>
              )) : (
                <tr><td colSpan={5} style={{ textAlign: 'center' }}>No hay datos para mostrar</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}

export default EstadisticasProveedores;