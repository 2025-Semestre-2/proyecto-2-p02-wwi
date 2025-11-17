import React, { useState, useEffect, useRef } from 'react';
import { useSucursal } from '../../context/useSucursal';
import VentasService from '../../services/ventasService';
import styles from './Ventas.module.css';
import { useNavigate } from 'react-router-dom';
import {
    ArrowLeft,
    Search,
    Users,
    Building2,
    AlertCircle,
    FileX,
    RotateCcw,
    Eye,
    MapPin,
    Phone,
    Mail,
    Globe,
    Filter,
    RefreshCw,
    CreditCard,
    Calendar,
    User,
    UserCheck,
    Database
} from 'lucide-react';


const Ventas = () => {
    const navigate = useNavigate();
    const { sucursalActiva } = useSucursal();
    
    // Helper para obtener color de sucursal
    const getSucursalColor = (id) => {
        const colors = { 1: '#1c4382', 2: '#b91016', 3: '#1c7e2f' };
        return colors[id] || '#1c4382';
    };
    
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState(null);
    const [ventas, setVentas] = useState([]);
    const [selectedVenta, setSelectedVenta] = useState(null);
    const [showModal, setShowModal] = useState(false);
    const [filters, setFilters] = useState({
        search: '',
        startDate: '',
        endDate: '',
        minAmount: '',
        maxAmount: ''
    });
    const [pagination, setPagination] = useState({
        currentPage: 1,
        pageSize: 10,
        totalPages: 1,
        totalRecords: 0
    });
    const skipLinkRef = useRef(null);

    // Cargar ventas desde la API
    const loadVentas = async (params = {}) => {
        if (!sucursalActiva) return;
        
        setIsLoading(true);
        setError(null);
        try {
            const { data, pagination: pag } = await VentasService.getVentas(sucursalActiva.id, {
                searchText: params.search || filters.search,
                startDate: params.startDate || filters.startDate,
                endDate: params.endDate || filters.endDate,
                minAmount: params.minAmount || filters.minAmount,
                maxAmount: params.maxAmount || filters.maxAmount,
                pageNumber: params.pageNumber || pagination.currentPage,
                pageSize: pagination.pageSize
            });
            setVentas(data);
            setPagination({
                ...pagination,
                currentPage: pag.currentPage,
                totalPages: pag.totalPages,
                totalRecords: pag.totalRecords
            });
        } catch (err) {
            console.error('Error cargando ventas:', err);
            setError('Error al cargar ventas.');
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        if (sucursalActiva) {
            loadVentas({ pageNumber: 1 });
        }
        // eslint-disable-next-line
    }, [sucursalActiva]);

    // Buscar ventas cuando cambian los filtros
    useEffect(() => {
        if (sucursalActiva) {
            loadVentas({ pageNumber: 1 });
        }
        // eslint-disable-next-line
    }, [filters]);

    // Cambiar de página
    const handlePageChange = (newPage) => {
        setPagination((prev) => ({ ...prev, currentPage: newPage }));
        loadVentas({ pageNumber: newPage });
    };

    // Cambiar filtros
    const handleFilterChange = (e) => {
        const { name, value } = e.target;
        setFilters((prev) => ({ ...prev, [name]: value }));
    };

    // Limpiar filtros
    const handleResetFilters = () => {
        setFilters({ search: '', startDate: '', endDate: '', minAmount: '', maxAmount: '' });
    };

    // Ver detalles de una venta
    const handleVerDetalles = async (venta) => {
        if (!sucursalActiva) return;
        
        setIsLoading(true);
        setError(null);
        try {
            const { data } = await VentasService.getVentaById(sucursalActiva.id, venta.InvoiceID);
            setSelectedVenta(data);
            setShowModal(true);
        } catch (err) {
            console.error('Error cargando detalles de la venta:', err);
            setError('Error al cargar detalles de la venta.');
        } finally {
            setIsLoading(false);
        }
    };

    // Cerrar modal
    const handleCloseModal = () => {
        setShowModal(false);
        setSelectedVenta(null);
    };

    if (isLoading) {
        return (
            <div className={styles.loadingContainer}>
                <div className={styles.loadingSpinner}></div>
                <div className={styles.loadingText}>Cargando ventas...</div>
            </div>
        );
    }

    if (error) {
        return (
            <div className={styles.errorContainer}>
                <div className={styles.errorTitle}>Error</div>
                <div className={styles.errorMessage}>{error}</div>
                <button className={styles.retryButton} onClick={() => loadVentas()}>Reintentar</button>
            </div>
        );
    }

    return (
        <div className={styles.container}>
            <a href="#mainContent" className={styles.skipLink} ref={skipLinkRef}>Saltar al contenido principal</a>
            <header className={styles.header}>
                <button
                    onClick={() => navigate('/home')}
                    className={styles.backButton}
                    aria-label="Volver al inicio"
                >
                    <ArrowLeft size={24} />
                </button>
                <div className={styles.headerContent}>
                    <div className={styles.titleSection}>
                        <h1 className={styles.headerTitle}>
                            <Users size={28} />
                            Gestión de Ventas
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
                        Consulta y gestión de ventas
                    </p>
                </div>
            </header>
            <main id="mainContent" className={styles.mainContent}>
                <section className={styles.filtersSection}>
                    <div className={styles.sectionTitle}>Filtros</div>
                    <div className={styles.filters}>
                        <input
                            className={styles.searchInput}
                            type="text"
                            name="search"
                            placeholder="Buscar por nombre de cliente"
                            value={filters.search}
                            onChange={handleFilterChange}
                        />
                        <input
                            className={styles.searchInput}
                            type="date"
                            name="startDate"
                            value={filters.startDate}
                            onChange={handleFilterChange}
                        />
                        <input
                            className={styles.searchInput}
                            type="date"
                            name="endDate"
                            value={filters.endDate}
                            onChange={handleFilterChange}
                        />
                        <input
                            className={styles.searchInput}
                            type="number"
                            name="minAmount"
                            placeholder="Monto mínimo"
                            value={filters.minAmount}
                            onChange={handleFilterChange}
                        />
                        <input
                            className={styles.searchInput}
                            type="number"
                            name="maxAmount"
                            placeholder="Monto máximo"
                            value={filters.maxAmount}
                            onChange={handleFilterChange}
                        />
                        <button className={styles.resetButton} onClick={handleResetFilters}>Restablecer filtros</button>
                    </div>
                    <div className={styles.resultsInfo}>
                        {pagination.totalRecords} ventas encontradas
                    </div>
                </section>
                <section className={styles.clientesSection}>
                    <div className={styles.sectionTitle}>Ventas</div>
                    <div className={styles.clientesTable}>
                        <div className={styles.tableHeader}>
                            <div>Factura</div>
                            <div>Fecha</div>
                            <div>Cliente</div>
                            <div>Método Entrega</div>
                            <div>Monto</div>
                            <div></div>
                        </div>
                        <div className={styles.tableBody}>
                            {ventas.length === 0 ? (
                                <div className={styles.emptyState}>
                                    <div className={styles.emptyTitle}>No hay ventas</div>
                                    <div className={styles.emptyMessage}>No se encontraron ventas con los filtros actuales.</div>
                                </div>
                            ) : (
                                ventas.map((venta) => (
                                    <div className={styles.tableRow} key={venta.InvoiceID}>
                                        <div className={styles.tableCell}>{venta.InvoiceID}</div>
                                        <div className={styles.tableCell}>{venta.InvoiceDate?.substring(0, 10)}</div>
                                        <div className={styles.tableCell}>{venta.CustomerName}</div>
                                        <div className={styles.tableCell}>{venta.DeliveryMethodName}</div>
                                        <div className={styles.tableCell}>{venta.TotalAmount?.toLocaleString('es-CR', { style: 'currency', currency: 'CRC' })}</div>
                                        <div className={styles.tableCell}>
                                            <button className={styles.detailButton} onClick={() => handleVerDetalles(venta)}>Ver detalles</button>
                                        </div>
                                    </div>
                                ))
                            )}
                        </div>
                    </div>
                    <div className={styles.pagination}>
                        <button
                            className={styles.paginationButton}
                            onClick={() => handlePageChange(pagination.currentPage - 1)}
                            disabled={pagination.currentPage === 1}
                        >Anterior</button>
                        <span className={styles.paginationInfo}>
                            Página {pagination.currentPage} de {pagination.totalPages}
                        </span>
                        <button
                            className={styles.paginationButton}
                            onClick={() => handlePageChange(pagination.currentPage + 1)}
                            disabled={pagination.currentPage === pagination.totalPages}
                        >Siguiente</button>
                    </div>
                </section>
            </main>
            {showModal && selectedVenta && (
                <VentaModal venta={selectedVenta} onClose={handleCloseModal} />
            )}
        </div>
    );
};

