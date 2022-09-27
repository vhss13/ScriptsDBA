/**********************************************************************************************
 * Tipo           Data            Autor            Versão                                     *
 * Query          30/09/2010      Marcelo Koga     1.0                                        *
 * Objetivo: Coletar informações dos privilégios sys dos usuários                             *
 *           Privilégios de create procedure, create funtion, show plan, etc                  *
 *                                                                                            *
 * Obs.:  Para demais privilegios com vinculo com as roles pode-se utilizar outras queries    * 
 * -- Instance                                                                                *
 *  dbo.sp_helpsrvrolemember(Instância)                                                       *
 *                                                                                            *
 * -- Database                                                                                *
 * USE <DATABASE>                                                                             *
 * GO                                                                                         *
 * select DbRole = g.name,                                                                    *
 *        MemberName = u.name,                                                                *
 *        LoginName = l.name                                                                  *
 * from sysusers u,                                                                           *
 *      sysusers g,                                                                           *
 *      sysmembers m,                                                                         *
 *      master.dbo.syslogins l                                                                *
 * where   g.uid = m.groupuid                                                                 *
 * and g.issqlrole = 1                                                                        *
 * and u.uid = m.memberuid                                                                    *
 * and u.sid = l.sid                                                                          *
 * order by 1, 2                                                                              *
 *                                                                                            *
 *********************************************************************************************/

IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#DBPrivInfo'))
BEGIN
DROP TABLE #DBPrivInfo
END

IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#DBPrivInfoTMP'))
BEGIN
DROP TABLE #DBPrivInfoTMP
END

CREATE TABLE #DBPrivInfo
([dbname] sysname, [username] sysname, [entity_name] sysname ,[subentity_name] sysname,[permission_name] sysname)

CREATE TABLE #DBPrivInfoTMP
([entity_name] sysname ,[subentity_name] sysname,[permission_name] sysname)

DECLARE @SQLString VARCHAR(3000)
DECLARE @MinDBId INT
DECLARE @MaxDBId INT
DECLARE @MinUserId INT
DECLARE @MaxUserId INT
DECLARE @DBName VARCHAR(255)
DECLARE @UserName VARCHAR(255)

DECLARE @tblDBName TABLE
(RowId INT IDENTITY(1,1),DBName VARCHAR(255),DBId INT)

DECLARE @tblUserName TABLE
(RowId INT IDENTITY(1,1),UserName VARCHAR(255),UserId INT)

INSERT INTO @tblDBName (DBName,DBId)
SELECT [Name],DBId FROM Master..sysdatabases WHERE (Status & 512) = 0 /*NOT IN (536,528,540,2584,1536,512,4194841)*/ and name not in ('tempdb') ORDER BY [Name]

SELECT @MinDBId = MIN(RowId),
@MaxDBId = MAX(RowId)
FROM @tblDBName

WHILE (@MinDBId <= @MaxDBId)
BEGIN
SELECT @DBName = [DBName]
FROM @tblDBName
WHERE RowId = @MinDBId

	SELECT @SQLString = 
	'USE ' + @DBName + ';' +
	'SELECT u.Name,u.UID' +
	' from sysusers u, sysusers g, sysmembers m, master.dbo.syslogins l' +
	' where g.uid = m.groupuid and u.uid = m.memberuid and u.sid = l.sid' +
	' and u.islogin = 1 and u.isntgroup = 0 and left(u.name,2) <> ''##'' and u.name not in (''dbo'',''guest'',''INFORMATION_SCHEMA'',''sys'')'
	
	DELETE FROM @tblUserName

	INSERT INTO @tblUserName (UserName,UserId)
	EXEC (@SQLString)

	SELECT @MinUserId = MIN(RowId),
	@MaxUserId = MAX(RowId)
	FROM @tblUserName

	WHILE (@MinUserId <= @MaxUserId)
	BEGIN
	SELECT @UserName = [UserName]
	FROM @tblUserName
	WHERE RowId = @MinUserId

	SELECT @SQLString = 
	'USE ' + @DBName + ';' +
	'EXECUTE AS USER = ''' + @username + ''';' +
	'SELECT * FROM fn_my_permissions(NULL, ''database'') ORDER BY subentity_name, permission_name ;' +
	'REVERT;'

	TRUNCATE TABLE #DBPrivInfoTMP

	INSERT INTO #DBPrivInfoTMP ([entity_name],[subentity_name],[permission_name])
	EXEC (@SQLString)

	INSERT INTO #DBPrivInfo([DBName],[username],[entity_name],[subentity_name],[permission_name])
	SELECT @DBName,@username,[entity_name],[subentity_name],[permission_name]
	FROM #DBPrivInfoTMP

	SELECT @MinUserId = @MinUserId + 1
	END

SELECT @MinDBId = @MinDBId + 1
END

SELECT * FROM #DBPrivInfo;

IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#DBPrivInfo'))
BEGIN
DROP TABLE #DBPrivInfo
END

IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#DBPrivInfoTMP'))
BEGIN
DROP TABLE #DBPrivInfoTMP
END