USE WideWorldImporters;
GO

-- Ver cómo están actualmente antes de cambiar
SELECT StateProvinceID, StateProvinceCode, StateProvinceName
FROM Application.StateProvinces
WHERE StateProvinceName IN (
    'Texas', 'Pennsylvania', 'New York', 'California',
    'Florida', 'Ohio', 'Oklahoma'
)
ORDER BY StateProvinceName;

-- Cambiar nombres de estados a provincias de Costa Rica

UPDATE Application.StateProvinces
SET StateProvinceName = N'San José'
WHERE StateProvinceName = 'Texas';

UPDATE Application.StateProvinces
SET StateProvinceName = N'Heredia'
WHERE StateProvinceName = 'Pennsylvania';

UPDATE Application.StateProvinces
SET StateProvinceName = N'Alajuela'
WHERE StateProvinceName = 'New York';

UPDATE Application.StateProvinces
SET StateProvinceName = N'Cartago'
WHERE StateProvinceName = 'California';

UPDATE Application.StateProvinces
SET StateProvinceName = N'Limón'
WHERE StateProvinceName = 'Florida';

UPDATE Application.StateProvinces
SET StateProvinceName = N'Guanacaste'
WHERE StateProvinceName = 'Ohio';

UPDATE Application.StateProvinces
SET StateProvinceName = N'Puntarenas'
WHERE StateProvinceName = 'Oklahoma';

-- (Opcional) Verificar cambios
SELECT StateProvinceID, StateProvinceCode, StateProvinceName
FROM Application.StateProvinces
WHERE StateProvinceName IN (
    N'San José', N'Heredia', N'Alajuela', N'Cartago',
    N'Limón', N'Guanacaste', N'Puntarenas'
)
ORDER BY StateProvinceName;
