CREATE PROCEDURE [dbo].[DBA_SP_VERIFICA_QUERY_ANALYZER] AS

/* TIPO DO OBJETO    	: DBA_SP_VERIFICA_QUERY_ANALYZER
** AUTOR                : Benes Guislandi
** DATA                 : 26/05/2010 
** SISTEMA              : Administração do MSSQL
** OBJETIVO             : Monitoração de Conexões de Studio Management no Servidor de produção
** MANUTEÇÃO            : Acresicda a opção de KILL
** DATA DA MANUTENÇÃO   : 10/09/2010
** OBS DA MANUTENÇÃO    : 
** PARAMETROS		: 
*/
declare	@spid  smallint
declare	@status nchar(10)
declare @hostname as varchar(128)
declare @nt_username as varchar(128)
declare @loginame as varchar(128)
declare @blocked smallint
declare @cpu int
declare @physical_io bigint
declare @memusage int
declare @login_time datetime
declare @last_batch datetime
declare @cmd nchar(32)
declare @prog varchar(60)

DECLARE Query_Analyzer CURSOR FOR
select 
	spid, 
	cast(hostname as varchar(30)) as hostname, 
	cast(nt_username as varchar(30)) as nt_username, 
	cast(loginame as varchar(30)) as loginame, 
	login_time, 
	last_batch, 
	cmd,
	cast(program_name as varchar (50)) as Program_name
from 
	master..sysprocesses 
where 
	program_name in ('Microsoft SQL Server Management Studio - Query', 'QUERY ANALYZER')
--	and loginame = 'ogsuporte' -- PARA TESTAR
	and ( hostname in ('') or loginame in (''))
order by status

OPEN Query_Analyzer

FETCH NEXT FROM Query_Analyzer INTO
		@spid, 
		@hostname, 
		@nt_username,
		@loginame,
		@login_time,
		@last_batch,
		@cmd,
		@prog


declare	@strSQL	varchar(5000)
set @strSQL = '' + char(13)
set @strSQL = @strSQL + char(13)
set @strSQL = @strSQL + 'PROCESSOS EXECUTANDO (Microsoft SQL Server Management Studio) NO SERVIDOR DE PRODUÇÃO: ' + CONVERT(VARCHAR(200),(SELECT @@SERVERNAME)) + char(13)
set @strSQL = @strSQL + char(13)
set @strSQL = @strSQL + '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'+ char(13)
set @strSQL = @strSQL + '|HOSTNAME                       |LOGINNAME                       |LOGIN_TIME               |LAST_BATCH               |CMD               |PROGRAM_NAME                                     |'+ char(13)
set @strSQL = @strSQL + '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'+ char(13)

-- PRINT @@FETCH_STATUS

IF @@FETCH_STATUS = 0
BEGIN
	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @strSQL = @strSQL + ' ' + 
					rtrim(convert(varchar(30),@hostname)) + space(30 - len(rtrim(convert(varchar(30),@hostname)))) + ' | ' + 
					rtrim(convert(varchar(30),@loginame)) + space(30 - len(rtrim(convert(varchar(30),@loginame)))) + ' | ' + 
					rtrim(convert(varchar(23),@login_time,121)) + space(19 - len(rtrim(convert(varchar(19),@login_time)))) + ' | ' + 
					rtrim(convert(varchar(23),@last_batch,121)) + space(19 - len(rtrim(convert(varchar(19),@last_batch)))) + ' | ' + 
					rtrim(convert(varchar(15),@cmd)) + space(15 - len(rtrim(convert(varchar(15),@cmd)))) + ' | ' + 					rtrim(convert(varchar(60),@prog)) + space(60 - len(rtrim(convert(varchar(60),@prog))))+ char(13)
	
		FETCH NEXT FROM Query_Analyzer INTO
				@spid,
				@hostname, 
				@nt_username,
				@loginame,
				@login_time,
				@last_batch,
				@cmd,
				@prog
	END
	
	set @strSQL = @strSQL + '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'+ char(13)
	
	print @strSQL
	set @strSQL = 'KILL '+convert(varchar(5), @spid)
	exec (@strSQL)
	
	
END	

CLOSE Query_Analyzer
DEALLOCATE Query_Analyzer




