IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#dbsize1'))
BEGIN
DROP TABLE #dbsize1
END

IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#dbs1'))
BEGIN
DROP TABLE #dbs1
END

IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#ls'))
BEGIN
DROP TABLE #ls
END

create table #ls (name varchar(255), LogSize real, LogSpaceUsed real, Status int)

insert #ls exec ('dbcc sqlperf(logspace)')

declare @name varchar(255), @sql varchar(1000);

select d.name, DATABASEPROPERTYEX(d.name, 'Status') Status,
case when DATABASEPROPERTYEX(d.name, 'IsAutoCreateStatistics') = 1
then 'ON' else 'OFF' end AutoCreateStatistics,
case when DATABASEPROPERTYEX(d.name, 'IsAutoUpdateStatistics') = 1
then 'ON' else 'OFF' end AutoUpdateStatistics,
case when DATABASEPROPERTYEX(d.name, 'IsAutoShrink') = 1
then 'ON' else 'OFF' end AutoShrink,
case when DATABASEPROPERTYEX(d.name, 'IsAutoClose') = 1
then 'ON' else 'OFF' end AutoClose,
DATABASEPROPERTYEX(d.name, 'Collation') Collation,
DATABASEPROPERTYEX(d.name, 'Updateability') Updateability,
DATABASEPROPERTYEX(d.name, 'UserAccess') UserAccess,
d.cmptlevel CompatibilityLevel,
DATABASEPROPERTYEX(d.name, 'Recovery') RecoveryModel,
convert(bigint, 0) as Size, convert(bigint, 0) Used,
case when sum(NumberReads+NumberWrites) > 0
then sum(IoStallMS)/sum(NumberReads+NumberWrites) else -1 end AvgIoMs,
ls.LogSize, ls.LogSpaceUsed,
b.backup_start_date LastBackup
into #dbs1
from master.dbo.sysdatabases as d
left join msdb..backupset b
on d.name = b.database_name and b.backup_start_date = (
select max(backup_start_date)
from msdb..backupset
where database_name = b.database_name
and type = 'D')
left join ::fn_virtualfilestats(-1, -1) as vfs
on d.dbid = vfs.DbId
join #ls as ls
on d.name = ls.name
group by d.name, DATABASEPROPERTYEX(d.name, 'Status'),
case when DATABASEPROPERTYEX(d.name, 'IsAutoCreateStatistics') = 1
then 'ON' else 'OFF' end,
case when DATABASEPROPERTYEX(d.name, 'IsAutoUpdateStatistics') = 1
then 'ON' else 'OFF' end,
case when DATABASEPROPERTYEX(d.name, 'IsAutoShrink') = 1
then 'ON' else 'OFF' end,
case when DATABASEPROPERTYEX(d.name, 'IsAutoClose') = 1
then 'ON' else 'OFF' end,
DATABASEPROPERTYEX(d.name, 'Collation'),
DATABASEPROPERTYEX(d.name, 'Updateability'),
DATABASEPROPERTYEX(d.name, 'UserAccess'),

d.cmptlevel,
DATABASEPROPERTYEX(d.name, 'Recovery'),
ls.LogSize, ls.LogSpaceUsed, b.backup_start_date;

create table #dbsize1 (
fileid int,
filegroup int,
TotalExtents bigint,
UsedExtents bigint,
dbname varchar(255),
FileName varchar(255));
declare c1 cursor for select name from #dbs1;
open c1;

fetch next from c1 into @name;
while @@fetch_status = 0
begin
set @sql = 'use [' + @name + ']; DBCC SHOWFILESTATS WITH NO_INFOMSGS;'
insert #dbsize1 exec(@sql);
update #dbs1
set Size = (select sum(TotalExtents) / 16 from #dbsize1),
Used = (select sum(UsedExtents) / 16 from #dbsize1)
where name = @name;
truncate table #dbsize1;
fetch next from c1 into @name;
end;
close c1;
deallocate c1;

IF EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'[dbo].[MyAuxTable]') AND type in (N'U'))
DROP TABLE [dbo].[MyAuxTable]
create table MyAuxTable (dbname varchar(30), size int, used int, logsize bigint,logspaceused bigint);
insert into MyAuxTable select name,size,used,logsize,logspaceused from #dbs1;

select
@@servername as 'Nome da Instancia'
,(select count(name) from master.dbo.sysdatabases) as 'No de BDs'
,sum(a.size)/(select count(name) from master.dbo.sysdatabases) as 'Espaco Alocado (mb)'
,sum(a.used)/(select count(name) from master.dbo.sysdatabases) as 'Espaco Utilizado (mb)'
,(sum(a.size)-sum(a.used))/(select count(name) from master.dbo.sysdatabases) as 'Espaco Livre (mb)'
from MyAuxTable a, master.dbo.sysdatabases b


IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#dbsize1'))
BEGIN
DROP TABLE #dbsize1
END

IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#dbs1'))
BEGIN
DROP TABLE #dbs1
END

IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#ls'))
BEGIN
DROP TABLE #ls
END