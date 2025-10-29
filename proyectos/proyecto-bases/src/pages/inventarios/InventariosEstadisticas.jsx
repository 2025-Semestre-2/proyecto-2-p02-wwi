import React, { useState, useEffect } from 'react';
import { BarChart3, Search, RefreshCw, Trash2, AlertCircle, RotateCcw, Hash, Info } from 'lucide-react';
import InventariosService from '../../services/inventariosService';
import styles from './Inventarios.module.css';

const InventariosEstadisticas = ({ stockGroups }) => {
    const [estadisticas, setEstadisticas] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [searchText, setSearchText] = useState('');
    const [selectedStockGroup, setSelectedStockGroup] = useState('');

    useEffect(() => {
        loadEstadisticas();
    // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const loadEstadisticas = async () => {
        setLoading(true);
        setError(null);

        try {
            const params = {
                searchText: searchText || undefined,
                stockGroup: selectedStockGroup || undefined
            };

            const response = await InventariosService.getInventariosEstadisticas(params);

            if (response.success) {
                // Si la respuesta es un array de arrays, tomar el primero
                const flatData = Array.isArray(response.data) && Array.isArray(response.data[0]) ? response.data[0] : response.data;
                setEstadisticas(flatData);
            } else {
                setError('Error al cargar las estadísticas');
            }
        } catch (error) {
            console.error('Error cargando estadísticas:', error);
            setError('Error al cargar las estadísticas: ' + error.message);
        } finally {
            setLoading(false);
        }
    };

    const handleSearch = () => {
        loadEstadisticas();
    };

    const handleClearFilters = () => {
        setSearchText('');
        setSelectedStockGroup('');
        setTimeout(() => loadEstadisticas(), 100);
    };

    const formatCurrency = (value) => {
        return new Intl.NumberFormat('es-CR', {
            style: 'currency',
            currency: 'CRC'
        }).format(value);
    };

    const formatQuantity = (value) => {
        return new Intl.NumberFormat('es-CR').format(value);
    };

    const isRollupRow = (row) => {
        return row.StockGroupName === null || row.StockGroupName === 'TOTAL GENERAL';
    };

    return (
        <div className={styles.estadisticasContainer}>
            <div className={styles.estadisticasHeader}>
                <h3><BarChart3 className={styles.headerIcon} /> Estadísticas de Inventario con ROLLUP</h3>
                <p>Resumen agrupado por categorías de productos</p>
            </div>

            {/* Filtros */}
            <div className={styles.filtersSection}>
                <h4><Search className={styles.filterIcon} /> Filtros</h4>
                <div className={styles.filtersGrid}>
                    <div className={styles.filterGroup}>
                        <label>Buscar producto:</label>
                        <input
                            type="text"
                            value={searchText}
                            onChange={(e) => setSearchText(e.target.value)}
                            placeholder="Nombre del producto..."
                            className={styles.filterInput}
                        />
                    </div>

                    <div className={styles.filterGroup}>
                        <label>Grupo de stock:</label>
                        <select
                            value={selectedStockGroup}
                            onChange={(e) => setSelectedStockGroup(e.target.value)}
                            className={styles.filterSelect}
                        >
                            <option value="">Todos los grupos</option>
                            {stockGroups.map((group) => (
                                <option key={group.StockGroupID} value={group.StockGroupName}>
                                    {group.StockGroupName}
                                </option>
                            ))}
                        </select>
                    </div>
                </div>

                <div className={styles.filterActions}>
                    <button 
                        onClick={handleSearch} 
                        className={styles.searchButton}
                        disabled={loading}
                    >
                        {loading ? <><RotateCcw className={styles.buttonIcon} /> Cargando...</> : <><Search className={styles.buttonIcon} /> Aplicar Filtros</>}
                    </button>
                    <button 
                        onClick={handleClearFilters} 
                        className={styles.clearButton}
                    >
                        <Trash2 className={styles.buttonIcon} /> Limpiar Filtros
                    </button>
                </div>
            </div>

            {/* Error */}
            {error && (
                <div className={styles.error}>
                    <AlertCircle className={styles.errorIcon} /> {error}
                </div>
            )}

            {/* Loading */}
            {loading && (
                <div className={styles.loading}>
                    <RotateCcw className={styles.loadingIcon} /> Cargando estadísticas...
                </div>
            )}

            {/* Tabla de estadísticas */}
            {!loading && estadisticas.length > 0 && (
                <div className={styles.estadisticasTable}>
                    <table className={styles.table}>
                        <thead>
                            <tr>
                                <th>Grupo de Stock</th>
                                <th>Total Productos</th>
                                <th>Cantidad Total en Stock</th>
                                <th>Valor Total Inventario</th>
                                <th>Precio Promedio</th>
                                <th>Stock Promedio</th>
                            </tr>
                        </thead>
                        <tbody>
                            {estadisticas.map((row, index) => (
                                <tr 
                                    key={index}
                                    className={isRollupRow(row) ? styles.rollupRow : styles.normalRow}
                                >
                                    <td className={isRollupRow(row) ? styles.rollupCell : ''}>
                                        {isRollupRow(row) ? 
                                            <strong><Hash className={styles.rollupIcon} /> TOTAL GENERAL</strong> : 
                                            row.StockGroupName
                                        }
                                    </td>
                                    <td className={isRollupRow(row) ? styles.rollupCell : ''}>
                                        {isRollupRow(row) ? 
                                            <strong>{formatQuantity(row.TotalProductos)}</strong> : 
                                            formatQuantity(row.TotalProductos)
                                        }
                                    </td>
                                    <td className={isRollupRow(row) ? styles.rollupCell : ''}>
                                        {isRollupRow(row) ? 
                                            <strong>{formatQuantity(row.CantidadTotalStock)}</strong> : 
                                            formatQuantity(row.CantidadTotalStock)
                                        }
                                    </td>
                                    <td className={isRollupRow(row) ? styles.rollupCell : ''}>
                                        {isRollupRow(row) ? 
                                            <strong>{formatCurrency(row.ValorTotalInventario)}</strong> : 
                                            formatCurrency(row.ValorTotalInventario)
                                        }
                                    </td>
                                    <td className={isRollupRow(row) ? styles.rollupCell : ''}>
                                        {isRollupRow(row) ? 
                                            <strong>{formatCurrency(row.PrecioPromedio)}</strong> : 
                                            formatCurrency(row.PrecioPromedio)
                                        }
                                    </td>
                                    <td className={isRollupRow(row) ? styles.rollupCell : ''}>
                                        {isRollupRow(row) ? 
                                            <strong>{formatQuantity(row.StockPromedio)}</strong> : 
                                            formatQuantity(row.StockPromedio)
                                        }
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}

            {/* Sin resultados */}
            {!loading && estadisticas.length === 0 && !error && (
                <div className={styles.noResults}>
                    <BarChart3 className={styles.noResultsIcon} /> No se encontraron estadísticas con los filtros aplicados
                </div>
            )}

            {/* Explicación del ROLLUP */}
            <div className={styles.rollupExplanation}>
                <h4><Info className={styles.infoIcon} /> Acerca de las Estadísticas con ROLLUP</h4>
                <p>
                    Esta tabla utiliza la función <strong>ROLLUP</strong> de SQL Server para generar 
                    subtotales automáticamente. Las filas marcadas como <strong>"TOTAL GENERAL"</strong> 
                    representan los totales consolidados de todos los grupos.
                </p>
                <ul>
                    <li><strong>Total Productos:</strong> Número de productos únicos</li>
                    <li><strong>Cantidad Total en Stock:</strong> Suma de todas las cantidades disponibles</li>
                    <li><strong>Valor Total Inventario:</strong> Valor monetario total del inventario</li>
                    <li><strong>Precio Promedio:</strong> Precio promedio ponderado por grupo</li>
                    <li><strong>Stock Promedio:</strong> Cantidad promedio en stock por producto</li>
                </ul>
            </div>
        </div>
    );
};

export default InventariosEstadisticas;
