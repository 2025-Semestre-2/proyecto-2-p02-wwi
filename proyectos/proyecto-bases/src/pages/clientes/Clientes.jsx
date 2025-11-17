import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import useSucursal from '../../context/useSucursal';
import styles from './Clientes.module.css';
import ClientesService from '../../services/clientesService';
import MapComponent from '../../components/MapComponent';
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

const Clientes = () => {
    const navigate = useNavigate();
    const { sucursalActiva } = useSucursal();
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState(null);
    const [clientes, setClientes] = useState([]);
    const [filteredClientes, setFilteredClientes] = useState([]);
    const [selectedCliente, setSelectedCliente] = useState(null);
    const [showModal, setShowModal] = useState(false);
    const [searchText, setSearchText] = useState(''); // Texto de búsqueda temporal
    const [filters, setFilters] = useState({
        search: '', // Texto de búsqueda aplicado
        categoria: 'all'
    });
    const [currentPage, setCurrentPage] = useState(1);
    // Estados adicionales para paginación
    const [totalPages, setTotalPages] = useState(1);
    const [totalRecords, setTotalRecords] = useState(0);
    const clientesPerPage = 10;
    const skipLinkRef = useRef(null);

    // Función helper para obtener color de sucursal
    const getSucursalColor = () => {
        switch(sucursalActiva?.id) {
            case 'corporativo': return '#1c4382';
            case 'sanJose': return '#b91016';
            case 'limon': return '#1c7e2f';
            default: return '#6b7280';
        }
    };

    // Función para cargar clientes con los nuevos datos completos
    const loadClientes = async (searchText = '', pageNumber = 1) => {
        setIsLoading(true);
        try {
            const response = await ClientesService.getClientes({
                searchText: searchText,
                orderBy: 'CustomerName',
                orderDirection: 'ASC',
                pageNumber: pageNumber,
                pageSize: clientesPerPage
            }, sucursalActiva?.id || 'corporativo'); // Pasar ID de sucursal activa

            if (response.success) {
                // Mapear los datos completos de la API al formato esperado por el frontend
                const processedClientes = response.data.map(customer => ({
                    id: customer.CustomerID,
                    nombre: customer.CustomerName || 'N/A',
                    categoria: customer.Categoria || 'N/A',
                    metodoEntrega: customer.MetodoEntrega || 'N/A',
                    ciudad: customer.CiudadEntrega || 'N/A',
                    ciudadCompleta: `${customer.CiudadEntrega || 'N/A'}, ${customer.EstadoEntrega || 'N/A'}, ${customer.PaisEntrega || 'N/A'}`,
                    telefono: customer.PhoneNumber || 'N/A',
                    fax: customer.FaxNumber || 'N/A',
                    email: customer.ContactoPrimarioEmail || 'N/A',
                    sitioWeb: customer.WebsiteURL || 'N/A',
                    grupoCompra: customer.GrupoCompra || 'N/A',
                    limiteCredito: customer.CreditLimit ?? 0,
                    diasPago: customer.PaymentDays ?? 0,
                    descuentoEstandar: customer.StandardDiscountPercentage ?? 0,
                    fechaApertura: customer.AccountOpenedDate || '',
                    enEspera: customer.EstadoCredito === 'En Hold de Crédito',
                    estado: customer.EstadoCredito || 'Activo',
                    contactoPrimario: {
                        fullName: customer.ContactoPrimarioNombre || 'N/A',
                        phoneNumber: customer.ContactoPrimarioTelefono || 'N/A',
                        emailAddress: customer.ContactoPrimarioEmail || 'N/A',
                    },
                    contactoAlternativo: customer.ContactoAlternativoNombre ? {
                        fullName: customer.ContactoAlternativoNombre,
                        phoneNumber: customer.ContactoAlternativoTelefono || 'N/A',
                        emailAddress: customer.ContactoAlternativoEmail || 'N/A',
                    } : null,
                    // Direcciones
                    direccionEntrega1: customer.DireccionEntrega1 || '',
                    direccionEntrega2: customer.DireccionEntrega2 || '',
                    codigoPostalEntrega: customer.CodigoPostalEntrega || '',
                    direccionPostal1: customer.DireccionPostal1 || '',
                    direccionPostal2: customer.DireccionPostal2 || '',
                    codigoPostalPostal: customer.CodigoPostalPostal || '',
                    // Coordenadas para el mapa
                    latitud: customer.LatitudEntrega ?? null,
                    longitud: customer.LongitudEntrega ?? null,
                }));

                setClientes(processedClientes);
                setFilteredClientes(processedClientes);

                // Imprimir en terminal la lista de clientes cargados
                console.log('--- LISTA DE CLIENTES CARGADOS ---');
                processedClientes.forEach((c, idx) => {
                    console.log(`#${idx + 1}`);
                    Object.entries(c).forEach(([key, value]) => {
                        if (typeof value === 'object' && value !== null) {
                            console.log(`  ${key}:`);
                            Object.entries(value).forEach(([k, v]) => {
                                console.log(`    ${k}: ${v}`);
                            });
                        } else {
                            console.log(`  ${key}: ${value}`);
                        }
                    });
                });
                console.log('-------------------------------');

                // Actualizar información de paginación
                if (response.pagination) {
                    setCurrentPage(response.pagination.currentPage);
                    setTotalPages(response.pagination.totalPages);
                    setTotalRecords(response.pagination.totalRecords);
                }

                setError(null);
            } else {
                throw new Error('Error al cargar los datos de clientes');
            }
        } catch (err) {
            console.error('Error cargando clientes:', err);
            setError('Error al cargar los datos. Por favor, intente nuevamente.');
            setClientes([]);
            setFilteredClientes([]);
        } finally {
            setIsLoading(false);
        }
    };

    // Carga inicial de datos y recarga cuando cambia la sucursal
    useEffect(() => {
        if (sucursalActiva) {
            loadClientes(filters.search, 1);
            setCurrentPage(1);
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [sucursalActiva]);

    // Filtrado local solo por categoría (la búsqueda se hace en el servidor)
    useEffect(() => {
        let filtered = clientes;

        if (filters.categoria !== 'all') {
            filtered = filtered.filter(cliente => cliente.categoria === filters.categoria);
        }

        setFilteredClientes(filtered);
        setCurrentPage(1);
    }, [filters.categoria, clientes]);

    // Función para manejar la búsqueda con el botón
    const handleSearch = () => {
        loadClientes(searchText, 1); // Buscar con el texto ingresado
        setFilters(prev => ({ ...prev, search: searchText }));
        setCurrentPage(1);
    };

    // Función para limpiar la búsqueda
    const handleClearSearch = () => {
        setSearchText('');
        setFilters(prev => ({ ...prev, search: '' }));
        loadClientes('', 1);
        setCurrentPage(1);
    };

    // Permitir buscar con Enter
    const handleKeyPress = (e) => {
        if (e.key === 'Enter') {
            handleSearch();
        }
    };

    // Paginación
    const indexOfLastCliente = currentPage * clientesPerPage;
    const indexOfFirstCliente = indexOfLastCliente - clientesPerPage;
    const currentClientes = filteredClientes.slice(indexOfFirstCliente, indexOfLastCliente);

    const handleFilterChange = (filterType, value) => {
        setFilters(prev => ({
            ...prev,
            [filterType]: value
        }));
    };

    const handleResetFilters = () => {
        setSearchText('');
        setFilters({
            search: '',
            categoria: 'all'
        });
        loadClientes('', 1);
        setCurrentPage(1);
    };

    const handleVerDetalles = async (cliente) => {
        try {
            // Obtener detalles completos del cliente desde la API
            const response = await ClientesService.getClienteById(cliente.id);
            if (response.success) {

                // Extraer el primer objeto si la respuesta es un array
                const d = Array.isArray(response.data) ? response.data[0] : response.data;

                const clienteDetallado = {
                    ...cliente,
                    clienteid: d.CustomerID || cliente.id,
                    nombre: d.NombreCliente || d.CustomerName || cliente.nombre || 'N/A',
                    categoria: d.Categoria || cliente.categoria || 'N/A',
                    grupoCompra: d.GrupoCompra || cliente.grupoCompra || 'N/A',
                    metodoEntrega: d.MetodoEntrega || cliente.metodoEntrega || 'N/A',
                    limiteCredito: d.LimiteCredito ?? d.CreditLimit ?? cliente.limiteCredito ?? 0,
                    diasPago: d.DiasGraciaPago ?? d.PaymentDays ?? cliente.diasPago ?? 0,
                    descuentoEstandar: d.PorcentajeDescuentoEstandar ?? d.StandardDiscountPercentage ?? cliente.descuentoEstandar ?? 0,
                    fechaApertura: d.FechaAperturaCuenta || d.AccountOpenedDate || cliente.fechaApertura || '',
                    enEspera: d.EstadoCredito === 'En Hold de Crédito',
                    telefono: d.Telefono || d.PhoneNumber || cliente.telefono || 'N/A',
                    fax: d.Fax || d.FaxNumber || cliente.fax || 'N/A',
                    sitioWeb: d.SitioWeb || d.WebsiteURL || cliente.sitioWeb || 'N/A',
                    ciudadCompleta: `${d.CiudadEntrega || ''}, ${d.EstadoEntrega || ''}, ${d.PaisEntrega || ''}`,
                    direccionEntrega1: d.DireccionEntrega1 || '',
                    direccionEntrega2: d.DireccionEntrega2 || '',
                    codigoPostalEntrega: d.CodigoPostalEntrega || '',
                    direccionPostal1: d.DireccionPostal1 || '',
                    direccionPostal2: d.DireccionPostal2 || '',
                    codigoPostalPostal: d.CodigoPostalPostal || '',
                    latitud: d.LatitudEntrega ?? null,
                    longitud: d.LongitudEntrega ?? null,
                    contactoPrimario: {
                        fullName: d.ContactoPrimarioNombre || 'N/A',
                        phoneNumber: d.ContactoPrimarioTelefono || 'N/A',
                        emailAddress: d.ContactoPrimarioEmail || 'N/A',
                    },
                    contactoAlternativo: d.ContactoAlternativoNombre ? {
                        fullName: d.ContactoAlternativoNombre,
                        phoneNumber: d.ContactoAlternativoTelefono || 'N/A',
                        emailAddress: d.ContactoAlternativoEmail || 'N/A',
                    } : null,
                };
                setSelectedCliente(clienteDetallado);
            } else {
                setSelectedCliente(cliente);
            }
        } catch (error) {
            console.error('Error cargando detalles del cliente:', error);
            // Si hay error, usar los datos que ya tenemos
            setSelectedCliente(cliente);
        }
        setShowModal(true);
    };

    const retry = () => {
        loadClientes(filters.search);
    };

    // Función para cambiar de página
    const handlePageChange = (newPage) => {
        if (newPage >= 1 && newPage <= totalPages) {
            loadClientes(filters.search, newPage);
        }
    };

    if (isLoading) {
        return (
            <div className={styles.container}>
                <div className={styles.loadingContainer}>
                    <div className={styles.loadingSpinner} aria-label="Cargando clientes"></div>
                    <p className={styles.loadingText}>Cargando clientes...</p>
                </div>
            </div>
        );
    }

    if (error) {
        return (
            <div className={styles.container}>
                <div className={styles.errorContainer}>
                    <AlertCircle size={48} className={styles.errorIcon} />
                    <h2 className={styles.errorTitle}>Error al cargar la información</h2>
                    <p className={styles.errorMessage}>{error}</p>
                    <button
                        onClick={retry}
                        className={styles.retryButton}
                        aria-label="Reintentar carga de información"
                    >
                        <RotateCcw size={20} />
                        Reintentar
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className={styles.container}>
            {/* Skip Link */}
            <a
                href="#main-content"
                className={styles.skipLink}
                ref={skipLinkRef}
                tabIndex="0"
            >
                Saltar al contenido principal
            </a>

            {/* Header */}
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
                            Gestión de Clientes
                        </h1>
                        {sucursalActiva && (
                            <div 
                                className={styles.sucursalBadge}
                                style={{ 
                                    backgroundColor: getSucursalColor(),
                                    color: 'white'
                                }}
                            >
                                <Database size={16} />
                                <span>{sucursalActiva.nombre}</span>
                            </div>
                        )}
                    </div>
                    <p className={styles.headerSubtitle}>
                        {sucursalActiva?.id === 'corporativo' 
                            ? 'Vista consolidada de todas las sucursales' 
                            : `Clientes de sucursal ${sucursalActiva?.nombre}`
                        }
                    </p>
                </div>
            </header>

            <main id="main-content" className={styles.mainContent}>
                {/* Filtros y Búsqueda */}
                <section className={styles.filtersSection} aria-labelledby="filters-title">
                    <h2 id="filters-title" className={styles.sectionTitle}>
                        <Filter size={24} />
                        Filtros y Búsqueda
                    </h2>

                    <div className={styles.filters}>
                        <div className={styles.searchContainer}>
                            <Search size={20} className={styles.searchIcon} />
                            <input
                                type="text"
                                placeholder="Buscar por nombre de cliente"
                                value={searchText}
                                onChange={(e) => setSearchText(e.target.value)}
                                onKeyPress={handleKeyPress}
                                className={styles.searchInput}
                                aria-label="Buscar clientes"
                            />
                            <button
                                onClick={handleSearch}
                                className={styles.searchButton}
                                aria-label="Buscar"
                                title="Buscar clientes"
                            >
                                <Search size={18} />
                                Buscar
                            </button>
                            {searchText && (
                                <button
                                    onClick={handleClearSearch}
                                    className={styles.clearButton}
                                    aria-label="Limpiar búsqueda"
                                    title="Limpiar búsqueda"
                                >
                                    ✕
                                </button>
                            )}
                        </div>

                        <div className={styles.filterButtons}>
                            <button
                                onClick={() => handleFilterChange('categoria', 'all')}
                                className={`${styles.filterButton} ${filters.categoria === 'all' ? styles.active : ''}`}
                                aria-pressed={filters.categoria === 'all'}
                            >
                                <Building2 size={16} />
                                Todas las categorías
                            </button>
                            <button
                                onClick={() => handleFilterChange('categoria', 'Novelty Shop')}
                                className={`${styles.filterButton} ${filters.categoria === 'Novelty Shop' ? styles.active : ''}`}
                                aria-pressed={filters.categoria === 'Novelty Shop'}
                            >
                                Novelty Shop
                            </button>
                            <button
                                onClick={() => handleFilterChange('categoria', 'Supermarket')}
                                className={`${styles.filterButton} ${filters.categoria === 'Supermarket' ? styles.active : ''}`}
                                aria-pressed={filters.categoria === 'Supermarket'}
                            >
                                Supermarket
                            </button>
                            <button
                                onClick={() => handleFilterChange('categoria', 'Corporate')}
                                className={`${styles.filterButton} ${filters.categoria === 'Corporate' ? styles.active : ''}`}
                                aria-pressed={filters.categoria === 'Corporate'}
                            >
                                Corporate
                            </button>

                            <button
                                onClick={handleResetFilters}
                                className={styles.resetButton}
                                aria-label="Restaurar filtros"
                            >
                                <RefreshCw size={16} />
                                Restaurar Filtros
                            </button>
                        </div>
                    </div>

                    <div className={styles.resultsInfo}>
                        <p>
                            Mostrando {filteredClientes.length} cliente(s)
                            {filters.search && ` para "${filters.search}"`}
                        </p>
                    </div>
                </section>

                {/* Lista de Clientes */}
                <section className={styles.clientesSection} aria-labelledby="clientes-title">
                    <h3 id="clientes-title" className="sr-only">Lista de clientes</h3>

                    {filteredClientes.length === 0 ? (
                        <div className={styles.emptyState}>
                            <FileX size={48} className={styles.emptyIcon} />
                            <h3 className={styles.emptyTitle}>No se encontraron clientes</h3>
                            <p className={styles.emptyMessage}>
                                No hay clientes que coincidan con los filtros aplicados.
                            </p>
                            <button
                                onClick={handleResetFilters}
                                className={styles.resetButton}
                            >
                                <RefreshCw size={20} />
                                Mostrar todos los clientes
                            </button>
                        </div>
                    ) : (
                        <>
                            <div className={styles.clientesTable}>
                                <div className={styles.tableHeader}>
                                    <div className={styles.headerCell}>Nombre del Cliente</div>
                                    <div className={styles.headerCell}>Categoría</div>
                                    <div className={styles.headerCell}>Método de Entrega</div>
                                    <div className={styles.headerCell}>Ciudad</div>
                                    <div className={styles.headerCell}>Acciones</div>
                                </div>

                                <div className={styles.tableBody} role="list">
                                    {currentClientes.map((cliente) => (
                                        <div
                                            key={cliente.id}
                                            className={styles.tableRow}
                                            role="listitem"
                                        >
                                            <div className={styles.tableCell}>
                                                <div className={styles.clienteInfo}>
                                                    <Users size={20} className={styles.clienteIcon} />
                                                    <div>
                                                        <span className={styles.clienteNombre}>{cliente.nombre}</span>
                                                        <span className={styles.clienteContacto}>
                                                            <Phone size={14} />
                                                            {cliente.telefono}
                                                        </span>
                                                    </div>
                                                </div>
                                            </div>
                                            <div className={styles.tableCell}>
                                                <span className={styles.categoria}>{cliente.categoria}</span>
                                            </div>
                                            <div className={styles.tableCell}>
                                                <span className={styles.metodoEntrega}>{cliente.metodoEntrega}</span>
                                            </div>
                                            <div className={styles.tableCell}>
                                                <span className={styles.ciudad}>
                                                    <MapPin size={14} />
                                                    {cliente.ciudad}
                                                </span>
                                            </div>
                                            <div className={styles.tableCell}>
                                                <button
                                                    onClick={() => handleVerDetalles(cliente)}
                                                    className={styles.detailButton}
                                                    aria-label={`Ver detalles de ${cliente.nombre}`}
                                                >
                                                    <Eye size={16} />
                                                    Ver Detalles
                                                </button>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </div>

                            {/* Paginación */}
                            {totalPages > 1 && (
                                <div className={styles.pagination} role="navigation" aria-label="Navegación de páginas">
                                    <button
                                        onClick={() => handlePageChange(currentPage - 1)}
                                        disabled={currentPage === 1}
                                        className={styles.paginationButton}
                                        aria-label="Página anterior"
                                    >
                                        Anterior
                                    </button>

                                    <span className={styles.paginationInfo} aria-live="polite">
                                        Página {currentPage} de {totalPages} ({totalRecords} clientes total)
                                    </span>

                                    <button
                                        onClick={() => handlePageChange(currentPage + 1)}
                                        disabled={currentPage === totalPages}
                                        className={styles.paginationButton}
                                        aria-label="Página siguiente"
                                    >
                                        Siguiente
                                    </button>
                                </div>
                            )}
                        </>
                    )}
                </section>
            </main>

            {/* Modal de Detalles del Cliente */}
            {showModal && selectedCliente && (
                <ClienteModal
                    cliente={selectedCliente}
                    onClose={() => setShowModal(false)}
                />
            )}
        </div>
    );
};

// Componente Modal de Detalles del Cliente
const ClienteModal = ({ cliente, onClose }) => {
    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('es-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 2
        }).format(amount);
    };

    const formatDate = (dateString) => {
        const date = new Date(dateString);
        return date.toLocaleDateString('es-ES', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
        });
    };

    return (
        <div className={styles.modalOverlay} onClick={onClose}>
            <div className={styles.modalContent} onClick={e => e.stopPropagation()}>
                <div className={styles.modalHeader}>
                    <h2>
                        <Users size={24} />
                        Detalles del Cliente
                    </h2>
                    <button onClick={onClose} className={styles.modalClose}>
                        ✕
                    </button>
                </div>

                <div className={styles.modalBody}>
                    <div className={styles.clienteDetails}>
                        <div className={styles.detailGroup}>
                            <h3>Información General</h3>
                            <div className={styles.detailItem}>
                                <Users size={16} />
                                <span className={styles.detailLabel}>Nombre del Cliente:</span>
                                <span className={styles.detailValue}>{cliente.nombre}</span>
                            </div>
                            <div className={styles.detailItem}>
                                <Building2 size={16} />
                                <span className={styles.detailLabel}>Categoría:</span>
                                <span className={styles.detailValue}>{cliente.categoria}</span>
                            </div>
                            <div className={styles.detailItem}>
                                <Building2 size={16} />
                                <span className={styles.detailLabel}>Grupo de Compra:</span>
                                <span className={styles.detailValue}>{cliente.grupoCompra}</span>
                            </div>
                            <div className={styles.detailItem}>
                                <Calendar size={16} />
                                <span className={styles.detailLabel}>Fecha de Apertura:</span>
                                <span className={styles.detailValue}>{formatDate(cliente.fechaApertura)}</span>
                            </div>
                        </div>

                        <div className={styles.detailGroup}>
                            <h3>Información Financiera</h3>
                            <div className={styles.detailItem}>
                                <CreditCard size={16} />
                                <span className={styles.detailLabel}>Límite de Crédito:</span>
                                <span className={styles.detailValue}>{formatCurrency(cliente.limiteCredito)}</span>
                            </div>
                            <div className={styles.detailItem}>
                                <Calendar size={16} />
                                <span className={styles.detailLabel}>Días de Gracia para Pagar:</span>
                                <span className={styles.detailValue}>{cliente.diasPago} días</span>
                            </div>
                            <div className={styles.detailItem}>
                                <span className={styles.detailLabel}>Descuento Estándar:</span>
                                <span className={styles.detailValue}>{cliente.descuentoEstandar}%</span>
                            </div>
                            <div className={styles.detailItem}>
                                <span className={styles.detailLabel}>En Espera de Crédito:</span>
                                <span className={`${styles.detailValue} ${cliente.enEspera ? styles.warning : styles.success}`}>
                                    {cliente.enEspera ? 'Sí' : 'No'}
                                </span>
                            </div>
                        </div>

                        <div className={styles.detailGroup}>
                            <h3>Contactos</h3>
                            {cliente.contactoPrimario && (
                                <div className={styles.contactCard}>
                                    <h4>
                                        <User size={16} />
                                        Contacto Primario
                                    </h4>
                                    <div className={styles.detailItem}>
                                        <span className={styles.detailLabel}>Nombre:</span>
                                        <span className={styles.detailValue}>{cliente.contactoPrimario.fullName}</span>
                                    </div>
                                    <div className={styles.detailItem}>
                                        <Phone size={16} />
                                        <span className={styles.detailLabel}>Teléfono:</span>
                                        <span className={styles.detailValue}>{cliente.contactoPrimario.phoneNumber}</span>
                                    </div>
                                    <div className={styles.detailItem}>
                                        <Mail size={16} />
                                        <span className={styles.detailLabel}>Email:</span>
                                        <span className={styles.detailValue}>
                                            <a href={`mailto:${cliente.contactoPrimario.emailAddress}`}>
                                                {cliente.contactoPrimario.emailAddress}
                                            </a>
                                        </span>
                                    </div>
                                </div>
                            )}

                            {cliente.contactoAlternativo && (
                                <div className={styles.contactCard}>
                                    <h4>
                                        <UserCheck size={16} />
                                        Contacto Alternativo
                                    </h4>
                                    <div className={styles.detailItem}>
                                        <span className={styles.detailLabel}>Nombre:</span>
                                        <span className={styles.detailValue}>{cliente.contactoAlternativo.fullName}</span>
                                    </div>
                                    <div className={styles.detailItem}>
                                        <Phone size={16} />
                                        <span className={styles.detailLabel}>Teléfono:</span>
                                        <span className={styles.detailValue}>{cliente.contactoAlternativo.phoneNumber}</span>
                                    </div>
                                    <div className={styles.detailItem}>
                                        <Mail size={16} />
                                        <span className={styles.detailLabel}>Email:</span>
                                        <span className={styles.detailValue}>
                                            <a href={`mailto:${cliente.contactoAlternativo.emailAddress}`}>
                                                {cliente.contactoAlternativo.emailAddress}
                                            </a>
                                        </span>
                                    </div>
                                </div>
                            )}
                        </div>

                        <div className={styles.detailGroup}>
                            <h3>Información de Contacto General</h3>
                            <div className={styles.detailItem}>
                                <Phone size={16} />
                                <span className={styles.detailLabel}>Teléfono Principal:</span>
                                <span className={styles.detailValue}>{cliente.telefono}</span>
                            </div>
                            <div className={styles.detailItem}>
                                <Phone size={16} />
                                <span className={styles.detailLabel}>Fax:</span>
                                <span className={styles.detailValue}>{cliente.fax}</span>
                            </div>
                            <div className={styles.detailItem}>
                                <Globe size={16} />
                                <span className={styles.detailLabel}>Sitio Web:</span>
                                <span className={styles.detailValue}>
                                    <a href={cliente.sitioWeb} target="_blank" rel="noopener noreferrer">
                                        {cliente.sitioWeb}
                                    </a>
                                </span>
                            </div>
                        </div>

                        <div className={styles.detailGroup}>
                            <h3>Método de Entrega</h3>
                            <div className={styles.detailItem}>
                                <span className={styles.detailLabel}>Método:</span>
                                <span className={styles.detailValue}>{cliente.metodoEntrega}</span>
                            </div>
                        </div>

                        <div className={styles.detailGroup}>
                            <h3>Direcciones</h3>
                            <div className={styles.addressCard}>
                                <h4>Dirección de Entrega</h4>
                                <div className={styles.addressContent}>
                                    <MapPin size={16} />
                                    <div>
                                        <p>{cliente.direccionEntrega1}</p>
                                        {cliente.direccionEntrega2 && <p>{cliente.direccionEntrega2}</p>}
                                        <p>{cliente.ciudadCompleta}</p>
                                        <p>Código Postal: {cliente.codigoPostalEntrega}</p>
                                    </div>
                                </div>
                            </div>

                            <div className={styles.addressCard}>
                                <h4>Dirección Postal</h4>
                                <div className={styles.addressContent}>
                                    <Mail size={16} />
                                    <div>
                                        <p>{cliente.direccionPostal1}</p>
                                        {cliente.direccionPostal2 && <p>{cliente.direccionPostal2}</p>}
                                        <p>{cliente.ciudadCompleta}</p>
                                        <p>Código Postal: {cliente.codigoPostalPostal}</p>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className={styles.detailGroup}>
                            <h3>Localización en Mapa</h3>
                            <MapComponent
                                latitud={cliente.latitud}
                                longitud={cliente.longitud}
                                ciudad={cliente.ciudadCompleta}
                                direccion={`${cliente.direccionEntrega1 || ''} ${cliente.direccionEntrega2 || ''}`.trim()}
                                height="350px"
                            />
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Clientes;
