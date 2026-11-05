USE [DB_SCRUM_PLANNING];
GO
/* Credenciales de prueba solicitadas en la especificación del profesor. */
DECLARE @FullName VARCHAR(80) = 'CALHECTOR';
DECLARE @UserName VARCHAR(80) = 'CALHECTOR';
DECLARE @Email VARCHAR(80) = 'calhector@localhost.local';
DECLARE @Password VARCHAR(256) = '12345678';
DECLARE @Encrypted VARBINARY(256);
IF EXISTS (SELECT 1 FROM SQM_SECURITY.TBL_Users WHERE userName=@UserName OR userEmail=@Email)
    THROW 51001, 'El usuario o correo ya existe; no se duplico el administrador.', 1;
OPEN SYMMETRIC KEY KEY_HASH DECRYPTION BY CERTIFICATE CERT_SCRUMPLANNING;
SET @Encrypted = SQM_SECURITY.Fn_EncryptByKey(@Password);
CLOSE SYMMETRIC KEY KEY_HASH;
INSERT INTO SQM_SECURITY.TBL_Users(userFullName,userName,userEmail,userPassword,userRolId,userCreationDate,userEnable)
VALUES(@FullName,@UserName,@Email,@Encrypted,1,GETDATE(),1);
PRINT 'Administrador creado. Usa el nombre de usuario y la contraseña definidos arriba para autenticarte.';
GO
