-- Script 15-- Possible Bad NC Indexes (writes > reads)



SELECT  DISTINCT OBJECT_NAME(s.[object_id]) AS [Table Name] ,        i.name AS [Index Name] ,        i.index_id ,  i.is_disabled,  STATS_DATE(st.[object_id],st.[stats_id]) AS StatsDate,  MAX(CASE WHEN mh.[MaintenanceType] = 'REBUILD' OR mh.[MaintenanceType] = 'Update statistics' THEN ius.[DateUpdated] ELSE STATS_DATE(st.[object_id],st.[stats_id]) END) AS MaintenanceDate,  ius.[Writes] AS IUS_Writes,        ius.[Reads] AS IUS_Reads,  ius.[Writes] - ius.[Reads] AS [Difference],  ( user_seeks + user_scans + user_lookups ) AS Reads,  user_updates AS Writes,        'DROP INDEX ' + i.name + ' ON ' + sch.[name] + '.' + OBJECT_NAME(i.[object_id])FROM    sys.dm_db_index_usage_stats AS s WITH ( NOLOCK )        INNER JOIN sys.indexes AS i WITH ( NOLOCK )            ON s.[object_id] = i.[object_id]            AND i.index_id = s.index_id  JOIN sys.[tables] AS t ON t.[object_id] = i.[object_id]  JOIN sys.[schemas] AS sch ON sch.[schema_id] = t.[schema_id]  LEFT OUTER JOIN sys.[stats] AS st ON i.[object_id] = st.[object_id] AND i.[name] = st.[name]   LEFT OUTER JOIN [AdminDB].dbo.[atblIndexUsageStats] AS ius ON ius.[DatabaseName] = DB_NAME() AND ius.[ObjectName] = OBJECT_NAME(s.[object_id]) AND ius.[IndexName] = i.name   LEFT OUTER JOIN [AdminDB].dbo.[atblTableMaintenanceHistory] AS mh ON mh.[DatabaseName] = DB_NAME() AND mh.[ObjectName] = OBJECT_NAME(s.[object_id]) AND mh.[IndexName] = i.[name]WHERE   OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1        AND s.database_id = DB_ID()        AND user_updates > ( user_seeks + user_scans + user_lookups )  AND ius.[Writes] > ius.[Reads]        AND i.index_id > 1        AND i.is_primary_key = 0 and i.is_unique_constraint = 0        AND ius.[Reads] = 0       -- and OBJECT_NAME(i.[object_id]) =  ''GROUP BY s.[object_id], i.name,i.index_id,i.is_disabled,STATS_DATE(st.[object_id],st.[stats_id]),ius.[Writes], ius.[Reads] ,( user_seeks + user_scans + user_lookups ),user_updates,i.object_id,sch.nameORDER BY --[Percent Reads] ASC,  [Difference] DESC ,        ius.[Writes] DESC ,        [ius].[Reads] ASC;