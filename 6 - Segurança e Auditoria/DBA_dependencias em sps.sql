DECLARE @TableName AS VARCHAR(1000) = 'Packets'
DECLARE @ColName AS VARCHAR(1000) = 'PacketNo'

SELECT DISTINCT
 --O.object_id,
 O.name SPName
 --O2.object_id,
 --O2.name TableName,
 --SC.[text] SPText
FROM 
 sys.objects AS O
LEFT JOIN sys.sql_expression_dependencies sed
 ON sed.referencing_id = O.object_id
INNER JOIN sys.objects O2
 ON O2.object_id = sed.referenced_id
  AND O2.type = 'U' --Table
  AND O2.name = @TableName
INNER JOIN SYSCOMMENTS SC
 ON SC.id = O.object_id
  AND SC.[Text] LIKE '%' + @ColName + '%'
WHERE
 O.[type] = 'P' --StoredProcedure