--Listar os últimos backups realizados com SUCESSO
SELECT  sd.name,
        CASE bs.TYPE
			WHEN 'D' THEN 'database'
			WHEN 'L' THEN 'log'
			WHEN 'I' THEN 'differential'
			WHEN 'F' THEN 'filegroup'
			WHEN 'G' THEN 'diff file'
			WHEN 'P' THEN 'partial'
			WHEN 'Q' THEN 'partial differential'
			ELSE 'other'
		END AS Type,
        bs.database_name,
        max(bs.backup_start_date) as last_backup
FROM    master..sysdatabases sd
        Left outer join msdb..backupset bs on rtrim(bs.database_name) = rtrim(sd.name)
        left outer JOIN msdb..backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
--WHERE sd.name = 'DBA_Info' and bs.backup_start_date > getdate() - 10
Group by sd.name,
        bs.TYPE,
        bs.database_name
Order by sd.name,last_backup
