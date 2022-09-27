USE [master];
go
 
-- SET EVERYTHING UP WITH THE SERVICE BROKER
--  We could also do this when creating the DatabaseBackup database
--  as part of the initial package run, or update.
--  Trustworthy allows a stored proc in the current database
--   execute SP_SEND_DBMAIL in msdb
 
ALTER DATABASE DatabaseBackup SET ENABLE_BROKER;
go
ALTER DATABASE DatabaseBackup SET TRUSTWORTHY ON;
go
 
 
USE DatabaseBackup
GO
 
-- Drop the notification if it exists
IF EXISTS ( SELECT  *
            FROM    sys.server_event_notifications
            WHERE   name = N'CaptureDBAEvents' )
    BEGIN
        DROP EVENT NOTIFICATION [CaptureDBAEvents] ON SERVER;
    END
 
-- Drop the route if it exists
IF EXISTS ( SELECT  *
            FROM    sys.routes
            WHERE   name = N'DBAEventRoute' )
    BEGIN
        DROP ROUTE [DBAEventRoute];
    END
 
-- Drop the service if it exists
IF EXISTS ( SELECT  *
            FROM    sys.services
            WHERE   name = N'DBAEventService' )
    BEGIN
        DROP SERVICE [DBAEventService];
    END
 
-- Drop the queue if it exists
IF EXISTS ( SELECT  *
            FROM    sys.service_queues
            WHERE   name = N'DBAEventQueue' )
    BEGIN
        DROP QUEUE [DBAEventQueue];
    END
 
IF EXISTS ( SELECT *
            FROM MASTER.sys.event_notifications
            WHERE name = N'CaptureDBAEvents' )
    BEGIN
        DROP EVENT NOTIFICATION [CaptureDBAEvents] ON SERVER
    END
 
--  Create a service broker queue to hold the events
CREATE QUEUE [DBAEventQueue]
WITH STATUS=ON;
GO
 
--  Create a service broker service receive the events
CREATE SERVICE [DBAEventService]
ON QUEUE [DBAEventQueue] ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
GO
 
-- Create a service broker route to the service
CREATE ROUTE [DBAEventRoute]
WITH SERVICE_NAME = 'DBAEventService',
ADDRESS = 'LOCAL';
GO
 
-- Create the event notification to capture the events
CREATE EVENT NOTIFICATION [CaptureDBAEvents]
ON SERVER
WITH FAN_IN
FOR CREATE_DATABASE, DROP_DATABASE, CREATE_LOGIN, DROP_LOGIN, CREATE_USER, DROP_USER, BLOCKED_PROCESS_REPORT, DEADLOCK_GRAPH, ADD_ROLE_MEMBER, ADD_SERVER_ROLE_MEMBER
TO SERVICE 'DBAEventService', 'current database';
GO





USE DatabaseBackup
GO
 
-- Drop the procedure if it exists
IF EXISTS ( SELECT *
            FROM sys.procedures
            WHERE   name = N'ProcessEvents' )
    BEGIN
        DROP PROCEDURE [ProcessEvents];
    END
GO
 
