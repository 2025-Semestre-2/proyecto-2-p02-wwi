import React, { useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import styles from './Estadisticas.module.css';
import { 
  BarChart3, 
  Users, 
  ShoppingCart, 
  Trophy, 
  TrendingUp, 
  ArrowLeft 
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
  const [activeTab, setActiveTab] = useState('proveedores');
  const skipLinkRef = useRef(null);

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
          <h1 className={styles.headerTitle}>
            <BarChart3 size={32} />
            Módulo de Estadísticas
          </h1>
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