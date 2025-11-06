-- Sede San José 
USE WWI_Sucursal_SJ;
GO
CREATE USER admin_sucursal FOR LOGIN admin_sj;
GO

-- Sede Limón
USE WWI_Sucursal_LIM;
GO
CREATE USER admin_sucursal FOR LOGIN admin_lim;
GO

-- Sede Corporativo
USE WWI_Corporativo;
GO
CREATE USER corp_analytics FOR LOGIN corp_analytics;
GO