// Modal de detalles de la venta/factura
const VentaModal = ({ venta, onClose }) => {
    const { encabezado, lineas } = venta;
    return (
        <div className={styles.modalOverlay}>
            <div className={styles.modalContent}>
                <div className={styles.modalHeader}>
                    <h2>Factura #{encabezado.InvoiceID}</h2>
                    <button className={styles.modalClose} onClick={onClose}>×</button>
                </div>
                <div className={styles.modalBody}>
                    <div className={styles.clienteDetails}>
                        <div className={styles.detailGroup}>
                            <h3>Encabezado</h3>
                            <div className={styles.detailItem}><span className={styles.detailLabel}>Cliente:</span> <span className={styles.detailValue}>{encabezado.CustomerName}</span></div>
                            <div className={styles.detailItem}><span className={styles.detailLabel}>Fecha:</span> <span className={styles.detailValue}>{encabezado.InvoiceDate?.substring(0, 10)}</span></div>
                            <div className={styles.detailItem}><span className={styles.detailLabel}>Método de entrega:</span> <span className={styles.detailValue}>{encabezado.DeliveryMethodName}</span></div>
                            <div className={styles.detailItem}><span className={styles.detailLabel}>Persona de contacto:</span> <span className={styles.detailValue}>{encabezado.ContactPersonName}</span></div>
                            <div className={styles.detailItem}><span className={styles.detailLabel}>Vendedor:</span> <span className={styles.detailValue}>{encabezado.SalespersonName}</span></div>
                            <div className={styles.detailItem}><span className={styles.detailLabel}>Número de orden:</span> <span className={styles.detailValue}>{encabezado.CustomerPurchaseOrderNumber}</span></div>
                            <div className={styles.detailItem}><span className={styles.detailLabel}>Instrucciones de entrega:</span> <span className={styles.detailValue}>{encabezado.DeliveryInstructions}</span></div>
                        </div>
                        <div className={styles.detailGroup}>
                            <h3>Detalle de la factura</h3>
                            <div>
                                {lineas && lineas.length > 0 ? (
                                    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                                        <thead>
                                            <tr>
                                                <th>Producto</th>
                                                <th>Cantidad</th>
                                                <th>Precio unitario</th>
                                                <th>Impuesto</th>
                                                <th>Monto impuesto</th>
                                                <th>Total línea</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {lineas.map((l) => (
                                                <tr key={l.InvoiceLineID}>
                                                    <td>{l.StockItemName}</td>
                                                    <td>{l.Quantity}</td>
                                                    <td>{l.UnitPrice?.toLocaleString('es-CR', { style: 'currency', currency: 'CRC' })}</td>
                                                    <td>{l.TaxRate}%</td>
                                                    <td>{l.TaxAmount?.toLocaleString('es-CR', { style: 'currency', currency: 'CRC' })}</td>
                                                    <td>{l.ExtendedPrice?.toLocaleString('es-CR', { style: 'currency', currency: 'CRC' })}</td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                ) : (
                                    <div>No hay líneas de factura.</div>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Ventas;
