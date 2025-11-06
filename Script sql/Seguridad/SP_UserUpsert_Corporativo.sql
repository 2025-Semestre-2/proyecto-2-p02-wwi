USE WWI_Corporativo;
GO
CREATE OR ALTER PROCEDURE Sec.sp_UpsertUser
    @username NVARCHAR(100),
    @password NVARCHAR(200) = NULL,
    @fullname NVARCHAR(200),
    @rol      NVARCHAR(50),
    @active   BIT = 1,
    @email    NVARCHAR(256) = NULL,
    @hiredate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Sec.AppUsers WHERE username = @username)
    BEGIN
        DECLARE @salt VARBINARY(32) = CRYPT_GEN_RANDOM(32);
        DECLARE @hash VARBINARY(64) = HASHBYTES('SHA2_256', @salt + CONVERT(VARBINARY(MAX), @password));
        INSERT INTO Sec.AppUsers (username, password_hash, password_salt, fullname, active, rol, email, hiredate)
        VALUES (@username, @hash, @salt, @fullname, @active, @rol, @email, @hiredate);
    END
    ELSE
    BEGIN
        IF @password IS NOT NULL
        BEGIN
            DECLARE @salt2 VARBINARY(32) = CRYPT_GEN_RANDOM(32);
            DECLARE @hash2 VARBINARY(64) = HASHBYTES('SHA2_256', @salt2 + CONVERT(VARBINARY(MAX), @password));
            UPDATE Sec.AppUsers
               SET password_hash = @hash2,
                   password_salt = @salt2,
                   fullname      = @fullname,
                   active        = @active,
                   rol           = @rol,
                   email         = @email,
                   hiredate      = @hiredate
             WHERE username = @username;
        END
        ELSE
        BEGIN
            UPDATE Sec.AppUsers
               SET fullname = @fullname,
                   active   = @active,
                   rol      = @rol,
                   email    = @email,
                   hiredate = @hiredate
             WHERE username = @username;
        END
    END
END
GO
