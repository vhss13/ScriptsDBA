USE MASTER
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID('dbo.fn_blocker_pfe_sql_text'))
   DROP FUNCTION dbo.fn_blocker_pfe_sql_text

GO
---------------------------------------------------------------------------------------
-- Procedure: dbo.fn_blocker_pfe_sql_text 
---------------------------------------------------------------------------------------
CREATE FUNCTION dbo.fn_blocker_pfe_sql_text(@sql_handle BINARY(20), @stmt_start INT, @stmt_end INT, @length INT)
RETURNS VARCHAR(8000)
AS
BEGIN

    DECLARE @text VARCHAR(8000)
    DECLARE @len INT

    IF @stmt_end > 0 
    BEGIN
       SET @len = (@stmt_end - @stmt_start)/2
       IF @len < @length 
          SET @length = @len       
    END
 
    SELECT @text = SUBSTRING(text, @stmt_start/2, @length) FROM ::fn_get_sql(@sql_handle)

    RETURN @text

end

GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID('dbo.sp_blocker_pfe80') )
   DROP PROCEDURE dbo.sp_blocker_pfe80
GO
---------------------------------------------------------------------------------------
-- Procedure: dbo.sp_blocker_pfe 
---------------------------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_blocker_pfe80 (
    @info bit = 0, 
    @process bit = 0, 
    @process2 bit = 0, 
    @lock bit = 0, 
    @waitstat bit = 0, 
    @inputbuffer bit = 0,
    @sqlhandle bit = 0,
    @sqlhandle_collect bit = 0,
    @sqlhandle_flush bit = 0,
    @opentran bit = 0,
    @logspace bit = 0,
    @memstatus bit = 0,
    @perfinfo bit = 0,
    @trace bit = 0,
    @textsize int = 256
    )
AS 

SET NOCOUNT ON
SET LANGUAGE 'us_english'

DECLARE @spid VARCHAR(6)
DECLARE @blocked VARCHAR(6)
DECLARE @time DATETIME
DECLARE @time2 DATETIME
DECLARE @dbname nVARCHAR(128)
DECLARE @status SQL_VARIANT
DECLARE @useraccess SQL_VARIANT
DECLARE @perfobjname NVARCHAR(256)

IF is_member('sysadmin')=0 
BEGIN
  PRINT 'Deve ser um membro do grupo sysadmin para executar esta procedure'
  return
END

SET @time = getdate()

DECLARE @probclients 
    TABLE (
        spid        SMALLINT, 
        ecid        SMALLINT, 
        blocked        SMALLINT, 
        waittype    BINARY(2), 
        dbid        SMALLINT, 
        sql_handle    BINARY(20), 
        stmt_start    INT, 
        stmt_end    INT, 
        PRIMARY KEY (spid, ecid))

INSERT @probclients 
    SELECT spid, ecid, blocked, waittype, dbid, sql_handle, stmt_start, stmt_end
    FROM master.dbo.sysprocesses 
    WHERE 
            (
            kpid<>0 OR 
            waittype<>0x0000 OR 
            open_tran<>0 OR 
            spid IN (SELECT blocked FROM master.dbo.sysprocesses)
            ) AND spid>50

---------------------------------------------------------------------------------------
-- 8.2 Start time: 
---------------------------------------------------------------------------------------
SET @time2 = GETDATE()
PRINT ''
--PRINT 'Start time: ' + CONVERT(VARCHAR(26), @time, 121) + ' ' + CONVERT(VARCHAR(12), datediff(ms,@time,@time2))

