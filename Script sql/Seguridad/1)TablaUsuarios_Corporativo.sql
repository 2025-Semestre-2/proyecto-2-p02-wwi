/*
================================================================================
TABLA DE USUARIOS CON CONTRASEÑAS ENCRIPTADAS
================================================================================
Requisito: Tabla de usuarios con contraseña encriptada usando funciones nativas
de SQL Server (HASHBYTES con SHA2_512 + SALT)
================================================================================
*/

-- ========================================
-- CORPORATIVO - Tabla Central de Usuarios
-- ========================================
USE WWI_Corporativo;
GO

-- Crear esquema Security si no existe
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Security')
    EXEC('CREATE SCHEMA Security');
GO

-- Tabla de Usuarios
IF OBJECT_ID('Security.Users', 'U') IS NOT NULL
    DROP TABLE Security.Users;
GO

CREATE TABLE Security.Users (
    UserID          INT IDENTITY(1,1) PRIMARY KEY,
    Username        NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash    VARBINARY(64) NOT NULL,  -- SHA2_512 genera 64 bytes
    PasswordSalt    UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    FullName        NVARCHAR(100) NOT NULL,
    Email           NVARCHAR(100) NOT NULL,
    Active          BIT NOT NULL DEFAULT 1,
    Role            NVARCHAR(20) NOT NULL CHECK (Role IN ('Administrador', 'Corporativo')),
    Sucursal        NVARCHAR(50) NULL,  -- NULL para Corporativo, 'San José' o 'Limón' para Admins
    HireDate        DATE NOT NULL DEFAULT GETDATE(),
    LastLogin       DATETIME2 NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CreatedBy       NVARCHAR(50) NOT NULL DEFAULT SUSER_SNAME(),
    ModifiedAt      DATETIME2 NULL,
    ModifiedBy      NVARCHAR(50) NULL,
    
    CONSTRAINT CHK_Users_Sucursal CHECK (
        (Role = 'Corporativo' AND Sucursal IS NULL) OR
        (Role = 'Administrador' AND Sucursal IN ('San José', 'Limón'))
    )
);
GO

CREATE NONCLUSTERED INDEX IX_Users_Username ON Security.Users(Username);
CREATE NONCLUSTERED INDEX IX_Users_Email ON Security.Users(Email);
CREATE NONCLUSTERED INDEX IX_Users_Active ON Security.Users(Active) WHERE Active = 1;
GO

PRINT '✅ Tabla Security.Users creada en WWI_Corporativo';
GO


-- ========================================
-- FUNCIÓN PARA ENCRIPTAR CONTRASEÑAS
-- ========================================
CREATE OR ALTER FUNCTION Security.fn_HashPassword(
    @Password NVARCHAR(100),
    @Salt UNIQUEIDENTIFIER
)
RETURNS VARBINARY(64)
AS
BEGIN
    -- Combinar password con salt y generar hash SHA2_512
    DECLARE @PasswordWithSalt NVARCHAR(200) = @Password + CAST(@Salt AS NVARCHAR(36));
    RETURN HASHBYTES('SHA2_512', @PasswordWithSalt);
END;
GO

PRINT '✅ Función Security.fn_HashPassword creada';
GO


