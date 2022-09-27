/****** Object:  StoredProcedure [dbo].[DBA_SP_DEFRAG]    Script Date: 11/24/2010 13:29:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* TIPO DO OBJETO    	: PROCEDURE
** AUTOR                : Benes Guislandi
** DATA                 : 27/05/2010 
** SISTEMA              : Administração do MSSQL
** OBJETIVO             : Efetuar a desfragmentação dos ínidces do banco de dados ClearSale
** MANUTEÇÃO            : Adicionado tratamento para executar reorganize em data type que não aceita rebuild online
** DATA DA MANUTENÇÃO   : 22/09/2010
** OBS DA MANUTENÇÃO    : 
*/

ALTER PROCEDURE [dbo].[DBA_SP_DEFRAG]
AS

-- INICIO DO PROCESSO
SET NOCOUNT ON

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER OFF

-- Declara Variáveis.
DECLARE @objectid int;
DECLARE @indexid int;
DECLARE @partitioncount bigint;
DECLARE @schemaname nvarchar(130); 
DECLARE @objectname nvarchar(130); 
DECLARE @indexname nvarchar(130); 
DECLARE @partitionnum bigint;
DECLARE @partitions bigint;
DECLARE @frag float;
DECLARE @command nvarchar(4000); 
DECLARE @db_id SMALLINT;
SET @db_id = DB_ID()

-- Identifica Tabelas que farão parte do processo.
SELECT	object_id AS objectid,
		index_id AS indexid,
		partition_number AS partitionnum,
		avg_fragmentation_in_percent AS frag
	INTO #work_to_do
FROM	sys.dm_db_index_physical_stats (@db_id, NULL, NULL , NULL, 'LIMITED')
WHERE	avg_fragmentation_in_percent > 10.0 AND index_id > 0;


-- Declara o cursor.
DECLARE partitions CURSOR FOR SELECT * FROM #work_to_do;

-- Abre o cursor.
OPEN partitions;

-- Loop.
WHILE (1=1)
    BEGIN;
		BEGIN TRY
        FETCH NEXT
           FROM partitions
           INTO @objectid, @indexid, @partitionnum, @frag;
        IF @@FETCH_STATUS < 0 BREAK;
        SELECT @objectname = QUOTENAME(o.name), @schemaname = QUOTENAME(s.name)
        FROM sys.objects AS o
        JOIN sys.schemas as s ON s.schema_id = o.schema_id
        WHERE o.object_id = @objectid;
        SELECT @indexname = QUOTENAME(name)
        FROM sys.indexes
        WHERE  object_id = @objectid AND index_id = @indexid;
        SELECT @partitioncount = count (*)
        FROM sys.partitions
        WHERE object_id = @objectid AND index_id = @indexid;

-- 10% é um ponto de decisão em que decidimos entre reorganizing e rebuilding.
        IF @frag < 10.0
            SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';
        IF @frag >= 10.0
            SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD WITH (ONLINE=ON)';
        IF @partitioncount > 1
            SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10));
        EXEC (@command);
        PRINT (@command);
		END TRY
		BEGIN CATCH
		SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
		SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';
		IF @partitioncount > 1
            SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10));
        EXEC (@command)
        PRINT (@command)
		END CATCH
    END

-- Fecha cursor.
CLOSE partitions;
DEALLOCATE partitions;

-- Guarda Histórico de Objetos Fragmentados
if (select count(*) from dbativit.sys.objects where name = 'work_to_do')=0
begin
CREATE TABLE [dbo].[work_to_do](
	[DBID] [smallint] NULL,
	[Data] [datetime] NOT NULL,
	[objectid] [int] NULL,
	[indexid] [int] NULL,
	[partitionnum] [int] NULL,
	[frag] [float] NULL
) ON [PRIMARY]
end

insert into DBATIVIT..work_to_do
select	db_id(),
		getdate(),
		objectid,
		indexid,
		partitionnum,
		frag
from	#work_to_do

--select * from DBATIVIT..work_to_do

-- Drop da tabela temporária.
DROP TABLE #work_to_do;
GO

=====================================================================================================================================================
Antiga forma, identificando os indices BLOB
=====================================================================================================================================================

/* TIPO DO OBJETO    	: PROCEDURE
** AUTOR                : Benes Guislandi
** DATA                 : 27/05/2010 
** SISTEMA              : Administração do MSSQL
** OBJETIVO             : Efetuar a desfragmentação dos ínidces do banco de dados ClearSale
** MANUTEÇÃO            : Adicionado tratamento para executar reorganize em data type que não aceita rebuild online
** DATA DA MANUTENÇÃO   : 22/09/2010
** OBS DA MANUTENÇÃO    : 
*/

