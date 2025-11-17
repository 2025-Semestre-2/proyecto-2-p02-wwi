// services/estadisticasService.js
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

class EstadisticasService {
    /**
     * Obtiene el endpoint correcto según la sucursal
     */
    static _getEndpoint(sucursalId) {
        const base = API_BASE_URL + '/estadisticas';
        if (sucursalId === 2) return base + '/sanjose';
        if (sucursalId === 3) return base + '/limon';
        return base;
    }

    /**
     * 1. Compras a proveedores con ROLLUP
     */
    static async getEstadisticasComprasProveedores(sucursalId, params = {}) {
        try {
            const searchParams = new URLSearchParams();
            
            if (params.searchTextProveedor) {
                searchParams.append('searchTextProveedor', params.searchTextProveedor);
            }
            if (params.searchTextCategoria) {
                searchParams.append('searchTextCategoria', params.searchTextCategoria);
            }
            
            const baseUrl = this._getEndpoint(sucursalId);
            const url = `${baseUrl}/proveedores/compras-rollup${searchParams.toString() ? '?' + searchParams.toString() : ''}`;
            
            const response = await fetch(url, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            return await response.json();
        } catch (error) {
            console.error('Error obteniendo estadísticas de compras a proveedores:', error);
            throw error;
        }
    }

    /**
     * 2. Ventas a clientes con ROLLUP
     */
    static async getEstadisticasVentasClientes(sucursalId, params = {}) {
        try {
            const searchParams = new URLSearchParams();
            
            if (params.searchTextCliente) {
                searchParams.append('searchTextCliente', params.searchTextCliente);
            }
            if (params.searchTextCategoria) {
                searchParams.append('searchTextCategoria', params.searchTextCategoria);
            }
            
            const baseUrl = this._getEndpoint(sucursalId);
            const url = `${baseUrl}/clientes/ventas-rollup${searchParams.toString() ? '?' + searchParams.toString() : ''}`;
            
            const response = await fetch(url, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            return await response.json();
        } catch (error) {
            console.error('Error obteniendo estadísticas de ventas a clientes:', error);
            throw error;
        }
    }

    /**
     * 3. Top 5 productos más rentables por año
     */
    static async getTopProductosRentables(sucursalId, params = {}) {
        try {
            const searchParams = new URLSearchParams();
            
            if (params.anio) {
                searchParams.append('anio', params.anio);
            }
            
            const baseUrl = this._getEndpoint(sucursalId);
            const url = `${baseUrl}/productos/top-rentables${searchParams.toString() ? '?' + searchParams.toString() : ''}`;
            
            const response = await fetch(url, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            return await response.json();
        } catch (error) {
            console.error('Error obteniendo top productos rentables:', error);
            throw error;
        }
    }

    /**
     * 4. Top 5 clientes con más facturas por año
     */
    static async getTopClientesFacturas(sucursalId, params = {}) {
        try {
            const searchParams = new URLSearchParams();
            
            if (params.anioInicio) {
                searchParams.append('anioInicio', params.anioInicio);
            }
            if (params.anioFin) {
                searchParams.append('anioFin', params.anioFin);
            }
            
            const baseUrl = this._getEndpoint(sucursalId);
            const url = `${baseUrl}/clientes/top-facturas${searchParams.toString() ? '?' + searchParams.toString() : ''}`;
            
            const response = await fetch(url, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            return await response.json();
        } catch (error) {
            console.error('Error obteniendo top clientes facturas:', error);
            throw error;
        }
    }

    /**
     * 5. Top 5 proveedores con más órdenes de compra por año
     */
    static async getTopProveedoresOrdenes(sucursalId, params = {}) {
        try {
            const searchParams = new URLSearchParams();
            
            if (params.anioInicio) {
                searchParams.append('anioInicio', params.anioInicio);
            }
            if (params.anioFin) {
                searchParams.append('anioFin', params.anioFin);
            }
            
            const baseUrl = this._getEndpoint(sucursalId);
            const url = `${baseUrl}/proveedores/top-ordenes${searchParams.toString() ? '?' + searchParams.toString() : ''}`;
            
            const response = await fetch(url, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            return await response.json();
        } catch (error) {
            console.error('Error obteniendo top proveedores ordenes:', error);
            throw error;
        }
    }

    /**
     * 6. Años disponibles
     */
    static async getAniosDisponibles(sucursalId) {
        try {
            const baseUrl = this._getEndpoint(sucursalId);
            const response = await fetch(`${baseUrl}/anios-disponibles`, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            return await response.json();
        } catch (error) {
            console.error('Error obteniendo años disponibles:', error);
            throw error;
        }
    }
}

export default EstadisticasService;