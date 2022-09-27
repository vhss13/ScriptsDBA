SELECT object_name(object_id) as UserTable,name as IndexName, type_desc, is_primary_key from sys.indexes
WHERE objectproperty((object_id),'IsUserTable')=1
-- AND type = 0 -- Heap
-- AND type = 1 -- Clustered
-- AND type = 2 -- NonClustered
ORDER BY UserTable