-- ========================================
-- PROCEDIMIENTO PARA CREAR USUARIO
-- ========================================
CREATE OR ALTER PROCEDURE Security.sp_CreateUser
    @Username NVARCHAR(50),
    @Password NVARCHAR(100),
    @FullName NVARCHAR(100),
    @Email NVARCHAR(100),
    @Role NVARCHAR(20),
    @Sucursal NVARCHAR(50) = NULL,
    @CreatedBy NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validaciones
        IF @Username IS NULL OR LEN(@Username) < 3
            THROW 50001, 'Username debe tener al menos 3 caracteres', 1;
        
        IF @Password IS NULL OR LEN(@Password) < 8
            THROW 50002, 'Password debe tener al menos 8 caracteres', 1;
        
        IF @Role NOT IN ('Administrador', 'Corporativo')
            THROW 50003, 'Role debe ser Administrador o Corporativo', 1;
        
        IF @Role = 'Administrador' AND @Sucursal IS NULL
            THROW 50004, 'Administrador debe tener una sucursal asignada', 1;
        
        IF @Role = 'Corporativo' AND @Sucursal IS NOT NULL
            THROW 50005, 'Usuario Corporativo no puede tener sucursal', 1;
        
        -- Verificar si el usuario ya existe
        IF EXISTS (SELECT 1 FROM Security.Users WHERE Username = @Username)
            THROW 50006, 'El username ya existe', 1;
        
        -- Generar salt único
        DECLARE @Salt UNIQUEIDENTIFIER = NEWID();
        
        -- Generar hash de la contraseña
        DECLARE @PasswordHash VARBINARY(64) = Security.fn_HashPassword(@Password, @Salt);
        
        -- Insertar usuario
        INSERT INTO Security.Users (
            Username, PasswordHash, PasswordSalt, FullName, Email, 
            Role, Sucursal, Active, HireDate, CreatedBy
        )
        VALUES (
            @Username, @PasswordHash, @Salt, @FullName, @Email,
            @Role, @Sucursal, 1, GETDATE(), ISNULL(@CreatedBy, SUSER_SNAME())
        );
        
        DECLARE @UserID INT = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
        
        PRINT CONCAT('✅ Usuario creado: ', @Username, ' (ID: ', @UserID, ')');
        
        SELECT @UserID AS UserID, @Username AS Username, @Role AS Role, @Sucursal AS Sucursal;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT CONCAT('❌ Error: ', @ErrorMessage);
        THROW;
    END CATCH
END;
GO

PRINT '✅ Procedimiento Security.sp_CreateUser creado';
GO


-- ========================================
-- PROCEDIMIENTO PARA VALIDAR LOGIN
-- ========================================
CREATE OR ALTER PROCEDURE Security.sp_ValidateLogin
    @Username NVARCHAR(50),
    @Password NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UserID INT;
    DECLARE @StoredHash VARBINARY(64);
    DECLARE @Salt UNIQUEIDENTIFIER;
    DECLARE @Active BIT;
    
    -- Obtener datos del usuario
    SELECT 
        @UserID = UserID,
        @StoredHash = PasswordHash,
        @Salt = PasswordSalt,
        @Active = Active
    FROM Security.Users
    WHERE Username = @Username;
    
    -- Validaciones
    IF @UserID IS NULL
    BEGIN
        PRINT '❌ Usuario no existe';
        SELECT 0 AS IsValid, 'Usuario no encontrado' AS Message;
        RETURN;
    END
    
    IF @Active = 0
    BEGIN
        PRINT '❌ Usuario inactivo';
        SELECT 0 AS IsValid, 'Usuario inactivo' AS Message;
        RETURN;
    END
    
    -- Calcular hash del password ingresado
    DECLARE @InputHash VARBINARY(64) = Security.fn_HashPassword(@Password, @Salt);
    
    -- Comparar hashes
    IF @InputHash = @StoredHash
    BEGIN
        -- Login exitoso - Actualizar último login
        UPDATE Security.Users
        SET LastLogin = GETDATE()
        WHERE UserID = @UserID;
        
        -- Retornar datos del usuario
        SELECT 
            1 AS IsValid,
            'Login exitoso' AS Message,
            UserID,
            Username,
            FullName,
            Email,
            Role,
            Sucursal,
            LastLogin
        FROM Security.Users
        WHERE UserID = @UserID;
        
        PRINT CONCAT('✅ Login exitoso: ', @Username);
    END
    ELSE
    BEGIN
        PRINT '❌ Contraseña incorrecta';
        SELECT 0 AS IsValid, 'Contraseña incorrecta' AS Message;
    END
END;
GO

PRINT '✅ Procedimiento Security.sp_ValidateLogin creado';
GO


