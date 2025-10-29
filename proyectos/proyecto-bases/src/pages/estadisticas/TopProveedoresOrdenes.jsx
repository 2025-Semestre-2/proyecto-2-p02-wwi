import React, { useState, useEffect } from 'react';
import EstadisticasService from '../../services/estadisticasService';
import { BarChart3, Search, RefreshCw, AlertCircle } from 'lucide-react';
import styles from './Estadisticas.module.css';

function TopProveedoresOrdenes() {
  const [sortOrder, setSortOrder] = useState('desc'); // 'asc' | 'desc'
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [estadisticas, setEstadisticas] = useState([]);
  const [anioInicio, setAnioInicio] = useState('');
  const [anioFin, setAnioFin] = useState('');
  const [aniosDisponibles, setAniosDisponibles] = useState([]);
  // Filtros de rango
  const [minOrdenes, setMinOrdenes] = useState('');
  const [maxOrdenes, setMaxOrdenes] = useState('');
  const [minMonto, setMinMonto] = useState('');
  const [maxMonto, setMaxMonto] = useState('');

  // Cargar años disponibles
  useEffect(() => {
    const loadAnios = async () => {
      try {
        const response = await EstadisticasService.getAniosDisponibles();
        console.log('Respuesta API años:', response);
        
        // Los datos vienen en response.data[0] (array doble)
        let rawData = response.data || response;
        if (Array.isArray(rawData) && rawData.length > 0 && Array.isArray(rawData[0])) {
          rawData = rawData[0];
        }
        
        // Normalizar los años a un array simple de objetos {anio: valor}
        const processedAnios = Array.isArray(rawData) ? rawData.map(item => ({
          anio: item.Anio || item.anio || item
        })) : [];
        
        setAniosDisponibles(processedAnios);
        console.log('Años disponibles procesados:', processedAnios);
      } catch (err) {
        console.error('Error cargando años disponibles:', err);
        setAniosDisponibles([]);
      }
    };
    
    loadAnios();
  }, []);

  const loadEstadisticas = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const response = await EstadisticasService.getTopProveedoresOrdenes({ anioInicio, anioFin });
      console.log('Respuesta API top proveedores:', response);
      
      // Los datos vienen en response.data[0] (array doble)
      let rawData = response.data || response;
      if (Array.isArray(rawData) && rawData.length > 0 && Array.isArray(rawData[0])) {
        rawData = rawData[0];
      }
      
      // Mapear los datos al formato esperado
      const processedData = Array.isArray(rawData) ? rawData.map(row => ({
        proveedor: row.NombreProveedor || row.nombreProveedor || row.Proveedor || row.proveedor || 'N/A',
        cantidadOrdenes: row.CantidadOrdenesCompra ?? row.cantidadOrdenesCompra ?? row.CantidadOrdenes ?? row.cantidadOrdenes ?? 0,
        montoTotal: row.MontoTotal ?? row.montoTotal ?? 0,
        anio: row.Anio || row.anio || 'N/A',
        ranking: row.Ranking || row.ranking || '-'
      })) : [];

      setEstadisticas(processedData);
      console.log('Top proveedores órdenes procesados:', processedData);
    } catch (err) {
      console.error('Error cargando top proveedores:', err);
      setError('Error al cargar las estadísticas de proveedores órdenes.');
      setEstadisticas([]);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadEstadisticas();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleSearch = (e) => {
    e.preventDefault();
    loadEstadisticas();
  };

  const handleReset = () => {
    setAnioInicio('');
    setAnioFin('');
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
    const ordenes = Number(row.cantidadOrdenes ?? row.CantidadOrdenes ?? row.CantidadOrdenesCompra ?? 0);
    const monto = Number(row.montoTotal ?? row.MontoTotal ?? 0);
    let cumple = true;
    if (minOrdenes !== '' && !isNaN(Number(minOrdenes))) cumple = cumple && ordenes >= Number(minOrdenes);
    if (maxOrdenes !== '' && !isNaN(Number(maxOrdenes))) cumple = cumple && ordenes <= Number(maxOrdenes);
    if (minMonto !== '' && !isNaN(Number(minMonto))) cumple = cumple && monto >= Number(minMonto);
    if (maxMonto !== '' && !isNaN(Number(maxMonto))) cumple = cumple && monto <= Number(maxMonto);
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
        <BarChart3 size={22} /> Top 5 Proveedores con Más Órdenes de Compra
      </h2>
  <form className={styles.filters} onSubmit={handleSearch}>
        <div className={styles.filterGroup}>
          <label>Año Inicio</label>
          <select
            className={styles.filterSelect}
            value={anioInicio}
            onChange={e => setAnioInicio(e.target.value)}
          >
            <option value="">Todos</option>
            {aniosDisponibles.map((a, idx) => (
              <option key={idx} value={a.anio}>{a.anio}</option>
            ))}
          </select>
        </div>
        <div className={styles.filterGroup}>
          <label>Año Fin</label>
          <select
            className={styles.filterSelect}
            value={anioFin}
            onChange={e => setAnioFin(e.target.value)}
          >
            <option value="">Todos</option>
            {aniosDisponibles.map((a, idx) => (
              <option key={idx} value={a.anio}>{a.anio}</option>
            ))}
          </select>
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
          <label>Monto Total (min)</label>
          <input
            className={styles.filterInput}
            type="number"
            min="0"
            value={minMonto}
            onChange={e => setMinMonto(e.target.value)}
            placeholder="Mínimo"
          />
        </div>
        <div className={styles.filterGroup}>
          <label>Monto Total (max)</label>
          <input
            className={styles.filterInput}
            type="number"
            min="0"
            value={maxMonto}
            onChange={e => setMaxMonto(e.target.value)}
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
        <div style={{overflowX:'auto'}}>
          {anioInicio === '' && anioFin === '' ? (
            // Ranking global (sin filtro de año)
            <table className={styles.table} style={{width:'100%', minWidth: '700px'}}>
              <thead>
                <tr>
                  <th>Ranking</th>
                  <th>Proveedor</th>
                  <th>Cantidad Órdenes</th>
                  <th>Monto Total</th>
                  <th>Año</th>
                </tr>
              </thead>
              <tbody>
                {estadisticasFiltradas.slice(0, 5).map((row, idx) => (
                  <tr key={idx}>
                    <td>{idx + 1}</td>
                    <td>{row.proveedor}</td>
                    <td>{row.cantidadOrdenes.toLocaleString('es-US')}</td>
                    <td>{formatCurrency(row.montoTotal)}</td>
                    <td>{row.anio}</td>
                  </tr>
                ))}
                {estadisticasFiltradas.length === 0 && (
                  <tr><td colSpan={5} style={{textAlign:'center'}}>No hay datos para mostrar</td></tr>
                )}
              </tbody>
            </table>
          ) : (
            // Ranking por año (agrupado visualmente)
            (() => {
              // Agrupar por año
              const grouped = {};
              estadisticasFiltradas.forEach(row => {
                if (!grouped[row.anio]) grouped[row.anio] = [];
                grouped[row.anio].push(row);
              });
              return Object.keys(grouped).sort((a, b) => b - a).map(anioKey => (
                <div key={anioKey} style={{marginBottom: 24}}>
                  <div style={{fontWeight:'bold', fontSize:16, margin:'8px 0'}}>{`Año: ${anioKey}`}</div>
                  <table className={styles.table} style={{width:'100%', minWidth: '700px'}}>
                    <thead>
                      <tr>
                        <th>Ranking</th>
                        <th>Proveedor</th>
                        <th>Cantidad Órdenes</th>
                        <th>Monto Total</th>
                        <th>Año</th>
                      </tr>
                    </thead>
                    <tbody>
                      {grouped[anioKey].slice(0, 5).map((row, idx) => (
                        <tr key={idx}>
                          <td>{idx + 1}</td>
                          <td>{row.proveedor}</td>
                          <td>{row.cantidadOrdenes.toLocaleString('es-US')}</td>
                          <td>{formatCurrency(row.montoTotal)}</td>
                          <td>{row.anio}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ));
            })()
          )}
        </div>
      )}
    </section>
  );
}

export default TopProveedoresOrdenes;