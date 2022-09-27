/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

USE [DBAFMU]
GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DisplayToID]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[DisplayToID]
GO

CREATE TABLE [dbo].[DisplayToID](
	[GUID] [uniqueidentifier] NOT NULL,
	[RunID] [int] NULL,
	[DisplayString] [varchar](1024) NOT NULL,
	[LogStartTime] [char](24) NULL,
	[LogStopTime] [char](24) NULL,
	[NumberOfRecords] [int] NULL,
	[MinutesToUTC] [int] NULL,
	[TimeZoneName] [char](32) NULL
) ON [PRIMARY]

GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CounterDetails]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[CounterDetails]
GO

CREATE TABLE [dbo].[CounterDetails](
	[CounterID] [int] IDENTITY(1,1) NOT NULL,
	[MachineName] [varchar](1024) NOT NULL,
	[ObjectName] [varchar](1024) NOT NULL,
	[CounterName] [varchar](1024) NOT NULL,
	[CounterType] [int] NOT NULL,
	[DefaultScale] [int] NOT NULL,
	[InstanceName] [varchar](1024) NULL,
	[InstanceIndex] [int] NULL,
	[ParentName] [varchar](1024) NULL,
	[ParentObjectID] [int] NULL,
	[TimeBaseA] [int] NULL,
	[TimeBaseB] [int] NULL
) ON [PRIMARY]

GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CounterData]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[CounterData]
GO

CREATE TABLE [dbo].[CounterData](
	[GUID] [uniqueidentifier] NOT NULL,
	[CounterID] [int] NOT NULL,
	[RecordIndex] [int] NOT NULL,
	[CounterDateTime] [char](24) NOT NULL,
	[CounterValue] [float] NOT NULL,
	[FirstValueA] [int] NULL,
	[FirstValueB] [int] NULL,
	[SecondValueA] [int] NULL,
	[SecondValueB] [int] NULL,
	[MultiCount] [int] NULL
) ON [PRIMARY]

GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DS_Carga_Capacidade_BancoDatafile]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[DS_Carga_Capacidade_BancoDatafile]
GO

CREATE TABLE [dbo].[DS_Carga_Capacidade_BancoDatafile](
	[DataHoraColeta] [datetime] NOT NULL,
	[NomeServidor] [sql_variant] NULL,
	[NomeInstancia] [sql_variant] NULL,
	[NomeDrive] [varchar](3) NULL,
	[NomeBancoDados] [varchar](50) NULL,
	[NomeArquivoLogicoBancoDados] [varchar](50) NULL,
	[TipoArquivoLogicoBancoDados] [varchar](10) NULL,
	[NomeArquivoFisicoBancoDados] [varchar](200) NULL,
	[EspacoTotalBancoMB] [int] NULL,
	[EspacoUtilizadoBancoMB] [int] NULL,
	[EspacoLivreBancoMB] [int] NULL
) ON [PRIMARY]
GO 

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DS_Carga_Capacidade_BancoTabela]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[DS_Carga_Capacidade_BancoTabela]
GO

CREATE TABLE [dbo].[DS_Carga_Capacidade_BancoTabela](
	[DataHoraColeta] [datetime] NOT NULL,
	[NomeServidor] [sql_variant] NULL,
	[NomeInstancia] [sql_variant] NULL,
	[NomeBancoDados] [varchar](50) NULL,
	[NomeTabela] [varchar](100) NULL,
	[QuantidadeLinhas] [int] NULL,
	[EspacoAlocadoMB] [int] NULL,
	[EspacoUtilizadoMB] [int] NULL
) ON [PRIMARY]
GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DS_Carga_Capacidade_Disco]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[DS_Carga_Capacidade_Disco]
GO