alter PROCEDURE DBA_SP_DEFRAG
AS

-- INICIO DO PROCESSO

SET NOCOUNT ON;

-- Declara Variáveis.
DECLARE @objectid int;
DECLARE @indexid int;
DECLARE @partitioncount bigint;
DECLARE @schemaname nvarchar(130); 
DECLARE @objectname nvarchar(130); 
DECLARE @indexname nvarchar(130); 
DECLARE @partitionnum bigint;
DECLARE @partitions bigint;
DECLARE @frag float;
DECLARE @command nvarchar(4000); 
DECLARE @cont int; 
DECLARE @db_id SMALLINT;
SET	@db_id = DB_ID()

-- Identifica Tabelas que NÃO farão parte do processo REBUILD e sim do REORGANIZE.

if object_id('tempdb..#work_to_do') is not null
begin
	drop table #work_to_do
end

if object_id('tempdb..#work_not_to_do') is not null
begin
	drop table #work_not_to_do
end

if object_id('tempdb..#work_not_to_do2') is not null
begin
	drop table #work_not_to_do2
end

select	st.object_id as OBJECTID,
	ss.name as SCHEMANAME, 
	st.name as TABLENAME, 
	si.name as SYSNAMES
		INTO #work_not_to_do
from	sys.tables st inner join sys.schemas ss
	on st.schema_id = ss.schema_id
	left join sys.indexes si
	on st.object_id = si.object_id
	inner join sys.columns sc
	on st.object_id = sc.object_id
	inner join sys.types stp
	on sc.user_type_id = stp.user_type_id
where	stp.name in ('text', 'ntext', 'image', 'xml')
	or (stp.name in ('varchar', 'nvarchar', 'varbinary') and sc.max_length = '-1')
	and st.name not in ('sysdiagrams')

select distinct * ,'id'=identity(int,1,1) into #work_not_to_do2 from #work_not_to_do

set @cont = @@rowcount
while @cont <> 0
begin
	select @objectname = QUOTENAME(TABLENAME), @indexname = QUOTENAME(SYSNAMES), @schemaname = QUOTENAME(SCHEMANAME) from #work_not_to_do2 where id = @cont
	if (@objectname) is not null
	begin
		set @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';
--		print (@command)
		exec (@command)
	end
	set @cont = @cont-1
end


-- Identifica Tabelas que farão parte do processo de REBUILD.
SELECT  object_id AS objectid,
        index_id AS indexid,
        partition_number AS partitionnum,
        avg_fragmentation_in_percent AS frag
              	INTO #work_to_do
FROM    sys.dm_db_index_physical_stats (@db_id, NULL, NULL , NULL, 'LIMITED')
WHERE   avg_fragmentation_in_percent > 10.0 AND index_id > 0 
		and object_id not in (Select OBJECTID from #work_not_to_do2)

-- Declara o cursor e executa o REBUILD ONLINE.
DECLARE partitions CURSOR FOR SELECT * FROM #work_to_do;

-- Abre o cursor.
OPEN partitions;

-- Loop.
WHILE (1=1)
    BEGIN;
        FETCH NEXT
           FROM partitions
           INTO @objectid, @indexid, @partitionnum, @frag;
        IF @@FETCH_STATUS < 0 BREAK;
        SELECT @objectname = QUOTENAME(o.name), @schemaname = QUOTENAME(s.name)
        FROM sys.objects AS o
        JOIN sys.schemas as s ON s.schema_id = o.schema_id
        WHERE o.object_id = @objectid;
        SELECT @indexname = QUOTENAME(name)
        FROM sys.indexes
        WHERE  object_id = @objectid AND index_id = @indexid;
        SELECT @partitioncount = count (*)
        FROM sys.partitions
        WHERE object_id = @objectid AND index_id = @indexid;

        IF @frag >= 10.0
            SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD WITH (ONLINE=ON)';
        IF @partitioncount > 1
            SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10));
        EXEC (@command);
--        PRINT (@command);
        PRINT N'Executed: ' + @command;
    END;

-- Fecha cursor.
CLOSE partitions;
DEALLOCATE partitions;


-- Guarda Histórico de Objetos Fragmentados
insert into DBATIVIT..work_to_do
select	db_id(),
		getdate(),
		objectid,
		indexid,
		partitionnum,
		frag
from	#work_to_do

-- Guarda Histórico de Objetos Fragmentados
insert into DBATIVIT..work_not_to_do
select	db_id(),
		getdate(),
		OBJECTID,
		SCHEMANAME, 
		TABLENAME, 
		SYSNAMES
from	#work_not_to_do2

--select * from DBATIVIT..work_to_do
--select * from DBATIVIT..work_not_to_do