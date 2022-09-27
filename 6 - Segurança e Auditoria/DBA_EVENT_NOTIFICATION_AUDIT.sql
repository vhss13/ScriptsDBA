/********************************************************************************************************
* Tipo              Data           Autor(es)                           Versão                           *
* Script            26/10/2010     Marcelo Koga/Benes Guislandi        1.0                              *
* Objetivo: Habiliar coleta de eventos de auditoria atravez do Event Notification                       *
*           Histórico coletado inserido na tabela AuditXML do banco DBATIVIT                            *
*                                                                                                       *
* Obs.: 1. Feature habilitada a partir da versão SQL Server 2005                                        *
*       2. Necessário a existência do banco DBATIVIT (onde será armazenado as logs de auditoria)        *
*          Caso queira utilizar outro banco deve-se alterar as referencias ao banco do script           *
*       3. Adicionar/editar os eventos que serão auditados através dos comandos de inserts na tabela    *
*          temporária #MYEVENTS                                                                         *
*                                                                                                       *
* Página de referência web para consulta                                                                *
* http://msdn.microsoft.com/en-US/library/ms186582(v=SQL.90).aspx                                       *
*                                                                                                       *
********************************************************************************************************/

SET NOCOUNT ON

-- Inserir no comando de insert da tabela temporaria os eventos que serão auditados
IF EXISTS (SELECT 1 FROM tempdb..sysobjects WHERE [Id] = OBJECT_ID('tempdb..#MYEVENTS'))
BEGIN
DROP TABLE #MYEVENTS
END
CREATE TABLE #MYEVENTS (ID INT IDENTITY,EVENTS VARCHAR(2000))
--INSERT INTO #MYEVENTS VALUES ('DDL_SERVER_SECURITY_EVENTS')
--INSERT INTO #MYEVENTS VALUES ('DDL_DATABASE_SECURITY_EVENTS')
--INSERT INTO #MYEVENTS VALUES ('ALTER_DATABASE')

-- Identifica se os parametros broker estão habilitados
IF EXISTS(select	name, service_broker_guid, is_trustworthy_on, is_broker_enabled 
			from	sys.databases
			WHERE	name = 'DBATIVIT'
					AND (is_trustworthy_on = 0 OR is_broker_enabled = 0))
BEGIN					
	alter database [DBATIVIT] set trustworthy on
	alter database [DBATIVIT] set enable_broker with no_wait
END
ELSE
	select	name, service_broker_guid, is_trustworthy_on, is_broker_enabled 
			from	sys.databases
			WHERE	name = 'DBATIVIT'
GO

-- Valida se o event notification existe
IF EXISTS(	select	sen.name, d.name
			from	sys.server_event_notifications sen 	join sys.databases d 
					on sen.broker_instance = d.service_broker_guid
			where	d.name = 'DBATIVIT'
					AND sen.name = 'ServerSecurityAudit')
BEGIN
	drop event notification [ServerSecurityAudit]
	on server
END				

-- Valida se o service existe
IF EXISTS(	select	name
			from	sys.services
			where	name = 'AuditService')
BEGIN
	drop service [AuditService]
END		

-- Valida se a queue existe
IF EXISTS(	select	name
			from	sys.service_queues
			where	name = 'AuditQueue')
BEGIN
	drop queue [DBATIVIT].[dbo].[AuditQueue]
END					
					
-- Valida se o routes existe
IF EXISTS(	select	name
			from	sys.routes
			where	name = 'AuditRoute')
BEGIN
	drop route [AuditRoute]
END

-- Cria tabela de auditoria
IF NOT EXISTS(select name from DBATIVIT.sys.objects where name = 'AuditXML')
BEGIN
	USE [DBATIVIT]

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[AuditXML](
	[idAuditXML] [int] IDENTITY(1,1) NOT NULL,
	[eventxml] [xml] NULL,
	[EventType] [sysname] NULL,
	[PostTime] [datetime] NULL,
	[LogDtInclusao] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[AuditXML] ADD DEFAULT (getdate()) FOR [LogDtInclusao]
PRINT 'TABELA [AuditXML] CRIADA COM SUCESSO !!!'
END
GO

-- Cria procedure que popula tabela de auditoria
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uspGetAudit]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[uspGetAudit];
GO