CREATE TABLE [dbo].[DS_Carga_Capacidade_Disco](
	[DataHoraColeta] [datetime] NOT NULL,
	[NomeServidor] [sql_variant] NULL,
	[NomeInstancia] [sql_variant] NULL,
	[NomeDrive] [varchar](3) NULL,
	[EspacoLivreDriveMB] [int] NULL
) ON [PRIMARY]
GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DS_Carga_Parametros_Banco]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[DS_Carga_Parametros_Banco]
GO

CREATE TABLE [dbo].[DS_Carga_Parametros_Banco](
	[DataHoraColeta] [datetime] NOT NULL,
	[NomeServidor] [sql_variant] NULL,
	[NomeInstancia] [sql_variant] NULL,
	[NomeParametro] [nvarchar](35) NULL,
	[ValorMinimo] [int] NULL,
	[ValorMaximo] [int] NULL,
	[ValorConfigurado] [int] NULL,
	[ValorEmExecucao] [int] NULL
) ON [PRIMARY]
GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DS_Carga_PerfmonCollector]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[DS_Carga_PerfmonCollector]
GO

CREATE TABLE [dbo].[DS_Carga_PerfmonCollector](
	[DataHoraColeta] [datetime],
	[NomeServidor] [sql_variant] NULL,
	[NomeInstancia] [sql_variant] NULL,
	[NomeContador] [varchar](2051) NULL,
	[ValorContador] [float] NOT NULL
) ON [PRIMARY]
GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DBA_DB_SIZE]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[DBA_DB_SIZE]
GO

CREATE TABLE [dbo].[DBA_DB_SIZE]
(
[ServerName] VARCHAR(50),
[DBName] VARCHAR(50),
[LogicalFileName] VARCHAR(50),
[UsageType] VARCHAR(10),
[FreeSpaceInDrive] INT,
[Total_Space_MB] INT,
[Used_Space_MB] INT,
[Free_Space_MB] INT,
[Free_Space_PCT] INT,
[MaxSize_MB] INT,
[NextAllocation_MB] INT,
[GrowthType] VARCHAR(20),
[FileId] INT,
[GroupId] INT,
[PhysicalFileName] VARCHAR(200),
[Status] VARCHAR(30),
[Updateability] VARCHAR(30),
[RecoveryMode] VARCHAR(30),
[UserAccess] VARCHAR(30),
[Version] VARCHAR(50),
[DateChecked] DATETIME
)
GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DBA_DB_TABLESIZE]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[DBA_DB_TABLESIZE]
GO

 CREATE TABLE [dbo].[DBA_DB_TABLESIZE]
 (
 [DateChecked]      DATETIME,
 [DatabaseName]     VARCHAR(50),
 [TableName]        VARCHAR(100),
 [FilegroupName]    VARCHAR(50),
 [QtdRows]          INT,
 [AllocatedSize_MB] INT,
 [UsedSize_MB]      INT
 )
 GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_PADDING OFF
GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DBA_VW_Carga_Capacidade_BancoDatafile]') AND type in (N'V'))
DROP VIEW [dbo].[DBA_VW_Carga_Capacidade_BancoDatafile]
GO


CREATE VIEW [dbo].[DBA_VW_Carga_Capacidade_BancoDatafile] 

AS  

SELECT	GETDATE() AS DataHoraColeta, 
		SERVERPROPERTY('MachineName') AS NomeServidor,
		SERVERPROPERTY('ServerName') AS NomeInstancia, 
		LEFT(DBS.PhysicalFileName, 3) AS NomeDrive, 
		DBS.DBName AS NomeBancoDados, 
		DBS.LogicalFileName AS NomeArquivoLogicoBancoDados, 
		DBS.UsageType AS TipoArquivoLogicoBancoDados, 
		DBS.PhysicalFileName AS NomeArquivoFisicoBancoDados, 
		SUM(DBS.Total_Space_MB) AS EspacoTotalBancoMB, 
		SUM(DBS.Used_Space_MB) AS EspacoUtilizadoBancoMB, 
		SUM(DBS.Free_Space_MB) AS EspacoLivreBancoMB
