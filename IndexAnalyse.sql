--Stored Procedure que mostra quais os indices
--uma tabela possue
sp_helpindex 'Person.Person'

--Utilizando a DMV sys.dm_db_index_usage_stats podemos verificar
--qual a utilização de um índice
SELECT 
	OBJECT_NAME(dmi.[object_id]) AS tbl_name, 
	i.name AS idx_name, 
	dmi.* 
FROM
	sys.dm_db_index_usage_stats dmi 
INNER JOIN
	sys.indexes i 
ON
	dmi.index_id = i.index_id 
AND 
	dmi.[object_id] = i.[object_id]
WHERE
	database_id = 12 
AND 
	OBJECT_NAME(dmi.[object_id]) = 'Person'
GO

--Utilizando a DMF sys.dm_db_index_physical_stats, podemos verificar
--qual a taxa de fragmentação de um índice 
SELECT 
	a.index_id, 
	name, 
	avg_fragmentation_in_percent
FROM 
	sys.dm_db_index_physical_stats 
	(DB_ID('AdventureWorks2008'),OBJECT_ID(N'Person.Person'), NULL, NULL, NULL) AS a
INNER JOIN 
	sys.indexes AS b 
ON 
	a.[object_id] = b.[object_id] AND a.index_id = b.index_id;

--Utilizando as DMVs sys.dm_db_missing_index_  , podemos verificar
--em quais tabelas o SQL Server se aproveitaria de uma nova estrutura
--de índice
SELECT TOP 10 *
FROM sys.dm_db_missing_index_group_stats
ORDER BY avg_total_user_cost * avg_user_impact * (user_seeks + user_scans)DESC;

SELECT migs.group_handle, mid.*
FROM sys.dm_db_missing_index_group_stats AS migs
INNER JOIN sys.dm_db_missing_index_groups AS mig
    ON (migs.group_handle = mig.index_group_handle)
INNER JOIN sys.dm_db_missing_index_details AS mid
    ON (mig.index_handle = mid.index_handle) --order by object_id
WHERE migs.group_handle = 4;
go

--Exibe quantas páginas de dados, por tabela, o SQL SERVER 
--carregou no BUFFER POOL
SELECT count(*)AS cached_pages_count 
    ,name ,index_id 
FROM sys.dm_os_buffer_descriptors AS bd 
    INNER JOIN 
    (
        SELECT object_name(object_id) AS name 
            ,index_id ,allocation_unit_id
        FROM sys.allocation_units AS au
            INNER JOIN sys.partitions AS p 
                ON au.container_id = p.hobt_id 
                    AND (au.type = 1 OR au.type = 3)
        UNION ALL
        SELECT object_name(object_id) AS name   
            ,index_id, allocation_unit_id
        FROM sys.allocation_units AS au
            INNER JOIN sys.partitions AS p 
                ON au.container_id = p.hobt_id 
                    AND au.type = 2
    ) AS obj 
        ON bd.allocation_unit_id = obj.allocation_unit_id
WHERE database_id = db_id()
GROUP BY name, index_id 
ORDER BY cached_pages_count DESC, name