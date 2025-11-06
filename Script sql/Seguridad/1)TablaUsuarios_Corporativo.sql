USE WWI_Corporativo;
GO
IF SCHEMA_ID('Sec') IS NULL EXEC('CREATE SCHEMA Sec');
GO
CREATE TABLE Sec.AppUsers (
    iduser     INT IDENTITY(1,1) PRIMARY KEY,
    username   NVARCHAR(100) UNIQUE NOT NULL,
    password_hash VARBINARY(64)     NOT NULL,
    password_salt VARBINARY(32)     NOT NULL,
    fullname   NVARCHAR(200)        NOT NULL,
    active     BIT                  NOT NULL DEFAULT 1,
    rol        NVARCHAR(50)         NOT NULL,
    email      NVARCHAR(256)        NULL,
    hiredate   DATE                 NULL,
    created_at DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
