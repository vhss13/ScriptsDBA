select top 10 database_name,
              CASE 
                WHEN Type = 'd' THEN 'Full'
                WHEN Type = 'i' THEN 'Diferencial'
                WHEN Type = 'l' THEN 'Log'
              END as Backup_Type,
              (convert(int,backup_size/1024/1024)) as BackupSize_Mb,
              backup_start_date,
              backup_finish_date
 from msdb.dbo.backupset
 where  type = 'd'
-- and database_name = 'Maritima_Produção'
 order by backup_start_date desc





-- Find the backup full
SELECT Database_Name, 
    CONVERT( SmallDateTime , MAX(Backup_Finish_Date)) as Last_Backup, 
    DATEDIFF(d, MAX(Backup_Finish_Date), Getdate()) as Days_Since_Last
FROM MSDB.dbo.BackupSet
WHERE Type = 'd'
GROUP BY Database_Name
ORDER BY 3 DESC
Go

-- Find the backup Diff
SELECT Database_Name, 
    CONVERT( SmallDateTime , MAX(Backup_Finish_Date)) as Last_Backup, 
    DATEDIFF(d, MAX(Backup_Finish_Date), Getdate()) as Days_Since_Last
FROM MSDB.dbo.BackupSet
WHERE Type = 'i'
GROUP BY Database_Name
ORDER BY 3 DESC

-- Find the backup Log
SELECT Database_Name, 
    CONVERT( SmallDateTime , MAX(Backup_Finish_Date)) as Last_Backup, 
    DATEDIFF(d, MAX(Backup_Finish_Date), Getdate()) as Days_Since_Last
FROM MSDB.dbo.BackupSet
WHERE Type = 'l'
GROUP BY Database_Name
ORDER BY 3 DESC


--===============================================================================

select top 12 BS.database_name,
              CASE WHEN BS.type = 'd' THEN 'Full'
                   WHEN BS.type = 'i' THEN 'Diferencial'
                   WHEN BS.type = 'l' THEN 'Log'
              END as Backup_Type,
              (convert(int,backup_size/1024/1024)) as BackupSize_Mb,
              bmf.physical_device_name,
              backup_start_date, backup_finish_date
 from msdb.dbo.backupset BS, msdb.dbo.backupmediafamily BMF
 where bmf.media_set_id = bs.media_set_id
 and type = 'i'
-- and database_name in ('xxxx')
 order by backup_start_date desc