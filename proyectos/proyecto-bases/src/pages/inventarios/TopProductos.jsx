import React, { useState, useEffect } from 'react';
import { Trophy, Calendar, BarChart3, Search, RefreshCw, Trash2, AlertCircle, RotateCcw, Medal, Hash, Info } from 'lucide-react';
import InventariosService from '../../services/inventariosService';
import styles from './Inventarios.module.css';

const TopProductos = () => {
    const [topProductos, setTopProductos] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [anioInicio, setAnioInicio] = useState('');
    const [anioFin, setAnioFin] = useState('');

    useEffect(() => {
        // Cargar datos por defecto con el año actual
        const currentYear = new Date().getFullYear();
        setAnioInicio(currentYear - 2); // Últimos 2 años
        setAnioFin(currentYear);
        loadTopProductos();
    // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const loadTopProductos = async () => {
        setLoading(true);
        setError(null);

        try {
            const params = {
                anioInicio: anioInicio || undefined,
                anioFin: anioFin || undefined
            };

            const response = await InventariosService.getTopProductosPorVentas(params);

            if (response.success) {
                // Si la respuesta es un array de arrays, tomar el primero
                const flatData = Array.isArray(response.data) && Array.isArray(response.data[0]) ? response.data[0] : response.data;
                setTopProductos(flatData);
            } else {
                setError('Error al cargar el top de productos');
            }
        } catch (error) {
            console.error('Error cargando top productos:', error);
            setError('Error al cargar el top de productos: ' + error.message);
        } finally {
            setLoading(false);
        }
    };

    const handleSearch = () => {
        loadTopProductos();
    };

    const handleClearFilters = () => {
        const currentYear = new Date().getFullYear();
        setAnioInicio(currentYear - 2);
        setAnioFin(currentYear);
        setTimeout(() => loadTopProductos(), 100);
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

    const getRankingIcon = (ranking) => {
        switch (ranking) {
            case 1: return <Medal className={`${styles.rankIcon} ${styles.goldIcon}`} />;
            case 2: return <Medal className={`${styles.rankIcon} ${styles.silverIcon}`} />;
            case 3: return <Medal className={`${styles.rankIcon} ${styles.bronzeIcon}`} />;
            default: return <Hash className={styles.rankIcon} />;
        }
    };

    const getRankingClass = (ranking) => {
        switch (ranking) {
            case 1: return styles.goldRank;
            case 2: return styles.silverRank;
            case 3: return styles.bronzeRank;
            default: return styles.normalRank;
        }
    };

    // Agrupar productos por año
    const productosPorAnio = topProductos.reduce((acc, producto) => {
        const anio = producto.Anio;
        if (!acc[anio]) {
            acc[anio] = [];
        }
        acc[anio].push(producto);
        return acc;
    }, {});

    return (
        <div className={styles.topProductosContainer}>
            <div className={styles.topProductosHeader}>
                <h3><Trophy className={styles.headerIcon} /> Top 10 Productos Más Vendidos por Año</h3>
                <p>Ranking de productos utilizando DENSE_RANK para manejo de empates</p>
            </div>

            {/* Filtros */}
            <div className={styles.filtersSection}>
                <h4><Calendar className={styles.filterIcon} /> Filtros de Período</h4>
                <div className={styles.filtersGrid}>
                    <div className={styles.filterGroup}>
                        <label>Año de inicio:</label>
                        <input
                            type="number"
                            value={anioInicio}
                            onChange={(e) => setAnioInicio(e.target.value)}
                            placeholder="Ej: 2022"
                            min="2013"
                            max="2016"
                            className={styles.filterInput}
                        />
                    </div>

                    <div className={styles.filterGroup}>
                        <label>Año de fin:</label>
                        <input
                            type="number"
                            value={anioFin}
                            onChange={(e) => setAnioFin(e.target.value)}
                            placeholder="Ej: 2024"
                            min="2013"
                            max="2016"
                            className={styles.filterInput}
                        />
                    </div>
                </div>

                <div className={styles.filterActions}>
                    <button 
                        onClick={handleSearch} 
                        className={styles.searchButton}
                        disabled={loading}
                    >
                        {loading ? <><RotateCcw className={styles.buttonIcon} /> Cargando...</> : <><BarChart3 className={styles.buttonIcon} /> Generar Ranking</>}
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
                    <RotateCcw className={styles.loadingIcon} /> Generando ranking de productos...
                </div>
            )}

            {/* Rankings por año */}
            {!loading && Object.keys(productosPorAnio).length > 0 && (
                <div className={styles.rankingsPorAnio}>
                    {Object.keys(productosPorAnio)
                        .sort((a, b) => parseInt(b) - parseInt(a)) // Ordenar años descendente
                        .map(anio => (
                        <div key={anio} className={styles.anioSection}>
                            <div className={styles.anioHeader}>
                                <h4><Calendar className={styles.yearIcon} /> Año {anio}</h4>
                                <span className={styles.totalProductos}>
                                    {productosPorAnio[anio].length} productos en el ranking
                                </span>
                            </div>

                            <div className={styles.rankingGrid}>
                                {productosPorAnio[anio].map((producto) => (
                                    <div 
                                        key={`${anio}-${producto.StockItemID}`}
                                        className={`${styles.rankingCard} ${getRankingClass(producto.RankingVentas)}`}
                                    >
                                        <div className={styles.rankingHeader}>
                                            <div className={styles.rankingPosition}>
                                                {getRankingIcon(producto.RankingVentas)}
                                            </div>
                                            <div className={styles.rankingNumber}>
                                                Ranking #{producto.RankingVentas}
                                            </div>
                                        </div>

                                        <div className={styles.productInfo}>
                                            <h5>{producto.StockItemName}</h5>
                                            <p className={styles.productCode}>ID: {producto.StockItemID}</p>
                                        </div>

                                        <div className={styles.salesStats}>
                                            <div className={styles.statItem}>
                                                <span className={styles.statLabel}>Cantidad Vendida:</span>
                                                <span className={styles.statValue}>
                                                    {formatQuantity(producto.CantidadVendida)}
                                                </span>
                                            </div>
                                            <div className={styles.statItem}>
                                                <span className={styles.statLabel}>Ingresos Totales:</span>
                                                <span className={styles.statValue}>
                                                    {formatCurrency(producto.IngresosTotales)}
                                                </span>
                                            </div>
                                            <div className={styles.statItem}>
                                                <span className={styles.statLabel}>Precio Promedio:</span>
                                                <span className={styles.statValue}>
                                                    {formatCurrency(producto.PrecioPromedio)}
                                                </span>
                                            </div>
                                            <div className={styles.statItem}>
                                                <span className={styles.statLabel}>Total Órdenes:</span>
                                                <span className={styles.statValue}>
                                                    {formatQuantity(producto.TotalOrdenes)}
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Sin resultados */}
            {!loading && topProductos.length === 0 && !error && (
                <div className={styles.noResults}>
                    <Trophy className={styles.noResultsIcon} /> No se encontraron datos de ventas para el período seleccionado
                </div>
            )}

            {/* Explicación del DENSE_RANK */}
            <div className={styles.denseRankExplanation}>
                <h4><Info className={styles.infoIcon} /> Acerca del Ranking con DENSE_RANK</h4>
                <p>
                    Esta clasificación utiliza la función <strong>DENSE_RANK()</strong> de SQL Server 
                    para manejar correctamente los empates en las ventas:
                </p>
                <ul>
                    <li><strong>Sin saltos de posición:</strong> Si hay empate en la posición 2, la siguiente posición será 3 (no 4)</li>
                    <li><strong>Ranking por ingresos:</strong> Se ordena por ingresos totales descendente</li>
                    <li><strong>Top 10:</strong> Solo se muestran los primeros 10 productos por año</li>
                    <li><strong>Métricas incluidas:</strong> Cantidad vendida, ingresos totales, precio promedio y total de órdenes</li>
                </ul>
                <p>
                    <strong>Período disponible:</strong> Los datos de muestra van desde 2013 hasta 2016.
                </p>
            </div>
        </div>
    );
};

export default TopProductos;
