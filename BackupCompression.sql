--Verificando a taxa de compress�o dos
--arquivos de backup
SELECT
	[name],
	backup_size,
	compressed_backup_size,
	backup_size/compressed_backup_size AS Ratio	
FROM
	msdb..backupset