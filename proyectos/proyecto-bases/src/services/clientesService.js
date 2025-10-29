// services/clientesService.js
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

class ClientesService {
    /**
     * Obtiene todos los clientes con filtros opcionales y paginación
     */
    static async getClientes(params = {}) {
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
            
            const url = `${API_BASE_URL}/clientes${searchParams.toString() ? '?' + searchParams.toString() : ''}`;
            
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
     */
    static async getClientesEstadisticas(params = {}) {
        try {
            const searchParams = new URLSearchParams();
            
            if (params.searchText) {
                searchParams.append('searchText', params.searchText);
            }
            if (params.categoria) {
                searchParams.append('categoria', params.categoria);
            }
            
            const url = `${API_BASE_URL}/clientes/estadisticas${searchParams.toString() ? '?' + searchParams.toString() : ''}`;
            
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
     */
    static async getTopClientesPorAnio(params = {}) {
        try {
            const searchParams = new URLSearchParams();
            
            if (params.anioInicio) {
                searchParams.append('anioInicio', params.anioInicio);
            }
            if (params.anioFin) {
                searchParams.append('anioFin', params.anioFin);
            }
            
            const url = `${API_BASE_URL}/clientes/top-por-anio${searchParams.toString() ? '?' + searchParams.toString() : ''}`;
            
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
     */
    static async getCategorias() {
        try {
            const response = await fetch(`${API_BASE_URL}/clientes/categorias`, {
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
