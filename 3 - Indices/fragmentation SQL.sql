SELECT

OBJECT_NAME(i.object_id) AS TableName 
,

i.name AS TableIndexName 
,

phystat.avg_fragmentation_in_percent 
FROM

sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, ‘DETAILED’) phystat inner JOIN sys.indexes i 

ON i.object_id = phystat.object_id 

AND i.index_id = phystat.index_id WHERE phystat.avg_fragmentation_in_percent > 10 

AND phystat.avg_fragmentation_in_percent < 40 


SELECT OBJECT_NAME(ind.OBJECT_ID) AS TableName, 
ind.name AS IndexName, indexstats.index_type_desc AS IndexType, 
indexstats.avg_fragmentation_in_percent 
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats 
INNER JOIN sys.indexes ind  
ON ind.object_id = indexstats.object_id 
AND ind.index_id = indexstats.index_id 
WHERE indexstats.avg_fragmentation_in_percent > 30 
ORDER BY indexstats.avg_fragmentation_in_percent DESC






select object_name(itable.object_id) as tablename,itable.name as IndexName,indexfrag.avg_fragmentation_in_percentfrom sys.dm_db_index_physical_stats(db_id(), null, null, null, 'DETAILED') indexfraginner join sys.indexes itable on itable.object_id = indexfrag.object_idand itable.index_id = indexfrag.index_id-- make sure to set this where clause to the percentage below which you want to exclude results.where indexfrag.avg_fragmentation_in_percent > 20order by avg_fragmentation_in_percent desc, tablename 
