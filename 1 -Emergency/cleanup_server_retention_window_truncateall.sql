--EXEC [internal].[cleanup_server_retention_window_truncateall]

CREATE PROCEDURE [internal].[cleanup_server_retention_window_truncateall]
--WITH EXECUTE AS 'AllSchemaOwner'
AS  
    
----- STRUCTURE OF TABLES:

--[internal].[operations]
--  [internal].[executions]
--      [internal].[executable_statistics]
--      [internal].[execution_component_phases]d
--      [internal].[execution_data_statistics]
--      [internal].[execution_data_taps]
--      [internal].[execution_parameter_values]
--      [internal].[execution_property_override_values]
--  [internal].[extended_operation_info]
--  [internal].[operation_messages] --(DATA HEAVY)
--      [internal].[event_messages] --(DATA HEAVY)
--          [internal].[event_message_context]
--  [internal].[operation_os_sys_info]
--  [internal].[operation_permissions]
--  [internal].[validations]

    SET NOCOUNT ON
    
    DECLARE @enable_clean_operation bit
    DECLARE @retention_window_length INT
    
    DECLARE @caller_name nvarchar(256)
    DECLARE @caller_sid  varbinary(85)
    DECLARE @operation_id BIGINT
    
    EXECUTE AS CALLER
        SET @caller_name =  SUSER_NAME()
        SET @caller_sid =   SUSER_SID()
    REVERT
         
    
    BEGIN TRY
        SELECT @enable_clean_operation = CONVERT(bit, property_value) 
            FROM [catalog].[catalog_properties]
            WHERE property_name = 'OPERATION_CLEANUP_ENABLED'
        
        IF @enable_clean_operation = 1
        BEGIN
            SELECT @retention_window_length = CONVERT(INT,property_value)  
                FROM [catalog].[catalog_properties]
                WHERE property_name = 'RETENTION_WINDOW'
                
            IF @retention_window_length <= 0 
            BEGIN
                RAISERROR(27163    ,16,1,'RETENTION_WINDOW')
            END
            
            INSERT INTO [internal].[operations] (
                [operation_type],  
                [created_time], 
                [object_type],
                [object_id],
                [object_name],
                [STATUS], 
                [start_time],
                [caller_sid], 
                [caller_name]
                )
            VALUES (
                2,
                SYSDATETIMEOFFSET(),
                NULL,                     
                NULL,                     
                NULL,                     
                1,      
                SYSDATETIMEOFFSET(),
                @caller_sid,            
                @caller_name            
                ) 
            SET @operation_id = SCOPE_IDENTITY() 






            -- Remove all [internal].[executions] dependancies
            TRUNCATE TABLE [internal].[executable_statistics]
            TRUNCATE TABLE [internal].[execution_component_phases]
            TRUNCATE TABLE [internal].[execution_data_statistics]
            TRUNCATE TABLE [internal].[execution_data_taps]
            TRUNCATE TABLE [internal].[execution_parameter_values]
            TRUNCATE TABLE [internal].[execution_property_override_values]


            -- Remove all [internal].[event_message_context] dependancies
            TRUNCATE TABLE [internal].[event_message_context]

            -- Remove all non-dependant tables
            TRUNCATE TABLE [internal].[operation_os_sys_info]
            TRUNCATE TABLE [internal].[operation_permissions]
            TRUNCATE TABLE [internal].[validations]
            TRUNCATE TABLE [internal].[extended_operation_info]

            -- Deal with [internal].[event_messages] and [internal].[operation_messages]
            ALTER TABLE [internal].[event_message_context] DROP CONSTRAINT [FK_EventMessageContext_EventMessageId_EventMessages]
        
            TRUNCATE TABLE internal.event_messages
        
            ALTER TABLE [internal].[event_message_context]  WITH CHECK ADD  CONSTRAINT [FK_EventMessageContext_EventMessageId_EventMessages] FOREIGN KEY([event_message_id])
            REFERENCES [internal].[event_messages] ([event_message_id])
            ON DELETE CASCADE

            ALTER TABLE [internal].[event_messages] DROP CONSTRAINT [FK_EventMessages_OperationMessageId_OperationMessage]
        
            TRUNCATE TABLE [internal].[operation_messages]

            ALTER TABLE [internal].[event_messages]  WITH CHECK ADD  CONSTRAINT [FK_EventMessages_OperationMessageId_OperationMessage] FOREIGN KEY([event_message_id])
            REFERENCES [internal].[operation_messages] ([operation_message_id])
            ON DELETE CASCADE

            -- Deal with [internal].[executions]

            ALTER TABLE [internal].[executable_statistics] DROP CONSTRAINT [FK_ExecutableStatistics_ExecutionId_Executions]
            ALTER TABLE [internal].[execution_component_phases] DROP CONSTRAINT [FK_ExecCompPhases_ExecutionId_Executions]
            ALTER TABLE [internal].[execution_data_statistics] DROP CONSTRAINT [FK_ExecDataStat_ExecutionId_Executions]
            ALTER TABLE [internal].[execution_data_taps] DROP CONSTRAINT [FK_ExecDataTaps_ExecutionId_Executions]
            ALTER TABLE [internal].[execution_parameter_values] DROP CONSTRAINT [FK_ExecutionParameterValue_ExecutionId_Executions]
            ALTER TABLE [internal].[execution_property_override_values] DROP CONSTRAINT [FK_ExecutionPropertyOverrideValue_ExecutionId_Executions]

            TRUNCATE TABLE [internal].[executions]

            ALTER TABLE [internal].[execution_property_override_values]  WITH CHECK ADD  CONSTRAINT [FK_ExecutionPropertyOverrideValue_ExecutionId_Executions] FOREIGN KEY([execution_id])
            REFERENCES [internal].[executions] ([execution_id])
            ON DELETE CASCADE

            ALTER TABLE [internal].[execution_parameter_values]  WITH CHECK ADD  CONSTRAINT [FK_ExecutionParameterValue_ExecutionId_Executions] FOREIGN KEY([execution_id])
            REFERENCES [internal].[executions] ([execution_id])
            ON DELETE CASCADE

            ALTER TABLE [internal].[execution_data_taps]  WITH CHECK ADD  CONSTRAINT [FK_ExecDataTaps_ExecutionId_Executions] FOREIGN KEY([execution_id])
            REFERENCES [internal].[executions] ([execution_id])
            ON DELETE CASCADE

            ALTER TABLE [internal].[execution_data_statistics]  WITH CHECK ADD  CONSTRAINT [FK_ExecDataStat_ExecutionId_Executions] FOREIGN KEY([execution_id])
            REFERENCES [internal].[executions] ([execution_id])
            ON DELETE CASCADE
        
            ALTER TABLE [internal].[execution_component_phases]  WITH CHECK ADD  CONSTRAINT [FK_ExecCompPhases_ExecutionId_Executions] FOREIGN KEY([execution_id])
            REFERENCES [internal].[executions] ([execution_id])
            ON DELETE CASCADE
        
            ALTER TABLE [internal].[executable_statistics]  WITH CHECK ADD  CONSTRAINT [FK_ExecutableStatistics_ExecutionId_Executions] FOREIGN KEY([execution_id])
            REFERENCES [internal].[executions] ([execution_id])
            ON DELETE CASCADE
        

            -- Deal with [internal].[operations]
            DECLARE @deleted_ops TABLE(operation_id BIGINT, operation_type SMALLINT)

            DELETE --TOP (@delete_batch_size)
            FROM [internal].[operations] 
            OUTPUT DELETED.operation_id, DELETED.operation_type INTO @deleted_ops
            WHERE operation_id != @operation_id

            
            
            DECLARE @execution_id BIGINT
            DECLARE @sqlString              nvarchar(1024)
            DECLARE @key_name               [internal].[adt_name]
            DECLARE @certificate_name       [internal].[adt_name]
            
            
            DECLARE execution_cursor CURSOR LOCAL FOR 
                SELECT operation_id FROM @deleted_ops 
                WHERE operation_type = 200
            
            OPEN execution_cursor
            FETCH NEXT FROM execution_cursor INTO @execution_id
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @key_name = 'MS_Enckey_Exec_'+CONVERT(VARCHAR,@execution_id)
                SET @certificate_name = 'MS_Cert_Exec_'+CONVERT(VARCHAR,@execution_id)
                SET @sqlString = 'IF EXISTS (SELECT name FROM sys.symmetric_keys WHERE name = ''' + @key_name +''') '
                    +'DROP SYMMETRIC KEY '+ @key_name
                    EXECUTE sp_executesql @sqlString
                SET @sqlString = 'IF EXISTS (select name from sys.certificates WHERE name = ''' + @certificate_name +''') '
                    +'DROP CERTIFICATE '+ @certificate_name
                    EXECUTE sp_executesql @sqlString
                FETCH NEXT FROM execution_cursor INTO @execution_id
            END
            CLOSE execution_cursor
            DEALLOCATE execution_cursor

            END
    END TRY
    BEGIN CATCH
        
        
        IF (CURSOR_STATUS('local', 'execution_cursor') = 1 
            OR CURSOR_STATUS('local', 'execution_cursor') = 0)
        BEGIN
            CLOSE execution_cursor
            DEALLOCATE execution_cursor            
        END
        
        UPDATE [internal].[operations]
            SET [STATUS] = 4,
            [end_time] = SYSDATETIMEOFFSET()
            WHERE [operation_id] = @operation_id;       
        THROW
    END CATCH
    
    RETURN 0