FROM	DBA_DB_SIZE DBS
GROUP BY LEFT(DBS.PhysicalFileName, 3), DBS.DBName, DBS.LogicalFileName, DBS.UsageType, DBS.PhysicalFileName

GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DBA_VW_Carga_Capacidade_BancoTabela]') AND type in (N'V'))
DROP VIEW [dbo].[DBA_VW_Carga_Capacidade_BancoTabela]
GO

CREATE VIEW [dbo].[DBA_VW_Carga_Capacidade_BancoTabela] 

AS  

SELECT	GETDATE() AS DataHoraColeta, 
		SERVERPROPERTY('MachineName') AS NomeServidor,
		SERVERPROPERTY('ServerName') AS NomeInstancia, 
		TBS.DatabaseName AS NomeBancoDados, 
		TBS.TableName AS NomeTabela, 
		SUM(TBS.QtdRows) AS QuantidadeLinhas, 
		SUM(TBS.AllocatedSize_MB) AS EspacoAlocadoMB, 
		SUM(TBS.UsedSize_MB) AS EspacoUtilizadoMB
FROM	DBA_DB_TABLESIZE TBS
GROUP BY TBS.DatabaseName, TBS.TableName

GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DBA_VW_Carga_Capacidade_Disco]') AND type in (N'V'))
DROP VIEW [dbo].[DBA_VW_Carga_Capacidade_Disco]
GO

CREATE VIEW [dbo].[DBA_VW_Carga_Capacidade_Disco] 

AS  

SELECT	GETDATE() AS DataHoraColeta, 
		SERVERPROPERTY('MachineName') AS NomeServidor,
		SERVERPROPERTY('ServerName') AS NomeInstancia, 
		LEFT(DBS.PhysicalFileName, 3) AS NomeDrive, 
		MAX(DBS.FreeSpaceInDrive) AS EspacoLivreDriveMB
FROM	DBA_DB_SIZE DBS
GROUP BY LEFT(DBS.PhysicalFileName, 3) 

GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DBA_VW_Carga_Parametros_Banco]') AND type in (N'V'))
DROP VIEW [dbo].[DBA_VW_Carga_Parametros_Banco]
GO

CREATE VIEW [dbo].[DBA_VW_Carga_Parametros_Banco] 

AS  

SELECT	GETDATE() AS DataHoraColeta, 
		SERVERPROPERTY('MachineName') AS NomeServidor,
		SERVERPROPERTY('ServerName') AS NomeInstancia, 
		UPPER(NAME) AS NomeParametro,
		CONVERT(INT, MINIMUM) AS ValorMinimo,
		CONVERT(INT, MAXIMUM) AS ValorMaximo,
		CONVERT(INT, ISNULL(VALUE, VALUE_IN_USE)) AS ValorConfigurado,
		CONVERT(INT, VALUE_IN_USE) AS ValorEmExecucao
FROM	SYS.CONFIGURATIONS

GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DBA_VW_Carga_PerfmonCollector]') AND type in (N'V'))
DROP VIEW [dbo].[DBA_VW_Carga_PerfmonCollector]
GO

CREATE VIEW [dbo].[DBA_VW_Carga_PerfmonCollector] 

AS  

SELECT	CONVERT(VARCHAR, DTI.LogStopTime, 100) AS DataHoraColeta, 
		SERVERPROPERTY('MachineName') AS NomeServidor,
		SERVERPROPERTY('ServerName') AS NomeInstancia, 
		LTRIM(RTRIM(CDT.ObjectName)) + ' / ' + LTRIM(RTRIM(CDT.CounterName)) AS NomeContador,
		CD.CounterValue AS ValorContador
FROM	CounterDetails CDT
INNER JOIN CounterData CD  ON CDT.CounterID = CD.CounterID
INNER JOIN DisplayToID DTI ON DTI.GUID = CD.GUID
WHERE	CD.RecordIndex = (SELECT MAX(RecordIndex) FROM CounterData)

GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

-- Apaga a procedure antiga que e substituida pela "SP_CARGA_PERFORMANCE" e "SP_CARGA_CAPACIDADE"

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SP_CARGA_COLETAS]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SP_CARGA_COLETAS]
GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SP_CARGA_PERFORMANCE]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SP_CARGA_PERFORMANCE]
GO

CREATE PROCEDURE [dbo].[SP_CARGA_PERFORMANCE]
AS

BEGIN

DECLARE @DataCarga DATETIME
DECLARE @DataAtual DATETIME

SELECT @DataAtual = GETDATE()

--SELECT @DataCarga = MAX([DataHoraColeta]) FROM [DS_Carga_PerfmonCollector] WHERE DATEPART(YEAR, [DataHoraColeta]) = DATEPART(YEAR, @DataAtual) AND DATEPART(MONTH, [DataHoraColeta]) = DATEPART(MONTH, @DataAtual) AND DATEPART(DAY, [DataHoraColeta]) = DATEPART(DAY, @DataAtual)
--SELECT @DataCarga = ISNULL(@DataCarga, @DataAtual)
--DELETE FROM [DS_Carga_PerfmonCollector] WHERE [DataHoraColeta] = @DataCarga

INSERT INTO [DS_Carga_PerfmonCollector]
SELECT	@DataAtual AS DataHoraColeta, 
		SERVERPROPERTY('MachineName') AS NomeServidor,
		SERVERPROPERTY('ServerName') AS NomeInstancia, 
		REPLACE(CDT.ObjectName, LEFT(CDT.ObjectName, CHARINDEX(':', CDT.ObjectName, 1)), 'SQL Server ') + ' / ' + LTRIM(RTRIM(CDT.CounterName)) AS NomeContador,
		CD.CounterValue AS ValorContador
FROM	CounterDetails CDT
INNER JOIN CounterData CD  ON CDT.CounterID = CD.CounterID
INNER JOIN DisplayToID DTI ON DTI.GUID = CD.GUID
WHERE	CD.RecordIndex = (SELECT MAX(RecordIndex) FROM CounterData)

END

GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SP_CARGA_CAPACIDADE]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SP_CARGA_CAPACIDADE]
GO

CREATE PROCEDURE [dbo].[SP_CARGA_CAPACIDADE]
AS

BEGIN

DECLARE @DataCarga DATETIME
DECLARE @DataAtual DATETIME

SELECT @DataAtual = GETDATE()

SELECT @DataCarga = MAX([DataHoraColeta]) FROM [DS_Carga_Capacidade_Disco] WHERE DATEPART(YEAR, [DataHoraColeta]) = DATEPART(YEAR, @DataAtual) AND DATEPART(MONTH, [DataHoraColeta]) = DATEPART(MONTH, @DataAtual) AND DATEPART(DAY, [DataHoraColeta]) = DATEPART(DAY, @DataAtual)
SELECT @DataCarga = ISNULL(@DataCarga, @DataAtual)
DELETE FROM [DS_Carga_Capacidade_Disco] WHERE [DataHoraColeta] = @DataCarga

SELECT @DataCarga = MAX([DataHoraColeta]) FROM [DS_Carga_Capacidade_BancoDatafile] WHERE DATEPART(YEAR, [DataHoraColeta]) = DATEPART(YEAR, @DataAtual) AND DATEPART(MONTH, [DataHoraColeta]) = DATEPART(MONTH, @DataAtual) AND DATEPART(DAY, [DataHoraColeta]) = DATEPART(DAY, @DataAtual)
SELECT @DataCarga = ISNULL(@DataCarga, @DataAtual)
DELETE FROM [DS_Carga_Capacidade_BancoDatafile]	WHERE [DataHoraColeta] = @DataCarga

