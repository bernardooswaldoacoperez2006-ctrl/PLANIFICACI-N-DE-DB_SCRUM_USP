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
