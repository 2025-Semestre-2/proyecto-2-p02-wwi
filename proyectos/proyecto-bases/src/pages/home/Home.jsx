import './Home.css';
import { useNavigate } from 'react-router-dom';
import useSucursal from '../../context/useSucursal';
import { 
  Users, 
  Building2, 
  Package, 
  ShoppingCart, 
  BarChart3, 
  LogOut,
  MapPin,
  Database
} from 'lucide-react';

const Home = () => {
  const navigate = useNavigate();
  const { sucursalActiva, cerrarSesion } = useSucursal();

  const handleCerrarSesion = () => {
    cerrarSesion();
    navigate('/login');
  };

  // Colores por sucursal
  const getSucursalColor = () => {
    switch(sucursalActiva?.id) {
      case 'corporativo': return '#1c4382';
      case 'sanJose': return '#b91016';
      case 'limon': return '#1c7e2f';
      default: return '#6b7280';
    }
  };

  return (
    <div className="home-container">
      <div className="home-header">
        <div className="logo-container">
          <h1 className="logo-title">Wide World Importers</h1>
        </div>
        
        {/* Info de sucursal activa */}
        <div className="sucursal-info-header">
          <div className="sucursal-badge" style={{ borderColor: getSucursalColor() }}>
            {sucursalActiva?.id === 'corporativo' ? <Building2 size={20} /> : <MapPin size={20} />}
            <div className="sucursal-text">
              <span className="sucursal-label">Sucursal Activa:</span>
              <span className="sucursal-nombre" style={{ color: getSucursalColor() }}>
                {sucursalActiva?.nombre}
              </span>
            </div>
          </div>
          <div className="sucursal-detalles-mini">
            <Database size={14} />
            <span>{sucursalActiva?.baseDatos}</span>
          </div>
          <button className="btn-cerrar-sesion" onClick={handleCerrarSesion}>
            <LogOut size={18} />
            <span>Cambiar Sucursal</span>
          </button>
        </div>
      </div>

      <div className="home-content">
        <div className="welcome-section">
          <h2>Bienvenido al Sistema de Gestión</h2>
          <p>Selecciona un módulo para comenzar:</p>
        </div>

        <div className="navigation-grid">
          <a href="/clientes" className="nav-card">
            <div className="nav-icon">
              <Users size={32} />
            </div>
            <h3>Clientes</h3>
            <p>Gestión y consulta de clientes</p>
          </a>

          <a href="/proveedores" className="nav-card">
            <div className="nav-icon">
              <Building2 size={32} />
            </div>
            <h3>Proveedores</h3>
            <p>Gestión de proveedores y categorías</p>
          </a>

          <a href="/inventarios" className="nav-card">
            <div className="nav-icon">
              <Package size={32} />
            </div>
            <h3>Inventarios</h3>
            <p>Control de productos y stock</p>
          </a>

          <a href="/ventas" className="nav-card">
            <div className="nav-icon">
              <ShoppingCart size={32} />
            </div>
            <h3>Ventas</h3>
            <p>Consulta de facturas y ventas</p>
          </a>

          <a href="/estadisticas" className="nav-card">
            <div className="nav-icon">
              <BarChart3 size={32} />
            </div>
            <h3>Estadísticas</h3>
            <p>Reportes y análisis de datos</p>
          </a>
        </div>
      </div>
    </div>
  );
};

export default Home;
