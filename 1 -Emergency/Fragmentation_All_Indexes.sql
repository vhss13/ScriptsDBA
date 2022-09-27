--Cria��o da tabela tempor�ria que para armazenar
--informa��es sobre os �ndices
CREATE TABLE #Index_Frag
(
	Index_Id INT,
	Name VARCHAR(100),
	avg_fragmentation_in_percent FLOAT
)

--Inserinto da tabela tempor�ria a fragamenta��o de todos os �ndices
--de todas as tabelas do banco de dados selecionado
INSERT INTO #Index_Frag
EXEC SP_MSFOREACHTABLE '
SELECT 
	a.index_id, 
	name, 
	avg_fragmentation_in_percent
FROM 
	sys.dm_db_index_physical_stats (DB_ID(DB_NAME()),
OBJECT_ID("?"), NULL, NULL, NULL) AS a
JOIN 
	sys.indexes AS b 
ON 
	a.object_id = b.object_id 
AND 
	a.index_id = b.index_id'

--Verifica informa��o na tabela tempor�ria
SELECT
	*
FROM
	#Index_Frag
ORDER BY
	avg_fragmentation_in_percent DESC
	
--Excluir tabela tempor�ria
DROP TABLE #Index_Frag