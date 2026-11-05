GO
CREATE OR ALTER PROC [SQM_SECURITY].[USP_Roles] (
    @i_rolId INT = NULL,
    @i_rolName VARCHAR(80) = NULL,
    @i_rolCreationDate DATETIME = NULL,
    @i_rolCreatorId INT = NULL,
    @i_rolModificationDate DATETIME = NULL,
    @i_rolModificatorId INT = NULL,
    @i_rolEnable BIT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 20,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN
    SET NOCOUNT ON;
    IF @i_rolEnable IS NULL SET @i_rolEnable = 1;
    IF @i_rolModificationDate IS NULL SET @i_rolModificationDate = GETDATE();
    DECLARE @w_totalRows INT;

    IF @i_rolCreationDate IS NULL SET @i_rolCreationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_rolName, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CAMPO ROLNAME ES OBLIGATORIO';
            RETURN;
        END;
        BEGIN TRY
            INSERT INTO [SQM_SECURITY].[TBL_Roles] (rolName, rolCreationDate, rolCreatorId, rolModificationDate, rolModificatorId, rolEnable)
            VALUES (@i_rolName, @i_rolCreationDate, @i_rolCreatorId, @i_rolModificationDate, @i_rolModificatorId, @i_rolEnable);
            SET @o_Numero = 201;
            SET @o_MensajeUsuario = 'REGISTRO CREADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL CREAR REGISTRO';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_rolId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID ROLID ES OBLIGATORIO';
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Roles] WHERE rolId = @i_rolId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL REGISTRO NO EXISTE';
        END
        ELSE
        BEGIN
            BEGIN TRY
                UPDATE [SQM_SECURITY].[TBL_Roles]
                SET rolName = COALESCE(@i_rolName, rolName),
                    rolCreationDate = COALESCE(@i_rolCreationDate, rolCreationDate),
                    rolCreatorId = COALESCE(@i_rolCreatorId, rolCreatorId),
                    rolModificationDate = COALESCE(@i_rolModificationDate, rolModificationDate),
                    rolModificatorId = COALESCE(@i_rolModificatorId, rolModificatorId),
                    rolEnable = COALESCE(@i_rolEnable, rolEnable)
                WHERE rolId = @i_rolId;
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR REGISTRO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF ISNULL(@i_PageNumber, 0) <= 0 OR ISNULL(@i_RowsPerPage, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS PARAMETROS DE PAGINACION DEBEN SER MAYORES A CERO';
        END
        ELSE
        BEGIN
            BEGIN TRY
                SELECT rolId, rolName, rolCreationDate, rolCreatorId, rolModificationDate, rolModificatorId, rolEnable
                FROM [SQM_SECURITY].[TBL_Roles]
                ORDER BY rolId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;
                SET @w_totalRows = @@ROWCOUNT;
                IF @w_totalRows > 0
                BEGIN
                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'REGISTROS LISTADOS CORRECTAMENTE';
                END
                ELSE
                BEGIN
                    SET @o_Numero = 204;
                    SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
                END
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL LISTAR REGISTROS';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'ACCION PERMITIDA: I, U, S';
    END
END;
GO

GO
CREATE OR ALTER PROC [SQM_SECURITY].[USP_Users]
(
    @i_userId INT = NULL,
    @i_userFullName VARCHAR(80) = NULL,
    @i_userName VARCHAR(80) = NULL,
    @i_userEmail VARCHAR(80) = NULL,
    @i_userPassword VARCHAR(256) = NULL,
    @i_userRolId INT = NULL,
    @i_userCreationDate DATETIME = NULL,
    @i_userCreatorId INT = NULL,
    @i_userModificationDate DATETIME = NULL,
    @i_userModificatorId INT = NULL,
    @i_userEnable BIT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 20,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN
    IF @i_userModificationDate IS NULL SET @i_userModificationDate = GETDATE();
    IF @i_PageNumber IS NULL OR @i_PageNumber < 1 SET @i_PageNumber = 1;
    IF @i_RowsPerPage IS NULL OR @i_RowsPerPage < 1 SET @i_RowsPerPage = 20;

    DECLARE @w_userPasswordEncrypted VARBINARY(256), @w_totalRows INT;

    IF @i_userCreationDate IS NULL
        SET @i_userCreationDate = GETDATE();

    IF @i_userModificationDate IS NULL
        SET @i_userModificationDate = GETDATE();

    -- INSERTAR USER --
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_userFullName,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE COMPLETO ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_userName,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE USUARIO ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_userEmail,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CORREO ELECTRONICO ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_userPassword,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA CONTRASEÑA ES OBLIGATORIA';
        END;

        ELSE IF EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userName = @i_userName)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE USUARIO YA EXISTE';
        END;

        ELSE IF EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userEmail = @i_userEmail)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CORREO YA EXISTE';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Roles] (NOLOCK) WHERE rolId = @i_userRolId AND rolEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ROL NO EXISTE';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_USER;

            BEGIN TRY

                OPEN SYMMETRIC KEY KEY_HASH
                DECRYPTION BY CERTIFICATE CERT_SCRUMPLANNING;

                SET @w_userPasswordEncrypted = [SQM_SECURITY].[Fn_EncryptByKey](@i_userPassword);

                CLOSE SYMMETRIC KEY KEY_HASH;

                INSERT INTO [SQM_SECURITY].[TBL_Users]
                (userFullName,userName,userEmail,userPassword,userRolId,userCreationDate,userCreatorId,userModificationDate,userModificatorId,userEnable)
                VALUES(@i_userFullName,@i_userName,@i_userEmail,@w_userPasswordEncrypted,@i_userRolId,@i_userCreationDate,@i_userCreatorId,@i_userModificationDate,@i_userModificatorId,1);

                COMMIT TRANSACTION TRX_INS_USER;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'USUARIO REGISTRADO CORRECTAMENTE';

            END TRY

            BEGIN CATCH

                ROLLBACK TRANSACTION TRX_INS_USER;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR USUARIO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR USUARIO', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());

            END CATCH
        END
    END

    -- UPDATE USER --
    ELSE IF @w_Accion = 'U'
    BEGIN

        IF ISNULL(@i_userId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL USUARIO ES OBLIGATORIO';
        END
        ELSE IF ISNULL(@i_userModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_userId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL USUARIO NO EXISTE';
        END;

        ELSE IF @i_userName IS NOT NULL AND
            EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userName = @i_userName
        AND userId <> @i_userId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE USUARIO YA EXISTE';
        END;

        ELSE IF @i_userEmail IS NOT NULL AND
            EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userEmail = @i_userEmail
        AND userId <> @i_userId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CORREO YA EXISTE';
        END;

        ELSE IF @i_userRolId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Roles] (NOLOCK) 
		WHERE rolId = @i_userRolId AND rolEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ROL NO EXISTE';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_USER;

            BEGIN TRY

                IF @i_userPassword IS NOT NULL
                BEGIN
                    OPEN SYMMETRIC KEY KEY_HASH
                    DECRYPTION BY CERTIFICATE CERT_SCRUMPLANNING;
                        SET @w_userPasswordEncrypted = [SQM_SECURITY].Fn_EncryptByKey(@i_userPassword);
                    CLOSE SYMMETRIC KEY KEY_HASH;
                END

                UPDATE [SQM_SECURITY].[TBL_Users]
                SET userFullName = COALESCE(@i_userFullName,userFullName),
                    userName = COALESCE(@i_userName,userName),
                    userEmail = COALESCE(@i_userEmail,userEmail),
                    userPassword = COALESCE(@w_userPasswordEncrypted,userPassword),
                    userRolId = COALESCE(@i_userRolId,userRolId),
                    userModificationDate = @i_userModificationDate,
                    userModificatorId = @i_userModificatorId,
                    userEnable = COALESCE(@i_userEnable,userEnable)
                WHERE userId = @i_userId;

                COMMIT TRANSACTION TRX_UPD_USER;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'USUARIO ACTUALIZADO CORRECTAMENTE';

            END TRY

            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_USER;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR USUARIO'
                SET @o_MensajeTecnico =  CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR USUARIO', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());

            END CATCH
        END
    END

-- SELECT USER --
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF @i_PageNumber <= 0 OR @i_RowsPerPage <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS PARAMETROS DE PAGINACION DEBEN SER MAYORES A CERO';
            RETURN;
        END;

        BEGIN TRY

            SELECT 
                userId, 
                userFullName,
                userName,
                userEmail,
                userRolId,
                userCreationDate,
                userCreatorId,
                userModificationDate,
                userModificatorId,
                userEnable
            FROM [SQM_SECURITY].[TBL_Users] (NOLOCK)
            ORDER BY userId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'USUARIOS LISTADOS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END
        END TRY

        BEGIN CATCH

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LOS USUARIOS';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR USUARIOS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());

        END CATCH

    END

 -- ACCION INVALIDA --
    ELSE
    BEGIN

        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';

    END

END;
GO

GO
CREATE OR ALTER PROC [SQM_CATALOGS].[USP_Status]
(
    @i_statusId INT = NULL,
    @i_statusName VARCHAR(80) = NULL,
    @i_statusCreationDate DATETIME = NULL,
    @i_statusCreatorId INT = NULL,
    @i_statusModificationDate DATETIME = NULL,
    @i_statusModificatorId INT = NULL,
    @i_statusEnable BIT = NULL,
    @i_PageNumber INT = NULL,
    @i_RowsPerPage INT = NULL,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN
    DECLARE @w_totalRows INT;

    IF @i_statusCreationDate IS NULL
        SET @i_statusCreationDate = GETDATE();

    IF @i_statusModificationDate IS NULL
        SET @i_statusModificationDate = GETDATE();

    -- INSERTAR STATUS --
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_statusName,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL STATUS ES OBLIGATORIO';
        END;
        ELSE IF ISNULL(@i_statusCreatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL CREADOR ES OBLIGATORIO';
        END;
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_STATUS;
            BEGIN TRY
                INSERT INTO [SQM_CATALOGS].[TBL_Status]
                (statusName, statusCreationDate, statusCreatorId, statusModificationDate, statusModificatorId, statusEnable)
                VALUES(@i_statusName, @i_statusCreationDate, @i_statusCreatorId, @i_statusModificationDate, @i_statusModificatorId, 1);

                COMMIT TRANSACTION TRX_INS_STATUS;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'STATUS REGISTRADO CORRECTAMENTE';
            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_STATUS;
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR STATUS';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR STATUS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE STATUS --
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_statusId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL STATUS ES OBLIGATORIO';
        END;
        ELSE IF ISNULL(@i_statusModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_statusId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL STATUS NO EXISTE';
        END;
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_STATUS;
            BEGIN TRY
                UPDATE [SQM_CATALOGS].[TBL_Status]
                SET statusName = COALESCE(@i_statusName, statusName),
                    statusModificationDate = @i_statusModificationDate,
                    statusModificatorId = @i_statusModificatorId,
                    statusEnable = COALESCE(@i_statusEnable, statusEnable)
                WHERE statusId = @i_statusId;

                COMMIT TRANSACTION TRX_UPD_STATUS;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'STATUS ACTUALIZADO CORRECTAMENTE';
            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_STATUS;
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR STATUS';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR STATUS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- SELECT STATUS --
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF ISNULL(@i_PageNumber,0) <= 0 OR ISNULL(@i_RowsPerPage,0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS PARAMETROS DE PAGINACION SON OBLIGATORIOS Y DEBEN SER MAYORES A CERO';
        END
        ELSE
        BEGIN
            BEGIN TRY
                SELECT 
                    statusId,
                    statusName,
                    statusCreationDate,
                    statusCreatorId,
                    statusModificationDate,
                    statusModificatorId,
                    statusEnable
                FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK)
                ORDER BY statusId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;

                SET @w_totalRows = @@ROWCOUNT;

                IF (@w_totalRows > 0)
                BEGIN
                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'STATUS LISTADOS CORRECTAMENTE';
                END
                ELSE
                BEGIN
                    SET @o_Numero = 204;
                    SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
                END
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL LISTAR STATUS';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR STATUS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- ACCION INVALIDA --
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';
    END
END;
GO
GO
CREATE OR ALTER PROC [SQM_CATALOGS].[USP_Priorities] (
    @i_priorityId INT = NULL,
    @i_priorityName VARCHAR(80) = NULL,
    @i_priorityCreationDate DATETIME = NULL,
    @i_priorityCreatorId INT = NULL,
    @i_priorityModificationDate DATETIME = NULL,
    @i_priorityModificatorId INT = NULL,
    @i_priorityEnable BIT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 20,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN
    SET NOCOUNT ON;
    IF @i_priorityEnable IS NULL SET @i_priorityEnable = 1;
    IF @i_priorityModificationDate IS NULL SET @i_priorityModificationDate = GETDATE();
    DECLARE @w_totalRows INT;

    IF @i_priorityCreationDate IS NULL SET @i_priorityCreationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_priorityName, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CAMPO PRIORITYNAME ES OBLIGATORIO';
            RETURN;
        END;
        BEGIN TRY
            INSERT INTO [SQM_CATALOGS].[TBL_Priorities] (priorityName, priorityCreationDate, priorityCreatorId, priorityModificationDate, priorityModificatorId, priorityEnable)
            VALUES (@i_priorityName, @i_priorityCreationDate, @i_priorityCreatorId, @i_priorityModificationDate, @i_priorityModificatorId, @i_priorityEnable);
            SET @o_Numero = 201;
            SET @o_MensajeUsuario = 'REGISTRO CREADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL CREAR REGISTRO';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_priorityId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID PRIORITYID ES OBLIGATORIO';
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] WHERE priorityId = @i_priorityId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL REGISTRO NO EXISTE';
        END
        ELSE
        BEGIN
            BEGIN TRY
                UPDATE [SQM_CATALOGS].[TBL_Priorities]
                SET priorityName = COALESCE(@i_priorityName, priorityName),
                    priorityCreationDate = COALESCE(@i_priorityCreationDate, priorityCreationDate),
                    priorityCreatorId = COALESCE(@i_priorityCreatorId, priorityCreatorId),
                    priorityModificationDate = COALESCE(@i_priorityModificationDate, priorityModificationDate),
                    priorityModificatorId = COALESCE(@i_priorityModificatorId, priorityModificatorId),
                    priorityEnable = COALESCE(@i_priorityEnable, priorityEnable)
                WHERE priorityId = @i_priorityId;
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR REGISTRO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF ISNULL(@i_PageNumber, 0) <= 0 OR ISNULL(@i_RowsPerPage, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS PARAMETROS DE PAGINACION DEBEN SER MAYORES A CERO';
        END
        ELSE
        BEGIN
            BEGIN TRY
                SELECT priorityId, priorityName, priorityCreationDate, priorityCreatorId, priorityModificationDate, priorityModificatorId, priorityEnable
                FROM [SQM_CATALOGS].[TBL_Priorities]
                ORDER BY priorityId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;
                SET @w_totalRows = @@ROWCOUNT;
                IF @w_totalRows > 0
                BEGIN
                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'REGISTROS LISTADOS CORRECTAMENTE';
                END
                ELSE
                BEGIN
                    SET @o_Numero = 204;
                    SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
                END
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL LISTAR REGISTROS';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'ACCION PERMITIDA: I, U, S';
    END
END;
GO

GO
CREATE OR ALTER PROC [SQM_CATALOGS].[USP_BusinessValues] (
    @i_businessValueId INT = NULL,
    @i_businessValueName VARCHAR(80) = NULL,
    @i_businessValueCreationDate DATETIME = NULL,
    @i_businessValueCreatorId INT = NULL,
    @i_businessValueModificationDate DATETIME = NULL,
    @i_businessValueModificatorId INT = NULL,
    @i_businessValueEnable BIT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 20,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN
    SET NOCOUNT ON;
    IF @i_businessValueEnable IS NULL SET @i_businessValueEnable = 1;
    IF @i_businessValueModificationDate IS NULL SET @i_businessValueModificationDate = GETDATE();
    DECLARE @w_totalRows INT;

    IF @i_businessValueCreationDate IS NULL SET @i_businessValueCreationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_businessValueName, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CAMPO BUSINESSVALUENAME ES OBLIGATORIO';
            RETURN;
        END;
        BEGIN TRY
            INSERT INTO [SQM_CATALOGS].[TBL_BusinessValues] (businessValueName, businessValueCreationDate, businessValueCreatorId, businessValueModificationDate, businessValueModificatorId, businessValueEnable)
            VALUES (@i_businessValueName, @i_businessValueCreationDate, @i_businessValueCreatorId, @i_businessValueModificationDate, @i_businessValueModificatorId, @i_businessValueEnable);
            SET @o_Numero = 201;
            SET @o_MensajeUsuario = 'REGISTRO CREADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL CREAR REGISTRO';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_businessValueId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID BUSINESSVALUEID ES OBLIGATORIO';
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_BusinessValues] WHERE businessValueId = @i_businessValueId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL REGISTRO NO EXISTE';
        END
        ELSE
        BEGIN
            BEGIN TRY
                UPDATE [SQM_CATALOGS].[TBL_BusinessValues]
                SET businessValueName = COALESCE(@i_businessValueName, businessValueName),
                    businessValueCreationDate = COALESCE(@i_businessValueCreationDate, businessValueCreationDate),
                    businessValueCreatorId = COALESCE(@i_businessValueCreatorId, businessValueCreatorId),
                    businessValueModificationDate = COALESCE(@i_businessValueModificationDate, businessValueModificationDate),
                    businessValueModificatorId = COALESCE(@i_businessValueModificatorId, businessValueModificatorId),
                    businessValueEnable = COALESCE(@i_businessValueEnable, businessValueEnable)
                WHERE businessValueId = @i_businessValueId;
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR REGISTRO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF ISNULL(@i_PageNumber, 0) <= 0 OR ISNULL(@i_RowsPerPage, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS PARAMETROS DE PAGINACION DEBEN SER MAYORES A CERO';
        END
        ELSE
        BEGIN
            BEGIN TRY
                SELECT businessValueId, businessValueName, businessValueCreationDate, businessValueCreatorId, businessValueModificationDate, businessValueModificatorId, businessValueEnable
                FROM [SQM_CATALOGS].[TBL_BusinessValues]
                ORDER BY businessValueId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;
                SET @w_totalRows = @@ROWCOUNT;
                IF @w_totalRows > 0
                BEGIN
                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'REGISTROS LISTADOS CORRECTAMENTE';
                END
                ELSE
                BEGIN
                    SET @o_Numero = 204;
                    SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
                END
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL LISTAR REGISTROS';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'ACCION PERMITIDA: I, U, S';
    END
END;
GO

GO
CREATE OR ALTER PROC [SQM_CATALOGS].[USP_ActivityTypes] (
    @i_activityTypeId INT = NULL,
    @i_activityTypeName VARCHAR(80) = NULL,
    @i_activityTypeCreationDate DATETIME = NULL,
    @i_activityTypeCreatorId INT = NULL,
    @i_activityTypeModificationDate DATETIME = NULL,
    @i_activityTypeModificatorId INT = NULL,
    @i_activityTypeEnable BIT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 20,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN
    SET NOCOUNT ON;
    IF @i_activityTypeEnable IS NULL SET @i_activityTypeEnable = 1;
    IF @i_activityTypeModificationDate IS NULL SET @i_activityTypeModificationDate = GETDATE();
    DECLARE @w_totalRows INT;

    IF @i_activityTypeCreationDate IS NULL SET @i_activityTypeCreationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_activityTypeName, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CAMPO ACTIVITYTYPENAME ES OBLIGATORIO';
            RETURN;
        END;
        BEGIN TRY
            INSERT INTO [SQM_CATALOGS].[TBL_ActivityTypes] (activityTypeName, activityTypeCreationDate, activityTypeCreatorId, activityTypeModificationDate, activityTypeModificatorId, activityTypeEnable)
            VALUES (@i_activityTypeName, @i_activityTypeCreationDate, @i_activityTypeCreatorId, @i_activityTypeModificationDate, @i_activityTypeModificatorId, @i_activityTypeEnable);
            SET @o_Numero = 201;
            SET @o_MensajeUsuario = 'REGISTRO CREADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL CREAR REGISTRO';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_activityTypeId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID ACTIVITYTYPEID ES OBLIGATORIO';
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_ActivityTypes] WHERE activityTypeId = @i_activityTypeId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL REGISTRO NO EXISTE';
        END
        ELSE
        BEGIN
            BEGIN TRY
                UPDATE [SQM_CATALOGS].[TBL_ActivityTypes]
                SET activityTypeName = COALESCE(@i_activityTypeName, activityTypeName),
                    activityTypeCreationDate = COALESCE(@i_activityTypeCreationDate, activityTypeCreationDate),
                    activityTypeCreatorId = COALESCE(@i_activityTypeCreatorId, activityTypeCreatorId),
                    activityTypeModificationDate = COALESCE(@i_activityTypeModificationDate, activityTypeModificationDate),
                    activityTypeModificatorId = COALESCE(@i_activityTypeModificatorId, activityTypeModificatorId),
                    activityTypeEnable = COALESCE(@i_activityTypeEnable, activityTypeEnable)
                WHERE activityTypeId = @i_activityTypeId;
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR REGISTRO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF ISNULL(@i_PageNumber, 0) <= 0 OR ISNULL(@i_RowsPerPage, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS PARAMETROS DE PAGINACION DEBEN SER MAYORES A CERO';
        END
        ELSE
        BEGIN
            BEGIN TRY
                SELECT activityTypeId, activityTypeName, activityTypeCreationDate, activityTypeCreatorId, activityTypeModificationDate, activityTypeModificatorId, activityTypeEnable
                FROM [SQM_CATALOGS].[TBL_ActivityTypes]
                ORDER BY activityTypeId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;
                SET @w_totalRows = @@ROWCOUNT;
                IF @w_totalRows > 0
                BEGIN
                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'REGISTROS LISTADOS CORRECTAMENTE';
                END
                ELSE
                BEGIN
                    SET @o_Numero = 204;
                    SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
                END
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL LISTAR REGISTROS';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'ACCION PERMITIDA: I, U, S';
    END
END;
GO

GO
CREATE OR ALTER PROC [SQM_GENERAL].[USP_Initiatives] (
    @i_initiativeId INT = NULL,
    @i_initiativeSummary VARCHAR(200) = NULL,
    @i_initiativeDescription VARCHAR(2000) = NULL,
    @i_initiativeOwner INT = NULL,
    @i_initiativeGoals VARCHAR(255) = NULL,
    @i_initiativeBusinessValue INT = NULL,
    @i_initiativeTargetStart DATE = NULL,
    @i_initiativeTargetEnd DATE = NULL,
    @i_initiativeCreationDate DATETIME = NULL,
    @i_initiativeCreatorId INT = NULL,
    @i_initiativeModificationDate DATETIME = NULL,
    @i_initiativeModificatorId INT = NULL,
    @i_initiativeStatus INT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 20,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN
    SET NOCOUNT ON;
    IF @i_initiativeModificationDate IS NULL SET @i_initiativeModificationDate = GETDATE();
    DECLARE @w_totalRows INT;

    IF @i_initiativeCreationDate IS NULL SET @i_initiativeCreationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_initiativeSummary, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CAMPO INITIATIVESUMMARY ES OBLIGATORIO';
            RETURN;
        END;
        IF ISNULL(@i_initiativeDescription, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CAMPO INITIATIVEDESCRIPTION ES OBLIGATORIO';
            RETURN;
        END;
        BEGIN TRY
            INSERT INTO [SQM_GENERAL].[TBL_Initiatives] (initiativeSummary, initiativeDescription, initiativeOwner, initiativeGoals, initiativeBusinessValue, initiativeTargetStart, initiativeTargetEnd, initiativeCreationDate, initiativeCreatorId, initiativeModificationDate, initiativeModificatorId, initiativeStatus)
            VALUES (@i_initiativeSummary, @i_initiativeDescription, @i_initiativeOwner, @i_initiativeGoals, @i_initiativeBusinessValue, @i_initiativeTargetStart, @i_initiativeTargetEnd, @i_initiativeCreationDate, @i_initiativeCreatorId, @i_initiativeModificationDate, @i_initiativeModificatorId, @i_initiativeStatus);
            SET @o_Numero = 201;
            SET @o_MensajeUsuario = 'REGISTRO CREADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL CREAR REGISTRO';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_initiativeId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID INITIATIVEID ES OBLIGATORIO';
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Initiatives] WHERE initiativeId = @i_initiativeId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL REGISTRO NO EXISTE';
        END
        ELSE
        BEGIN
            BEGIN TRY
                UPDATE [SQM_GENERAL].[TBL_Initiatives]
                SET initiativeSummary = COALESCE(@i_initiativeSummary, initiativeSummary),
                    initiativeDescription = COALESCE(@i_initiativeDescription, initiativeDescription),
                    initiativeOwner = COALESCE(@i_initiativeOwner, initiativeOwner),
                    initiativeGoals = COALESCE(@i_initiativeGoals, initiativeGoals),
                    initiativeBusinessValue = COALESCE(@i_initiativeBusinessValue, initiativeBusinessValue),
                    initiativeTargetStart = COALESCE(@i_initiativeTargetStart, initiativeTargetStart),
                    initiativeTargetEnd = COALESCE(@i_initiativeTargetEnd, initiativeTargetEnd),
                    initiativeCreationDate = COALESCE(@i_initiativeCreationDate, initiativeCreationDate),
                    initiativeCreatorId = COALESCE(@i_initiativeCreatorId, initiativeCreatorId),
                    initiativeModificationDate = COALESCE(@i_initiativeModificationDate, initiativeModificationDate),
                    initiativeModificatorId = COALESCE(@i_initiativeModificatorId, initiativeModificatorId),
                    initiativeStatus = COALESCE(@i_initiativeStatus, initiativeStatus)
                WHERE initiativeId = @i_initiativeId;
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR REGISTRO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF ISNULL(@i_PageNumber, 0) <= 0 OR ISNULL(@i_RowsPerPage, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS PARAMETROS DE PAGINACION DEBEN SER MAYORES A CERO';
        END
        ELSE
        BEGIN
            BEGIN TRY
                SELECT initiativeId, initiativeSummary, initiativeDescription, initiativeOwner, initiativeGoals, initiativeBusinessValue, initiativeTargetStart, initiativeTargetEnd, initiativeCreationDate, initiativeCreatorId, initiativeModificationDate, initiativeModificatorId, initiativeStatus
                FROM [SQM_GENERAL].[TBL_Initiatives]
                ORDER BY initiativeId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;
                SET @w_totalRows = @@ROWCOUNT;
                IF @w_totalRows > 0
                BEGIN
                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'REGISTROS LISTADOS CORRECTAMENTE';
                END
                ELSE
                BEGIN
                    SET @o_Numero = 204;
                    SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
                END
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL LISTAR REGISTROS';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'ACCION PERMITIDA: I, U, S';
    END
END;
GO

GO
CREATE OR ALTER PROC [SQM_GENERAL].[USP_Epics] (
    @i_epicId INT = NULL,
    @i_epicName VARCHAR(100) = NULL,
    @i_epicSummary VARCHAR(500) = NULL,
    @i_epicDescription VARCHAR(4000) = NULL,
    @i_epicParentLink INT = NULL,
    @i_epicOwner INT = NULL,
    @i_epicStartDate DATE = NULL,
    @i_epicDueDate DATE = NULL,
    @i_epicPriority INT = NULL,
    @i_epicCreationDate DATETIME = NULL,
    @i_epicCreatorId INT = NULL,
    @i_epicModificationDate DATETIME = NULL,
    @i_epicModificatorId INT = NULL,
    @i_epicStatus INT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 20,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN
    SET NOCOUNT ON;
    IF @i_epicModificationDate IS NULL SET @i_epicModificationDate = GETDATE();
    DECLARE @w_totalRows INT;

    IF @i_epicCreationDate IS NULL SET @i_epicCreationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_epicName, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CAMPO EPICNAME ES OBLIGATORIO';
            RETURN;
        END;
        IF ISNULL(@i_epicSummary, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CAMPO EPICSUMMARY ES OBLIGATORIO';
            RETURN;
        END;
        IF ISNULL(@i_epicDescription, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CAMPO EPICDESCRIPTION ES OBLIGATORIO';
            RETURN;
        END;
        BEGIN TRY
            INSERT INTO [SQM_GENERAL].[TBL_Epics] (epicName, epicSummary, epicDescription, epicParentLink, epicOwner, epicStartDate, epicDueDate, epicPriority, epicCreationDate, epicCreatorId, epicModificationDate, epicModificatorId, epicStatus)
            VALUES (@i_epicName, @i_epicSummary, @i_epicDescription, @i_epicParentLink, @i_epicOwner, @i_epicStartDate, @i_epicDueDate, @i_epicPriority, @i_epicCreationDate, @i_epicCreatorId, @i_epicModificationDate, @i_epicModificatorId, @i_epicStatus);
            SET @o_Numero = 201;
            SET @o_MensajeUsuario = 'REGISTRO CREADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL CREAR REGISTRO';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_epicId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID EPICID ES OBLIGATORIO';
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Epics] WHERE epicId = @i_epicId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL REGISTRO NO EXISTE';
        END
        ELSE
        BEGIN
            BEGIN TRY
                UPDATE [SQM_GENERAL].[TBL_Epics]
                SET epicName = COALESCE(@i_epicName, epicName),
                    epicSummary = COALESCE(@i_epicSummary, epicSummary),
                    epicDescription = COALESCE(@i_epicDescription, epicDescription),
                    epicParentLink = COALESCE(@i_epicParentLink, epicParentLink),
                    epicOwner = COALESCE(@i_epicOwner, epicOwner),
                    epicStartDate = COALESCE(@i_epicStartDate, epicStartDate),
                    epicDueDate = COALESCE(@i_epicDueDate, epicDueDate),
                    epicPriority = COALESCE(@i_epicPriority, epicPriority),
                    epicCreationDate = COALESCE(@i_epicCreationDate, epicCreationDate),
                    epicCreatorId = COALESCE(@i_epicCreatorId, epicCreatorId),
                    epicModificationDate = COALESCE(@i_epicModificationDate, epicModificationDate),
                    epicModificatorId = COALESCE(@i_epicModificatorId, epicModificatorId),
                    epicStatus = COALESCE(@i_epicStatus, epicStatus)
                WHERE epicId = @i_epicId;
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR REGISTRO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF ISNULL(@i_PageNumber, 0) <= 0 OR ISNULL(@i_RowsPerPage, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS PARAMETROS DE PAGINACION DEBEN SER MAYORES A CERO';
        END
        ELSE
        BEGIN
            BEGIN TRY
                SELECT epicId, epicName, epicSummary, epicDescription, epicParentLink, epicOwner, epicStartDate, epicDueDate, epicPriority, epicCreationDate, epicCreatorId, epicModificationDate, epicModificatorId, epicStatus
                FROM [SQM_GENERAL].[TBL_Epics]
                ORDER BY epicId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;
                SET @w_totalRows = @@ROWCOUNT;
                IF @w_totalRows > 0
                BEGIN
                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'REGISTROS LISTADOS CORRECTAMENTE';
                END
                ELSE
                BEGIN
                    SET @o_Numero = 204;
                    SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
                END
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL LISTAR REGISTROS';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'ACCION PERMITIDA: I, U, S';
    END
END;
GO

GO
CREATE OR ALTER PROC [SQM_GENERAL].[USP_Features] (
    @i_featureId INT = NULL,
    @i_featureSummary VARCHAR(500) = NULL,
    @i_featureDescription VARCHAR(2000) = NULL,
    @i_featuresAcceptanceCriteria VARCHAR(4000) = NULL,
    @i_featureParentLink INT = NULL,
    @i_featureOwner INT = NULL,
    @i_featureStartDate DATE = NULL,
    @i_featureDueDate DATE = NULL,
    @i_featurePriority INT = NULL,
    @i_featureCreationDate DATETIME = NULL,
    @i_featureCreatorId INT = NULL,
    @i_featureModificationDate DATETIME = NULL,
    @i_featureModificatorId INT = NULL,
    @i_featureStatus INT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 20,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN
    SET NOCOUNT ON;
    IF @i_featureModificationDate IS NULL SET @i_featureModificationDate = GETDATE();
    DECLARE @w_totalRows INT;

    IF @i_featureCreationDate IS NULL SET @i_featureCreationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_featureSummary, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CAMPO FEATURESUMMARY ES OBLIGATORIO';
            RETURN;
        END;
        IF ISNULL(@i_featureDescription, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CAMPO FEATUREDESCRIPTION ES OBLIGATORIO';
            RETURN;
        END;
        BEGIN TRY
            INSERT INTO [SQM_GENERAL].[TBL_Features] (featureSummary, featureDescription, featuresAcceptanceCriteria, featureParentLink, featureOwner, featureStartDate, featureDueDate, featurePriority, featureCreationDate, featureCreatorId, featureModificationDate, featureModificatorId, featureStatus)
            VALUES (@i_featureSummary, @i_featureDescription, @i_featuresAcceptanceCriteria, @i_featureParentLink, @i_featureOwner, @i_featureStartDate, @i_featureDueDate, @i_featurePriority, @i_featureCreationDate, @i_featureCreatorId, @i_featureModificationDate, @i_featureModificatorId, @i_featureStatus);
            SET @o_Numero = 201;
            SET @o_MensajeUsuario = 'REGISTRO CREADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL CREAR REGISTRO';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_featureId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID FEATUREID ES OBLIGATORIO';
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Features] WHERE featureId = @i_featureId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL REGISTRO NO EXISTE';
        END
        ELSE
        BEGIN
            BEGIN TRY
                UPDATE [SQM_GENERAL].[TBL_Features]
                SET featureSummary = COALESCE(@i_featureSummary, featureSummary),
                    featureDescription = COALESCE(@i_featureDescription, featureDescription),
                    featuresAcceptanceCriteria = COALESCE(@i_featuresAcceptanceCriteria, featuresAcceptanceCriteria),
                    featureParentLink = COALESCE(@i_featureParentLink, featureParentLink),
                    featureOwner = COALESCE(@i_featureOwner, featureOwner),
                    featureStartDate = COALESCE(@i_featureStartDate, featureStartDate),
                    featureDueDate = COALESCE(@i_featureDueDate, featureDueDate),
                    featurePriority = COALESCE(@i_featurePriority, featurePriority),
                    featureCreationDate = COALESCE(@i_featureCreationDate, featureCreationDate),
                    featureCreatorId = COALESCE(@i_featureCreatorId, featureCreatorId),
                    featureModificationDate = COALESCE(@i_featureModificationDate, featureModificationDate),
                    featureModificatorId = COALESCE(@i_featureModificatorId, featureModificatorId),
                    featureStatus = COALESCE(@i_featureStatus, featureStatus)
                WHERE featureId = @i_featureId;
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR REGISTRO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF ISNULL(@i_PageNumber, 0) <= 0 OR ISNULL(@i_RowsPerPage, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS PARAMETROS DE PAGINACION DEBEN SER MAYORES A CERO';
        END
        ELSE
        BEGIN
            BEGIN TRY
                SELECT featureId, featureSummary, featureDescription, featuresAcceptanceCriteria, featureParentLink, featureOwner, featureStartDate, featureDueDate, featurePriority, featureCreationDate, featureCreatorId, featureModificationDate, featureModificatorId, featureStatus
                FROM [SQM_GENERAL].[TBL_Features]
                ORDER BY featureId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;
                SET @w_totalRows = @@ROWCOUNT;
                IF @w_totalRows > 0
                BEGIN
                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'REGISTROS LISTADOS CORRECTAMENTE';
                END
                ELSE
                BEGIN
                    SET @o_Numero = 204;
                    SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
                END
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL LISTAR REGISTROS';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'ACCION PERMITIDA: I, U, S';
    END
END;
GO

GO
CREATE OR ALTER PROC [SQM_GENERAL].[USP_ProductBacklogItems]
(
    @i_PBIId INT = NULL,
    @i_PBISummary VARCHAR(500) = NULL,
    @i_PBIDescription VARCHAR(2000) = NULL,
    @i_PBIsAcceptanceCriteria VARCHAR(4000) = NULL,
    @i_PBIOwner INT = NULL,
    @i_PBIParentLink INT = NULL,
    @i_PBIStoryPoint INT = NULL,
    @i_PBIStartDate DATE = NULL,
    @i_PBIDueDate DATE = NULL,
    @i_PBIPriority INT = NULL,
    @i_PBICreationDate DATETIME = NULL,
    @i_PBICreatorId INT = NULL,
    @i_PBIModificationDate DATETIME = NULL,
    @i_PBIModificatorId INT = NULL,
    @i_PBIStatus INT = NULL,
    @i_PageNumber INT = NULL,
    @i_RowsPerPage INT = NULL,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN
    DECLARE @w_totalRows INT;

    IF @i_PBICreationDate IS NULL
        SET @i_PBICreationDate = GETDATE();

    IF @i_PBIModificationDate IS NULL
        SET @i_PBIModificationDate = GETDATE();

    -- INSERTAR PBI --
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_PBISummary,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN ES OBLIGATORIO';
        END
        ELSE IF ISNULL(@i_PBIDescription,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA DESCRIPCION ES OBLIGATORIA';
        END
        ELSE IF ISNULL(@i_PBIsAcceptanceCriteria,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS CRITERIOS DE ACEPTACION SON OBLIGATORIOS';
        END
        ELSE IF ISNULL(@i_PBIOwner,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL OWNER ES OBLIGATORIO';
        END
        ELSE IF ISNULL(@i_PBIParentLink,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL FEATURE PADRE ES OBLIGATORIO';
        END
        ELSE IF ISNULL(@i_PBICreatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL CREADOR ES OBLIGATORIO';
        END
        ELSE IF ISNULL(@i_PBIStatus,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL STATUS ES OBLIGATORIO';
        END
        ELSE
        BEGIN
            BEGIN TRY
                INSERT INTO [SQM_GENERAL].[TBL_ProductBacklogItems]
                (PBISummary, PBIDescription, PBIsAcceptanceCriteria, PBIOwner, PBIParentLink,
                 PBIStoryPoint, PBIStartDate, PBIDueDate, PBIPriority, PBICreationDate, PBICreatorId,
                 PBIModificationDate, PBIModificatorId, PBIStatus)
                VALUES(@i_PBISummary, @i_PBIDescription, @i_PBIsAcceptanceCriteria, @i_PBIOwner, @i_PBIParentLink,
                       @i_PBIStoryPoint, @i_PBIStartDate, @i_PBIDueDate, @i_PBIPriority, @i_PBICreationDate, @i_PBICreatorId,
                       @i_PBIModificationDate, @i_PBIModificatorId, @i_PBIStatus);

                SET @o_Numero = 201; SET @o_MensajeUsuario = 'PBI REGISTRADO CORRECTAMENTE';
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR PBI';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR PBI', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE PBI --
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_PBIId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL PBI ES OBLIGATORIO';
        END
        ELSE IF ISNULL(@i_PBIModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_ProductBacklogItems] (NOLOCK) WHERE PBIId = @i_PBIId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL PBI NO EXISTE';
        END
        ELSE
        BEGIN
            BEGIN TRY
                UPDATE [SQM_GENERAL].[TBL_ProductBacklogItems]
                SET PBISummary = COALESCE(@i_PBISummary, PBISummary),
                    PBIDescription = COALESCE(@i_PBIDescription, PBIDescription),
                    PBIsAcceptanceCriteria = COALESCE(@i_PBIsAcceptanceCriteria, PBIsAcceptanceCriteria),
                    PBIOwner = COALESCE(@i_PBIOwner, PBIOwner),
                    PBIParentLink = COALESCE(@i_PBIParentLink, PBIParentLink),
                    PBIStoryPoint = COALESCE(@i_PBIStoryPoint, PBIStoryPoint),
                    PBIStartDate = COALESCE(@i_PBIStartDate, PBIStartDate),
                    PBIDueDate = COALESCE(@i_PBIDueDate, PBIDueDate),
                    PBIPriority = COALESCE(@i_PBIPriority, PBIPriority),
                    PBIModificationDate = @i_PBIModificationDate,
                    PBIModificatorId = @i_PBIModificatorId,
                    PBIStatus = COALESCE(@i_PBIStatus, PBIStatus)
                WHERE PBIId = @i_PBIId;

                SET @o_Numero = 200; SET @o_MensajeUsuario = 'PBI ACTUALIZADO CORRECTAMENTE';
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR PBI';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR PBI', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- SELECT PBI --
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF ISNULL(@i_PageNumber,0) <= 0 OR ISNULL(@i_RowsPerPage,0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS PARAMETROS DE PAGINACION SON OBLIGATORIOS Y DEBEN SER MAYORES A CERO';
        END
        ELSE
        BEGIN
            BEGIN TRY
                SELECT 
                    PBIId, PBISummary, PBIDescription, PBIsAcceptanceCriteria,
                    PBIOwner, PBIParentLink, PBIStoryPoint, PBIStartDate, PBIDueDate,
                    PBIPriority, PBICreationDate, PBICreatorId, PBIModificationDate,
                    PBIModificatorId, PBIStatus
                FROM [SQM_GENERAL].[TBL_ProductBacklogItems] (NOLOCK)
                ORDER BY PBIId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;

                SET @w_totalRows = @@ROWCOUNT;

                IF (@w_totalRows > 0)
                BEGIN
                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'PBIs LISTADOS CORRECTAMENTE';
                END
                ELSE
                BEGIN
                    SET @o_Numero = 204;
                    SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
                END
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL LISTAR PBIs';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR PBIs', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- ACCION INVALIDA --
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';
    END
END;
GO
GO
CREATE OR ALTER PROC [SQM_GENERAL].[USP_Tasks] (
    @i_taskId INT = NULL,
    @i_taskSummary VARCHAR(500) = NULL,
    @i_taskDescription VARCHAR(2000) = NULL,
    @i_taskOwner INT = NULL,
    @i_taskParentLink INT = NULL,
    @i_taskOriginalEstimate DECIMAL(4,2) = NULL,
    @i_taskCompletedWork DECIMAL(4,2) = NULL,
    @i_taskRemaningWork DECIMAL(4,2) = NULL,
    @i_taskStartDate DATE = NULL,
    @i_taskCompletedDate DATE = NULL,
    @i_taskDueDate DATE = NULL,
    @i_taskActivityType INT = NULL,
    @i_taskCreationDate DATETIME = NULL,
    @i_taskCreatorId INT = NULL,
    @i_taskModificationDate DATETIME = NULL,
    @i_taskModificatorId INT = NULL,
    @i_taskStatus INT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 20,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN
    SET NOCOUNT ON;
    IF @i_taskModificationDate IS NULL SET @i_taskModificationDate = GETDATE();
    DECLARE @w_totalRows INT;

    IF @i_taskCreationDate IS NULL SET @i_taskCreationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_taskSummary, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CAMPO TASKSUMMARY ES OBLIGATORIO';
            RETURN;
        END;
        IF ISNULL(@i_taskDescription, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CAMPO TASKDESCRIPTION ES OBLIGATORIO';
            RETURN;
        END;
        BEGIN TRY
            INSERT INTO [SQM_GENERAL].[TBL_Tasks] (taskSummary, taskDescription, taskOwner, taskParentLink, taskOriginalEstimate, taskCompletedWork, taskRemaningWork, taskStartDate, taskCompletedDate, taskDueDate, taskActivityType, taskCreationDate, taskCreatorId, taskModificationDate, taskModificatorId, taskStatus)
            VALUES (@i_taskSummary, @i_taskDescription, @i_taskOwner, @i_taskParentLink, @i_taskOriginalEstimate, @i_taskCompletedWork, @i_taskRemaningWork, @i_taskStartDate, @i_taskCompletedDate, @i_taskDueDate, @i_taskActivityType, @i_taskCreationDate, @i_taskCreatorId, @i_taskModificationDate, @i_taskModificatorId, @i_taskStatus);
            SET @o_Numero = 201;
            SET @o_MensajeUsuario = 'REGISTRO CREADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL CREAR REGISTRO';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_taskId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID TASKID ES OBLIGATORIO';
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Tasks] WHERE taskId = @i_taskId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL REGISTRO NO EXISTE';
        END
        ELSE
        BEGIN
            BEGIN TRY
                UPDATE [SQM_GENERAL].[TBL_Tasks]
                SET taskSummary = COALESCE(@i_taskSummary, taskSummary),
                    taskDescription = COALESCE(@i_taskDescription, taskDescription),
                    taskOwner = COALESCE(@i_taskOwner, taskOwner),
                    taskParentLink = COALESCE(@i_taskParentLink, taskParentLink),
                    taskOriginalEstimate = COALESCE(@i_taskOriginalEstimate, taskOriginalEstimate),
                    taskCompletedWork = COALESCE(@i_taskCompletedWork, taskCompletedWork),
                    taskRemaningWork = COALESCE(@i_taskRemaningWork, taskRemaningWork),
                    taskStartDate = COALESCE(@i_taskStartDate, taskStartDate),
                    taskCompletedDate = COALESCE(@i_taskCompletedDate, taskCompletedDate),
                    taskDueDate = COALESCE(@i_taskDueDate, taskDueDate),
                    taskActivityType = COALESCE(@i_taskActivityType, taskActivityType),
                    taskCreationDate = COALESCE(@i_taskCreationDate, taskCreationDate),
                    taskCreatorId = COALESCE(@i_taskCreatorId, taskCreatorId),
                    taskModificationDate = COALESCE(@i_taskModificationDate, taskModificationDate),
                    taskModificatorId = COALESCE(@i_taskModificatorId, taskModificatorId),
                    taskStatus = COALESCE(@i_taskStatus, taskStatus)
                WHERE taskId = @i_taskId;
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR REGISTRO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF ISNULL(@i_PageNumber, 0) <= 0 OR ISNULL(@i_RowsPerPage, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS PARAMETROS DE PAGINACION DEBEN SER MAYORES A CERO';
        END
        ELSE
        BEGIN
            BEGIN TRY
                SELECT taskId, taskSummary, taskDescription, taskOwner, taskParentLink, taskOriginalEstimate, taskCompletedWork, taskRemaningWork, taskStartDate, taskCompletedDate, taskDueDate, taskActivityType, taskCreationDate, taskCreatorId, taskModificationDate, taskModificatorId, taskStatus
                FROM [SQM_GENERAL].[TBL_Tasks]
                ORDER BY taskId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;
                SET @w_totalRows = @@ROWCOUNT;
                IF @w_totalRows > 0
                BEGIN
                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'REGISTROS LISTADOS CORRECTAMENTE';
                END
                ELSE
                BEGIN
                    SET @o_Numero = 204;
                    SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
                END
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL LISTAR REGISTROS';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'ACCION PERMITIDA: I, U, S';
    END
END;
GO

GO

/* ===== USP_TaskComments.sql ===== */
/*
  Adaptacion para DB_SCRUM_PLANNING.
  Los parametros y columnas devueltas se alinean con los campos del modelo
  de entidad correspondiente (tipos SQL equivalentes a int/str/datetime/Optional/bool).
  El codigo Pydantic de *_Models.py pertenece a Python y no se pega dentro de T-SQL.
*/
CREATE OR ALTER PROC [SQM_GENERAL].[USP_TaskComments] (
    @i_taskCommentId INT = NULL,
    @i_taskCommentParentLink INT = NULL,
    @i_taskCommentOwner INT = NULL,
    @i_taskCommentText NVARCHAR(4000) = NULL,
    @i_taskCommentCreationDate DATETIME = NULL,
    @i_taskCommentCreatorId INT = NULL,
    @i_taskCommentModificationDate DATETIME = NULL,
    @i_taskCommentModificatorId INT = NULL,
    @i_taskCommentStatus BIT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 20,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN
    SET NOCOUNT ON;
    IF @i_taskCommentStatus IS NULL SET @i_taskCommentStatus = 1;
    IF @i_taskCommentModificationDate IS NULL SET @i_taskCommentModificationDate = GETDATE();
    DECLARE @w_totalRows INT;

    IF @i_taskCommentCreationDate IS NULL SET @i_taskCommentCreationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_taskCommentText, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CAMPO TASKCOMMENTTEXT ES OBLIGATORIO';
            RETURN;
        END;
        BEGIN TRY
            INSERT INTO [SQM_GENERAL].[TBL_TaskComments] (taskCommentParentLink, taskCommentOwner, taskCommentText, taskCommentCreationDate, taskCommentCreatorId, taskCommentModificationDate, taskCommentModificatorId, taskCommentStatus)
            VALUES (@i_taskCommentParentLink, @i_taskCommentOwner, @i_taskCommentText, @i_taskCommentCreationDate, @i_taskCommentCreatorId, @i_taskCommentModificationDate, @i_taskCommentModificatorId, @i_taskCommentStatus);
            SET @o_Numero = 201;
            SET @o_MensajeUsuario = 'REGISTRO CREADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL CREAR REGISTRO';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_taskCommentId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID TASKCOMMENTID ES OBLIGATORIO';
        END
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_TaskComments] WHERE taskCommentId = @i_taskCommentId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL REGISTRO NO EXISTE';
        END
        ELSE
        BEGIN
            BEGIN TRY
                UPDATE [SQM_GENERAL].[TBL_TaskComments]
                SET taskCommentParentLink = COALESCE(@i_taskCommentParentLink, taskCommentParentLink),
                    taskCommentOwner = COALESCE(@i_taskCommentOwner, taskCommentOwner),
                    taskCommentText = COALESCE(@i_taskCommentText, taskCommentText),
                    taskCommentCreationDate = COALESCE(@i_taskCommentCreationDate, taskCommentCreationDate),
                    taskCommentCreatorId = COALESCE(@i_taskCommentCreatorId, taskCommentCreatorId),
                    taskCommentModificationDate = COALESCE(@i_taskCommentModificationDate, taskCommentModificationDate),
                    taskCommentModificatorId = COALESCE(@i_taskCommentModificatorId, taskCommentModificatorId),
                    taskCommentStatus = COALESCE(@i_taskCommentStatus, taskCommentStatus)
                WHERE taskCommentId = @i_taskCommentId;
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR REGISTRO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF ISNULL(@i_PageNumber, 0) <= 0 OR ISNULL(@i_RowsPerPage, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS PARAMETROS DE PAGINACION DEBEN SER MAYORES A CERO';
        END
        ELSE
        BEGIN
            BEGIN TRY
                SELECT taskCommentId, taskCommentParentLink, taskCommentOwner, taskCommentText, taskCommentCreationDate, taskCommentCreatorId, taskCommentModificationDate, taskCommentModificatorId, taskCommentStatus
                FROM [SQM_GENERAL].[TBL_TaskComments]
                ORDER BY taskCommentId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;
                SET @w_totalRows = @@ROWCOUNT;
                IF @w_totalRows > 0
                BEGIN
                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'REGISTROS LISTADOS CORRECTAMENTE';
                END
                ELSE
                BEGIN
                    SET @o_Numero = 204;
                    SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
                END
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL LISTAR REGISTROS';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'ACCION PERMITIDA: I, U, S';
    END
END;
GO

GO
