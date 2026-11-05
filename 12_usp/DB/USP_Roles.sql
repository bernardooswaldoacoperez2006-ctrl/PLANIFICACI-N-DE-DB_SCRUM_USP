/*
  Adaptacion para DB_SCRUM_PLANNING.
  Los parametros y columnas devueltas se alinean con los campos del modelo
  de entidad correspondiente (tipos SQL equivalentes a int/str/datetime/Optional/bool).
  El codigo Pydantic de *_Models.py pertenece a Python y no se pega dentro de T-SQL.
*/
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
