import { useContext } from 'react';
import SucursalContext from './SucursalContext';

// Custom hook to use the Sucursal context
const useSucursal = () => {
    const context = useContext(SucursalContext);
    if (!context) {
        throw new Error('useSucursal debe usarse dentro de un SucursalProvider');
    }
    return context;
};

export default useSucursal;