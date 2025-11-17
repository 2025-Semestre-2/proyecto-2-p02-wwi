// services/clientesService.js
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

class ClientesService {
    /**
     * Construye el endpoint según la sucursal seleccionada
     * @param {string} sucursalId - ID de la sucursal (corporativo, sanJose, limon)
     * @returns {string} - Endpoint base para la sucursal
     */
    static _getEndpoint(sucursalId = 'corporativo') {
        let endpoint = `${API_BASE_URL}/clientes`;
        
        if (sucursalId === 'sanJose') {
            endpoint = `${API_BASE_URL}/clientes/sanjose`;
        } else if (sucursalId === 'limon') {
            endpoint = `${API_BASE_URL}/clientes/limon`;
        }
        // corporativo usa el endpoint base (consolidado)
        
        return endpoint;
    }

    /**
     * Obtiene todos los clientes con filtros opcionales y paginación
     * @param {Object} params - Parámetros de búsqueda y paginación
     * @param {string} sucursalId - ID de la sucursal (corporativo, sanJose, limon)
     */
    static async getClientes(params = {}, sucursalId = 'corporativo') {
        try {
            const searchParams = new URLSearchParams();
            
            if (params.searchText) {
                searchParams.append('searchText', params.searchText);
            }
            if (params.orderBy) {
                searchParams.append('orderBy', params.orderBy);
            }
            if (params.orderDirection) {
                searchParams.append('orderDirection', params.orderDirection);
            }
            if (params.pageNumber) {
                searchParams.append('pageNumber', params.pageNumber);
            }
            if (params.pageSize) {
                searchParams.append('pageSize', params.pageSize);
            }
            
            const endpoint = this._getEndpoint(sucursalId);
            const url = `${endpoint}${searchParams.toString() ? '?' + searchParams.toString() : ''}`;
            
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
            console.error('Error obteniendo clientes:', error);
            throw error;
        }
    }

    /**
     * Obtiene un cliente específico por ID con todos los detalles
     */
    static async getClienteById(id) {
        try {
            const response = await fetch(`${API_BASE_URL}/clientes/${id}`, {
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
            console.error('Error obteniendo cliente:', error);
            throw error;
        }
    }

    /**
     * Obtiene estadísticas de clientes
     * @param {Object} params - Parámetros de búsqueda
     * @param {string} sucursalId - ID de la sucursal (corporativo, sanJose, limon)
     */
    static async getClientesEstadisticas(params = {}, sucursalId = 'corporativo') {
        try {
            const searchParams = new URLSearchParams();
            
            if (params.searchText) {
                searchParams.append('searchText', params.searchText);
            }
            if (params.categoria) {
                searchParams.append('categoria', params.categoria);
            }
            
            const endpoint = this._getEndpoint(sucursalId);
            const url = `${endpoint}/estadisticas${searchParams.toString() ? '?' + searchParams.toString() : ''}`;
            
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
            console.error('Error obteniendo estadísticas de clientes:', error);
            throw error;
        }
    }

    /**
     * Obtiene el top de clientes por año
     * @param {Object} params - Parámetros con años
     * @param {string} sucursalId - ID de la sucursal (corporativo, sanJose, limon)
     */
    static async getTopClientesPorAnio(params = {}, sucursalId = 'corporativo') {
        try {
            const searchParams = new URLSearchParams();
            
            if (params.anioInicio) {
                searchParams.append('anioInicio', params.anioInicio);
            }
            if (params.anioFin) {
                searchParams.append('anioFin', params.anioFin);
            }
            
            const endpoint = this._getEndpoint(sucursalId);
            const url = `${endpoint}/top-por-anio${searchParams.toString() ? '?' + searchParams.toString() : ''}`;
            
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
            console.error('Error obteniendo top clientes:', error);
            throw error;
        }
    }

    /**
     * Obtiene las categorías de clientes disponibles
     * @param {string} sucursalId - ID de la sucursal (corporativo, sanJose, limon)
     */
    static async getCategorias(sucursalId = 'corporativo') {
        try {
            const endpoint = this._getEndpoint(sucursalId);
            const response = await fetch(`${endpoint}/categorias`, {
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
            console.error('Error obteniendo categorías:', error);
            throw error;
        }
    }
}

export default ClientesService;
