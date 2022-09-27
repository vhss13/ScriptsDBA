SELECT * INTO trc 
FROM fn_trace_gettable ('C:\Program Files\Microsoft SQL Server\MSSQL10_50.SQL08\MSSQL\Log\log_19.trc',default)


SELECT   DB_NAME(DatabaseID) AS [Database] 
        ,HostName 
        ,ApplicationName 
        ,LoginName 
        ,StartTime 
        ,ObjectID 
        ,EventClass 
        ,ObjectName 
        ,DatabaseName 
FROM trc 