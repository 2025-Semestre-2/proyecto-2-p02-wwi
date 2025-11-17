import React, { useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useSucursal } from '../../context/useSucursal';
import styles from './Estadisticas.module.css';
import { 
  BarChart3, 
  Users, 
  ShoppingCart, 
  Trophy, 
  TrendingUp, 
  ArrowLeft,
  Database
} from 'lucide-react';

// Importar los componentes de cada pestaña
import EstadisticasProveedores from './EstadisticasProveedores.jsx';
import EstadisticasClientes from './EstadisticasClientes';
import TopProductosRentables from './TopProductosRentables.jsx';
import TopClientesFacturas from './TopClientesFacturas.jsx';
import TopProveedoresOrdenes from './TopProveedoresOrdenes.jsx';

const TABS = [
  { key: 'proveedores', label: 'Compras a Proveedores', icon: <ShoppingCart size={18} /> },
  { key: 'clientes', label: 'Ventas a Clientes', icon: <Users size={18} /> },
  { key: 'productos', label: 'Top Productos Rentables', icon: <TrendingUp size={18} /> },
  { key: 'topClientes', label: 'Top Clientes', icon: <Trophy size={18} /> },
  { key: 'topProveedores', label: 'Top Proveedores', icon: <BarChart3 size={18} /> },
];

function Estadisticas() {
  const navigate = useNavigate();
  const { sucursalActiva } = useSucursal();
  const [activeTab, setActiveTab] = useState('proveedores');
  const skipLinkRef = useRef(null);
  
  // Helper para obtener color de sucursal
  const getSucursalColor = (id) => {
    const colors = { 1: '#1c4382', 2: '#b91016', 3: '#1c7e2f' };
    return colors[id] || '#1c4382';
  };

  const renderActiveTab = () => {
    switch (activeTab) {
      case 'proveedores':
        return <EstadisticasProveedores />;
      case 'clientes':
        return <EstadisticasClientes />;
      case 'productos':
        return <TopProductosRentables />;
      case 'topClientes':
        return <TopClientesFacturas />;
      case 'topProveedores':
        return <TopProveedoresOrdenes />;
      default:
        return <EstadisticasProveedores />;
    }
  };

  return (
    <div className={styles.container}>
      <a 
        href="#main-content" 
        className={styles.skipLink}
        ref={skipLinkRef}
        tabIndex="0"
      >
        Saltar al contenido principal
      </a>
      
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
              <BarChart3 size={32} />
              Módulo de Estadísticas
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
            Consulta y análisis de datos clave del negocio
          </p>
        </div>
      </header>

      <div className={styles.tabs}>
        {TABS.map(tab => (
          <button
            key={tab.key}
            className={`${styles.tabButton} ${activeTab === tab.key ? styles.active : ''}`}
            onClick={() => setActiveTab(tab.key)}
            aria-selected={activeTab === tab.key}
          >
            {tab.icon} {tab.label}
          </button>
        ))}
      </div>

      <main id="main-content" className={styles.mainContent}>
        {renderActiveTab()}
      </main>
    </div>
  );
}

export default Estadisticas;