CREATE PROCEDURE [dbo].[ProcessEvents]
WITH EXECUTE AS OWNER
AS   
    SET XACT_ABORT ON;
    DECLARE @eventType VARCHAR(128);
    DECLARE @messagetypename NVARCHAR(256);
    DECLARE @ch UNIQUEIDENTIFIER;
 
    DECLARE @serverName VARCHAR(128);
    DECLARE @postTime VARCHAR(128);
    DECLARE @databaseName VARCHAR(128);
    DECLARE @duration VARCHAR(128);
    DECLARE @growthPages INT;  
    DECLARE @userName VARCHAR(128);
    DECLARE @loginInfo VARCHAR(256);
    DECLARE @SID VARCHAR(128);
 
    DECLARE @messageBody XML;
    DECLARE @emailTo VARCHAR(50);
    DECLARE @emailBody VARCHAR(MAX);
    DECLARE @subject varchar(150);
 
    SET @emailTo = '<DBA TEAM EMAIL HERE>@gmail.com;  
 
    WHILE (1=1)
    BEGIN        
        BEGIN TRY               
            BEGIN TRANSACTION              
                WAITFOR (                       
                    RECEIVE TOP(1)   
                    @ch = conversation_handle,                                                           
                    @messagetypename = message_type_name,                               
                    @messagebody = CAST(message_body AS XML)                       
                    FROM DBAEventQueue             
                ), TIMEOUT 60000;            
                IF (@@ROWCOUNT = 0)             
                BEGIN                    
                    ROLLBACK TRANSACTION;                      
                    BREAK;               
                END               
                IF (@messagetypename = 'http://schemas.microsoft.com/SQL/Notifications/EventNotification')               
                BEGIN 
                    --  Get the common information
                    SELECT @eventType = COALESCE(@messagebody.value('(/EVENT_INSTANCE/EventType)[1]','varchar(128)'),'UNKNOWN'),
                        @serverName = COALESCE(@messagebody.value('(/EVENT_INSTANCE/ServerName)[1]','varchar(128)'),'UNKNOWN'),
                        @postTime = COALESCE(CAST(@messagebody.value('(/EVENT_INSTANCE/PostTime)[1]','datetime') AS VARCHAR),'UNKNOWN');
                      
                    SELECT  @emailBody = 'The following event occurred:' + CHAR(10)
                        + CAST('Event Type: ' AS CHAR(25)) + @EventType + CHAR(10)
                        + CAST('ServerName: ' AS CHAR(25)) + @ServerName + CHAR(10)
                        + CAST('PostTime: ' AS CHAR(25)) + @PostTime + CHAR(10);
                     
                    -- Now the custom XML fields depending on the Event Type
                    IF (@EventType like '%_FILE_AUTO_GROW')
                    BEGIN
                        SELECT @duration = COALESCE(@messagebody.value('(/EVENT_INSTANCE/Duration)[1]','varchar(128)'),'UNKNOWN'),
                            @growthPages = COALESCE(@messagebody.value('(/EVENT_INSTANCE/IntegerData)[1]', 'int'),'UNKNOWN'),
                            @databaseName = COALESCE(@messagebody.value('(/EVENT_INSTANCE/DatabaseName)[1]','varchar(128)'),'UNKNOWN');
                     
                        SELECT @emailBody = @emailBody
                            + CAST('Duration: ' AS CHAR(25)) + @Duration + CHAR(10)
                            + CAST('GrowthSize_KB: ' AS CHAR(25)) + CAST(( @GrowthPages * 8 ) AS VARCHAR(20)) + CHAR(10)
                            + CAST('DatabaseName: ' AS CHAR(25)) + @DatabaseName + CHAR(10);
                    END
                    ELSE IF (@EventType like '%_DATABASE')
                    BEGIN
                        SELECT @userName = COALESCE(@messageBody.value('/EVENT_INSTANCE[1]/LoginName[1]', 'varchar(128)'),'UNKNOWN'),
                            @DatabaseName = COALESCE(@messagebody.value('(/EVENT_INSTANCE/DatabaseName)[1]','varchar(128)'),'UNKNOWN');
                     
                        SELECT @emailBody = @emailBody
                            + CAST('User: ' AS CHAR(25)) + @userName + CHAR(10)
                            + CAST('DatabaseName: ' AS CHAR(25)) + @DatabaseName + CHAR(10);
                    END
                    ELSE IF (@EventType like '%_LOGIN')
                    BEGIN
                        SELECT @userName = COALESCE(@messageBody.value('/EVENT_INSTANCE[1]/LoginName[1]', 'varchar(128)'),'UNKNOWN'),
                            @loginInfo = COALESCE(@messageBody.value('/EVENT_INSTANCE[1]/ObjectName[1]', 'varchar(256)'),'UNKNOWN'),
                            @SID = COALESCE(@messageBody.value('/EVENT_INSTANCE[1]/SID[1]', 'varchar(128)'),'UNKNOWN');
                     
                        SELECT @emailBody = @emailBody
                            + CAST('User: ' AS CHAR(25)) + @userName + CHAR(10)
                            + CAST('New User: ' AS CHAR(25)) + @loginInfo + CHAR(10)
                            + CAST('New SID: ' AS CHAR(25)) + @SID + CHAR(10);
                    END
                    ELSE IF (@EventType like '%_ROLE_MEMBER')
                    BEGIN
                        DECLARE @roleName VARCHAR(128);
                        DECLARE @command VARCHAR(128);
                        SELECT @userName = COALESCE(@messageBody.value('/EVENT_INSTANCE[1]/LoginName[1]', 'varchar(128)'),'UNKNOWN'),
                            @loginInfo = COALESCE(@messageBody.value('/EVENT_INSTANCE[1]/ObjectName[1]', 'varchar(256)'),'UNKNOWN'),
                            @roleName = COALESCE(@messageBody.value('/EVENT_INSTANCE[1]/RoleName[1]', 'varchar(256)'),'UNKNOWN'),
                            @command = COALESCE(@messageBody.value('/EVENT_INSTANCE[1]/TSQLCommand[1]/CommandText[1]', 'varchar(256)'),'UNKNOWN');
                        SELECT @emailBody = @emailBody
                            + CAST('User: ' AS CHAR(25)) + @userName + CHAR(10)
                            + CAST('Affected User: ' AS CHAR(25)) + @loginInfo + CHAR(10)
                            + CAST('New Role: ' AS CHAR(25)) + @roleName + CHAR(10)
                            + CAST('Command issued: ' AS CHAR(25)) + @command + CHAR(10);
                    END
                    ELSE  -- TRAP ALL OTHER EVENTS AND SPIT OUT JUST THE XML - We can pretty it up later <img src="http://www.the-fays.net/blog/wp-includes/images/smilies/icon_smile.gif" alt=":)" class="wp-smiley">
                    BEGIN
                        SELECT @emailBody = CAST(@messagebody AS VARCHAR(max));
                    END
 
                    -- Send email using Database Mail
                    SELECT @subject = @eventType + ' on ' + @serverName;
                    EXEC msdb.dbo.sp_send_dbmail               
                        @profile_name = 'DBA Email', -- your defined email profile
                        @recipients = @emailTo, -- your email
                        @subject = @subject,
                        @body = @emailBody;              
                END             
                IF (@messagetypename = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')           
                BEGIN                       
                    DECLARE @errorcode INT;                         
                    DECLARE @errormessage NVARCHAR(3000) ;                
                    -- Extract the error information from the sent message                 
                    SET @errorcode = (SELECT @messagebody.value(                       
                        N'declare namespace brokerns="http://schemas.microsoft.com/SQL/ServiceBroker/Error";                        
                        (/brokerns:Error/brokerns:Code)[1]', 'int'));                 
                    SET @errormessage = (SELECT @messagebody.value(                       
                        N'declare namespace brokerns="http://schemas.microsoft.com/SQL/ServiceBroker/Error";                       
                        (/brokerns:Error/brokerns:Description)[1]', 'nvarchar(3000)'));                 
                    -- Log the error
                    END CONVERSATION @ch WITH CLEANUP;                            
                END
                IF (@messagetypename = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')               
                BEGIN                      
                    -- End the conversation                       
                    END CONVERSATION @ch WITH CLEANUP;               
                END                                
            COMMIT TRANSACTION;  
        END TRY       
        BEGIN CATCH            
            ROLLBACK TRANSACTION;               
            DECLARE @ErrorNum INT;               
            DECLARE @ErrorMsg NVARCHAR(3000);               
            SELECT @ErrorNum = ERROR_NUMBER(), @ErrorMsg = ERROR_MESSAGE();               
            -- log the error               
            BREAK;       
        END CATCH  
    END
GO

-- Activate the procedure with the Queue
ALTER QUEUE [DBAEventQueue]
   WITH STATUS=ON,
      ACTIVATION
         (STATUS=ON,
          PROCEDURE_NAME = [ProcessEvents],
          MAX_QUEUE_READERS = 1,
          EXECUTE AS OWNER);
GO

