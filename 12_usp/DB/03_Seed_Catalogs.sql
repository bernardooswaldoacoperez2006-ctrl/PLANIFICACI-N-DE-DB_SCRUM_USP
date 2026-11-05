USE [DB_SCRUM_PLANNING];
GO
IF NOT EXISTS (SELECT 1 FROM SQM_SECURITY.TBL_Roles WHERE rolId=1)
BEGIN
    SET IDENTITY_INSERT SQM_SECURITY.TBL_Roles ON;
    INSERT SQM_SECURITY.TBL_Roles(rolId,rolName,rolCreationDate,rolCreatorId,rolEnable)
    VALUES(1,'Administrador',GETDATE(),NULL,1);
    SET IDENTITY_INSERT SQM_SECURITY.TBL_Roles OFF;
END
ELSE
    UPDATE SQM_SECURITY.TBL_Roles SET rolName='Administrador',rolEnable=1 WHERE rolId=1;
IF NOT EXISTS (SELECT 1 FROM SQM_SECURITY.TBL_Roles WHERE rolName='Usuario')
    INSERT SQM_SECURITY.TBL_Roles(rolName,rolEnable) VALUES('Usuario',1);
IF NOT EXISTS (SELECT 1 FROM SQM_CATALOGS.TBL_Status)
    INSERT SQM_CATALOGS.TBL_Status(statusName,statusEnable) VALUES('Pendiente',1),('En progreso',1),('Completado',1),('Cancelado',1);
IF NOT EXISTS (SELECT 1 FROM SQM_CATALOGS.TBL_Priorities)
    INSERT SQM_CATALOGS.TBL_Priorities(priorityName,priorityEnable) VALUES('Baja',1),('Media',1),('Alta',1),('Crítica',1);
IF NOT EXISTS (SELECT 1 FROM SQM_CATALOGS.TBL_BusinessValues)
    INSERT SQM_CATALOGS.TBL_BusinessValues(businessValueName,businessValueEnable) VALUES('Alto',1),('Medio',1),('Bajo',1);
IF NOT EXISTS (SELECT 1 FROM SQM_CATALOGS.TBL_ActivityTypes)
    INSERT SQM_CATALOGS.TBL_ActivityTypes(activityTypeName,activityTypeEnable) VALUES('Desarrollo',1),('Pruebas',1),('Documentación',1),('Reunión',1);
GO
