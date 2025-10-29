// services/proveedoresService.js - VERSIÓN CORREGIDA
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

class ProveedoresService {
    /**
     * Obtiene todos los proveedores con filtros opcionales y paginación
     */
    static async getProveedores(params = {}) {
        try {
            const searchParams = new URLSearchParams();
            
            // Mapear los parámetros del frontend a los que espera el backend
            if (params.search) {
                searchParams.append('search', params.search);
            }
            if (params.page) {
                searchParams.append('page', params.page);
            }
            if (params.pageSize) {
                searchParams.append('pageSize', params.pageSize);
            }
            if (params.category) {
                searchParams.append('category', params.category);
            }
            if (params.orderBy) {
                searchParams.append('orderBy', params.orderBy);
            }
            if (params.orderDirection) {
                searchParams.append('orderDirection', params.orderDirection);
            }
            
            const url = `${API_BASE_URL}/proveedores${searchParams.toString() ? '?' + searchParams.toString() : ''}`;
            
            console.log('ProveedoresService: Llamando a', url);

            const response = await fetch(url, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            console.log('ProveedoresService: Respuesta recibida', data);
            return data;
        } catch (error) {
            console.error('Error obteniendo proveedores:', error);
            throw error;
        }
    }

    /**
     * Obtiene un proveedor específico por ID con todos los detalles
     */
    static async getProveedorById(id) {
        try {
            const response = await fetch(`${API_BASE_URL}/proveedores/${id}`, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            console.log('ProveedoresService: Detalles del proveedor recibidos:', data);
            return data;
        } catch (error) {
            console.error('Error obteniendo proveedor:', error);
            throw error;
        }
    }

    /**
     * Obtiene las categorías de proveedores disponibles
     */
    static async getSupplierCategories() {
        try {
            const response = await fetch(`${API_BASE_URL}/proveedores/categories`, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            console.log('ProveedoresService: Categorías recibidas:', data);
            return data;
        } catch (error) {
            console.error('Error obteniendo categorías:', error);
            throw error;
        }
    }

    /**
     * Obtiene estadísticas de proveedores
     */
    static async getProveedoresEstadisticas(params = {}) {
        try {
            const searchParams = new URLSearchParams();
            
            if (params.searchText) {
                searchParams.append('searchText', params.searchText);
            }
            if (params.categoria) {
                searchParams.append('categoria', params.categoria);
            }
            
            const url = `${API_BASE_URL}/proveedores/estadisticas${searchParams.toString() ? '?' + searchParams.toString() : ''}`;
            
            const response = await fetch(url, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            console.log('ProveedoresService: Estadísticas recibidas:', data);
            return data;
        } catch (error) {
            console.error('Error obteniendo estadísticas de proveedores:', error);
            throw error;
        }
    }

    /**
     * Obtiene el top de proveedores por términos de pago
     */
    static async getTopProveedoresByPaymentTerms() {
        try {
            const response = await fetch(`${API_BASE_URL}/proveedores/top-payment-terms`, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            console.log('ProveedoresService: Top proveedores recibidos:', data);
            return data;
        } catch (error) {
            console.error('Error obteniendo top proveedores:', error);
            throw error;
        }
    }
}

export default ProveedoresService;