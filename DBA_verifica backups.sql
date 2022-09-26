--Verificação de Bancos Ativos sem Backup Full
Print 'Verificação de Bancos Ativos sem Backup Full'
Print '--------------------------------------------'
Select @@servername Instância, name 
from master..sysdatabases With (Nolock) 
Where status & 2016 = 0 and 
name not in (Select database_name From msdb..backupset With (Nolock) where type = 'D') and
name not in ('tempdb')
Order by name

--Verificação da Periodicidade do Backup Full
Print 'Verificação da Periodicidade do Backup Full'
Print '-------------------------------------------'
Select @@servername Instância, m1.database_name Db, 
--Len(Ltrim(Rtrim(m1.database_name))) Tam20,
m1.backup_start_date DtPenBckp, m3.backup_start_date DtUltBckp,
Datediff(hh,m1.backup_start_date,m3.backup_start_date) 'PerBkp',
Case When Datediff(hh,m1.backup_start_date,m3.backup_start_date) <= 48 Then
'Backup Full Diário' Else 'Período Maior que 48 horas !!!' 
End 'Status (<= 48 horas Diário)'
From
msdb..backupset m1 With (Nolock),
msdb..backupset m3 With (Nolock),
(
Select m1.database_name, max(m1.backup_set_id) MaxId 
From msdb..backupset m1 With (Nolock), 
(
Select database_name, max(backup_set_id) MaxId
From msdb..backupset With (Nolock) 
Where type = 'D' and 
database_name in 
(
Select name from master..sysdatabases With (Nolock) 
Where status & 2016 = 0)
group by database_name
) q2
Where m1.type = 'D' and 
m1.database_name in (Select name from master..sysdatabases With (Nolock) 
Where status & 2016 = 0) And m1.database_name = q2.database_name and 
m1.backup_set_id < q2.MaxId
group by m1.database_name
) q1,
(
Select database_name, max(backup_set_id) MaxId
From msdb..backupset With (Nolock) 
Where type = 'D' and 
database_name in 
(
Select name from master..sysdatabases With (Nolock) Where status & 2016 = 0
)
group by database_name
) q3
Where q1.database_name = q3.database_name and
m1.backup_set_id = q1.MaxId and
m3.backup_set_id = q3.MaxId
order by q1.database_name

--Verificação de Bancos Ativos sem Backup de Log
Print 'Verificação de Bancos Ativos sem Backup de Log'
Print '----------------------------------------------'
Select @@servername Instância, name from master..sysdatabases With (Nolock) 
Where status & 2016 = 0 and 
name not in (
Select database_name From msdb..backupset With (Nolock) where type = 'L') and
name not in ('tempdb')
Order by name

--Verificação da Periodicidade do Backup de Log
Print 'Verificação da Periodicidade do Backup de Log'
Print '---------------------------------------------'
Select @@servername Instância, m1.database_name Db,
m1.backup_start_date DtPenBckp, m3.backup_start_date DtUltBckp,
Datediff(hour,m1.backup_start_date,m3.backup_start_date) 'PerHour',
Datediff(minute,m1.backup_start_date,m3.backup_start_date) 'PerMin',
Case When Datediff(hh,m1.backup_start_date,m3.backup_start_date) <= 12 Then
'Backup Log' Else 'Período Maior que 12 horas !!!' 
End 'Status (<= 12 horas)'
From
msdb..backupset m1 With (Nolock),
msdb..backupset m3 With (Nolock),
(
Select m1.database_name, max(m1.backup_set_id) MaxId 
From msdb..backupset m1 With (Nolock), 
(
Select database_name, max(backup_set_id) MaxId
From msdb..backupset With (Nolock) 
Where type = 'L' and 
database_name in 
(
Select name from master..sysdatabases With (Nolock) 
Where status & 2016 = 0)
group by database_name
) q2
Where m1.type = 'L' and 
m1.database_name in (Select name from master..sysdatabases With (Nolock) 
Where status & 2016 = 0) And m1.database_name = q2.database_name and 
m1.backup_set_id < q2.MaxId
group by m1.database_name
) q1,
(
Select database_name, max(backup_set_id) MaxId
From msdb..backupset With (Nolock) 
Where type = 'L' and 
database_name in 
(
Select name from master..sysdatabases With (Nolock) Where status & 2016 = 0
)
group by database_name
) q3
Where q1.database_name = q3.database_name and
m1.backup_set_id = q1.MaxId and
m3.backup_set_id = q3.MaxId
order by q1.database_name
