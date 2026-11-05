/*
  Adaptacion para DB_SCRUM_PLANNING.
  Los parametros y columnas devueltas se alinean con los campos del modelo
  de entidad correspondiente (tipos SQL equivalentes a int/str/datetime/Optional/bool).
  El codigo Pydantic de *_Models.py pertenece a Python y no se pega dentro de T-SQL.
*/
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