SELECT @DataCarga = MAX([DataHoraColeta]) FROM [DS_Carga_Capacidade_BancoTabela] WHERE DATEPART(YEAR, [DataHoraColeta]) = DATEPART(YEAR, @DataAtual) AND DATEPART(MONTH, [DataHoraColeta]) = DATEPART(MONTH, @DataAtual) AND DATEPART(DAY, [DataHoraColeta]) = DATEPART(DAY, @DataAtual)
SELECT @DataCarga = ISNULL(@DataCarga, @DataAtual)
DELETE FROM [DS_Carga_Capacidade_BancoTabela] WHERE [DataHoraColeta] = @DataCarga

SELECT @DataCarga = MAX([DataHoraColeta]) FROM [DS_Carga_Parametros_Banco] WHERE DATEPART(YEAR, [DataHoraColeta]) = DATEPART(YEAR, @DataAtual) AND DATEPART(MONTH, [DataHoraColeta]) = DATEPART(MONTH, @DataAtual) AND DATEPART(DAY, [DataHoraColeta]) = DATEPART(DAY, @DataAtual)
SELECT @DataCarga = ISNULL(@DataCarga, @DataAtual)
DELETE FROM [DS_Carga_Parametros_Banco] WHERE [DataHoraColeta] = @DataCarga

INSERT INTO [DS_Carga_Capacidade_Disco]
SELECT	@DataAtual AS DataHoraColeta, 
		SERVERPROPERTY('MachineName') AS NomeServidor,
		SERVERPROPERTY('ServerName') AS NomeInstancia, 
		LEFT(DBS.PhysicalFileName, 3) AS NomeDrive, 
		MAX(DBS.FreeSpaceInDrive) AS EspacoLivreDriveMB
FROM	DBA_TIVIT_DB_SIZE DBS
GROUP BY LEFT(DBS.PhysicalFileName, 3) 

INSERT INTO [DS_Carga_Capacidade_BancoDatafile]
SELECT	@DataAtual AS DataHoraColeta, 
		SERVERPROPERTY('MachineName') AS NomeServidor,
		SERVERPROPERTY('ServerName') AS NomeInstancia, 
		LEFT(DBS.PhysicalFileName, 3) AS NomeDrive, 
		DBS.DBName AS NomeBancoDados, 
		DBS.LogicalFileName AS NomeArquivoLogicoBancoDados, 
		DBS.UsageType AS TipoArquivoLogicoBancoDados, 
		DBS.PhysicalFileName AS NomeArquivoFisicoBancoDados, 
		SUM(DBS.Total_Space_MB) AS EspacoTotalBancoMB, 
		SUM(DBS.Used_Space_MB) AS EspacoUtilizadoBancoMB, 
		SUM(DBS.Free_Space_MB) AS EspacoLivreBancoMB
FROM	DBA_TIVIT_DB_SIZE DBS
GROUP BY LEFT(DBS.PhysicalFileName, 3), DBS.DBName, DBS.LogicalFileName, DBS.UsageType, DBS.PhysicalFileName

INSERT INTO [DS_Carga_Capacidade_BancoTabela]
SELECT	@DataAtual AS DataHoraColeta, 
		SERVERPROPERTY('MachineName') AS NomeServidor,
		SERVERPROPERTY('ServerName') AS NomeInstancia, 
		TBS.DatabaseName AS NomeBancoDados, 
		TBS.TableName AS NomeTabela, 
		SUM(TBS.QtdRows) AS QuantidadeLinhas, 
		SUM(TBS.AllocatedSize_MB) AS EspacoAlocadoMB, 
		SUM(TBS.UsedSize_MB) AS EspacoUtilizadoMB
FROM	DBA_TIVIT_DB_TABLESIZE TBS
GROUP BY TBS.DatabaseName, TBS.TableName

