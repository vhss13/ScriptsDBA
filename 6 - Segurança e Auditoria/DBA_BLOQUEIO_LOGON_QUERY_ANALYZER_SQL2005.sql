USE master;
GO

CREATE LOGIN security_login WITH PASSWORD = 'teste123'; 
GO
GRANT VIEW SERVER STATE TO security_login;
GO
CREATE TRIGGER connection_limit_trigger
ON ALL SERVER WITH EXECUTE AS 'security_login' FOR LOGON
AS
BEGIN
	IF ORIGINAL_LOGIN()= 'thomas_anderson' AND    
	(SELECT COUNT(*) FROM sys.dm_exec_sessions            
	WHERE is_user_process = 1 AND original_login_name = 'thomas_anderson' and program_name like 'Microsoft SQL Server Management Studio%') > 1    
	ROLLBACK;
END;

===========================================================================================================================================================

set nocount on
declare @cont int,
	@spid int,
	@command varchar(2000)

if object_id('tempdb..#tmpspid') is not null
begin
	drop table #tmpspid
end

select 'id'=identity(int,1,1), session_id, original_login_name into #tmpspid from master.sys.dm_exec_sessions where is_user_process = 1 and original_login_name = 'thomas_anderson' and program_name like 'Microsoft SQL Server Management Studio%' order by session_id desc
set @cont = @@rowcount
while @cont <> 0
begin
	select @spid = session_id from #tmpspid where id = @cont
	if (@spid) is not null
	begin
		insert into audit_table 
		select 'Data'=getdate(), session_id, original_login_name, nt_user_name, host_name, nt_domain, program_name from master.sys.dm_exec_sessions where is_user_process = 1 and original_login_name = 'thomas_anderson' and program_name like 'Microsoft SQL Server Management Studio%' order by session_id desc 
		set @command='kill '+convert(varchar(5),@spid)
		print (@command)
		exec (@command)
	end
	set @cont = @cont-1
end
set nocount off


=============================================================================================================================================================


CREATE PROCEDURE [dbo].[DBA_SP_VERIFICA_QUERY_ANALYZER] AS

/* TIPO DO OBJETO       : DBA_SP_VERIFICA_QUERY_ANALYZER
** AUTOR                : Benes Guislandi
** DATA                 : 26/05/2010 
** SISTEMA              : Administra��o do MSSQL
** OBJETIVO             : Monitora��o de Conex�es de Studio Management no Servidor de produ��o
** MANUTE��O            : Acresicdo a op��o de KILL
** DATA DA MANUTEN��O   : 10/09/2010
** OBS DA MANUTEN��O    : 
** PARAMETROS           : 
*/
declare     @spid  smallint
declare     @status nchar(10)
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
      program_name = 'Microsoft SQL Server Management Studio - Query'
      and ( hostname in ('GOLL0317', 'GOLL0318') or loginame in ('appclearsale'))
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


declare     @strSQL     varchar(5000)
set @strSQL = '' + char(13)
set @strSQL = @strSQL + char(13)
set @strSQL = @strSQL + 'PROCESSOS EXECUTANDO (Microsoft SQL Server Management Studio) NO SERVIDOR DE PRODU��O: ' + CONVERT(VARCHAR(200),(SELECT @@SERVERNAME)) + char(13)
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
                             rtrim(convert(varchar(15),@cmd)) + space(15 - len(rtrim(convert(varchar(15),@cmd)))) + ' | ' + 
                             rtrim(convert(varchar(60),@prog)) + space(60 - len(rtrim(convert(varchar(60),@prog))))+ char(13)

      
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
