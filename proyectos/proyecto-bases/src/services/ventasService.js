// services/ventasService.js
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

class VentasService {
	/**
	 * Obtiene todas las ventas con filtros y paginación
	 */
	static async getVentas(params = {}) {
		try {
			const searchParams = new URLSearchParams();
			if (params.searchText) searchParams.append('searchText', params.searchText);
			if (params.startDate) searchParams.append('startDate', params.startDate);
			if (params.endDate) searchParams.append('endDate', params.endDate);
			if (params.minAmount) searchParams.append('minAmount', params.minAmount);
			if (params.maxAmount) searchParams.append('maxAmount', params.maxAmount);
			if (params.orderBy) searchParams.append('orderBy', params.orderBy);
			if (params.orderDirection) searchParams.append('orderDirection', params.orderDirection);
			if (params.pageNumber) searchParams.append('pageNumber', params.pageNumber);
			if (params.pageSize) searchParams.append('pageSize', params.pageSize);

			const url = `${API_BASE_URL}/ventas${searchParams.toString() ? '?' + searchParams.toString() : ''}`;
			const response = await fetch(url, {
				method: 'GET',
				headers: { 'Content-Type': 'application/json' },
			});
			if (!response.ok) {
				throw new Error(`HTTP error! status: ${response.status}`);
			}
			const data = await response.json();
			return data;
		} catch (error) {
			console.error('Error obteniendo ventas:', error);
			throw error;
		}
	}

	/**
	 * Obtiene una venta específica (factura) por ID
	 */
	static async getVentaById(id) {
		try {
			const response = await fetch(`${API_BASE_URL}/ventas/${id}`, {
				method: 'GET',
				headers: { 'Content-Type': 'application/json' },
			});
			if (!response.ok) {
				throw new Error(`HTTP error! status: ${response.status}`);
			}
			const data = await response.json();
			return data;
		} catch (error) {
			console.error('Error obteniendo venta:', error);
			throw error;
		}
	}
}

export default VentasService;
