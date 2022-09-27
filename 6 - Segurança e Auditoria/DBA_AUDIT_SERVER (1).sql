--------------------------------------------------------------------------

USE [master]
GO

/****** Object:  Audit [Audit-20130620-165920]    Script Date: 6/20/2013 6:55:01 PM ******/
DROP SERVER AUDIT [Audit-20130620-165920]
GO

/****** Object:  Audit [Audit-20130620-165920]    Script Date: 6/20/2013 6:55:01 PM ******/
CREATE SERVER AUDIT [Audit-20130620-165920]
TO FILE 
(	FILEPATH = N'D:\EDSON\'
	,MAXSIZE = 10 MB
	,MAX_FILES = 5
	,RESERVE_DISK_SPACE = OFF
)
WITH
(	QUEUE_DELAY = 1000
	,ON_FAILURE = CONTINUE
	,AUDIT_GUID = '39d7d96f-33a1-4517-b829-1a29d6ef68ce'
)
ALTER SERVER AUDIT [Audit-20130620-165920] WITH (STATE = ON)
GO

--------------------------------------------------------------------------

USE [master]
GO

DROP SERVER AUDIT SPECIFICATION [ServerAuditSpecification-20130620-170000]
GO

CREATE SERVER AUDIT SPECIFICATION [ServerAuditSpecification-20130620-170000]
FOR SERVER AUDIT [Audit-20130620-165920]
ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),
ADD (BACKUP_RESTORE_GROUP),
ADD (SERVER_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (SERVER_PERMISSION_CHANGE_GROUP),
ADD (SERVER_PRINCIPAL_IMPERSONATION_GROUP),
ADD (DATABASE_CHANGE_GROUP),
ADD (DATABASE_OBJECT_CHANGE_GROUP),
ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),
ADD (SERVER_OBJECT_CHANGE_GROUP),
ADD (SERVER_PRINCIPAL_CHANGE_GROUP),
ADD (SERVER_OPERATION_GROUP),
ADD (SERVER_STATE_CHANGE_GROUP),
ADD (SERVER_OBJECT_OWNERSHIP_CHANGE_GROUP)
WITH (STATE = ON)
GO

--------------------------------------------------------------------------
