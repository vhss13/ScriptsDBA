Set nocount on
-- Causes of Server Waits
print 'Causes of Server Waits'
print '================ '
SELECT TOP 10
 [Wait type] = wait_type,
 [Wait time (s)] = wait_time_ms / 1000,
 [% waiting] = CONVERT(DECIMAL(12,2), wait_time_ms * 100.0 
               / SUM(wait_time_ms) OVER())
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE '%SLEEP%' 
ORDER BY wait_time_ms DESC;

-- Reads
print 'Reads'
print '================ '
SELECT TOP 10 
        [Total Reads] = SUM(total_logical_reads)
        ,[Execution count] = SUM(qs.execution_count)
        ,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
GROUP BY DB_NAME(qt.dbid)
ORDER BY [Total Reads] DESC;

-- Writes
print 'Writes'
print '================ '
SELECT TOP 10 
        [Total Writes] = SUM(total_logical_writes)
        ,[Execution count] = SUM(qs.execution_count)
        ,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
GROUP BY DB_NAME(qt.dbid)
ORDER BY [Total Writes] DESC;

-- Missing Indexes by Database
print 'Missing Indexes by Database'
print '================ '
SELECT   DB_Name (d.database_id) DBName      ,
         d.statement AS          [ObjectName],
         gs.unique_compiles                  ,
         gs.user_seeks                       ,
         gs.user_scans                       ,
         gs.avg_total_user_cost              ,
         gs.avg_user_impact                  ,
         'CREATE INDEX IX_' + DB_NAME(d.database_id) + 
         RTRIM(CAST(d.index_handle AS CHAR(100))) + ' ON ' + d.statement + ' (' +
         CASE
                  WHEN equality_columns IS NOT NULL
                  THEN equality_columns
                  ELSE ''
         END +
         CASE
                  WHEN equality_columns IS NOT NULL
                       AND inequality_columns IS NOT NULL
                  THEN ', '
                  ELSE ''
         END +
         CASE
                  WHEN inequality_columns IS NOT NULL
                  THEN inequality_columns
                  ELSE ''
         END + ') ' +
         CASE
                  WHEN included_columns IS NOT NULL
                  THEN 'INCLUDE (' + included_columns + ')'
                  ELSE ''
         END MissingIndex
FROM     sys.dm_db_missing_index_groups g
         JOIN sys.dm_db_missing_index_group_stats gs
         ON       gs.group_handle = g.index_group_handle
         JOIN sys.dm_db_missing_index_details d
         ON       g.index_handle = d.index_handle
ORDER BY gs.user_seeks DESC

-- Costly Missing Indexes
print 'Costly Missing Indexes'
print '================ '
SELECT  TOP 10 
        [Total Cost]  = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0) 
        , avg_user_impact
        , TableName = statement
        , [EqualityUsage] = equality_columns 
        , [InequalityUsage] = inequality_columns
        , [Include Cloumns] = included_columns
FROM        sys.dm_db_missing_index_groups g 
INNER JOIN    sys.dm_db_missing_index_group_stats s 
       ON s.group_handle = g.index_group_handle 
INNER JOIN    sys.dm_db_missing_index_details d 
       ON d.index_handle = g.index_handle
ORDER BY [Total Cost] DESC;

-- Unused Indexes
print 'Unused Indexes'
print '================ '
SELECT TOP 1
        DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,user_updates    
        ,system_updates    
        -- Useful fields below:
        --, *
INTO #TempUnusedIndexes
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE  s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
    AND    user_seeks = 0
    AND user_scans = 0 
    AND user_lookups = 0
    AND s.[object_id] = -999  -- Dummy value to get table structure.
-- Loop around all the databases on the server.
EXEC sp_MSForEachDB    'USE [?]; 
-- Table already exists.
INSERT INTO #TempUnusedIndexes 
SELECT TOP 10    
        DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,user_updates    
        ,system_updates    
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE  s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
    AND    user_seeks = 0
    AND user_scans = 0 
    AND user_lookups = 0
    AND i.name IS NOT NULL    -- Ignore HEAP indexes.
ORDER BY user_updates DESC'
-- Select records.
SELECT TOP 10 * FROM #TempUnusedIndexes ORDER BY [user_updates] DESC
-- Tidy up.
DROP TABLE #TempUnusedIndexes

-- Costly Unused Indexes
print 'Costly Unused Indexes'
print '======================== '
SELECT TOP 1
        [Maintenance cost]  = (user_updates + system_updates)
        ,[Retrieval usage] = (user_seeks + user_scans + user_lookups)
        ,DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
INTO #TempMaintenanceCost
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id
WHERE s.database_id = DB_ID() 
    AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
    AND (user_updates + system_updates) > 0 -- Only report on active rows.
    AND s.[object_id] = -999  -- Dummy value to get table structure.
-- Loop around all the databases on the server.
EXEC sp_MSForEachDB    'USE [?]; 
-- Table already exists.
INSERT INTO #TempMaintenanceCost 
SELECT TOP 10
        [Maintenance cost]  = (user_updates + system_updates)
        ,[Retrieval usage] = (user_seeks + user_scans + user_lookups)
        ,DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id
