import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useSucursal } from '../../context/useSucursal';
import InventariosService from '../../services/inventariosService';
// import InventariosEstadisticas from './InventariosEstadisticas';
// import TopProductos from './TopProductos';
import styles from './Inventarios.module.css';
import {
    ArrowLeft,
    Search,
    Package,
    BarChart3,
    Trophy,
    AlertCircle,
    RotateCcw,
    Eye,
    Filter,
    RefreshCw,
    FileX,
    X,
    ChevronLeft,
    ChevronRight,
    Info,
    DollarSign,
    Hash,
    Database
} from 'lucide-react';

const Inventarios = () => {
    const navigate = useNavigate();
    const skipLinkRef = useRef(null);
    const { sucursalActiva } = useSucursal();
    
    // Helper para obtener color de sucursal
    const getSucursalColor = (id) => {
        const colors = { 1: '#1c4382', 2: '#b91016', 3: '#1c7e2f' };
        return colors[id] || '#1c4382';
    };
    
    // Estados principales
    const [stockItems, setStockItems] = useState([]);
    const [stockGroups, setStockGroups] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [selectedItem, setSelectedItem] = useState(null);

    // Estados de filtros
    const [searchText, setSearchText] = useState('');
    const [minQuantity, setMinQuantity] = useState('');
    const [maxQuantity, setMaxQuantity] = useState('');
    const [orderBy, setOrderBy] = useState('StockItemName');
    const [orderDirection, setOrderDirection] = useState('ASC');

    // Estados de paginación
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(20);
    const [totalPages, setTotalPages] = useState(1);
    const [totalRecords, setTotalRecords] = useState(0);

    // Estados de pestañas
    const [activeTab, setActiveTab] = useState('productos');

    useEffect(() => {
        if (sucursalActiva) {
            loadStockGroups();
            loadStockItems();
        }
    // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [sucursalActiva]);

    useEffect(() => {
        if (sucursalActiva) {
            loadStockItems();
        }
    // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [currentPage, pageSize, orderBy, orderDirection]);

    const loadStockGroups = async () => {
        try {
            const response = await InventariosService.getStockGroups(sucursalActiva.id);
            if (response.success) {
                setStockGroups(response.data);
            }
        } catch (error) {
            console.error('Error cargando grupos de stock:', error);
        }
    };

    const loadStockItems = async () => {
        setLoading(true);
        setError(null);

        try {
            const params = {
                searchText: searchText || undefined,
                minQuantity: minQuantity || undefined,
                maxQuantity: maxQuantity || undefined,
                orderBy,
                orderDirection,
                pageNumber: currentPage,
                pageSize
            };

            const response = await InventariosService.getStockItems(sucursalActiva.id, params);

            if (response.success) {
                setStockItems(response.data);
                if (response.pagination) {
                    setTotalPages(response.pagination.totalPages);
                    setTotalRecords(response.pagination.totalRecords);
                }
            } else {
                setError('Error al cargar los productos');
            }
        } catch (error) {
            console.error('Error cargando productos:', error);
            setError('Error al cargar los productos: ' + error.message);
        } finally {
            setLoading(false);
        }
    };

    const handleSearch = () => {
        setCurrentPage(1);
        loadStockItems();
    };

    const handleClearFilters = () => {
        setSearchText('');
        setMinQuantity('');
        setMaxQuantity('');
        setOrderBy('StockItemName');
        setOrderDirection('ASC');
        setCurrentPage(1);
        setTimeout(() => loadStockItems(), 100);
    };

    const handleItemClick = async (item) => {
        try {
            const response = await InventariosService.getStockItemById(item.StockItemID);
            if (response.success) {
                // Extraer el primer objeto si la respuesta es un array
                setSelectedItem(Array.isArray(response.data) ? response.data[0] : response.data);
            }
        } catch (error) {
            console.error('Error cargando detalles del producto:', error);
        }
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

    const renderProductList = () => (
        <div>
            {/* Sección de Filtros */}
            <section className={styles.filtersSection}>
                <h2 className={styles.sectionTitle}>
                    <Filter size={24} />
                    Filtros de Búsqueda
                </h2>
                
                <div className={styles.filters}>
                    {/* Búsqueda por texto */}
                    <div className={styles.searchContainer}>
                        <Search size={20} className={styles.searchIcon} />
                        <input
                            type="text"
                            value={searchText}
                            onChange={(e) => setSearchText(e.target.value)}
                            placeholder="Buscar por nombre de producto"
                            className={styles.searchInput}
                            aria-label="Buscar productos"
                        />
                    </div>

                    {/* Filtros adicionales */}
                    <div className={styles.filterGrid}>
                        <div className={styles.filterGroup}>
                            <label htmlFor="minQuantity">Cantidad mínima en stock:</label>
                            <input
                                id="minQuantity"
                                type="number"
                                value={minQuantity}
                                onChange={(e) => setMinQuantity(e.target.value)}
                                placeholder="Ej: 10"
                                className={styles.filterInput}
                                min="0"
                            />
                        </div>

                        <div className={styles.filterGroup}>
                            <label htmlFor="maxQuantity">Cantidad máxima en stock:</label>
                            <input
                                id="maxQuantity"
                                type="number"
                                value={maxQuantity}
                                onChange={(e) => setMaxQuantity(e.target.value)}
                                placeholder="Ej: 1000"
                                className={styles.filterInput}
                                min="0"
                            />
                        </div>

                        <div className={styles.filterGroup}>
                            <label htmlFor="orderBy">Ordenar por:</label>
                            <select
                                id="orderBy"
                                value={orderBy}
                                onChange={(e) => setOrderBy(e.target.value)}
                                className={styles.filterSelect}
                            >
                                <option value="StockItemName">Nombre</option>
                                <option value="QuantityOnHand">Cantidad en Stock</option>
                                <option value="UnitPrice">Precio</option>
                                <option value="StockGroupName">Grupo</option>
                            </select>
                        </div>

                        <div className={styles.filterGroup}>
                            <label htmlFor="orderDirection">Dirección:</label>
                            <select
                                id="orderDirection"
                                value={orderDirection}
                                onChange={(e) => setOrderDirection(e.target.value)}
                                className={styles.filterSelect}
                            >
                                <option value="ASC">Ascendente</option>
                                <option value="DESC">Descendente</option>
                            </select>
                        </div>

                        <div className={styles.filterGroup}>
                            <label htmlFor="pageSize">Productos por página:</label>
                            <select
                                id="pageSize"
                                value={pageSize}
                                onChange={(e) => {
                                    setPageSize(parseInt(e.target.value));
                                    setCurrentPage(1);
                                }}
                                className={styles.filterSelect}
                            >
                                <option value={10}>10</option>
                                <option value={20}>20</option>
                                <option value={50}>50</option>
                                <option value={100}>100</option>
                            </select>
                        </div>
                    </div>

                    {/* Botones de acción */}
                    <div className={styles.filterActions}>
                        <button 
                            onClick={handleSearch} 
                            className={styles.searchButton}
                            disabled={loading}
                        >
                            <Search size={16} />
                            {loading ? 'Cargando...' : 'Buscar'}
                        </button>
                        <button 
                            onClick={handleClearFilters} 
                            className={styles.clearButton}
                            disabled={loading}
                        >
                            <RefreshCw size={16} />
                            Limpiar Filtros
                        </button>
                    </div>
                </div>

                {/* Información de resultados */}
                <div className={styles.resultsInfo}>
                    Mostrando {stockItems.length} de {totalRecords} productos | Página {currentPage} de {totalPages}
                </div>
            </section>

            {/* Sección de Productos */}
            <section className={styles.productosSection}>
                <h2 className={styles.sectionTitle}>
                    <Package size={24} />
                    Lista de Productos
                </h2>

                {/* Estados de error y carga */}
                {error && (
                    <div className={styles.errorContainer}>
                        <AlertCircle size={48} className={styles.errorIcon} />
                        <h3 className={styles.errorTitle}>Error al cargar productos</h3>
                        <p className={styles.errorMessage}>{error}</p>
                        <button className={styles.retryButton} onClick={() => loadStockItems()}>
                            <RotateCcw size={16} />
                            Reintentar
                        </button>
                    </div>
                )}

                {loading && (
                    <div className={styles.loadingContainer}>
                        <div className={styles.loadingSpinner}></div>
                        <p className={styles.loadingText}>Cargando productos...</p>
                    </div>
                )}

                {/* Tabla de productos */}
                {!loading && !error && stockItems.length > 0 && (
                    <div className={styles.productosTable}>
                        <div className={styles.tableHeader}>
                            <div className={styles.headerCell}>Producto</div>
                            <div className={styles.headerCell}>Grupo</div>
                            <div className={styles.headerCell}>Stock</div>
                            <div className={styles.headerCell}>Precio</div>
                            <div className={styles.headerCell}>Acciones</div>
                        </div>
                        
                        <div className={styles.tableBody}>
                            {stockItems.map((item) => (
                                <div key={item.StockItemID} className={styles.tableRow}>
                                    <div className={styles.tableCell}>
                                        <div className={styles.productoInfo}>
                                            <Package size={20} className={styles.productoIcon} />
                                            <div>
                                                <span className={styles.productoNombre}>{item.StockItemName}</span>
                                                <div className={styles.productoId}>
                                                    <Hash size={12} />
                                                    ID: {item.StockItemID}
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <div className={styles.tableCell}>
                                        <span className={styles.grupo}>{item.StockGroupName}</span>
                                    </div>
                                    <div className={styles.tableCell}>
                                        <span className={styles.stock}>{formatQuantity(item.QuantityOnHand)}</span>
                                    </div>
                                    <div className={styles.tableCell}>
                                        <span className={styles.precio}>{formatCurrency(item.UnitPrice)}</span>
                                    </div>
                                    <div className={styles.tableCell}>
                                        <button
                                            className={styles.detailButton}
                                            onClick={() => handleItemClick(item)}
                                            aria-label={`Ver detalles de ${item.StockItemName}`}
                                        >
                                            <Eye size={16} />
                                            Ver Detalles
                                        </button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}

                {/* Estado vacío */}
                {!loading && !error && stockItems.length === 0 && (
                    <div className={styles.emptyState}>
                        <FileX size={64} className={styles.emptyIcon} />
                        <h3 className={styles.emptyTitle}>No se encontraron productos</h3>
                        <p className={styles.emptyMessage}>
                            No hay productos que coincidan con los filtros aplicados.
                            Intenta ajustar los criterios de búsqueda.
                        </p>
                    </div>
                )}

                {/* Paginación */}
                {!loading && stockItems.length > 0 && totalPages > 1 && (
                    <div className={styles.pagination}>
                        <button
                            className={styles.paginationButton}
                            onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                            disabled={currentPage === 1}
                        >
                            <ChevronLeft size={16} />
                            Anterior
                        </button>
                        
                        <div className={styles.paginationInfo}>
                            Página {currentPage} de {totalPages}
                        </div>
                        
                        <button
                            className={styles.paginationButton}
                            onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
                            disabled={currentPage === totalPages}
                        >
                            Siguiente
                            <ChevronRight size={16} />
                        </button>
                    </div>
                )}
            </section>

            {/* Modal de detalles */}
            {selectedItem && (
                <div className={styles.modalOverlay} onClick={() => setSelectedItem(null)}>
                    <div className={styles.modalContent} onClick={(e) => e.stopPropagation()}>
                        <div className={styles.modalHeader}>
                            <h2>Detalles del Producto</h2>
                            <button
                                className={styles.modalClose}
                                onClick={() => setSelectedItem(null)}
                                aria-label="Cerrar modal"
                            >
                                <X size={24} />
                            </button>
                        </div>
                        
                        <div className={styles.modalBody}>
                            <div className={styles.productDetails}>
                                <div className={styles.detailGroup}>
                                    <h3>Información Básica</h3>
                                    <div className={styles.detailItem}>
                                        <span className={styles.detailLabel}>ID del Producto:</span>
                                        <span className={styles.detailValue}>{selectedItem.StockItemID}</span>
                                    </div>
                                    <div className={styles.detailItem}>
                                        <span className={styles.detailLabel}>Nombre:</span>
                                        <span className={styles.detailValue}>{selectedItem.StockItemName}</span>
                                    </div>
                                    <div className={styles.detailItem}>
                                        <span className={styles.detailLabel}>Grupo de Stock:</span>
                                        <span className={styles.detailValue}>{selectedItem.StockGroupName}</span>
                                    </div>
                                    <div className={styles.detailItem}>
                                        <span className={styles.detailLabel}>Proveedor:</span>
                                        <span className={styles.detailValue}>{selectedItem.SupplierName}</span>
                                    </div>
                                </div>

                                <div className={styles.detailGroup}>
                                    <h3>Información de Stock y Precios</h3>
                                    <div className={styles.detailItem}>
                                        <span className={styles.detailLabel}>Cantidad en Stock:</span>
                                        <span className={styles.detailValue}>{formatQuantity(selectedItem.QuantityOnHand)}</span>
                                    </div>
                                    <div className={styles.detailItem}>
                                        <span className={styles.detailLabel}>Precio Unitario:</span>
                                        <span className={styles.detailValue}>{formatCurrency(selectedItem.UnitPrice)}</span>
                                    </div>
                                    {selectedItem.RecommendedRetailPrice && (
                                        <div className={styles.detailItem}>
                                            <span className={styles.detailLabel}>Precio Recomendado:</span>
                                            <span className={styles.detailValue}>{formatCurrency(selectedItem.RecommendedRetailPrice)}</span>
                                        </div>
                                    )}
                                    <div className={styles.detailItem}>
                                        <span className={styles.detailLabel}>Unidad de Medida:</span>
                                        <span className={styles.detailValue}>{selectedItem.UnitPackageName}</span>
                                    </div>
                                </div>

                                {selectedItem.SearchDetails && (
                                    <div className={styles.detailGroup}>
                                        <h3>Detalles Adicionales</h3>
                                        <div className={styles.detailItem}>
                                            <span className={styles.detailLabel}>Información de Búsqueda:</span>
                                            <span className={styles.detailValue}>{selectedItem.SearchDetails}</span>
                                        </div>
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );

    return (
        <div className={styles.container}>
            {/* Skip Link para accesibilidad */}
            <a href="#main-content" className={styles.skipLink} ref={skipLinkRef}>
                Saltar al contenido principal
            </a>

            {/* Header con botón de regreso */}
            <header className={styles.header}>
                <button 
                    className={styles.backButton}
                    onClick={() => navigate('/home')}
                    aria-label="Volver al inicio"
                >
                    <ArrowLeft size={24} />
                </button>
                
                <div className={styles.headerContent}>
                    <div className={styles.titleSection}>
                        <h1 className={styles.headerTitle}>
                            <Package size={28} />
                            Gestión de Inventarios
                        </h1>
                        {sucursalActiva && (
                            <span 
                                className={styles.sucursalBadge}
                                style={{ backgroundColor: getSucursalColor(sucursalActiva.id) }}
                            >
                                <Database size={16} />
                                {sucursalActiva.nombre}
                            </span>
                        )}
                    </div>
                    <p className={styles.headerSubtitle}>
                        Sistema de gestión de productos, stock y análisis estadístico
                    </p>
                </div>
            </header>

            {/* Contenido principal */}
            <main id="main-content" className={styles.mainContent}>
                {/* Navegación por pestañas */}
                <div className={styles.tabNavigation}>
                    <button
                        className={`${styles.tabButton} ${activeTab === 'productos' ? styles.activeTab : ''}`}
                        onClick={() => setActiveTab('productos')}
                        aria-selected={activeTab === 'productos'}
                    >
                        <Package size={18} />
                        Lista de Productos
                    </button>
                    <button
                        className={`${styles.tabButton} ${activeTab === 'grupos' ? styles.activeTab : ''}`}
                        onClick={() => setActiveTab('grupos')}
                        aria-selected={activeTab === 'grupos'}
                    >
                        <BarChart3 size={18} />
                        Grupos de Stock ({stockGroups.length})
                    </button>
                </div>

                {/* Contenido de pestañas */}
                <div className={styles.tabContent}>
                    {activeTab === 'productos' && renderProductList()}
                    {activeTab === 'grupos' && (
                        <section className={styles.gruposSection}>
                            <h2 className={styles.sectionTitle}>
                                <BarChart3 size={24} />
                                Grupos de Stock
                            </h2>
                            {stockGroups.length === 0 ? (
                                <div className={styles.emptyState}>
                                    <FileX size={64} className={styles.emptyIcon} />
                                    <h3 className={styles.emptyTitle}>No hay grupos de stock</h3>
                                    <p className={styles.emptyMessage}>
                                        No se encontraron grupos de stock disponibles.
                                    </p>
                                </div>
                            ) : (
                                <div className={styles.gruposGrid}>
                                    {stockGroups.map((grupo) => (
                                        <div key={grupo.StockGroupID} className={styles.grupoCard}>
                                            <h3>{grupo.StockGroupName}</h3>
                                            <p className={styles.grupoId}>ID: {grupo.StockGroupID}</p>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </section>
                    )}
                </div>
            </main>
        </div>
    );
};

export default Inventarios;
