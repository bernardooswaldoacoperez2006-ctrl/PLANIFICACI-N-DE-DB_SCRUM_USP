USE [DB_SCRUM_PLANNING];
GO
/* Tablas base para los 12 procedimientos almacenados incluidos. */
IF OBJECT_ID(N'SQM_SECURITY.TBL_Roles',N'U') IS NULL CREATE TABLE SQM_SECURITY.TBL_Roles (
 rolId INT IDENTITY(1,1) PRIMARY KEY, rolName VARCHAR(80) NOT NULL UNIQUE,
 rolCreationDate DATETIME NOT NULL CONSTRAINT DF_Roles_Creation DEFAULT GETDATE(), rolCreatorId INT NULL,
 rolModificationDate DATETIME NULL, rolModificatorId INT NULL, rolEnable BIT NOT NULL CONSTRAINT DF_Roles_Enable DEFAULT 1);
GO
IF OBJECT_ID(N'SQM_SECURITY.TBL_Users',N'U') IS NULL CREATE TABLE SQM_SECURITY.TBL_Users (
 userId INT IDENTITY(1,1) PRIMARY KEY, userFullName VARCHAR(80) NOT NULL, userName VARCHAR(80) NOT NULL UNIQUE,
 userEmail VARCHAR(80) NOT NULL UNIQUE, userPassword VARBINARY(256) NOT NULL, userRolId INT NOT NULL,
 userCreationDate DATETIME NOT NULL CONSTRAINT DF_Users_Creation DEFAULT GETDATE(), userCreatorId INT NULL,
 userModificationDate DATETIME NULL, userModificatorId INT NULL, userEnable BIT NOT NULL CONSTRAINT DF_Users_Enable DEFAULT 1,
 CONSTRAINT FK_Users_Roles FOREIGN KEY(userRolId) REFERENCES SQM_SECURITY.TBL_Roles(rolId));
GO
IF OBJECT_ID(N'SQM_CATALOGS.TBL_Status',N'U') IS NULL CREATE TABLE SQM_CATALOGS.TBL_Status (
 statusId INT IDENTITY(1,1) PRIMARY KEY, statusName VARCHAR(80) NOT NULL UNIQUE,
 statusCreationDate DATETIME NOT NULL DEFAULT GETDATE(), statusCreatorId INT NULL, statusModificationDate DATETIME NULL,
 statusModificatorId INT NULL, statusEnable BIT NOT NULL DEFAULT 1);
IF OBJECT_ID(N'SQM_CATALOGS.TBL_Priorities',N'U') IS NULL CREATE TABLE SQM_CATALOGS.TBL_Priorities (
 priorityId INT IDENTITY(1,1) PRIMARY KEY, priorityName VARCHAR(80) NOT NULL UNIQUE,
 priorityCreationDate DATETIME NOT NULL DEFAULT GETDATE(), priorityCreatorId INT NULL, priorityModificationDate DATETIME NULL,
 priorityModificatorId INT NULL, priorityEnable BIT NOT NULL DEFAULT 1);
IF OBJECT_ID(N'SQM_CATALOGS.TBL_BusinessValues',N'U') IS NULL CREATE TABLE SQM_CATALOGS.TBL_BusinessValues (
 businessValueId INT IDENTITY(1,1) PRIMARY KEY, businessValueName VARCHAR(80) NOT NULL UNIQUE,
 businessValueCreationDate DATETIME NOT NULL DEFAULT GETDATE(), businessValueCreatorId INT NULL, businessValueModificationDate DATETIME NULL,
 businessValueModificatorId INT NULL, businessValueEnable BIT NOT NULL DEFAULT 1);
IF OBJECT_ID(N'SQM_CATALOGS.TBL_ActivityTypes',N'U') IS NULL CREATE TABLE SQM_CATALOGS.TBL_ActivityTypes (
 activityTypeId INT IDENTITY(1,1) PRIMARY KEY, activityTypeName VARCHAR(80) NOT NULL UNIQUE,
 activityTypeCreationDate DATETIME NOT NULL DEFAULT GETDATE(), activityTypeCreatorId INT NULL, activityTypeModificationDate DATETIME NULL,
 activityTypeModificatorId INT NULL, activityTypeEnable BIT NOT NULL DEFAULT 1);
