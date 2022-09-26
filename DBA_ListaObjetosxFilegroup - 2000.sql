IF OBJECT_ID('tempdb.dbo.#FileGroup') IS NOT NULL
      DROP TABLE #FileGroup

IF OBJECT_ID('tempdb.dbo.#ObjectFileGroup') IS NOT NULL
      DROP TABLE #ObjectFileGroup

CREATE TABLE #FileGroup (
      FileGroup sysname
)

CREATE TABLE #ObjectFileGroup (
      ObjectName sysname,
      ObjectType varchar(20),
      FileGroupID int,
      FileGroup sysname
)

SET NOCOUNT ON
DECLARE @TableName sysname
DECLARE @id int
DECLARE cur_Tables CURSOR FAST_FORWARD FOR

      SELECT TableName = [name], id FROM dbo.sysobjects WHERE type = 'U'

OPEN cur_Tables
FETCH NEXT FROM cur_Tables INTO @TableName, @id
WHILE @@FETCH_STATUS = 0
  BEGIN
      TRUNCATE TABLE #FileGroup
      INSERT #FileGroup (FileGroup)
      EXEC sp_objectfilegroup @id
      INSERT #ObjectFileGroup (ObjectName, ObjectType, FileGroupID, FileGroup)
      SELECT @TableName, 'TABLE', FILEGROUP_ID(FileGroup), FileGroup
       FROM #FileGroup
      FETCH NEXT FROM cur_Tables INTO @TableName, @id
  END
CLOSE cur_Tables
DEALLOCATE cur_Tables

INSERT #ObjectFileGroup (ObjectName, ObjectType, FileGroupID, FileGroup)
SELECT OBJECT_NAME(id) + ' * ' +[name], 'INDEX', groupid, FILEGROUP_NAME(groupid)  FROM dbo.sysindexes
 WHERE FILEGROUP_NAME(groupid) IS NOT NULL
      AND OBJECT_NAME(id) NOT LIKE 'sys%'
      AND [name] NOT LIKE '_WA_Sys%'
      AND [name] NOT LIKE 'Statistic_%'

SELECT FileGroupName = FILEGROUP_NAME(sf.groupid),/*ofg.FileGroup, */ofg.ObjectName, ofg.ObjectType, FileName = sf.filename, FileSize = sf.[size] / 128
 FROM #ObjectFileGroup ofg
      RIGHT JOIN dbo.sysfiles sf
 ON ofg.FileGroupID = sf.groupid
 ORDER BY FileGroup, ObjectName
