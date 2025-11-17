const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

class InventariosService {
    /**
     * Construye el endpoint según la sucursal seleccionada
     * @param {string} sucursalId - ID de la sucursal (corporativo, sanJose, limon)
     * @returns {string} - Endpoint base para la sucursal
     */
    static _getEndpoint(sucursalId = 'corporativo') {
        let endpoint = `${API_BASE_URL}/inventarios`;
        
        if (sucursalId === 'sanJose') {
            endpoint = `${API_BASE_URL}/inventarios/sanjose`;
        } else if (sucursalId === 'limon') {
            endpoint = `${API_BASE_URL}/inventarios/limon`;
        }
        
        return endpoint;
    }

    /**
     * Obtiene todos los productos con filtros opcionales y paginación
     * @param {Object} params - Parámetros de búsqueda y paginación
     * @param {string} sucursalId - ID de la sucursal (corporativo, sanJose, limon)
     */
    static async getStockItems(params = {}, sucursalId = 'corporativo') {
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

            const endpoint = this._getEndpoint(sucursalId);
            const url = `${endpoint}${queryParams.toString() ? `?${queryParams.toString()}` : ''}`;
            
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
     * @param {string} sucursalId - ID de la sucursal (corporativo, sanJose, limon)
     */
    static async getStockGroups(sucursalId = 'corporativo') {
        try {
            const endpoint = this._getEndpoint(sucursalId);
            const response = await fetch(`${endpoint}/stock-groups`);

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
