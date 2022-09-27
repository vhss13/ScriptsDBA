
USE MSDB;
go
CREATE TABLE [DBO].[dba_defrag_maintenance_history]
(
[db_name] [SYSNAME] NOT NULL,
[TABLE_name] [SYSNAME] NOT NULL,
[index_name] [SYSNAME] NOT NULL,
[frag] [FLOAT] NULL,
[page] [INT] NULL,
[actiON_taken] [VARCHAR](35) NULL,
[date] [DATETIME] NULL DEFAULT (GETDATE())
)
go
--Archive the data's in master DB
USE MASTER;
go
CREATE TABLE [DBO].[dba_defrag_maintenance_history]
(
[db_name] [SYSNAME] NOT NULL,
[TABLE_name] [SYSNAME] NOT NULL,
[index_name] [SYSNAME] NOT NULL,
[frag] [FLOAT] NULL,
[page] [INT] NULL,
[actiON_taken] [VARCHAR](35) NULL,
[date] [DATETIME] NULL DEFAULT (GETDATE())
)
go
– Sproc

?
USE msdb
go
CREATE  PROC [DBO].[indexdefragmentatiON] @p_dbname SYSNAME
/*
Summary:        Remove the Index Fragmentation to improve the query performance
Contact:           Muthukkumaran Kaliyamoorhty SQL DBA
Description:      This Sproc will take the fragmentation details and do three kinds of work.
                       1. Check the fragmentation greater than 30% and pages greater than 1000 then rebuild
                       2. Check the fragmentation between 15% to 29% and pages greater than 1000 then reorganize
                       3. Update the statistics the first two conditions is false
ChangeLog:
Date                             Coder                                                                           Description
2011-03-11                    Muthukkumaran Kaliyamoorhty                                      created
*************************All the SQL keywords should be written in upper case*************************
*/
AS
BEGIN
SET NOCOUNT ON
DECLARE
@db_name SYSNAME,
@tab_name SYSNAME,
@ind_name VARCHAR(500),
@schema_name SYSNAME,
@frag FLOAT,
@pages INT,
@min_id INT,
@max_id INT
SET @db_name=@p_dbname
--------------------------------------------------------------------------------------------------------------------------------------
--inserting the Fragmentation details
--------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE #tempfrag
(
   id INT identity,
   ObjectName char(255),
   ObjectId INT,
   IndexName varchar(1000),
   IndexId INT,
   Lvl INT,
   CountPages INT,
   CountRows INT,
   MinRecSize INT,
   MaxRecSize INT,
   AvgRecSize INT,
   ForRecCount INT,
   Extents INT,
   ExtentSwitches INT,
   AvgFreeBytes INT,
   AvgPageDensity INT,
   ScanDensity DECIMAL,
   BestCount INT,
   ActualCount INT,
   LogicalFrag DECIMAL,
   ExtentFrag DECIMAL);
INSERT INTO #tempfrag
EXEC ('use ['+@db_name+'];DBCC SHOWCONTIG WITH FAST, TABLERESULTS, ALL_INDEXES');
CREATE TABLE #tempschema
(
obj SYSNAME,
ind SYSNAME,
TABLE_schema SYSNAME,
frag FLOAT,
page INT
)
INSERT INTO #tempschema
EXEC('
SELECT
d.objectname,
d.indexname ,
i.TABLE_schema,
d.logicalfrag ,
d.countpages
FROM #tempfrag d JOIN ['+@db_name+'].INFORMATION_SCHEMA.TABLES i ON (d.OBJECTNAME=i.TABLE_NAME)
')
SELECT @min_id=MIN(ID)FROM #tempfrag
SELECT @max_id=MAX(ID)FROM #tempfrag
TRUNCATE TABLE msdb.DBO.dba_defrag_maintenance_history
WHILE (@min_id<=@max_id)
BEGIN
SELECT
@tab_name=d.objectname,
@ind_name=d.indexname ,
@schema_name=t.TABLE_schema,
@frag=d.logicalfrag ,
@pages=d.countpages
FROM #tempfrag d JOIN #tempschema t ON(d.objectname=t.obj)
WHERE id=@min_id
--------------------------------------------------------------------------------------------------------------------------------------
--Check the fragmentation greater than 30% and pages greater than 1000 then rebuild
--------------------------------------------------------------------------------------------------------------------------------------
IF (@ind_name IS NOT NULL )
BEGIN
IF (@frag>=30 AND @pages>1000)
BEGIN
EXEC ('USE ['+@db_name+'];SET QUOTED_IDENTIFIER OFF;DBCC DBREINDEX("['+@db_name+'].[DBO].['+@tab_name +']",['+@ind_name+'])')
INSERT INTO msdb.DBO.dba_defrag_maintenance_history
VALUES (@db_name,@tab_name,@ind_name,@frag,@pages,'REBUILD',GETDATE())
END
--------------------------------------------------------------------------------------------------------------------------------------
--Check the fragmentation between 15% to 29% and pages greater than 1000 then reorganize
--------------------------------------------------------------------------------------------------------------------------------------
ELSE IF((@frag BETWEEN 15 AND 29) AND @pages>1000 )
BEGIN
EXEC ('USE ['+@db_name+'];SET QUOTED_IDENTIFIER OFF;DBCC INDEXDEFRAG( ['+@db_name+'],['+@tab_name +'], ['+@ind_name+'] )')
EXEC ('USE ['+@db_name+'];SET QUOTED_IDENTIFIER OFF;UPDATE STATISTICS ['+@schema_name+'].['+@tab_name+']' )
INSERT INTO msdb.DBO.dba_defrag_maintenance_history
VALUES (@db_name,@tab_name,@ind_name,@frag,@pages,'REORGANIZE & UPDATESTATS',GETDATE())
END
--------------------------------------------------------------------------------------------------------------------------------------
--Update the statistics if the first two conditions is false
--------------------------------------------------------------------------------------------------------------------------------------
ELSE
BEGIN
EXEC ('USE ['+@db_name+'];SET QUOTED_IDENTIFIER OFF;UPDATE STATISTICS ['+@schema_name+'].['+@tab_name+']'  )
INSERT INTO msdb.DBO.dba_defrag_maintenance_history
VALUES (@db_name,@tab_name,@ind_name,@frag,@pages,'UPDATESTATS',GETDATE())
END
END
SET @min_id=@min_id+1
END
--------------------------------------------------------------------------------------------------------------------------------------
--Archive the fragmentation details for future reference
--------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO master.DBO.dba_defrag_maintenance_history
SELECT * FROM msdb.DBO.dba_defrag_maintenance_history
END