INSERT INTO [DS_Carga_Parametros_Banco]
SELECT	@DataAtual AS DataHoraColeta, 
		SERVERPROPERTY('MachineName') AS NomeServidor,
		SERVERPROPERTY('ServerName') AS NomeInstancia, 
		UPPER(NAME) AS NomeParametro,
		CONVERT(INT, MINIMUM) AS ValorMinimo,
		CONVERT(INT, MAXIMUM) AS ValorMaximo,
		CONVERT(INT, ISNULL(VALUE, VALUE_IN_USE)) AS ValorConfigurado,
		CONVERT(INT, VALUE_IN_USE) AS ValorEmExecucao
FROM	SYS.CONFIGURATIONS

END

GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SP_DBSIZE]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SP_DBSIZE]
GO

CREATE PROCEDURE [dbo].[SP_DBSIZE] 
AS

BEGIN

SET NOCOUNT ON

IF EXISTS (SELECT 1 FROM tempdb..sysobjects WHERE [Id] = OBJECT_ID('tempdb..#DBFileInfo'))
BEGIN
DROP TABLE #DBFileInfo
END

IF EXISTS (SELECT 1 FROM tempdb..sysobjects WHERE [Id] = OBJECT_ID('tempdb..#LogSizeStats'))
BEGIN
DROP TABLE #LogSizeStats
END

IF EXISTS (SELECT 1 FROM tempdb..sysobjects WHERE [Id] = OBJECT_ID('tempdb..#DataFileStats'))
BEGIN
DROP TABLE #DataFileStats
END

IF EXISTS (SELECT 1 FROM tempdb..sysobjects WHERE [Id] = OBJECT_ID('tempdb..#FixedDrives'))
BEGIN
DROP TABLE #FixedDrives
END

CREATE TABLE #FixedDrives
(DriveLetter VARCHAR(10),
MB_Free DEC(20,2))

CREATE TABLE #DataFileStats
(DBName VARCHAR(255),
DBId INT,
FileId TINYINT,
[FileGroup] TINYINT,
TotalExtents DEC(20,2),
UsedExtents DEC(20,2),
[Name] VARCHAR(255),
[FileName] VARCHAR(400))

CREATE TABLE #LogSizeStats -- DBCC SQLPERF -- Provides statistics about how the transaction-log space was used in all databases. It can also be used to reset wait and latch statistics.
(DBName VARCHAR(255) NOT NULL PRIMARY KEY CLUSTERED, -- Database Name -- Name of the database for the log statistics displayed.
DBId INT,
LogFile REAL, -- Log Size (MB) -- Actual amount of space available for the log. This amount is smaller than the amount originally allocated for log space because the SQL Server 2005 Database Engine reserves a small amount of disk space for internal header information.
LogFileUsed REAL, -- Log Space Used (%) -- Percentage of the log file currently occupied with transaction log information.
Status BIT) -- Status -- Status of the log file. Always 0.

CREATE TABLE #DBFileInfo
([ServerName] VARCHAR(255),
[DBName] VARCHAR(65),
[LogicalFileName] VARCHAR(400),
[UsageType] VARCHAR (30),
[Size_MB] DEC(20,2),
[SpaceUsed_MB] DEC(20,2),
[MaxSize_MB] DEC(20,2),
[NextAllocation_MB] DEC(20,2),
[GrowthType] VARCHAR(65),
[FileId] SMALLINT,
[GroupId] SMALLINT,
[PhysicalFileName] VARCHAR(400),
[DateChecked] DATETIME)

DECLARE @SQLString VARCHAR(3000)
DECLARE @MinId INT
DECLARE @MaxId INT
DECLARE @DBName VARCHAR(255)

DECLARE @tblDBName TABLE
(RowId INT IDENTITY(1,1),
DBName VARCHAR(255),
DBId INT)

INSERT INTO @tblDBName (DBName,DBId)
SELECT [Name],DBId FROM master..sysdatabases WHERE (Status & 512) = 0 /*NOT IN (536,528,540,2584,1536,512,4194841)*/ ORDER BY [Name]

