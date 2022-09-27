DECLARE @ServerName SYSNAME
, @Message nvarchar(1000)
, @CMD1 nvarchar(max)
--
DECLARE @Server_List Table
( SrvID SMALLINT
, SrvName SYSNAME )
--
Set NoCount ON
--
-- Load up linked server list
--
BEGIN
INSERT INTO @Server_List (SrvID, SrvName)
SELECT SrvID
, SrvName 
FROM [master].[SYS].sysservers
ORDER BY SrvID ASC
END
--
SELECT TOP 1 @ServerName = SrvName
FROM @Server_List
ORDER BY SrvID ASC
--
-- Loop through the Linked Server List
--
WHILE EXISTS ( SELECT * FROM @Server_List )
BEGIN
SELECT @Message = 'Server Name is '+ @ServerName
--
RAISERROR (@Message, 10,1) WITH NOWAIT
--
SET @CMD1 = 'EXEC master.dbo.sp_serveroption @server=N'''
+ @ServerName
+ ''', @optname=N''rpc'', @optvalue=N''true'''
Exec sp_executesql @cmd1
--
SET @CMD1 = 'EXEC master.dbo.sp_serveroption @server=N'''
+ @ServerName
+ ''', @optname=N''rpc out'', @optvalue=N''true'''
Exec sp_executesql @cmd1
--
set @cmd1 = 'EXEC master.dbo.sp_serveroption @server = '''
+ @ServerName
+ ''', @optname=N''remote proc transaction promotion'', @optvalue=N''false'''
Exec sp_executesql @stmt=@cmd1,@params=N''
--
DELETE FROM @Server_List WHERE SrvName = @ServerName
--
SELECT TOP 1 @ServerName = SrvName
FROM @Server_List
ORDER BY SrvID ASC
--
END 