-- ========================================
-- PROCEDIMIENTO PARA CAMBIAR CONTRASEÑA
-- ========================================
CREATE OR ALTER PROCEDURE Security.sp_ChangePassword
    @Username NVARCHAR(50),
    @OldPassword NVARCHAR(100),
    @NewPassword NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validar password antiguo primero
        DECLARE @UserID INT;
        DECLARE @StoredHash VARBINARY(64);
        DECLARE @Salt UNIQUEIDENTIFIER;
        
        SELECT 
            @UserID = UserID,
            @StoredHash = PasswordHash,
            @Salt = PasswordSalt
        FROM Security.Users
        WHERE Username = @Username AND Active = 1;
        
        IF @UserID IS NULL
            THROW 50007, 'Usuario no encontrado o inactivo', 1;
        
        -- Verificar password antiguo
        DECLARE @OldHash VARBINARY(64) = Security.fn_HashPassword(@OldPassword, @Salt);
        
        IF @OldHash <> @StoredHash
            THROW 50008, 'Contraseña actual incorrecta', 1;
        
        -- Validar nuevo password
        IF LEN(@NewPassword) < 8
            THROW 50009, 'Nueva contraseña debe tener al menos 8 caracteres', 1;
        
        -- Generar nuevo salt y hash
        DECLARE @NewSalt UNIQUEIDENTIFIER = NEWID();
        DECLARE @NewHash VARBINARY(64) = Security.fn_HashPassword(@NewPassword, @NewSalt);
        
        -- Actualizar
        UPDATE Security.Users
        SET 
            PasswordHash = @NewHash,
            PasswordSalt = @NewSalt,
            ModifiedAt = GETDATE(),
            ModifiedBy = @Username
        WHERE UserID = @UserID;
        
        COMMIT TRANSACTION;
        
        PRINT CONCAT('✅ Contraseña actualizada para: ', @Username);
        SELECT 1 AS Success, 'Contraseña actualizada exitosamente' AS Message;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT CONCAT('❌ Error: ', @ErrorMessage);
        SELECT 0 AS Success, @ErrorMessage AS Message;
    END CATCH
END;
GO

PRINT '✅ Procedimiento Security.sp_ChangePassword creado';
GO


-- ========================================
-- DATOS INICIALES - USUARIOS DE PRUEBA
-- ========================================
PRINT '';
PRINT '========================================';
PRINT 'CREANDO USUARIOS INICIALES';
PRINT '========================================';

-- Usuario Corporativo
EXEC Security.sp_CreateUser
    @Username = 'corporativo',
    @Password = 'Corp2024#Secure',
    @FullName = 'Usuario Corporativo',
    @Email = 'corporativo@wwi.com',
    @Role = 'Corporativo',
    @CreatedBy = 'SYSTEM';

-- Administrador San José
EXEC Security.sp_CreateUser
    @Username = 'admin_sj',
    @Password = 'Admin2024#SJ',
    @FullName = 'Administrador San José',
    @Email = 'admin.sj@wwi.com',
    @Role = 'Administrador',
    @Sucursal = 'San José',
    @CreatedBy = 'SYSTEM';

-- Administrador Limón
EXEC Security.sp_CreateUser
    @Username = 'admin_lim',
    @Password = 'Admin2024#LIM',
    @FullName = 'Administrador Limón',
    @Email = 'admin.lim@wwi.com',
    @Role = 'Administrador',
    @Sucursal = 'Limón',
    @CreatedBy = 'SYSTEM';

PRINT '';
PRINT '========================================';
PRINT 'PRUEBAS DE FUNCIONALIDAD';
PRINT '========================================';

-- Probar login correcto
PRINT '';
PRINT 'Prueba 1: Login exitoso';
EXEC Security.sp_ValidateLogin 
    @Username = 'corporativo', 
    @Password = 'Corp2024#Secure';

-- Probar login incorrecto
PRINT '';
PRINT 'Prueba 2: Login con contraseña incorrecta';
EXEC Security.sp_ValidateLogin 
    @Username = 'corporativo', 
    @Password = 'WrongPassword';

PRINT '';
PRINT '========================================';
PRINT '✅ SISTEMA DE USUARIOS COMPLETADO';
PRINT '========================================';
PRINT '';
PRINT 'Usuarios creados:';
PRINT '  - corporativo / Corp2024#Secure';
PRINT '  - admin_sj / Admin2024#SJ';
PRINT '  - admin_lim / Admin2024#LIM';
PRINT '';

-- Ver usuarios creados
SELECT 
    UserID, Username, FullName, Email, Role, Sucursal, Active, HireDate
FROM Security.Users
ORDER BY UserID;
GO