-- 2005 em diante pode ser feito por Server Audit

CREATE TRIGGER LogonTimeStamp
ON ALL SERVER FOR LOGON
AS
BEGIN
INSERT INTO LogonAudit SELECT GETDATE(), @@SPID, SYSTEM_USER,USER
END;
