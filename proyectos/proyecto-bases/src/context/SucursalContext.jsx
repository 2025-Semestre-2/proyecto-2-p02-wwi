// Context para manejar la sucursal activa en toda la aplicación
import React, { createContext, useState, useEffect } from 'react';


const SucursalContext = createContext();

export const SucursalProvider = ({ children }) => {
    // Recuperar sucursal del localStorage si existe
    const [sucursalActiva, setSucursalActiva] = useState(() => {
        const stored = localStorage.getItem('sucursalActiva');
        return stored ? JSON.parse(stored) : null;
    });

    // Guardar en localStorage cuando cambie
    useEffect(() => {
        if (sucursalActiva) {
            localStorage.setItem('sucursalActiva', JSON.stringify(sucursalActiva));
        } else {
            localStorage.removeItem('sucursalActiva');
        }
    }, [sucursalActiva]);

    const seleccionarSucursal = (sucursal) => {
        setSucursalActiva(sucursal);
    };

    const cerrarSesion = () => {
        setSucursalActiva(null);
        localStorage.removeItem('sucursalActiva');
    };

    const value = {
        sucursalActiva,
        seleccionarSucursal,
        cerrarSesion,
        isAuthenticated: !!sucursalActiva
    };

    return (
        <SucursalContext.Provider value={value}>
            {children}
        </SucursalContext.Provider>
    );
};

export default SucursalContext;
