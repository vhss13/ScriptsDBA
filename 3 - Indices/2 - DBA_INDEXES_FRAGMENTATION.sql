IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#TempFragmentation'))
BEGIN
DROP TABLE #TempFragmentation
END

create table #TempFragmentation
([DatbaseName] varchar(128),
[SchemaName] varchar(128),
[TableName] varchar(128),
[IndexName] varchar(128),
[Fragmentation %] decimal(5,2))

EXEC sp_MSForEachDB      'USE [?];
INSERT INTO #TempFragmentation 
SELECT 
    DB_NAME() AS DatbaseName
    , SCHEMA_NAME(o.Schema_ID) AS SchemaName
    , OBJECT_NAME(s.[object_id]) AS TableName
    , i.name AS IndexName 
    , ROUND(avg_fragmentation_in_percent,2) AS [Fragmentation %]
FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, null) s
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
INNER JOIN sys.objects o ON i.object_id = O.object_id    
WHERE s.database_id = DB_ID() 
AND i.name IS NOT NULL   
AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
ORDER BY [Fragmentation %] DESC'
 
SELECT @@servername as InstanceName,* FROM #TempFragmentation
-- WHERE [Fragmentation %] > 50
ORDER BY [Fragmentation %] DESC

IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#TempFragmentation'))
BEGIN
DROP TABLE #TempFragmentation
END