SELECT TOP 10
execution_count ,
statement_start_offset AS stmt_start_offset ,
sql_handle ,
plan_handle ,
total_logical_reads / execution_count AS avg_logical_reads ,
total_logical_writes / execution_count AS avg_logical_writes ,
total_physical_reads / execution_count AS avg_physical_reads ,
t.text
FROM sys.dm_exec_query_stats AS s
CROSS APPLY sys.dm_exec_sql_text(s.sql_handle) AS t
ORDER BY avg_physical_reads DESC