GO
IF OBJECT_ID(N'SQM_GENERAL.TBL_Initiatives',N'U') IS NULL CREATE TABLE SQM_GENERAL.TBL_Initiatives (
 initiativeId INT IDENTITY(1,1) PRIMARY KEY, initiativeSummary VARCHAR(200) NOT NULL, initiativeDescription VARCHAR(2000) NULL,
 initiativeOwner INT NULL, initiativeGoals VARCHAR(255) NULL, initiativeBusinessValue INT NULL, initiativeTargetStart DATE NULL,
 initiativeTargetEnd DATE NULL, initiativeCreationDate DATETIME NOT NULL DEFAULT GETDATE(), initiativeCreatorId INT NULL,
 initiativeModificationDate DATETIME NULL, initiativeModificatorId INT NULL, initiativeStatus INT NULL);
IF OBJECT_ID(N'SQM_GENERAL.TBL_Epics',N'U') IS NULL CREATE TABLE SQM_GENERAL.TBL_Epics (
 epicId INT IDENTITY(1,1) PRIMARY KEY, epicName VARCHAR(100) NOT NULL, epicSummary VARCHAR(500) NULL, epicDescription VARCHAR(4000) NULL,
 epicParentLink INT NULL, epicOwner INT NULL, epicStartDate DATE NULL, epicDueDate DATE NULL, epicPriority INT NULL,
 epicCreationDate DATETIME NOT NULL DEFAULT GETDATE(), epicCreatorId INT NULL, epicModificationDate DATETIME NULL,
 epicModificatorId INT NULL, epicStatus INT NULL);
IF OBJECT_ID(N'SQM_GENERAL.TBL_Features',N'U') IS NULL CREATE TABLE SQM_GENERAL.TBL_Features (
 featureId INT IDENTITY(1,1) PRIMARY KEY, featureSummary VARCHAR(500) NOT NULL, featureDescription VARCHAR(2000) NULL,
 featuresAcceptanceCriteria VARCHAR(4000) NULL, featureParentLink INT NULL, featureOwner INT NULL, featureStartDate DATE NULL,
 featureDueDate DATE NULL, featurePriority INT NULL, featureCreationDate DATETIME NOT NULL DEFAULT GETDATE(), featureCreatorId INT NULL,
 featureModificationDate DATETIME NULL, featureModificatorId INT NULL, featureStatus INT NULL);
IF OBJECT_ID(N'SQM_GENERAL.TBL_ProductBacklogItems',N'U') IS NULL CREATE TABLE SQM_GENERAL.TBL_ProductBacklogItems (
 PBIId INT IDENTITY(1,1) PRIMARY KEY, PBISummary VARCHAR(500) NOT NULL, PBIDescription VARCHAR(2000) NOT NULL,
 PBIsAcceptanceCriteria VARCHAR(4000) NOT NULL, PBIOwner INT NULL, PBIParentLink INT NULL, PBIStoryPoint INT NULL,
 PBIStartDate DATE NULL, PBIDueDate DATE NULL, PBIPriority INT NULL, PBICreationDate DATETIME NOT NULL DEFAULT GETDATE(),
 PBICreatorId INT NULL, PBIModificationDate DATETIME NULL, PBIModificatorId INT NULL, PBIStatus INT NULL);
IF OBJECT_ID(N'SQM_GENERAL.TBL_Tasks',N'U') IS NULL CREATE TABLE SQM_GENERAL.TBL_Tasks (
 taskId INT IDENTITY(1,1) PRIMARY KEY, taskSummary VARCHAR(500) NOT NULL, taskDescription VARCHAR(2000) NULL,
 taskOwner INT NULL, taskParentLink INT NULL, taskOriginalEstimate DECIMAL(4,2) NULL, taskCompletedWork DECIMAL(4,2) NULL,
 taskRemaningWork DECIMAL(4,2) NULL, taskStartDate DATE NULL, taskCompletedDate DATE NULL, taskDueDate DATE NULL,
 taskActivityType INT NULL, taskCreationDate DATETIME NOT NULL DEFAULT GETDATE(), taskCreatorId INT NULL,
 taskModificationDate DATETIME NULL, taskModificatorId INT NULL, taskStatus INT NULL);
IF OBJECT_ID(N'SQM_GENERAL.TBL_TaskComments',N'U') IS NULL CREATE TABLE SQM_GENERAL.TBL_TaskComments (
 taskCommentId INT IDENTITY(1,1) PRIMARY KEY, taskCommentParentLink INT NOT NULL, taskCommentOwner INT NULL,
 taskCommentText NVARCHAR(4000) NOT NULL, taskCommentCreationDate DATETIME NOT NULL DEFAULT GETDATE(), taskCommentCreatorId INT NULL,
 taskCommentModificationDate DATETIME NULL, taskCommentModificatorId INT NULL, taskCommentStatus BIT NOT NULL DEFAULT 1);
GO
