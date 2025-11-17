import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import useSucursal from '../../context/useSucursal';
import { Building2, MapPin, Database, ChevronRight, Check } from 'lucide-react';
import './Login.css';

const SUCURSALES = [
    {
        id: 'corporativo',
        nombre: 'Corporativo',
        ubicacion: 'San José - Oficina Central',
        descripcion: 'Acceso completo a datos consolidados de todas las sucursales',
        icono: Building2,
        color: '#1c4382', // Corporativo
        puerto: 1444,
        servidor: 'localhost,1444',
        baseDatos: 'WWI_Corporativo',
        permisos: ['ver_todo', 'reportes_globales', 'administración']
    },
    {
        id: 'sanJose',
        nombre: 'San José',
        ubicacion: 'San José - Sucursal',
        descripcion: 'Gestión de operaciones de la sucursal de San José',
        icono: MapPin,
        color: '#b91016', // San José
        puerto: 1445,
        servidor: 'localhost,1445',
        baseDatos: 'WWI_Sucursal_SJ',
        permisos: ['clientes_locales', 'inventario_local', 'ventas_locales']
    },
    {
        id: 'limon',
        nombre: 'Limón',
        ubicacion: 'Limón - Sucursal',
        descripcion: 'Gestión de operaciones de la sucursal de Limón',
        icono: MapPin,
        color: '#1c7e2f', // Limón
        puerto: 1446,
        servidor: 'localhost,1446',
        baseDatos: 'WWI_Sucursal_LIM',
        permisos: ['clientes_locales', 'inventario_local', 'ventas_locales']
    }
];

const Login = () => {
    const navigate = useNavigate();
    const { seleccionarSucursal } = useSucursal();
    const [selectedSucursal, setSelectedSucursal] = useState(null);
    const [hoveredCard, setHoveredCard] = useState(null);

    const handleSucursalSelect = (sucursal) => {
        setSelectedSucursal(sucursal);
    };

    const handleContinuar = () => {
        if (selectedSucursal) {
            // Guardar sucursal en el context
            seleccionarSucursal(selectedSucursal);
            
            // Navegar al home
            navigate('/home');
            
            console.log('Sucursal seleccionada:', {
                nombre: selectedSucursal.nombre,
                servidor: selectedSucursal.servidor,
                baseDatos: selectedSucursal.baseDatos
            });
        }
    };

    return (
        <div className="login-container">
            <div className="login-content">
                {/* Header */}
                <div className="login-header">
                    <div className="logo-section">
                        <Database size={48} className="logo-icon" />
                        <h1 className="logo-text">Wide World Importers</h1>
                    </div>
                    <p className="subtitle">Sistema de Gestión Distribuido</p>
                </div>

                {/* Información */}
                <div className="info-section">
                    <h2>Selecciona tu Sucursal</h2>
                    <p>Elige la sucursal desde la cual deseas acceder al sistema</p>
                </div>

                {/* Cards de sucursales */}
                <div className="sucursales-grid">
                    {SUCURSALES.map((sucursal) => {
                        const Icon = sucursal.icono;
                        const isSelected = selectedSucursal?.id === sucursal.id;
                        const isHovered = hoveredCard === sucursal.id;

                        return (
                            <div
                                key={sucursal.id}
                                className={`sucursal-card ${isSelected ? 'selected' : ''} ${isHovered ? 'hovered' : ''}`}
                                onClick={() => handleSucursalSelect(sucursal)}
                                onMouseEnter={() => setHoveredCard(sucursal.id)}
                                onMouseLeave={() => setHoveredCard(null)}
                                style={{
                                    borderColor: isSelected ? sucursal.color : 'transparent'
                                }}
                            >
                                {/* Indicador de selección */}
                                {isSelected && (
                                    <div 
                                        className="selection-indicator"
                                        style={{ backgroundColor: sucursal.color }}
                                    >
                                        <Check size={20} />
                                    </div>
                                )}

                                {/* Icono */}
                                <div 
                                    className="sucursal-icon"
                                    style={{ 
                                        backgroundColor: `${sucursal.color}20`,
                                        color: sucursal.color 
                                    }}
                                >
                                    <Icon size={32} />
                                </div>

                                {/* Información */}
                                <div className="sucursal-info">
                                    <h3 className="sucursal-nombre">{sucursal.nombre}</h3>
                                    <p className="sucursal-ubicacion">{sucursal.ubicacion}</p>
                                    <p className="sucursal-descripcion">{sucursal.descripcion}</p>
                                </div>

                                {/* Detalles técnicos */}
                                <div className="sucursal-detalles">
                                    <div className="detalle-item">
                                        <span className="detalle-label">Base de datos:</span>
                                        <span className="detalle-value">{sucursal.baseDatos}</span>
                                    </div>
                                    <div className="detalle-item">
                                        <span className="detalle-label">Puerto:</span>
                                        <span className="detalle-value">{sucursal.puerto}</span>
                                    </div>
                                </div>

                                {/* Permisos */}
                                <div className="sucursal-permisos">
                                    {sucursal.permisos.map((permiso, index) => (
                                        <span key={index} className="permiso-badge">
                                            {permiso.replace(/_/g, ' ')}
                                        </span>
                                    ))}
                                </div>
                            </div>
                        );
                    })}
                </div>

                {/* Botón Continuar */}
                <button
                    className={`btn-continuar ${selectedSucursal ? 'active' : 'disabled'}`}
                    onClick={handleContinuar}
                    disabled={!selectedSucursal}
                >
                    <span>Continuar al Sistema</span>
                    <ChevronRight size={20} />
                </button>

                {/* Info adicional */}
                <div className="footer-info">
                    <p>La sucursal seleccionada determinará los datos y permisos disponibles</p>
                    <p className="tech-info">
                        Sistema Multi-Base: 3 servidores SQL independientes con replicación P2P
                    </p>
                </div>
            </div>
        </div>
    );
};

export default Login;
