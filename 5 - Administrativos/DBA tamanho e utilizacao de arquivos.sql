SELECT
CAST(100 * (CAST (((sysfiles.size/128.0 -CAST(FILEPROPERTY(sysfiles.name,
 + '' + 'SpaceUsed' + '' + '' ) AS int)/128.0)/(sysfiles.size/128.0))
AS decimal(4,2))) AS varchar(8)) + '' + '' + '%' + '' + '' AS 'FreeSpace%',
CAST(sysfiles.size/128.0 AS int) AS FileSizeMB,
CAST(sysfiles.size/128.0 - CAST(FILEPROPERTY(sysfiles.name,  + '' +
       'SpaceUsed' + '' + '' ) AS int)/128.0 AS int) AS FreeSpaceMB,
sysfiles.name AS LogicalFileName, sysfiles.filename AS PhysicalFileName,
CONVERT(sysname,DatabasePropertyEx('TempDB','Status')) AS Status,
CONVERT(sysname,DatabasePropertyEx('TempDB','Updateability')) AS Updateability,
CONVERT(sysname,DatabasePropertyEx('TempDB','Recovery')) AS RecoveryMode
FROM dbo.sysfiles
