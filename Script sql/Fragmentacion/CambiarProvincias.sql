USE WideWorldImporters;
GO

/* 1) Crear columna para el grupo de provincia si no existe */
IF NOT EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('Application.StateProvinces')
      AND name = 'StateProvinceGroup'
)
BEGIN
    ALTER TABLE Application.StateProvinces
    ADD StateProvinceGroup NVARCHAR(50) NULL;
END;
GO

/* 2) Asignar a CADA provincia un grupo de Costa Rica (7 grupos) de forma aleatoria */
WITH Enumeradas AS (
    SELECT 
        sp.StateProvinceID,
        ROW_NUMBER() OVER (ORDER BY NEWID()) AS rn
    FROM Application.StateProvinces sp
)
UPDATE sp
SET StateProvinceGroup =
    CASE ((e.rn - 1) % 7)
        WHEN 0 THEN N'San José'
        WHEN 1 THEN N'Heredia'
        WHEN 2 THEN N'Alajuela'
        WHEN 3 THEN N'Cartago'
        WHEN 4 THEN N'Limón'
        WHEN 5 THEN N'Guanacaste'
        WHEN 6 THEN N'Puntarenas'
    END
FROM Application.StateProvinces sp
JOIN Enumeradas e
    ON sp.StateProvinceID = e.StateProvinceID;
GO

/* 3) (Opcional) Ver cuantos clientes hay en cada grupo de provincia */
SELECT 
    sp.StateProvinceGroup,
    COUNT(c.CustomerID) AS TotalClientes
FROM Application.StateProvinces sp
LEFT JOIN Application.Cities city
    ON city.StateProvinceID = sp.StateProvinceID
LEFT JOIN Sales.Customers c
    ON c.DeliveryCityID = city.CityID
GROUP BY sp.StateProvinceGroup
ORDER BY sp.StateProvinceGroup;
GO
