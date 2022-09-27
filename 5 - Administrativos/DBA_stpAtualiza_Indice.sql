-- Inicio script

--Exec DBA_stpAtualiza_Indices

Alter PROCEDURE [dbo].[DBA_stpAtualiza_Indices]

AS

BEGIN

-- Seta a Hora para o Processo acabar
DECLARE @Hora TINYINT
DECLARE @Min TINYINT

SET @Hora = 09  -- hora cheia Ex: 14 para 14:00
SET @Min = 35

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Sai da rotina quando a janela de manutenção é finalizada
IF GETDATE()> DATEADD(MI,+@Min,DATEADD(HH,+@Hora,CAST(FLOOR(CAST(GETDATE()AS FLOAT))AS DATETIME)))

BEGIN
RETURN
END

-- Cria tabela temporaria que armazera as estatisticas das tabelas
CREATE TABLE 
	#showcontig 
	(
		ObjectName SYSNAME,
		ObjectId INT,
		IndexName SYSNAME,
		IndexId INT,
		Level INT,
		Pages INT,
		Rows INT,
		MinimumRecordSize INT,
		MaximumRecordSize INT,
		AverageRecordSize INT,
		ForwardedRecords INT,
		Extents INT,
		ExtentSwitches INT,
		AverageFreeBytes INT,
		AveragePageDensity INT,
		ScanDensity INT,
		BestCount INT,
		ActualCount INT,
		LogicalFragmentation INT,
		ExtentFragmentation INT
	)

-- Declara variaveis que serao utilizadas pelo cursor
DECLARE @nome AS SYSNAME,
@str AS VARCHAR(512)

-- Seleciona todas as tabelas do database que não são do sistema
DECLARE cTables CURSOR FOR
	SELECT
		'"' + s.name +	'.' + t.name + '"'
	FROM
		sys.tables t
	INNER JOIN sys.indexes i ON
		t.object_id = i.object_id
	INNER JOIN sys.schemas s ON
		t.schema_id = s.schema_id
	WHERE
		t.name NOT LIKE 'sys%'
		and
		i.Index_Id > 0

--Loop para coleta de informações estatísticas sobre as tabelas e seus respectivos índices
OPEN cTables

FETCH NEXT FROM cTables INTO @nome

WHILE @@fetch_status = 0 BEGIN
	SET @str = 'dbcc showcontig(' + @nome + ') with all_indexes, fast, tableresults'
	INSERT INTO #showcontig
	EXEC (@str)
	FETCH NEXT FROM cTables INTO @nome
END

CLOSE cTables

DEALLOCATE cTables

-- Cria tabela temporaria que armazenara os indices que devem ser atualizados
CREATE TABLE 
	#Atualiza_Indices
		(
			Id_indice INT IDENTITY(1,1),
			Ds_Comando VARCHAR(4000)
		)

-- Inicia a CTE para concatenar o comando a ser executado, segmentado pelas operacoes de REORGANIZE ou REBUILD
;WITH Tamanho_Tabelas AS 

(

		--Seleciona os índices para realizar o reorganize
		SELECT 
			ObjectName
			, IndexId
			, IndexName
			, 'alter index ' + IndexName + ' ON ' + ObjectName + ' REORGANIZE;' AS command
		FROM
			#showcontig
		WHERE
			ScanDensity > 50
			OR
			LogicalFragmentation < 30)

		UNION

		-- Seleciona os índices para realizar o rebuild
		SELECT
			ObjectName,
			IndexId,
			IndexName,
			'alter index ' + IndexName + ' ON ' + ObjectName + ' REBUILD PARTITION = ALL WITH ( FILLFACTOR = 85, PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, ONLINE = OFF, SORT_IN_TEMPDB = OFF );' AS command
		FROM
			#showcontig
		WHERE
			(ScanDensity = 50)
			AND
			LogicalFragmentation >= 30
)

-- Insere na tabela temporaria o retorno da CTE
INSERT INTO 
	#Atualiza_Indices (Ds_Comando)
		SELECT 
			command 
		FROM 
			tamanho_tabelas

-- Declara variaveis que serao utilizadas pelo looping de execucao de comandos
DECLARE @Loop INT,
@Comando NVARCHAR(4000)

-- Seta valor da variavel de looping
SET @Loop = 1

-- Inicia o looping de execucao de comandos
WHILE EXISTS(SELECT TOP 1 NULL FROM #Atualiza_Indices)
BEGIN
		IF GETDATE()> DATEADD(MI,+@Min,DATEADD(HH,+@Hora,CAST(FLOOR(CAST(GETDATE()AS FLOAT))AS DATETIME)))
		BEGIN
		BREAK -- Sai do loop quando acabar a janela de manutenção
		END

		SELECT
			@Comando = Ds_Comando
		FROM
			#Atualiza_Indices
		WHERE
			Id_Indice = @Loop

		EXECUTE sp_executesql @Comando

		DELETE FROM #Atualiza_Indices WHERE Id_Indice = @Loop

		SET @Loop= @Loop + 1
END

-- Exclui tabelas temporarias
DROP TABLE #showcontig
DROP TABLE #Atualiza_Indices

END
SET NOCOUNT OFF
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

-- Termino script