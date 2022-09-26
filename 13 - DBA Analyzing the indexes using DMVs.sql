SELECT db.name AS [database] ,
 ob.name [table],
 ix.name [index],
 dm_ix.user_seeks ,
 dm_ix.user_scans ,
 dm_ix.user_lookups
 FROM sys.dm_db_index_usage_stats dm_ix
 INNER JOIN sys.databases db ON db.database_id = dm_ix.database_id
 INNER JOIN sys.indexes ix ON ix.object_id = dm_ix.object_id
 INNER JOIN sys.objects ob ON ob.object_id = dm_ix.object_id
 WHERE ob.type = 'U'
