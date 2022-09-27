-- cpu number

SELECT cpu_count AS [Logical CPUs]
,cpu_count / hyperthread_ratio AS [Physical CPUs]
FROM sys.dm_os_sys_info



--If you’re using SQL Server 2005, you can discover when the computer was restarted by
--running this SQL snippet:

SELECT DATEADD(ss, -(ms_ticks / 1000), GetDate()) AS [Start dateTime]
FROM sys.dm_os_sys_info