---------------------------------------------------------------------------------------
-- Static Configuration
---------------------------------------------------------------------------------------
IF @info = 1 
BEGIN
    SET @time2 = GETDATE()
    PRINT ''
    PRINT 'INFORMAÇÕES'

    PRINT ''
    PRINT 'ServerName: ' + @@SERVERNAME
    PRINT 'PhysicalName: ' + CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS VARCHAR)
    PRINT 'ProductVersion: ' + CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR)
    PRINT 'ProductLevel: ' + CAST(SERVERPROPERTY('ProductLevel') AS VARCHAR)
    PRINT 'Edition: ' + CAST(SERVERPROPERTY('Edition') AS VARCHAR)
    PRINT 'ProcessId: ' + CAST(SERVERPROPERTY('ProcessId') AS VARCHAR)
    PRINT 'SessionId: ' + CAST(@@SPID AS VARCHAR)
    PRINT ''
    --PRINT @@version
    --PRINT ''
    --PRINT 'EXEC xp_msver'
    --PRINT ''
    --EXEC xp_msver

    --PRINT 'SELECT sysconfigures'
    --PRINT ''
    --SELECT value, comment FROM sysconfigures

    --PRINT 'INFO ' + convert(VARCHAR(12), datediff(ms,@time2,getdate())) 
END

---------------------------------------------------------------------------------------
-- Connections 
---------------------------------------------------------------------------------------
IF @process = 1 
BEGIN
    SET @time2 = GETDATE()
    PRINT ''
    PRINT 'SYSPROCESSES' 

    SELECT spid, status, blocked, open_tran, 
        waitresource, waittype, waittime, cmd, lastwaittype, 
        cpu, physical_io,memusage, 
        last_batch=convert(VARCHAR(26), last_batch,121),
        login_time=convert(VARCHAR(26), login_time,121),
        net_address,net_library, 
        dbid, ecid, kpid, hostname, hostprocess, loginame, program_name, 
        nt_domain, nt_username, uid, sid,
        sql_handle, stmt_start, stmt_end
    FROM master.dbo.sysprocesses
    WHERE 
        spid IN (SELECT spid FROM @probclients)

    --PRINT 'ESP ' + convert(VARCHAR(12), datediff(ms,@time2,getdate())) 
END

---------------------------------------------------------------------------------------
-- Connections2 
---------------------------------------------------------------------------------------
IF @process2 = 1 
BEGIN
    SET @time2 = GETDATE()
    PRINT ''
    PRINT 'SYSPROCESSES2' 

    SELECT spid, status, blocked, open_tran, 
        waitresource, waittype, waittime, cmd, lastwaittype, 
        cpu, physical_io,memusage, 
        last_batch=convert(VARCHAR(26), last_batch,121),
        login_time=convert(VARCHAR(26), login_time,121),
        net_address,net_library, 
        dbid, ecid, kpid, hostname, hostprocess, loginame, program_name, 
        nt_domain, nt_username, uid, sid,
        sql_handle, stmt_start, stmt_end
    FROM master.dbo.sysprocesses
    WHERE 
        (kpid<>0 OR waittype<>0x0000 OR open_tran<>0) AND (spid>50)

   -- PRINT 'ESP2 ' + convert(VARCHAR(12), datediff(ms,@time2,getdate())) 
END
---------------------------------------------------------------------------------------
-- SYSLOCKINFO 
---------------------------------------------------------------------------------------
IF @lock = 1 
BEGIN
    SELECT @time2 = GETDATE()
    PRINT ''
    PRINT 'SYSLOCKINFO'

	SELECT CONVERT (smallint, req_spid) AS spid,
		rsc_dbid AS dbid,
		rsc_objid AS ObjId,
		rsc_indid AS IndId,
		SUBSTRING (v.name, 1, 4) AS Type,
		SUBSTRING (rsc_text, 1, 32) as Resource,
		SUBSTRING (u.name, 1, 8) AS Mode,
		SUBSTRING (x.name, 1, 5) AS Status
	FROM 	
		master.dbo.syslockinfo l inner join master.dbo.spt_values v on (l.rsc_type = v.number and v.type = 'LR')
								 inner join master.dbo.spt_values x on (l.req_status = x.number and x.type = 'LS')
								 inner join master.dbo.spt_values u on (l.req_mode + 1 = u.number and u.type = 'L')
	WHERE l.rsc_type = 5 


   -- PRINT 'ESL ' + convert(VARCHAR(12), datediff(ms,@time2,getdate())) 
END

