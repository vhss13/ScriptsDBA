
--Exec DBA_stpAtualiza_Estatisticas

Alter PROCEDURE [dbo].[DBA_stpAtualiza_Estatisticas]
As
BEGIN

DECLARE @Hora TINYINT
DECLARE @Min TINYINT

SET @Hora = 15  -- hora cheia Ex: 14 para 14:00
SET @Min = 30

SET NOCOUNT ON
-- Sai da rotina quando a janela de manutenção é finalizada
IF GETDATE()> dateadd(mi,+@Min,dateadd(hh,+@Hora,cast(floor(cast(getdate()as float))as datetime)))
BEGIN
RETURN
END

Create table 
	#Atualiza_Estatisticas
	(
		Id_Estatistica int identity(1,1),
		Ds_Comando varchar(4000),
		Nr_Linha int
	)

;WITH Tamanho_Tabelas AS 
	(
		SELECT 
			obj.name, 
			prt.rows
		FROM 
			sys.objects obj
		join sys.stats sta on obj.object_id = sta.object_id
		JOIN sys.indexes idx on obj.object_id= idx.object_id
		JOIN sys.partitions prt on obj.object_id= prt.object_id
		JOIN sys.allocation_units alloc on alloc.container_id= prt.partition_id
		WHERE 
			obj.type= 'U' AND 
			idx.index_id IN (0, 1)and 
			prt.rows> 1000 and
			STATS_DATE(obj.object_id, sta.stats_id) < getdate()-30 
			and substring(OBJECT_NAME(obj.object_id),1,3) 
			not in ('sys','dtp')
			and substring( OBJECT_NAME(obj.object_id) , 1,1) <> '_' -- elimina tabelas temporarias
		GROUP BY 
			obj.name, 
			prt.rows
	)

insert into #Atualiza_Estatisticas(Ds_Comando,Nr_Linha)
	SELECT 
		'UPDATE STATISTICS ' + B.name+ ' ' + A.name+ ' WITH FULLSCAN', D.rows
	FROM 
		sys.stats A
	join sys.sysobjects B on A.object_id = B.id
	join sys.sysindexes C on C.id = B.id and A.name= C.Name
	JOIN Tamanho_Tabelas D on  B.name= D.Name
	WHERE  
		C.rowmodctr > 1000
		and substring( B.name,1,3) 
		not in ('sys','dtp')
	ORDER BY 
		D.rows

declare @Loop int, @Comando nvarchar(4000)
set @Loop = 1


while exists(select top 1 * from #Atualiza_Estatisticas)
begin

	IF GETDATE()> dateadd(mi,+@Min,dateadd(hh,+@Hora,cast(floor(cast(getdate()as float))as datetime)))
	begin
		print 'Saindo Break'
		BREAK -- Sai do loop quando acabar a janela de manutenção
	End

	select 
		@Comando = Ds_Comando
	from 
		#Atualiza_Estatisticas
	where 
		Id_Estatistica = @Loop

	EXECUTE sp_executesql @Comando

	delete from 
		#Atualiza_Estatisticas
	where 
		Id_Estatistica = @Loop

	set @Loop= @Loop + 1
END
End
