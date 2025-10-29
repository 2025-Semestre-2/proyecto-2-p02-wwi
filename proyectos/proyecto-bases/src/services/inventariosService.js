const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

class InventariosService {
    /**
     * Obtiene todos los productos con filtros opcionales y paginación
     */
    static async getStockItems(params = {}) {
        try {
            const queryParams = new URLSearchParams();

            // Agregar parámetros si existen
            if (params.searchText) queryParams.append('searchText', params.searchText);
            if (params.minQuantity) queryParams.append('minQuantity', params.minQuantity);
            if (params.maxQuantity) queryParams.append('maxQuantity', params.maxQuantity);
            if (params.orderBy) queryParams.append('orderBy', params.orderBy);
            if (params.orderDirection) queryParams.append('orderDirection', params.orderDirection);
            if (params.pageNumber) queryParams.append('pageNumber', params.pageNumber);
            if (params.pageSize) queryParams.append('pageSize', params.pageSize);

            const url = `${API_BASE_URL}/inventarios${queryParams.toString() ? `?${queryParams.toString()}` : ''}`;
            
            console.log('InventariosService: Llamando a', url);

            const response = await fetch(url);

            if (!response.ok) {
                throw new Error(`Error ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            console.log('InventariosService: Respuesta recibida', data);

            return data;
        } catch (error) {
            console.error('Error en InventariosService.getStockItems:', error);
            throw error;
        }
    }

    /**
     * Obtiene un producto específico por ID
     */
    static async getStockItemById(id) {
        try {
            const response = await fetch(`${API_BASE_URL}/inventarios/${id}`);

            if (!response.ok) {
                throw new Error(`Error ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            return data;
        } catch (error) {
            console.error('Error en InventariosService.getStockItemById:', error);
            throw error;
        }
    }

    /**
     * Obtiene todos los grupos de stock para filtros dinámicos
     */
    static async getStockGroups() {
        try {
            const response = await fetch(`${API_BASE_URL}/inventarios/stock-groups`);

            if (!response.ok) {
                throw new Error(`Error ${response.status}: ${response.statusText}`);
            }

            return await response.json();
        } catch (error) {
            console.error('Error en InventariosService.getStockGroups:', error);
            throw error;
        }
    }
}

export default InventariosService;