---------------------------------------------------------------------------------------
-- DBCC SQLPERF(WAITSTATS)
---------------------------------------------------------------------------------------
--IF @waitstat = 1 
--BEGIN
--    SELECT @time2 = GETDATE()
--    PRINT ''
--    PRINT 'DBCC SQLPERF(WAITSTATS)'

--    DBCC SQLPERF(WAITSTATS)

--    PRINT 'DBCCWAIT ' + convert(VARCHAR(12), datediff(ms,@time2,getdate())) 
--END

---------------------------------------------------------------------------------------
-- DBCC INPUTBUFFER
---------------------------------------------------------------------------------------
--IF @inputbuffer = 1
--BEGIN
--    SELECT @time2 = GETDATE()
--    PRINT ''
--    PRINT 'DBCC INPUTBUFFER(*)'

--    DECLARE ibuffer CURSOR FAST_FORWARD FOR
--        SELECT DISTINCT CAST (spid AS VARCHAR(6)) AS spid
--        FROM @probclients
--        WHERE (spid <> @@spid) 

--    OPEN ibuffer
--    FETCH NEXT FROM ibuffer INTO @spid
        
--    WHILE (@@FETCH_STATUS <> -1)
--    BEGIN
--        PRINT ''
--        PRINT 'DBCC INPUTBUFFER FOR SPID ' + @spid
--        EXEC ('DBCC INPUTBUFFER (' + @spid + ')')

--        FETCH NEXT FROM ibuffer INTO @spid
--    END
--    DEALLOCATE IBUFFER

--    PRINT 'DBCCINPUTBUFFER(*) END ' + convert(VARCHAR(12), datediff(ms,@time2,getdate())) 
--END

---------------------------------------------------------------------------------------
-- SQLHANDLE
---------------------------------------------------------------------------------------
--IF @sqlhandle = 1
--BEGIN
--    SELECT @time2 = GETDATE()
--    PRINT ''
--    PRINT 'SQLHANDLE'

--    SELECT 
--        sql_handle, stmt_start, stmt_end,
--        total = count(*), 
--        text = cast(dbo.fn_blocker_pfe_sql_text(sql_handle, stmt_start, stmt_end, @textsize) as VARCHAR(1024))
--    FROM @probclients WHERE ecid = 0 and spid<>@@spid
--    GROUP BY sql_handle, stmt_start, stmt_end
--    ORDER BY count(*) DESC

--    PRINT 'ESH HANDLE 0x0000000000000000000000000000000000000000 ' + convert(VARCHAR(12), datediff(ms,@time2,getdate())) 
--END

---------------------------------------------------------------------------------------
-- DBCC OPENTRAN
---------------------------------------------------------------------------------------
--IF @opentran = 1 
--BEGIN
--    SELECT @time2 = GETDATE()
--    PRINT ''
--    PRINT 'DBCC OPENTRAN(*)'
--    DECLARE ibuffer CURSOR FAST_FORWARD FOR
--        SELECT DISTINCT CAST (dbid AS VARCHAR(6)) FROM @probclients
--        WHERE dbid <> 0
--        UNION SELECT '2'

--    OPEN ibuffer
--    FETCH NEXT FROM ibuffer INTO @spid

--    WHILE (@@FETCH_STATUS <> -1)
--    BEGIN
--        PRINT ''
--        SET @dbname = DB_NAME(@spid)
--        SET @status = DATABASEPROPERTYEX(@dbname,'Status')
--        SET @useraccess = DATABASEPROPERTYEX(@dbname,'UserAccess')

--        PRINT 'DBCC OPENTRAN FOR DBID ' + @spid + ' ['+ @dbname + ']'

--        IF @status = N'ONLINE' and @useraccess = N'SINGLE_USER'
--            PRINT 'Skipped: Status=ONLINE UserAccess=SINGLE_USER'
--        ELSE
--            DBCC OPENTRAN(@dbname)
        
--        FETCH NEXT FROM ibuffer INTO @spid

--    END

--    DEALLOCATE ibuffer

--    PRINT 'DBCCOPENTRAN(*) END ' + convert(VARCHAR(12), datediff(ms,@time2,getdate()))
--END

