--Varia��o do script de �ndices necess�rios, que gera script com nome do �ndice no formato IX_NomeTabela_campo1_campo2...

SELECT  
      [Impact] = (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans),  
      [Table] = [statement],
      [CreateIndexStatement] = 'CREATE NONCLUSTERED INDEX ix_' 
            + sys.objects.name COLLATE DATABASE_DEFAULT 
            + '_' 
            + REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns,'')+ISNULL(mid.inequality_columns,''), '[', ''), ']',''), ', ','_')
            + ' ON ' 
            + [statement] 
            + ' ( ' + IsNull(mid.equality_columns, '') 
            + CASE WHEN mid.inequality_columns IS NULL THEN '' ELSE 
                  CASE WHEN mid.equality_columns IS NULL THEN '' ELSE ',' END 
            + mid.inequality_columns END + ' ) ' 
            + CASE WHEN mid.included_columns IS NULL THEN '' ELSE 'INCLUDE (' + mid.included_columns + ')' END 
            + ';', 
      mid.equality_columns,
      mid.inequality_columns,
      mid.included_columns
FROM sys.dm_db_missing_index_group_stats AS migs 
      INNER JOIN sys.dm_db_missing_index_groups AS mig ON migs.group_handle = mig.index_group_handle 
      INNER JOIN sys.dm_db_missing_index_details AS mid ON mig.index_handle = mid.index_handle 
      INNER JOIN sys.objects WITH (nolock) ON mid.OBJECT_ID = sys.objects.OBJECT_ID 
WHERE (migs.group_handle IN 
            (SELECT TOP (500) group_handle 
            FROM sys.dm_db_missing_index_group_stats WITH (nolock) 
            ORDER BY (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) DESC))  
      AND OBJECTPROPERTY(sys.objects.OBJECT_ID, 'isusertable') = 1 
ORDER BY [Impact] DESC , [CreateIndexStatement] DESC
