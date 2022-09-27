-- I/O stalls at the database level

SET TRAN ISOLATION LEVEL READ UNCOMMITTED
SELECT DB_NAME(database_id) AS [DatabaseName]
, SUM(CAST(io_stall / 1000.0 AS DECIMAL(20,2))) AS [IO stall (secs)]
, SUM(CAST(num_of_bytes_read / 1024.0 / 1024.0 AS DECIMAL(20,2)))
AS [IO read (MB)]
, SUM(CAST(num_of_bytes_written / 1024.0 / 1024.0 AS DECIMAL(20,2)))
AS [IO written (MB)]
, SUM(CAST((num_of_bytes_read + num_of_bytes_written)
/ 1024.0 / 1024.0 AS DECIMAL(20,2))) AS [TotalIO (MB)]
FROM sys.dm_io_virtual_file_stats(NULL, NULL)
GROUP BY database_id
ORDER BY [IO stall (secs)] DESC