---------------------------------------------------------------------------------------
-- DBCC MEMORYSTATUS
---------------------------------------------------------------------------------------
--IF @memstatus = 1
--BEGIN
--    SELECT @time2 = GETDATE()
--    PRINT ''
--    PRINT 'DBCC MEMORYSTATUS'

--    DBCC MEMORYSTATUS

--    PRINT 'MEMSTATUS ' + convert(VARCHAR(12), datediff(ms,@time2,getdate()))
--END

---------------------------------------------------------------------------------------
-- DBCC SQLPERF(LOGSPACE)
---------------------------------------------------------------------------------------
--IF @logspace = 1
--BEGIN
--    SELECT @time2 = GETDATE()
--    PRINT ''
--    PRINT 'DBCC SQLPERF(LOGSPACE)'

--    DBCC SQLPERF(LOGSPACE)

--    PRINT 'DBCCLOG ' + convert(VARCHAR(12), datediff(ms,@time2,getdate()))
--END

---------------------------------------------------------------------------------------
-- Sysperfinfo
---------------------------------------------------------------------------------------
--IF @perfinfo = 1
--BEGIN

--    SELECT @time2 = GETDATE()
--    PRINT ''
--    PRINT 'SYSPERFINFO'
    
--    SELECT TOP 1 @perfobjname=LEFT(object_name, CHARINDEX(N':',object_name)) FROM sysperfinfo
--    SELECT object_name, counter_name, cntr_value FROM sysperfinfo
--    WHERE 
--        object_name IN (@perfobjname + N'Buffer Manager',
--                        @perfobjname + N'Databases',
--                        @perfobjname + N'General Statistics',
--                        @perfobjname + N'Memory Manager',
--                        @perfobjname + N'SQL Statistics') 

--    PRINT 'PERFINFO ' + convert(VARCHAR(12), datediff(ms,@time2,getdate()))

--END

---------------------------------------------------------------------------------------
-- ::fn_trace_getinfo
---------------------------------------------------------------------------------------
--IF @trace = 1
--BEGIN
--    SELECT @time2 = GETDATE()
--    PRINT ''
--    PRINT 'TRACE_GETINFO'

--    SELECT * FROM ::fn_trace_getinfo(0)

--    PRINT 'TRCINF ' + convert(VARCHAR(12), datediff(ms,@time2,getdate()))
--END

---------------------------------------------------------------------------------------
-- End time
---------------------------------------------------------------------------------------
--PRINT ''
--PRINT 'End time: ' + convert(varchar(26), getdate(), 121)
   
GO    

IF EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID('dbo.sp_blocker_pfe_auto') )
   DROP PROCEDURE dbo.sp_blocker_pfe_auto
GO
---------------------------------------------------------------------------------------
-- Procedure: dbo.sp_blocker_pfe_auto
---------------------------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_blocker_pfe_auto
AS

SET NOCOUNT ON

EXEC dbo.sp_blocker_pfe80 @info = 1, @trace = 1

--WHILE 1=1
BEGIN

    --EXEC dbo.sp_blocker_pfe80 @process2 = 1, @inputbuffer = 1, @sqlhandle = 1
    --RAISERROR('',0,1) WITH NOWAIT
    --WAITFOR DELAY '0:0:15'

    --EXEC dbo.sp_blocker_pfe80 @process2 = 1, @inputbuffer = 1, @sqlhandle = 1
    --RAISERROR('',0,1) WITH NOWAIT
    --WAITFOR DELAY '0:0:15'

	--EXEC dbo.sp_blocker_pfe80 @process2 = 1, @inputbuffer = 1, @sqlhandle = 1
	--RAISERROR('',0,1) WITH NOWAIT
	-- WAITFOR DELAY '0:0:15'

    EXEC dbo.sp_blocker_pfe80 
            @process2 = 1, @inputbuffer = 1, @sqlhandle = 1,
            @waitstat = 1, @lock = 1, @opentran = 1
    RAISERROR('',0,1) WITH NOWAIT
    --WAITFOR DELAY '0:0:15'
    
END