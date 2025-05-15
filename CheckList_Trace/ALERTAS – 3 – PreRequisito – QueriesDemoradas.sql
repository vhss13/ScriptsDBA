--*******************************************************************************************************************************
--	Instrucoes de utilizacao do script.
--*******************************************************************************************************************************/
--	1) Fazer um Replace(CTRL + H) no caminho "D:\Temp" e alterar para um Caminho Real no servidor.


--------------------------------------------------------------------------------------------------------------------------------
--	Criacao da tabela de Traces.
--------------------------------------------------------------------------------------------------------------------------------
use DBA_MON

if OBJECT_ID('Traces') is not null
	drop table Traces
	
CREATE TABLE [dbo].[Traces](
	[TextData] varchar(max) NULL,
	[NTUserName] [varchar](128) NULL,
	[HostName] [varchar](128) NULL,
	[ApplicationName] [varchar](128) NULL,
	[LoginName] [varchar](128) NULL,
	[SPID] [int] NULL,
	[Duration] [numeric](15, 2) NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[ServerName] [varchar](128) NULL,
	[Reads] [int] NULL,
	[Writes] [int] NULL,
	[CPU] [int] NULL,
	[DataBaseName] [varchar](128) NULL,
	[RowCounts] [int] NULL,
	[SessionLoginName] [varchar](128) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]        

GO

--------------------------------------------------------------------------------------------------------------------------------
-- Criando a procedure que ira criar o Trace.
--------------------------------------------------------------------------------------------------------------------------------
use DBA_MON

if OBJECT_ID('stpCreate_Trace') is not null
	drop procedure stpCreate_Trace
GO

