--Utilizando as DMVs e DMFs da categoria sys.dm_exec, podemos listar informações
--detalhadas sobre as conexões existentes em uma instância de SQL Server, inclusive
--quais as queries que cada Login está executando no momento
SELECT
	sys.dm_exec_sessions.session_id,
	sys.dm_exec_sessions.host_name,
	sys.dm_exec_sessions.program_name,
	sys.dm_exec_sessions.client_interface_name,
	sys.dm_exec_sessions.login_name,
	sys.dm_exec_sessions.nt_domain,
	sys.dm_exec_sessions.nt_user_name,
	sys.dm_exec_connections.client_net_address,
	sys.dm_exec_connections.local_net_address,
	sys.dm_exec_connections.connection_id,
	sys.dm_exec_connections.parent_connection_id,
	sys.dm_exec_connections.most_recent_sql_handle,
	(SELECT [Text] FROM master.sys.dm_exec_sql_text(sys.dm_exec_connections.most_recent_sql_handle )) as sqlscript,
	(SELECT DB_NAME([dbid]) FROM master.sys.dm_exec_sql_text(sys.dm_exec_connections.most_recent_sql_handle )) as databasename,
	(SELECT OBJECT_ID([objectid]) FROM master.sys.dm_exec_sql_text(sys.dm_exec_connections.most_recent_sql_handle )) as objectname
FROM
	sys.dm_exec_sessions 
INNER JOIN 
	sys.dm_exec_connections
ON 
	sys.dm_exec_connections.session_id = sys.dm_exec_sessions.session_id