WHERE s.database_id = DB_ID() 
    AND i.name IS NOT NULL    -- Ignore HEAP indexes.
    AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
    AND (user_updates + system_updates) > 0 -- Only report on active rows.
ORDER BY [Maintenance cost]  DESC'
-- Select records.
SELECT TOP 10 * FROM #TempMaintenanceCost 
ORDER BY [Maintenance cost]  DESC
-- Tidy up.
DROP TABLE #TempMaintenanceCost

-- Used Indexes
print 'Used Indexes'
print '======================== '
SELECT TOP 1
        [Usage] = (user_seeks + user_scans + user_lookups)
        ,DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
INTO #TempUsage
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE   s.database_id = DB_ID() 
    AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
    AND (user_seeks + user_scans + user_lookups) > 0 
-- Only report on active rows.
    AND s.[object_id] = -999  -- Dummy value to get table structure.
-- Loop around all the databases on the server.
EXEC sp_MSForEachDB    'USE [?]; 
-- Table already exists.
INSERT INTO #TempUsage 
SELECT TOP 10
        [Usage] = (user_seeks + user_scans + user_lookups)
        ,DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE   s.database_id = DB_ID() 
    AND i.name IS NOT NULL    -- Ignore HEAP indexes.
    AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
    AND (user_seeks + user_scans + user_lookups) > 0 -- Only report on active rows.
ORDER BY [Usage]  DESC'
-- Select records.
SELECT TOP 10 * FROM #TempUsage ORDER BY [Usage] DESC
-- Tidy up.
DROP TABLE #TempUsage

-- Logically Fragmented Indexes
print 'Logically Fragmented Indexes'
print '================================= '
IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#TempFragmentation'))
BEGIN
DROP TABLE #TempFragmentation
END
SELECT TOP 1 
        DatbaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,[Fragmentation %] = ROUND(avg_fragmentation_in_percent,2)
INTO #TempFragmentation
FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, null) s
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE s.[object_id] = -999  -- Dummy value just to get table structure.
-- Loop around all the databases on the server.
EXEC sp_MSForEachDB    'USE [?]; 
-- Table already exists.
INSERT INTO #TempFragmentation 
SELECT TOP 10
        DatbaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,[Fragmentation %] = ROUND(avg_fragmentation_in_percent,2)
FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, null) s
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE s.database_id = DB_ID() 
      AND i.name IS NOT NULL    -- Ignore HEAP indexes.
    AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
ORDER BY [Fragmentation %] DESC'
-- Select records.
SELECT TOP 10 * FROM #TempFragmentation ORDER BY [Fragmentation %] DESC
-- Tidy up.
IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#TempFragmentation'))
BEGIN
DROP TABLE #TempFragmentation
END

-- Costly Queries by I/O
print 'Costly Queries by I/O'
print '=========================== '
SELECT TOP 10 
 [Average IO] = (total_logical_reads + total_logical_writes) / qs.execution_count
,[Total IO] = (total_logical_reads + total_logical_writes)
,[Execution count] = qs.execution_count
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) 
        ,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
ORDER BY [Average IO] DESC;

-- Costly Queries by CPU
print 'Costly Queries by CPU'
print '=========================== '
SELECT TOP 10 
 [Average CPU used] = total_worker_time / qs.execution_count
,[Total CPU used] = total_worker_time
,[Execution count] = qs.execution_count
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - 
qs.statement_start_offset)/2)
,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
ORDER BY [Average CPU used] DESC;

-- Costly CLR Queries
print 'Costly Queries by CPU'
print '==========================='
SELECT TOP 10 
 [Average CLR Time] = total_clr_time / execution_count 
,[Total CLR Time] = total_clr_time 
,[Execution count] = qs.execution_count
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)
,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats as qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
WHERE total_clr_time <> 0
ORDER BY [Average CLR Time] DESC;

-- Most-Executed Queries
print 'Most-Executed Queries'
print '==========================='
SELECT TOP 10 
 [Execution count] = execution_count
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)
,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
ORDER BY [Execution count] DESC;

-- Queries Suffering from Blocking
print 'Queries Suffering from Blocking'
print '=================================='
SELECT TOP 10 
 [Average Time Blocked] = (total_elapsed_time - total_worker_time) / qs.execution_count
,[Total Time Blocked] = total_elapsed_time - total_worker_time 
,[Execution count] = qs.execution_count
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) 
,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
ORDER BY [Average Time Blocked] DESC;

-- Lowest Plan Reuse
print 'Lowest Plan Reuse'
print '===================='
SELECT TOP 10
 [Plan usage] = cp.usecounts
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), 
qt.text)) * 2 ELSE qs.statement_end_offset END - 
qs.statement_start_offset)/2)
,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
,cp.cacheobjtype
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
INNER JOIN sys.dm_exec_cached_plans as cp on qs.plan_handle=cp.plan_handle
WHERE cp.plan_handle=qs.plan_handle
ORDER BY [Plan usage] ASC;

Set nocount off