CREATE  Procedure [dbo].[stpCreate_Trace]
AS
BEGIN
	-- Trace Queries Demoradas
	DECLARE @Id_Alerta_Parametro INT = (SELECT Id_Alerta_Parametro FROM [DBA_MON].[dbo].Alerta_Parametro (NOLOCK) WHERE Nm_Alerta = 'Trace Queries Demoradas')

	--------------------------------------------------------------------------------------------------------------------------------
	-- Recupera os parametros do Alerta
	--------------------------------------------------------------------------------------------------------------------------------
	DECLARE @Tempo_Traces INT
	
	SELECT	@Tempo_Traces = Vl_Parametro					-- Segundos
	FROM [dbo].[Alerta_Parametro]
	WHERE [Id_Alerta_Parametro] = @Id_Alerta_Parametro			-- Trace Queries Demoradas

	-- Trava de seguranca para colocar um valor default na variavel
	IF(@Tempo_Traces IS NULL OR @Tempo_Traces < 0)
	BEGIN
		SELECT @Tempo_Traces = 3	-- Segundos
	END	

	/*******************************************************************************************************************************
	-- Created by: SQL Server Profiler 2005
	-- Date: 09/09/2008  14:44:14
	*******************************************************************************************************************************/
	-- Create a Queue.
	declare @rc int
	declare @TraceID int
	declare @maxfilesize bigint
	set @maxfilesize = 50

	/*******************************************************************************************************************************
	-- ATENCAO!!!
	-- Alterar esse Caminho!!!
	*******************************************************************************************************************************/
	exec @rc = sp_trace_create @TraceID output, 0, N'D:\Temp\Duracao', @maxfilesize, NULL 

	if (@rc != 0) goto error

	-- Client side File and Table cannot be scripted.

	-- Set the events.
	declare @on bit
	set @on = 1

	-- 10 RPC:Completed Ocorre quando uma RPC (chamada de procedimento remoto) e concluida. 
	exec sp_trace_setevent @TraceID, 10, 1, @on		-- TextData: Valor de texto dependente da classe de evento capturada no rastreamento.
	exec sp_trace_setevent @TraceID, 10, 6, @on		-- NTUserName: Nome de usuario do Microsoft Windows. 
	exec sp_trace_setevent @TraceID, 10, 8, @on		-- HostName: Nome do computador cliente que originou a solicitacao. 
	exec sp_trace_setevent @TraceID, 10, 10, @on	-- ApplicationName: Nome do aplicativo cliente que criou a conexao com uma instancia do SQL Server.
													-- Essa coluna e populada com os valores passados pelo aplicativo e nao com o nome exibido do programa.
	exec sp_trace_setevent @TraceID, 10, 11, @on	-- LoginName: Nome de logon do cliente no SQL Server.
	exec sp_trace_setevent @TraceID, 10, 12, @on	-- SPID: ID de processo de servidor atribuida pelo SQL Server ao processo associado ao cliente.
	exec sp_trace_setevent @TraceID, 10, 13, @on	-- Duration: Tempo decorrido (em milhoes de segundos) utilizado pelo evento. 
													-- Esta coluna de dados nao e populada pelo evento Hash Warning.
	exec sp_trace_setevent @TraceID, 10, 14, @on	-- StartTime: Horario de inacio do evento, quando disponivel.
	exec sp_trace_setevent @TraceID, 10, 15, @on	-- EndTime: Horario em que o evento foi encerrado. Esta coluna nao e populada para classes de evento
													-- iniciais, como SQL:BatchStarting ou SP:Starting. Tambem nao e populada pelo evento Hash Warning.
	exec sp_trace_setevent @TraceID, 10, 16, @on	-- Reads: Numero de leituras logicas do disco executadas pelo servidor em nome do evento. 
													-- Esta coluna nao e populada pelo evento Lock:Released.
	exec sp_trace_setevent @TraceID, 10, 17, @on	-- Writes: Numero de gravacoes no disco fisico executadas pelo servidor em nome do evento.
	exec sp_trace_setevent @TraceID, 10, 18, @on	-- CPU: Tempo da CPU (em milissegundos) usado pelo evento.
	exec sp_trace_setevent @TraceID, 10, 19, @on	-- CPU: Tempo da CPU (em milissegundos) usado pelo evento.
	exec sp_trace_setevent @TraceID, 10, 26, @on	-- ServerName: Nome da instancia do SQL Server, servername ou servername\instancename, 
													-- que esta sendo rastreada
	exec sp_trace_setevent @TraceID, 10, 35, @on	-- DatabaseName: Nome do banco de dados especificado na instrucao USE banco de dados.
	exec sp_trace_setevent @TraceID, 10, 40, @on	-- DBUserName: Nome de usuario do banco de dados do SQL Server do cliente.
	exec sp_trace_setevent @TraceID, 10, 48, @on	-- RowCounts: Numero de linhas no lote.
	exec sp_trace_setevent @TraceID, 10, 64, @on	-- SessionLoginName: O nome de logon do usuario que originou a sessao. Por exemplo, se voce 
													-- se conectar ao SQL Server usando Login1 e executar uma instrucao como Login2, SessionLoginName
													-- ira exibir Login1, enquanto que LoginName exibira Login2. Esta coluna de dados exibe logons
													-- tanto do SQL Server, quanto do Windows.

	exec sp_trace_setevent @TraceID, 12, 1,  @on	-- TextData: Valor de texto dependente da classe de evento capturada no rastreamento.
	exec sp_trace_setevent @TraceID, 12, 6,  @on	-- NTUserName: Nome de usuario do Microsoft Windows. 
	exec sp_trace_setevent @TraceID, 12, 8,  @on	-- HostName: Nome do computador cliente que originou a solicitacao. 
	exec sp_trace_setevent @TraceID, 12, 10, @on	-- ApplicationName: Nome do aplicativo cliente que criou a conexao com uma instancia do SQL Server. 
													-- Essa coluna e populada com os valores passados pelo aplicativo e nao com o nome exibido do programa.
	exec sp_trace_setevent @TraceID, 12, 11, @on	-- LoginName: Nome de logon do cliente no SQL Server.
	exec sp_trace_setevent @TraceID, 12, 12, @on	-- SPID: ID de processo de servidor atribuida pelo SQL Server ao processo associado ao cliente.
	exec sp_trace_setevent @TraceID, 12, 13, @on	-- Duration: Tempo decorrido (em milhoes de segundos) utilizado pelo evento. Esta coluna de dados nao
													-- e populada pelo evento Hash Warning.
	exec sp_trace_setevent @TraceID, 12, 14, @on	-- StartTime: Hororio de inicio do evento, quando disponivel.
	exec sp_trace_setevent @TraceID, 12, 15, @on	-- EndTime: Horario em que o evento foi encerrado. Esta coluna nao e populada para classes de evento
													-- iniciais, como SQL:BatchStarting ou SP:Starting. Tambem nao e populada pelo evento Hash Warning.
	exec sp_trace_setevent @TraceID, 12, 16, @on	-- Reads: Numero de leituras logicas do disco executadas pelo servidor em nome do evento. 
													-- Esta coluna nao e populada pelo evento Lock:Released.
	exec sp_trace_setevent @TraceID, 12, 17, @on	-- Writes: Numero de gravacoes no disco fisico executadas pelo servidor em nome do evento.
	exec sp_trace_setevent @TraceID, 12, 18, @on	-- CPU: Tempo da CPU (em milissegundos) usado pelo evento.
	exec sp_trace_setevent @TraceID, 12, 26, @on	-- ServerName: Nome da instancia do SQL Server, servername ou servername\instancename, 
													-- que esta sendo rastreada
	exec sp_trace_setevent @TraceID, 12, 35, @on	-- DatabaseName: Nome do banco de dados especificado na instrucao USE banco de dados.
	exec sp_trace_setevent @TraceID, 12, 40, @on	-- DBUserName: Nome de usuario do banco de dados do SQL Server do cliente.
	exec sp_trace_setevent @TraceID, 12, 48, @on	-- RowCounts: Numero de linhas no lote.
	exec sp_trace_setevent @TraceID, 12, 64, @on	-- SessionLoginName: O nome de logon do usuario que originou a sessao. Por exemplo, se voce se
													-- conectar ao SQL Server usando Login1 e executar uma instrucao como Login2, SessionLoginName
													-- ira exibir Login1, enquanto que LoginName exibira Login2. Esta coluna de dados exibe logons
													-- tanto do SQL Server, quanto do Windows.

	-- Set the Filters.
	declare @intfilter int
	declare @bigintfilter bigint

	exec sp_trace_setfilter @TraceID, 10, 0, 7, N'SQL Server Profiler - 4d8f4bca-f08c-4755-b90c-6ec17a6f1275'
	exec sp_trace_setfilter @TraceID, 10, 0, 7, N'DatabaseMail90%'

	/*******************************************************************************************************************************
	-- Configura o tempo minimo para as queries demoradas (em segundos)
	*******************************************************************************************************************************/
	set @bigintfilter = 1000000 * @Tempo_Traces		--  @Tempo_Traces (em segundos)

	exec sp_trace_setfilter @TraceID, 13, 0, 4, @bigintfilter

	set @bigintfilter = null
	exec sp_trace_setfilter @TraceID, 13, 0, 1, @bigintfilter

	exec sp_trace_setfilter @TraceID, 1, 0, 7, N'NO STATS%'

	exec sp_trace_setfilter @TraceID, 1, 0, 7, N'NULL%'

	-- Set the trace status to start.
	exec sp_trace_setstatus @TraceID, 1

	-- Display trace id for future references.
	select TraceID = @TraceID

	goto finish

	error: 
		select ErrorCode = @rc

	finish: 