INSERT INTO #LogSizeStats (DBName,LogFile,LogFileUsed,Status)
EXEC ('DBCC SQLPERF(LOGSPACE) WITH NO_INFOMSGS')

UPDATE #LogSizeStats
SET DBId = DB_ID(DBName)

INSERT INTO #FixedDrives EXEC master..xp_fixeddrives

SELECT @MinId = MIN(RowId),
@MaxId = MAX(RowId)
FROM @tblDBName

WHILE (@MinId <= @MaxId)
BEGIN
SELECT @DBName = [DBName]
FROM @tblDBName
WHERE RowId = @MinId

SELECT @SQLString =
'SELECT ServerName = @@SERVERNAME,'+
' DBName = '''+@DBName+''','+
' LogicalFileName = [name],'+
' UsageType = CASE WHEN (64&[status])=64 THEN ''Log'' ELSE ''Data'' END,'+
' Size_MB = [size]*8/1024.00,'+
' SpaceUsed_MB = NULL,'+
' MaxSize_MB = CASE [maxsize] WHEN -1 THEN -1 WHEN 0 THEN [size]*8/1024.00 ELSE maxsize/1024.00*8 END,'+
' NextExtent_MB = CASE WHEN (1048576&[status])=1048576 THEN ([growth]/100.00)*([size]*8/1024.00) WHEN [growth]=0 THEN 0 ELSE [growth]*8/1024.00 END,'+
' GrowthType = CASE WHEN (1048576&[status])=1048576 THEN ''%'' ELSE ''Pages'' END,'+
' FileId = [fileid],'+
' GroupId = [groupid],'+
' PhysicalFileName= [filename],'+
' CurTimeStamp = GETDATE()'+
'FROM ['+@DBName+']..sysfiles'

PRINT @SQLString
INSERT INTO #DBFileInfo
EXEC (@SQLString)

UPDATE #DBFileInfo
SET SpaceUsed_MB = Size_MB / 100.0 * (SELECT LogFileUsed FROM #LogSizeStats WHERE DBName = @DBName)
WHERE UsageType = 'Log'

SELECT @SQLString = 'USE [' + @DBName + '] DBCC SHOWFILESTATS WITH NO_INFOMSGS'

INSERT #DataFileStats (FileId,[FileGroup],TotalExtents,UsedExtents,[Name],[FileName])
EXECUTE(@SQLString)

UPDATE #DBFileInfo
SET [SpaceUsed_MB] = S.[UsedExtents]*64/1024.00
FROM #DBFileInfo AS F
INNER JOIN #DataFileStats AS S
ON F.[FileId] = S.[FileId]
AND F.[GroupId] = S.[FileGroup]
AND F.[DBName] = @DBName

TRUNCATE TABLE #DataFileStats

SELECT @MinId = @MinId + 1
END

INSERT INTO DBA_DB_SIZE(
[ServerName],
[DBName],
[LogicalFileName],
[UsageType],
[FreeSpaceInDrive],
[Total_Space_MB],
[Used_Space_MB],
[Free_Space_MB],
[Free_Space_PCT],
[MaxSize_MB],
[NextAllocation_MB],
[GrowthType],
[FileId],
[GroupId],
[PhysicalFileName],
[Status],
[Updateability],
[RecoveryMode],
[UserAccess],
[Version],
[DateChecked]
)
SELECT [ServerName],
[DBName],
[LogicalFileName],
[UsageType] AS SegmentName,
B.MB_Free AS FreeSpaceInDrive,
[Size_MB],
[SpaceUsed_MB],
[Size_MB] - [SpaceUsed_MB] AS FreeSpace_MB,
CAST(([Size_MB] - [SpaceUsed_MB]) / [Size_MB] AS decimal(4,2)) AS FreeSpace_Pct,
[MaxSize_MB],
[NextAllocation_MB],
CASE MaxSize_MB WHEN -1 THEN CAST(CAST(([NextAllocation_MB]/[Size_MB])*100 AS INT) AS VARCHAR(10))+' %' ELSE 'Pages' END AS [GrowthType],
[FileId],
[GroupId],
[PhysicalFileName],
CONVERT(sysname,DatabasePropertyEx([DBName],'Status')) AS Status,
CONVERT(sysname,DatabasePropertyEx([DBName],'Updateability')) AS Updateability,
CONVERT(sysname,DatabasePropertyEx([DBName],'Recovery')) AS RecoveryMode,
CONVERT(sysname,DatabasePropertyEx([DBName],'UserAccess')) AS UserAccess,
CONVERT(sysname,DatabasePropertyEx([DBName],'Version')) AS Version,
[DateChecked]
FROM #DBFileInfo AS A
LEFT JOIN #FixedDrives AS B
ON SUBSTRING(A.PhysicalFileName,1,1) = B.DriveLetter
ORDER BY DBName,GroupId,FileId

IF EXISTS (SELECT 1 FROM tempdb..sysobjects WHERE [Id] = OBJECT_ID('tempdb..#DBFileInfo'))
BEGIN
DROP TABLE #DBFileInfo
END

IF EXISTS (SELECT 1 FROM tempdb..sysobjects WHERE [Id] = OBJECT_ID('tempdb..#LogSizeStats'))
BEGIN
DROP TABLE #LogSizeStats
END

IF EXISTS (SELECT 1 FROM tempdb..sysobjects WHERE [Id] = OBJECT_ID('tempdb..#DataFileStats'))
BEGIN
DROP TABLE #DataFileStats
END

IF EXISTS (SELECT 1 FROM tempdb..sysobjects WHERE [Id] = OBJECT_ID('tempdb..#FixedDrives'))
BEGIN
DROP TABLE #FixedDrives
END

SET NOCOUNT OFF

END

GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SP_TABLESIZE]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SP_TABLESIZE]
GO

CREATE PROCEDURE [dbo].[SP_TABLESIZE]
AS

BEGIN

SET NOCOUNT ON

DECLARE @SQLString VARCHAR(3000)
DECLARE @MinId INT
DECLARE @MaxId INT
DECLARE @DBName VARCHAR(255)

DECLARE @tblDBName TABLE
(RowId INT IDENTITY(1,1),
DBName VARCHAR(255),
DBId INT)

INSERT INTO @tblDBName (DBName,DBId)
SELECT [Name],DBId FROM Master..sysdatabases
 WHERE (Status & 512) = 0 /*NOT IN (536,528,540,2584,1536,512,4194841)*/
 AND   [Name] not in ('master','model','msdb','tempdb') ORDER BY [Name]

SELECT @MinId = MIN(RowId),
@MaxId = MAX(RowId)
FROM @tblDBName

WHILE (@MinId <= @MaxId)
BEGIN
 SELECT @DBName = [DBName]
 FROM @tblDBName
 WHERE RowId = @MinId
 
 SELECT @SQLString = 'USE [' + @DBName + '] dbcc updateusage(0)'
 EXECUTE(@SQLString)

 SELECT @SQLString = 'USE [' + @DBName + '] select getdate(),db_name() DatabaseName,object_name(id) TableName,filegroup_name(groupid) FilegroupName,sum(rows) QtdRows,convert(int,(sum(reserved) * 8.192 /1024.0)) as AllocatedMb,convert(int,(sum(used) * 8.192  /1024.0)) as UsedMb from sysindexes where indid in (0,1,255) group by id, groupid'
 INSERT [DBA].[DBO].[DBA_DB_TABLESIZE] ([DateChecked],[DatabaseName],[TableName],[FilegroupName],[QtdRows],[AllocatedSize_MB],[UsedSize_MB])
 EXECUTE(@SQLString)

 SELECT @MinId = @MInId + 1
END

SET NOCOUNT OFF

END

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

/* --------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------- */
