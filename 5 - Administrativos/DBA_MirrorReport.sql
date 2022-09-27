DECLARE @SQLString VARCHAR(3000)  
DECLARE @MinId INT  
DECLARE @MaxId INT  
DECLARE @DBName VARCHAR(255)  
  
SELECT A.NAME AS DATABASE_NAME,  
  CASE   
  WHEN B.mirroring_state = 0 then 'Suspended'  
  WHEN B.mirroring_state = 1 then 'Disconnected from the other partner'  
  WHEN B.mirroring_state = 2 then 'Synchronizing'  
  WHEN B.mirroring_state = 3 then 'Pending Failover'  
  WHEN B.mirroring_state = 4 then 'Synchronized'  
  WHEN B.mirroring_state = 5 then 'The partners are not synchronized. Failover is not possible now.'  
  WHEN B.mirroring_state = 6 then 'The partners are synchronized. Failover is potentially possible'  
  WHEN B.mirroring_state is NULL then 'Database is inaccessible or is not mirrored.'  
 END AS MIRROR_STATE  
FROM sys.databases A,  
  sys.database_mirroring B  
WHERE a.database_id = B.database_id  
AND a.NAME not in ('master','model','msdb','tempdb','DBATIVIT')
ORDER BY a.name  

DECLARE @tblDBName TABLE  
(RowId INT IDENTITY(1,1),  
DBName VARCHAR(255),  
DBId INT)  
  
INSERT INTO @tblDBName (DBName,DBId)  
SELECT a.Name,a.database_id   
FROM master.sys.databases A,  
     master.sys.database_mirroring B  
WHERE a.database_id = B.database_id  
AND mirroring_state IS NOT NULL  
ORDER BY a.name  
  
SELECT @MinId = MIN(RowId),  
@MaxId = MAX(RowId)  
FROM @tblDBName  
  
WHILE (@MinId <= @MaxId)  
BEGIN  
SELECT @DBName = [DBName]  
FROM @tblDBName  
WHERE RowId = @MinId  
  
SELECT @SQLString =  
'EXEC msdb.sys.sp_dbmmonitorresults @database_name=N' + '''' +   
@DBNAME + '''' + ', @mode = 0, @update_table = 1'  
  
--PRINT @SQLString  
EXEC (@SQLString)  
  
SELECT @MinId = @MInId + 1  
END  