END

GO

/*******************************************************************************************************************************
-- Criacao do JOB de Traces.
*******************************************************************************************************************************/

USE [msdb]

GO

-- Se o job ja existe, exclui para criar novamente.
IF EXISTS ( SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'DBA - Trace Banco de Dados')
	EXEC msdb.dbo.sp_delete_job @job_name = N'DBA - Trace Banco de Dados', @delete_unused_schedule = 1

GO

BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0

	------------------------------------------------------------------------------------------------------------------------------------	
	-- Seleciona a Categoria do JOB
	------------------------------------------------------------------------------------------------------------------------------------
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name = N'Database Maintenance' AND category_class = 1)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_category @class = N'JOB', @type = N'LOCAL', @name = N'Database Maintenance'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END

	DECLARE @jobId BINARY(16)
	EXEC	@ReturnCode = msdb.dbo.sp_add_job 
			@job_name = N'DBA - Trace Banco de Dados',
			@enabled = 1,
			@notify_level_eventlog = 0,
			@notify_level_email = 0,
			@notify_level_netsend = 0,
			@notify_level_page = 0,
			@delete_level = 0,
			@description = N'No description available.',
			@category_name = N'Database Maintenance',
			@owner_login_name = N'sa',
			@job_id = @jobId OUTPUT
			
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	------------------------------------------------------------------------------------------------------------------------------------	
	-- Cria o Step 1 do JOB - Desabilita o Trace
	------------------------------------------------------------------------------------------------------------------------------------
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
			@job_id = @jobId, 
			@step_name = N'DBA - Desabilita o Trace',
			@step_id = 1,
			@cmdexec_success_code = 0,
			@on_success_action = 3,
			@on_success_step_id = 0,
			@on_fail_action = 3,
			@on_fail_step_id = 0,
			@retry_attempts = 0,
			@retry_interval = 0,
			@os_run_priority = 0,
			@subsystem = N'TSQL',
			@command = N'
