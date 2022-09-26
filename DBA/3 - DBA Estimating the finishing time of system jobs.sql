-- Estimating the finishing time of system jobs
--ALTER INDEX REORGANIZE
-- AUTO_SHRINK option with ALTER DATABASE
--BACKUP DATABASE
--CREATE INDEX
-- DBCC CHECKDB
-- DBCC CHECKFILEGROUP
-- DBCC CHECKTABLE
-- DBCC INDEXDEFRAG
-- DBCC SHRINKDATABASE
-- DBCC SHRINKFILE
-- KILL (Transact-SQL)
-- RESTORE DATABASE
-- UPDATE STATISTICS


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT r.percent_complete
, DATEDIFF(MINUTE, start_time, GETDATE()) AS Age
, DATEADD(MINUTE, DATEDIFF(MINUTE, start_time, GETDATE()) /
percent_complete * 100, start_time) AS EstimatedEndTime
, t.Text AS ParentQuery
, SUBSTRING (t.text,(r.statement_start_offset/2) + 1,
((CASE WHEN r.statement_end_offset = -1
THEN LEN(CONVERT(NVARCHAR(MAX), t.text)) * 2
ELSE r.statement_end_offset
END - r.statement_start_offset)/2) + 1) AS IndividualQuery
, start_time
, DB_NAME(Database_Id) AS DatabaseName
, Status
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(sql_handle) t
WHERE session_id > 50
AND percent_complete > 0
ORDER BY percent_complete DESC
