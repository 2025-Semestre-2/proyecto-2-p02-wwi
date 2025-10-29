import React, { useState, useEffect, useCallback } from 'react';
import {
    ArrowLeft,
    Search,
    Building2,
    Package,
    Truck,
    MapPin,
    RefreshCw,
    Eye,
    Users,
    Filter,
    X,
    Phone,
    Mail,
    Globe,
    User,
    CreditCard,
    Calendar,
    Building,
    AlertCircle,
    ChevronLeft,
    ChevronRight
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import proveedoresService from '../../services/proveedoresService';
import MapComponent from '../../components/MapComponent';
import styles from './Proveedores.module.css';

const Proveedores = () => {
    const navigate = useNavigate();

    // Estados principales
    const [proveedores, setProveedores] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    // Estados de filtros
    const [searchTerm, setSearchTerm] = useState('');
    const [selectedCategory, setSelectedCategory] = useState('');
    const [categories, setCategories] = useState([]);

    // Estados de paginación
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize] = useState(10);
    const [totalRecords, setTotalRecords] = useState(0);

    // Estados del modal
    const [showModal, setShowModal] = useState(false);
    const [selectedProveedor, setSelectedProveedor] = useState(null);
    const [modalLoading, setModalLoading] = useState(false);

    // Calcular información de paginación
    const totalPages = Math.ceil(totalRecords / pageSize);
    const hasNextPage = currentPage < totalPages;
    const hasPrevPage = currentPage > 1;

    // Cargar categorías al montar el componente
    // Cargar categorías al montar el componente
    useEffect(() => {
        const loadCategories = async () => {
            try {
                console.log('Proveedores] Cargando categorías...');
                const response = await proveedoresService.getSupplierCategories();

                console.log('[Proveedores] Respuesta completa de categorías:', response);
                console.log('[Proveedores] Estructura de data:', response.data);

                if (response.success && response.data) {
                    // Log para ver la estructura de cada categoría
                    response.data.forEach((cat, idx) => {
                        console.log(`[Proveedores] Categoría ${idx}:`, cat);
                    });

                    setCategories(response.data);
                    console.log('[Proveedores] Categorías cargadas:', response.data.length);
                } else {
                    console.error('[Proveedores] Error en respuesta de categorías:', response);
                }
            } catch (error) {
                console.error('[Proveedores] Error al cargar categorías:', error);
            }
        };

        loadCategories();
    }, []);

    // Función para cargar proveedores
    const loadProveedores = useCallback(async (page = 1, search = '', category = '') => {
        try {
            setLoading(true);
            setError(null);

            console.log('[Proveedores] Cargando proveedores...', {
                page,
                search,
                category,
                pageSize
            });

            const response = await proveedoresService.getProveedores({
                page,
                pageSize,
                search: search.trim(),
                category: category || undefined
            });

            if (response.success && response.data) {
                setProveedores(response.data.proveedores || []);
                setTotalRecords(response.data.totalRecords || 0);
                setCurrentPage(page);

                console.log('[Proveedores] Datos cargados:', {
                    total: response.data.totalRecords,
                    proveedores: response.data.proveedores?.length || 0,
                    page
                });
            } else {
                throw new Error(response.message || 'Error al cargar proveedores');
            }
        } catch (error) {
            console.error('[Proveedores] Error:', error);
            setError(error.message || 'Error inesperado al cargar proveedores');
            setProveedores([]);
            setTotalRecords(0);
        } finally {
            setLoading(false);
        }
    }, [pageSize]);

    // Cargar proveedores al montar y cuando cambien los filtros
    useEffect(() => {
        loadProveedores(1, searchTerm, selectedCategory);
    }, [loadProveedores, searchTerm, selectedCategory]);

    // Función para cargar detalles del proveedor
    const loadProveedorDetails = async (proveedorId) => {
        try {
            setModalLoading(true);
            console.log('🔍 [Proveedores] Cargando detalles del proveedor:', proveedorId);

            const response = await proveedoresService.getProveedorById(proveedorId);

            if (response.success && response.data) {
                const d = response.data;
                // Mapear campos para el modal (igual que en clientes)
                const proveedorDetallado = {
                    ...d,
                    direccionEntrega1: d.DeliveryAddressLine1 || '',
                    direccionEntrega2: d.DeliveryAddressLine2 || '',
                    codigoPostalEntrega: d.DeliveryPostalCode || '',
                    direccionPostal1: d.PostalAddressLine1 || '',
                    direccionPostal2: d.PostalAddressLine2 || '',
                    codigoPostalPostal: d.PostalPostalCode || '',
                    ciudadCompleta: `${d.CiudadEntrega || ''}, ${d.EstadoEntrega || ''}, ${d.PaisEntrega || ''}`,
                    latitud: d.LatitudEntrega ?? null,
                    longitud: d.LongitudEntrega ?? null,
                };
                setSelectedProveedor(proveedorDetallado);
                setShowModal(true);
                console.log('[Proveedores] Detalles cargados:', proveedorDetallado);
            } else {
                throw new Error(response.message || 'Error al cargar detalles del proveedor');
            }
        } catch (error) {
            console.error('[Proveedores] Error al cargar detalles:', error);
            alert('Error al cargar los detalles del proveedor');
        } finally {
            setModalLoading(false);
        }
    };

    // Manejadores de eventos
    const handleSearchChange = (e) => {
        setSearchTerm(e.target.value);
        setCurrentPage(1);
    };

    const handleCategoryChange = (category) => {
        setSelectedCategory(selectedCategory === category ? '' : category);
        setCurrentPage(1);
    };

    const handleReset = () => {
        setSearchTerm('');
        setSelectedCategory('');
        setCurrentPage(1);
    };

    const handlePageChange = (newPage) => {
        loadProveedores(newPage, searchTerm, selectedCategory);
    };

    const handleViewDetails = (proveedor) => {
        loadProveedorDetails(proveedor.SupplierID);
    };

    const handleCloseModal = () => {
        setShowModal(false);
        setSelectedProveedor(null);
    };

    const handleRetry = () => {
        loadProveedores(currentPage, searchTerm, selectedCategory);
    };

    // Efecto para manejar teclas
    useEffect(() => {
        const handleKeyPress = (e) => {
            if (e.key === 'Escape' && showModal) {
                handleCloseModal();
            }
        };

        document.addEventListener('keydown', handleKeyPress);
        return () => document.removeEventListener('keydown', handleKeyPress);
    }, [showModal]);

    // Componente de Loading
    if (loading && !proveedores.length) {
        return (
            <div className={styles.container}>
                <a href="#main-content" className={styles.skipLink}>
                    Saltar al contenido principal
                </a>
                <div className={styles.loadingContainer}>
                    <div className={styles.loadingSpinner} aria-label="Cargando"></div>
                    <p className={styles.loadingText}>Cargando proveedores...</p>
                </div>
            </div>
        );
    }

    // Componente de Error
    if (error && !proveedores.length) {
        return (
            <div className={styles.container}>
                <a href="#main-content" className={styles.skipLink}>
                    Saltar al contenido principal
                </a>
                <div className={styles.errorContainer}>
                    <AlertCircle size={64} className={styles.errorIcon} />
                    <h1 className={styles.errorTitle}>Error al cargar proveedores</h1>
                    <p className={styles.errorMessage}>{error}</p>
                    <button onClick={handleRetry} className={styles.retryButton}>
                        <RefreshCw size={20} />
                        Intentar nuevamente
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className={styles.container}>
            <a href="#main-content" className={styles.skipLink}>
                Saltar al contenido principal
            </a>

            {/* Header */}
            <header className={styles.header}>
                <button
                    onClick={() => navigate('/')}
                    className={styles.backButton}
                    aria-label="Volver al inicio"
                >
                    <ArrowLeft size={24} />
                </button>
                <div className={styles.headerContent}>
                    <h1 className={styles.headerTitle}>
                        <Building2 size={32} />
                        Gestión de Proveedores
                    </h1>
                    <p className={styles.headerSubtitle}>
                        Administra y consulta la información de todos los proveedores
                    </p>
                </div>
            </header>

            <main id="main-content" className={styles.mainContent}>
                {/* Sección de Filtros */}
                <section className={styles.filtersSection} aria-label="Filtros de búsqueda">
                    <h2 className={styles.sectionTitle}>
                        <Filter size={20} />
                        Filtros de Búsqueda
                    </h2>

                    <div className={styles.filters}>
                        {/* Barra de búsqueda */}
                        <div className={styles.searchContainer}>
                            <Search size={20} className={styles.searchIcon} />
                            <input
                                type="text"
                                placeholder="Buscar por nombre de proveedor"
                                value={searchTerm}
                                onChange={handleSearchChange}
                                className={styles.searchInput}
                                aria-label="Buscar proveedores"
                            />
                        </div>

                        {/* Botones de categorías */}
                        <div className={styles.filterButtons}>
                            {categories.map((category, index) => {
                                // Determinar el nombre y clave de la categoría
                                const categoryName = category.SupplierCategoryName || category.CategoryName || category.nombre || `categoria-${index}`;

                                // CORRECCIÓN: Crear una key única y estable
                                const categoryKey = category.SupplierCategoryID
                                    ? `category-${category.SupplierCategoryID}`
                                    : `category-${index}-${categoryName.replace(/\s+/g, '-')}`;

                                const supplierCount = category.CantidadProveedores || category.SupplierCount || category.count || 0;

                                return (
                                    <button
                                        key={categoryKey}
                                        onClick={() => handleCategoryChange(categoryName)}
                                        className={`${styles.filterButton} ${selectedCategory === categoryName ? styles.active : ''
                                            }`}
                                        aria-pressed={selectedCategory === categoryName}
                                    >
                                        <Package size={16} />
                                        {categoryName}
                                        {supplierCount > 0 && (
                                            <span className={styles.categoryCount}>({supplierCount})</span>
                                        )}
                                    </button>
                                );
                            })}

                            {categories.length > 0 && (
                                <button
                                    onClick={handleReset}
                                    className={styles.resetButton}
                                    aria-label="Limpiar filtros"
                                >
                                    <X size={16} />
                                    Limpiar filtros
                                </button>
                            )}
                        </div>
                    </div>

                    <div className={styles.resultsInfo}>
                        Mostrando {proveedores.length} de {totalRecords} proveedores
                        {searchTerm && ` para "${searchTerm}"`}
                        {selectedCategory && ` en categoría "${selectedCategory}"`}
                    </div>
                </section>

                {/* Sección de Proveedores */}
                <section className={styles.proveedoresSection} aria-label="Lista de proveedores">
                    <h2 className={styles.sectionTitle}>
                        <Users size={20} />
                        Proveedores ({totalRecords})
                    </h2>

                    {/* Tabla de proveedores */}
                    {proveedores.length > 0 ? (
                        <div className={styles.proveedoresTable}>
                            <div className={styles.tableHeader} role="row">
                                <div className={styles.headerCell} role="columnheader">Proveedor</div>
                                <div className={styles.headerCell} role="columnheader">Categoría</div>
                                <div className={styles.headerCell} role="columnheader">Entrega</div>
                                <div className={styles.headerCell} role="columnheader">Ubicación</div>
                                <div className={styles.headerCell} role="columnheader">Acciones</div>
                            </div>

                            <div className={styles.tableBody} role="rowgroup">
                                {proveedores.map((proveedor) => (
                                    <div key={proveedor.SupplierID} className={styles.tableRow} role="row">
                                        <div className={styles.tableCell} role="cell">
                                            <div className={styles.proveedorInfo}>
                                                <Building2 size={24} className={styles.proveedorIcon} />
                                                <div>
                                                    <span className={styles.proveedorNombre}>
                                                        {proveedor.SupplierName}
                                                    </span>
                                                    {proveedor.PrimaryContactPerson && (
                                                        <div className={styles.proveedorContacto}>
                                                            <User size={14} />
                                                            {proveedor.PrimaryContactPerson}
                                                        </div>
                                                    )}
                                                </div>
                                            </div>
                                        </div>

                                        <div className={styles.tableCell} role="cell">
                                            {(proveedor.SupplierCategoryName || proveedor.Categoria) && (
                                                <span className={styles.categoria}>
                                                    {proveedor.SupplierCategoryName || proveedor.Categoria}
                                                </span>
                                            )}
                                        </div>

                                        <div className={styles.tableCell} role="cell">
                                            <div className={styles.metodoEntrega}>
                                                <Truck size={16} />
                                                {proveedor.DeliveryMethodName || 'No especificado'}
                                            </div>
                                        </div>

                                        <div className={styles.tableCell} role="cell">
                                            <div className={styles.ciudad}>
                                                <MapPin size={16} />
                                                {proveedor.DeliveryCityName || 'No especificado'}
                                            </div>
                                        </div>

                                        <div className={styles.tableCell} role="cell">
                                            <button
                                                onClick={() => handleViewDetails(proveedor)}
                                                className={styles.detailButton}
                                                aria-label={`Ver detalles de ${proveedor.SupplierName}`}
                                            >
                                                <Eye size={16} />
                                                Ver detalles
                                            </button>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    ) : (
                        <div className={styles.emptyState}>
                            <Building2 size={64} className={styles.emptyIcon} />
                            <h3 className={styles.emptyTitle}>No se encontraron proveedores</h3>
                            <p className={styles.emptyMessage}>
                                {searchTerm || selectedCategory
                                    ? 'Intenta ajustar los filtros de búsqueda'
                                    : 'No hay proveedores disponibles en este momento'
                                }
                            </p>
                        </div>
                    )}

                    {/* Paginación */}
                    {totalPages > 1 && (
                        <div className={styles.pagination} role="navigation" aria-label="Paginación">
                            <button
                                onClick={() => handlePageChange(currentPage - 1)}
                                disabled={!hasPrevPage}
                                className={styles.paginationButton}
                                aria-label="Página anterior"
                            >
                                <ChevronLeft size={16} />
                                Anterior
                            </button>

                            <span className={styles.paginationInfo}>
                                Página {currentPage} de {totalPages}
                            </span>

                            <button
                                onClick={() => handlePageChange(currentPage + 1)}
                                disabled={!hasNextPage}
                                className={styles.paginationButton}
                                aria-label="Página siguiente"
                            >
                                Siguiente
                                <ChevronRight size={16} />
                            </button>
                        </div>
                    )}
                </section>
            </main>

            {/* Modal de detalles */}
            {showModal && (
                <div
                    className={styles.modalOverlay}
                    onClick={handleCloseModal}
                    role="dialog"
                    aria-modal="true"
                    aria-labelledby="modal-title"
                >
                    <div
                        className={styles.modalContent}
                        onClick={(e) => e.stopPropagation()}
                    >
                        <div className={styles.modalHeader}>
                            <h2 id="modal-title">
                                <Building2 size={24} />
                                Detalles del Proveedor
                            </h2>
                            <button
                                onClick={handleCloseModal}
                                className={styles.modalClose}
                                aria-label="Cerrar modal"
                            >
                                <X size={18} />
                            </button>
                        </div>

                        <div className={styles.modalBody}>
                            {modalLoading ? (
                                <div className={styles.loadingContainer}>
                                    <div className={styles.loadingSpinner}></div>
                                    <p>Cargando detalles...</p>
                                </div>
                            ) : selectedProveedor ? (
                                <div className={styles.proveedorDetails}>
                                    {/* Información básica */}
                                    <div className={styles.detailGroup}>
                                        <h3>Información Básica</h3>
                                        <div className={styles.detailItem}>
                                            <span className={styles.detailLabel}>Nombre:</span>
                                            <span className={styles.detailValue}>{selectedProveedor.SupplierName}</span>
                                        </div>
                                        <div className={styles.detailItem}>
                                            <span className={styles.detailLabel}>Categoría:</span>
                                            <span className={styles.detailValue}>
                                                {selectedProveedor.SupplierCategoryName || selectedProveedor.Categoria}
                                            </span>
                                        </div>
                                        <div className={styles.detailItem}>
                                            <span className={styles.detailLabel}>ID:</span>
                                            <span className={styles.detailValue}>{selectedProveedor.SupplierID}</span>
                                        </div>
                                        <div className={styles.detailItem}>
                                            <span className={styles.detailLabel}>Referencia:</span>
                                            <span className={styles.detailValue}>{selectedProveedor.SupplierReference || 'N/A'}</span>
                                        </div>
                                    </div>

                                    {/* Información de contacto */}
                                    <div className={styles.detailGroup}>
                                        <h3>Contacto</h3>
                                        <div className={styles.contactCard}>
                                            <h4>
                                                <User size={16} />
                                                Información de Contacto
                                            </h4>
                                            {(selectedProveedor.PrimaryContactPerson || selectedProveedor.ContactoPrimarioNombre) && (
                                                <div className={styles.detailItem}>
                                                    <User size={16} />
                                                    <span className={styles.detailLabel}>Contacto Principal:</span>
                                                    <span className={styles.detailValue}>{selectedProveedor.PrimaryContactPerson || selectedProveedor.ContactoPrimarioNombre}</span>
                                                </div>
                                            )}
                                            {(selectedProveedor.PhoneNumber || selectedProveedor.ContactoPrimarioTelefono) && (
                                                <div className={styles.detailItem}>
                                                    <Phone size={16} />
                                                    <span className={styles.detailLabel}>Teléfono:</span>
                                                    <span className={styles.detailValue}>
                                                        <a href={`tel:${selectedProveedor.PhoneNumber || selectedProveedor.ContactoPrimarioTelefono}`}>
                                                            {selectedProveedor.PhoneNumber || selectedProveedor.ContactoPrimarioTelefono}
                                                        </a>
                                                    </span>
                                                </div>
                                            )}
                                            {(selectedProveedor.FaxNumber || selectedProveedor.ContactoPrimarioFax) && (
                                                <div className={styles.detailItem}>
                                                    <span className={styles.detailLabel}>Fax:</span>
                                                    <span className={styles.detailValue}>{selectedProveedor.FaxNumber || selectedProveedor.ContactoPrimarioFax}</span>
                                                </div>
                                            )}
                                            {(selectedProveedor.WebsiteURL || selectedProveedor.SitioWeb) && (
                                                <div className={styles.detailItem}>
                                                    <Globe size={16} />
                                                    <span className={styles.detailLabel}>Sitio web:</span>
                                                    <span className={styles.detailValue}>
                                                        <a href={selectedProveedor.WebsiteURL || selectedProveedor.SitioWeb} target="_blank" rel="noopener noreferrer">
                                                            {selectedProveedor.WebsiteURL || selectedProveedor.SitioWeb}
                                                        </a>
                                                    </span>
                                                </div>
                                            )}
                                            {(selectedProveedor.PrimaryContactEmail || selectedProveedor.ContactoPrimarioEmail) && (
                                                <div className={styles.detailItem}>
                                                    <Mail size={16} />
                                                    <span className={styles.detailLabel}>Email:</span>
                                                    <span className={styles.detailValue}>
                                                        <a href={`mailto:${selectedProveedor.PrimaryContactEmail || selectedProveedor.ContactoPrimarioEmail}`}>
                                                            {selectedProveedor.PrimaryContactEmail || selectedProveedor.ContactoPrimarioEmail}
                                                        </a>
                                                    </span>
                                                </div>
                                            )}
                                        </div>
                                    </div>

                                    {/* Dirección y Mapa */}

                                    <div className={styles.detailGroup}>
                                        <h3>Direcciones</h3>
                                        <div className={styles.addressCard}>
                                            <h4>Dirección de Entrega</h4>
                                            <div className={styles.addressContent}>
                                                <MapPin size={16} />
                                                <div>
                                                    <p>{selectedProveedor.direccionEntrega1}</p>
                                                    {selectedProveedor.direccionEntrega2 && <p>{selectedProveedor.direccionEntrega2}</p>}
                                                    <p>{selectedProveedor.ciudadCompleta}</p>
                                                    <p>Código Postal: {selectedProveedor.codigoPostalEntrega}</p>
                                                </div>
                                            </div>
                                        </div>

                                        <div className={styles.addressCard}>
                                            <h4>Dirección Postal</h4>
                                            <div className={styles.addressContent}>
                                                <Mail size={16} />
                                                <div>
                                                    <p>{selectedProveedor.direccionPostal1}</p>
                                                    {selectedProveedor.direccionPostal2 && <p>{selectedProveedor.direccionPostal2}</p>}
                                                    <p>{selectedProveedor.ciudadCompleta}</p>
                                                    <p>Código Postal: {selectedProveedor.codigoPostalPostal}</p>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    <div className={styles.detailGroup}>
                                        <h3>Localización en Mapa</h3>
                                        <MapComponent
                                            latitud={selectedProveedor.latitud}
                                            longitud={selectedProveedor.longitud}
                                            ciudad={selectedProveedor.ciudadCompleta}
                                            direccion={`${selectedProveedor.direccionEntrega1 || ''} ${selectedProveedor.direccionEntrega2 || ''}`.trim()}
                                            height="350px"
                                        />
                                    </div>

                                    {/* Información comercial */}
                                    <div className={styles.detailGroup}>
                                        <h3>Información Comercial</h3>
                                        {selectedProveedor.PaymentDays && (
                                            <div className={styles.detailItem}>
                                                <Calendar size={16} />
                                                <span className={styles.detailLabel}>Días de gracia para pagar:</span>
                                                <span className={styles.detailValue}>{selectedProveedor.PaymentDays} días</span>
                                            </div>
                                        )}
                                        {(selectedProveedor.DeliveryMethodName || selectedProveedor.MetodoEntrega) && (
                                            <div className={styles.detailItem}>
                                                <Truck size={16} />
                                                <span className={styles.detailLabel}>Método de entrega:</span>
                                                <span className={styles.detailValue}>
                                                    {selectedProveedor.DeliveryMethodName || selectedProveedor.MetodoEntrega}
                                                </span>
                                            </div>
                                        )}
                                        {selectedProveedor.BankAccountName && (
                                            <div className={styles.detailItem}>
                                                <CreditCard size={16} />
                                                <span className={styles.detailLabel}>Nombre del banco:</span>
                                                <span className={styles.detailValue}>{selectedProveedor.BankAccountName}</span>
                                            </div>
                                        )}
                                        {selectedProveedor.BankAccountNumber && (
                                            <div className={styles.detailItem}>
                                                <CreditCard size={16} />
                                                <span className={styles.detailLabel}>Número de cuenta corriente:</span>
                                                <span className={styles.detailValue}>{selectedProveedor.BankAccountNumber}</span>
                                            </div>
                                        )}
                                        {selectedProveedor.BankAccountBranch && (
                                            <div className={styles.detailItem}>
                                                <Building size={16} />
                                                <span className={styles.detailLabel}>Sucursal:</span>
                                                <span className={styles.detailValue}>{selectedProveedor.BankAccountBranch}</span>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            ) : (
                                <div className={styles.errorContainer}>
                                    <AlertCircle size={32} className={styles.errorIcon} />
                                    <p>Error al cargar los detalles del proveedor</p>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Proveedores;
