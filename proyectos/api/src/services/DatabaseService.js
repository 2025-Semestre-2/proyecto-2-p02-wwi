const { getConnection, sql } = require('../config/database');

class DatabaseService {
    /**
     * Ejecuta un procedimiento almacenado
     * @param {string} procedureName - Nombre del procedimiento almacenado
     * @param {Object} params - Parámetros del procedimiento
     * @returns {Promise} Resultado del procedimiento
     */
    static async executeStoredProcedure(procedureName, params = {}) {
        try {
            const pool = await getConnection();
            const request = pool.request();

            // Agregar parámetros
            Object.keys(params).forEach(key => {
                const param = params[key];
                if (param && typeof param === 'object' && param.type && param.value !== undefined) {
                    request.input(key, param.type, param.value);
                } else {
                    request.input(key, param);
                }
            });

            const result = await request.execute(procedureName);
            
            console.log(`DatabaseService: Resultado de ${procedureName}:`, {
                hasRecordset: !!result.recordset,
                hasRecordsets: !!result.recordsets,
                recordsetsLength: result.recordsets ? result.recordsets.length : 0,
                firstRecordsetLength: result.recordsets && result.recordsets[0] ? result.recordsets[0].length : 0
            });
            
            return {
                success: true,
                data: result.recordsets || result.recordset || [],
                rowsAffected: result.rowsAffected
            };
        } catch (error) {
            console.error(`Error ejecutando procedimiento ${procedureName}:`, error);
            throw error;
        }
    }

    /**
     * Ejecuta una consulta SQL directa
     * @param {string} query - Consulta SQL
     * @param {Object} params - Parámetros de la consulta
     * @returns {Promise} Resultado de la consulta
     */
    static async executeQuery(query, params = {}) {
        try {
            const pool = await getConnection();
            const request = pool.request();

            // Agregar parámetros
            Object.keys(params).forEach(key => {
                const param = params[key];
                if (param.type && param.value !== undefined) {
                    request.input(key, param.type, param.value);
                } else {
                    request.input(key, param);
                }
            });

            const result = await request.query(query);
            return {
                success: true,
                data: result.recordset,
                rowsAffected: result.rowsAffected
            };
        } catch (error) {
            console.error('Error ejecutando consulta:', error);
            throw error;
        }
    }

    /**
     * Valida la conexión a la base de datos
     * @returns {Promise<boolean>} True si la conexión es exitosa
     */
    static async testConnection() {
        try {
            const pool = await getConnection();
            await pool.request().query('SELECT 1 as test');
            return true;
        } catch (error) {
            console.error('Error testando conexión:', error);
            return false;
        }
    }
}

module.exports = DatabaseService;