declare @Traceid int

select @Traceid = traceid
from fn_trace_getinfo (null)
where cast(value as varchar(100)) like ''%Duracao%''

exec sp_trace_setstatus  @Traceid ,  @status = 0
exec sp_trace_setstatus  @Traceid ,  @status = 2

',
			@database_name = N'master',
			@flags = 0

	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	------------------------------------------------------------------------------------------------------------------------------------
	-- Cria o Step 2 do JOB - Insere registros Traces
	------------------------------------------------------------------------------------------------------------------------------------
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
			@job_id = @jobId, 
			@step_name = N'Insere registros Traces', 
			@step_id = 2, 
			@cmdexec_success_code = 0, 
			@on_success_action = 3, 
			@on_success_step_id = 0, 
			@on_fail_action = 3, 
			@on_fail_step_id = 0, 
			@retry_attempts = 0, 
			@retry_interval = 0, 
			@os_run_priority = 0, 
			@subsystem = N'TSQL', 
			@command = N'Insert Into Traces(TextData, NTUserName, HostName, ApplicationName, LoginName, SPID, Duration, StartTime, 
EndTime,  Reads, Writes, CPU, ServerName,DataBaseName, RowCounts, SessionLoginName)

Select TextData,NTUserName, HostName, ApplicationName, LoginName, SPID, 
cast(Duration /1000/1000.00 as numeric(15,2)) Duration, StartTime,
EndTime, Reads,Writes, CPU, ServerName, DataBaseName, RowCounts, SessionLoginName
FROM :: fn_trace_gettable(''D:\Temp\Duracao.trc'', default)
where Duration is not null
	and rowcounts < 900000000
	and TextData not like ''%exec stpCarga_ContadoresSQL%''
	and TextData not like ''%stpBackup_Log_Todas_Databases%''
	and TextData not like ''%stpCarga_Historico_Waits_Stats%''
	and reads < 900000000', 
			@database_name = N'DBA_MON', 
			@flags = 0

	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	------------------------------------------------------------------------------------------------------------------------------------
	-- Cria o Step 3 do JOB - Exclui o arquivo de trace antigo
	------------------------------------------------------------------------------------------------------------------------------------
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
			@job_id = @jobId, 
			@step_name = N'Exclui o arquivo de trace antigo', 
			@step_id = 3,
			@cmdexec_success_code = 0,
			@on_success_action = 3,
			@on_success_step_id = 0,
			@on_fail_action = 3,
			@on_fail_step_id = 0,
			@retry_attempts = 0,
			@retry_interval = 0,
			@os_run_priority = 0,
			@subsystem=N'CmdExec',
			@command = N'Del "D:\Temp\Duracao.trc" /Q',
			@flags = 0

	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	------------------------------------------------------------------------------------------------------------------------------------
	-- Cria o Step 4 do JOB - Cria o Trace
	------------------------------------------------------------------------------------------------------------------------------------
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
			@job_id = @jobId, 
			@step_name = N'Cria o Trace', 
			@step_id = 4, 
			@cmdexec_success_code = 0, 
			@on_success_action = 1, 
			@on_success_step_id = 0, 
			@on_fail_action = 2, 
			@on_fail_step_id = 0, 
			@retry_attempts = 0, 
			@retry_interval = 0, 
			@os_run_priority = 0, 
			@subsystem = N'TSQL', 
			@command = N'exec DBA_MON.dbo.stpCreate_Trace', 
			@database_name = N'DBA_MON', 
			@flags = 0

	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
		
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	declare @Dt_Atual varchar(8) = convert(varchar(8), getdate(), 112)


	------------------------------------------------------------------------------------------------------------------------------------	
	-- Cria o Schedule do JOB
	------------------------------------------------------------------------------------------------------------------------------------
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule 
			@job_id = @jobId, 
			@name = N'DBA - Traces Banco de Dados', 
			@enabled = 1,
			@freq_type = 4,
			@freq_interval = 1,
			@freq_subday_type = 4,
			@freq_subday_interval = 5,
			@freq_relative_interval = 0,
			@freq_recurrence_factor = 0,
			@active_start_date = @Dt_Atual,
			@active_end_date = 99991231,
			@active_start_time = 100,
			@active_end_time = 235959
		
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'

	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

COMMIT TRANSACTION

GOTO EndSave

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

EndSave:

GO

USE DBA_MON

GO

EXEC [dbo].[stpCreate_Trace]