USE [DBATIVIT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspGetAudit]
as
begin
  DECLARE @procTable TABLE(
       service_instance_id UNIQUEIDENTIFIER,
       handle UNIQUEIDENTIFIER,
       message_sequence_number BIGINT,
       service_name NVARCHAR(512),
       service_contract_name NVARCHAR(256),
       message_type_name NVARCHAR(256),
       validation NCHAR,
       message_body VARBINARY(MAX)) ;

  RECEIVE 
      conversation_group_id,
      conversation_handle,
      message_sequence_number,
      service_name,
      service_contract_name,
      message_type_name,
      validation,
      message_body
  FROM AuditQueue
  INTO @procTable

  DECLARE cQueue cursor for
    select message_body from @procTable order by message_sequence_number
  DECLARE @xml XML
  
  open cQueue
  fetch next from cQueue into @xml
  while @@FETCH_STATUS = 0
  begin
    insert into AuditXML(
      EventType, 
      PostTime,
      eventxml) 
    values(
      @xml.value('(/EVENT_INSTANCE/EventType)[1]', 'sysname'),
      @xml.value('(/EVENT_INSTANCE/PostTime)[1]', 'datetime'),
      @xml)
    fetch next from cQueue into @xml
  end
  close cQueue
  Deallocate cQueue
end
GO

-- Cria nova queue
CREATE QUEUE [DBATIVIT].[dbo].[AuditQueue]
  WITH 
    STATUS = ON,
    ACTIVATION (
      PROCEDURE_NAME = [DBATIVIT].[dbo].[uspGetAudit],
      MAX_QUEUE_READERS = 1,
      EXECUTE AS SELF)
GO

-- Cria novo serviço
CREATE SERVICE [AuditService]
 ON QUEUE [AuditQueue] ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification])
GO

-- Cria Route
create route [AuditRoute]
  with
    SERVICE_NAME = 'AuditService',
    ADDRESS = 'LOCAL'
GO

-- Cria event notification
DECLARE @DBATIVIT_service_broker_guid varchar(50)
DECLARE @MYEVENTS varchar(2000)
DECLARE @NR_EVENTS int
DECLARE @cmd varchar(2000)
SELECT  @DBATIVIT_service_broker_guid = service_broker_guid from sys.databases where name = 'DBATIVIT'

IF (SELECT COUNT(*) FROM #MYEVENTS) = 0
BEGIN
PRINT 'Necessário configurar pelo menos 1 evento de auditoria'
END

IF (SELECT COUNT(*) FROM #MYEVENTS) = 1
BEGIN
SELECT  @cmd = 'create event notification [ServerSecurityAudit]' + CHAR(13) +
			'on server for ' + CHAR(13) + EVENTS + CHAR(13) +
			'to service' + CHAR(13) +
			'''' + 'AuditService' + '''' + CHAR(13) +
			',' + '''' + @DBATIVIT_service_broker_guid + '''' FROM #MYEVENTS
--PRINT (@cmd)
EXEC (@cmd)
select 'Habilitado o evento de auditoria: ' + EVENTS FROM #MYEVENTS
END

IF (SELECT COUNT(*) FROM #MYEVENTS) > 1
BEGIN
DECLARE @EVENTID smallint
DECLARE @EVENTNAME VARCHAR(200)
DECLARE CUR_EVENTS CURSOR FOR
SELECT ID,EVENTS from #MYEVENTS WHERE ID <> 1;

SELECT @MYEVENTS = EVENTS from #MYEVENTS WHERE ID = 1;

OPEN CUR_EVENTS;
FETCH NEXT FROM CUR_EVENTS INTO @EVENTID,@EVENTNAME;

WHILE @@FETCH_STATUS = 0
BEGIN

SELECT @MYEVENTS = @MYEVENTS + ',' + @EVENTNAME

FETCH NEXT FROM CUR_EVENTS INTO @EVENTID,@EVENTNAME;

END;
CLOSE CUR_EVENTS;
DEALLOCATE CUR_EVENTS;

SELECT  @cmd = 'create event notification [ServerSecurityAudit]' + CHAR(13) +
			'on server for ' + CHAR(13) + @MYEVENTS + CHAR(13) +
			'to service' + CHAR(13) +
			'''' + 'AuditService' + '''' + CHAR(13) +
			',' + '''' + @DBATIVIT_service_broker_guid + ''''
--PRINT (@cmd)
EXEC (@cmd)
select 'Habilitado os eventos de auditoria: ' + @MYEVENTS
END

-- Query de validação dos eventos coletados
-- USE [DBATIVIT]
-- GO
-- select * from AuditXML