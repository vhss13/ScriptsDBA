set nocount on

/**********************************
* remoção das tabelas temporárias *
**********************************/
if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbloginlist'))
begin
drop table #dbloginlist
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbresumo'))
begin
drop table #dbresumo
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbresumodb'))
begin
drop table #dbresumodb
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbdts'))
begin
drop table #dbdts
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbssis'))
begin
drop table #dbssis
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dblinkedserver'))
begin
drop table #dblinkedserver
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbtable'))
begin
drop table #dbtable
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbprocedure'))
begin
drop table #dbprocedure
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbfunction'))
begin
drop table #dbfunction
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbview'))
begin
drop table #dbview
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbuserlist'))
begin
drop table #dbuserlist
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dblogininfotmp'))
begin
drop table #dblogininfotmp
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dblogininfo'))
begin
drop table #dblogininfo
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbuserinfo'))
begin
drop table #dbuserinfo
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbfileinfo'))
begin
drop table #dbfileinfo
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#logsizestats'))
begin
drop table #logsizestats
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#datafilestats'))
begin
drop table #datafilestats
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#fixeddrives'))
begin
drop table #fixeddrives
end

/**********************************
* criação das tabelas temporárias *
**********************************/
create table #dbloginlist
([servername] varchar(255),
[loginname] varchar (100))

create table #dbresumo
([instance_name] varchar(255),
 [qde_login] int,
 [qde_dts] int,
 [qde_ssis] int,
 [qde_linkedserver] int)

create table #dbresumodb
([instance_name] varchar(255),
 [dbname] varchar(400),
 [qde_user] int,
 [qde_table] int,
 [qde_procedure] int,
 [qde_function] int,
 [qde_view] int)

create table #dbdts
([name] varchar(255),
 [description] varchar(255),
 [createdate] datetime,
 [owner] varchar(255))

create table #dbssis
([name] varchar(255),
 [description] varchar(255),
 [createdate] datetime,
 [owner] varchar(255))

create table #dblinkedserver
([name] varchar(255),
 [providername] varchar(255),
 [datasource] varchar(255))

create table #dbtable
([servername] varchar(255),
 [dbname] varchar(400),
 [name] varchar(255),
 [createdate] datetime)

create table #dbprocedure
([servername] varchar(255),
 [dbname] varchar(400),
 [name] varchar(255),
 [createdate] datetime)

create table #dbfunction
([servername] varchar(255),
 [dbname] varchar(400),
 [name] varchar(255),
 [createdate] datetime)

create table #dbview
([servername] varchar(255),
 [dbname] varchar(400),
 [name] varchar(255),
 [createdate] datetime)

create table #dbuserlist
([servername] varchar(255),
 [dbname] varchar(400),
 [username] varchar (100))

create table #dblogininfotmp
([serverrole] varchar(100),
 [membername] varchar (100),
 [membersid] varchar (100))

create table #dblogininfo
([servername] varchar(255),
 [serverrole] varchar(100),
 [loginname] varchar (100),
 [datechecked] datetime)

create table #dbuserinfo
([servername] varchar(255),
 [dbname] varchar(400),
 [dbrole] varchar(100),
 [membername] varchar (100),
 [loginname] varchar (100),
 [datechecked] datetime)

create table #fixeddrives
(driveletter varchar(10),
 mb_free dec(20,2))

create table #datafilestats
(dbname varchar(255),
 dbid int,
 fileid tinyint,
 [filegroup] tinyint,
 totalextents dec(20,2),
 usedextents dec(20,2),
 [name] varchar(255),
 [filename] varchar(400))

create table #logsizestats 
(dbname varchar(255) not null primary key clustered, 
 dbid int,
 logfile real,
 logfileused real,
 status bit)

create table #dbfileinfo
([servername] varchar(255),
 [dbname] varchar(255),
 [logicalfilename] varchar(400),
 [usagetype] varchar (30),
 [size_mb] dec(20,2),
 [spaceused_mb] dec(20,2),
 [maxsize_mb] dec(20,2),
 [nextallocation_mb] dec(20,2),
 [growthtype] varchar(65),
 [fileid] smallint,
 [groupid] smallint,
 [physicalfilename] varchar(400),
 [datechecked] datetime)

/*********************************
*    informações da instância    *
*********************************/
declare @sqlstring varchar(3000)
declare @minid int
declare @maxid int
declare @dbname varchar(255)
declare @version char(12)
set     @version =  convert(char(12),serverproperty('productversion'));

select @sqlstring =
'select servername = @@servername,' + char(13) +
' loginname = name' + char(13) +
'from master..syslogins'
-- print @sqlstring
insert into #dbloginlist
exec (@sqlstring)

select @sqlstring = 'exec sp_helpsrvrolemember'
-- print @sqlstring
insert into #dblogininfotmp
exec (@sqlstring)

select @sqlstring = 'select name, description, max(createdate) as createdate, owner ' + char(13) +
'from 	msdb..sysdtspackages' + char(13) +
'group by name, description, owner' + char(13) +
'order by name, description, owner'
-- print @sqlstring
insert into #dbdts
exec (@sqlstring)

select @sqlstring = 'select ssis.name,' + char(13) + 
'ssis.description,' + char(13) + 
'max(ssis.createdate) as ' + '''' + 'createdate' + '''' + ',' + char(13) + 
'l.name as ' + '''' + 'owner' + '''' + char(13) + 
'from msdb..sysssispackages ssis' + char(13) +
'left join master..syslogins l on ssis.ownersid = l.sid'   + char(13) +
'where ssis.name not in (' + '''' + 'perfcounterscollect'  + '''' + ',' + char(13) +
                             '''' + 'perfcountersupload'   + '''' + ',' + char(13) +
                             '''' + 'queryactivitycollect' + '''' + ',' + char(13) +
                             '''' + 'queryactivityupload'  + '''' + ',' + char(13) +
                             '''' + 'sqltracecollect'      + '''' + ',' + char(13) +
                             '''' + 'sqltraceupload'       + '''' + ',' + char(13) +
                             '''' + 'tsqlquerycollect'     + '''' + ',' + char(13) +
                             '''' + 'tsqlqueryupload'      + '''' + ')' + char(13) +
'group by ssis.name, ssis.description, l.name' + char(13) +
'order by ssis.name, ssis.description, l.name'
if  8 = (select substring(@version, 1, 1))
-- print 'ssis a partir do sql 2005'
select @sqlstring = 'ssis a partir do sql 2005'
if  (select count(*) from msdb..sysobjects where name = 'sysssispackages') = ''
-- print 'ssis não configurado'
select @sqlstring = 'ssis não configurado'
else
begin
-- print @sqlstring
insert into #dbssis
exec (@sqlstring)
end

select @sqlstring = 'select srvname as ' + '''' + 'name' + '''' + ', providername, datasource from master..sysservers where srvid <> 0 order by srvname'
-- print @sqlstring
insert into #dblinkedserver
exec (@sqlstring)

select @sqlstring =
'select servername = @@servername,' + char(13) +
'       serverrole = serverrole,' + char(13) +
'       loginname = membername,' + char(13) +
'       datechecked = getdate()' + char(13) +
'from #dblogininfotmp'
-- print @sqlstring
insert into #dblogininfo
exec (@sqlstring)

insert into #dbresumo (instance_name) select @@servername               as instance_name
update #dbresumo set qde_login        = (select count(login.loginname)  as qde_login from #dbloginlist login)
update #dbresumo set qde_dts          = (select count(distinct dts.name)         as qde_dts from #dbdts dts)update #dbresumo set qde_ssis         = (select count(distinct ssis.name)        as qde_ssis from #dbssis ssis)update #dbresumo set qde_linkedserver = (select count(ls.name)          as qde_linkedserver from #dblinkedserver ls)

/*********************************
*    informações dos bancos      *
*********************************/
declare @tbldbname table
(rowid int identity(1,1),
dbname varchar(400),
dbid int)

insert into @tbldbname (dbname,dbid)
select [name],dbid from master..sysdatabases where (status & 512) = 0 /*not in (536,528,540,2584,1536,512,4194841)*/ and name not in ('northwind','pubs')order by [name]

insert into #logsizestats (dbname,logfile,logfileused,status)
exec ('dbcc sqlperf(logspace) with no_infomsgs')

update #logsizestats
set dbid = db_id(dbname)

insert into #fixeddrives exec master..xp_fixeddrives

select @minid = min(rowid),
@maxid = max(rowid)
from @tbldbname

while (@minid <= @maxid)
begin
select @dbname = [dbname]
from @tbldbname
where rowid = @minid

insert into #dbresumodb (instance_name,dbname)
select @@servername as instance_name, @dbname as dbname

select @sqlstring =
'select servername = @@servername,' + char(13) +
' dbname = ' + '''' +@dbname+ '''' + ',' + char(13) +
' dbrole = g.name ' + ',' + char(13) +
' membername = u.name ' + ',' + char(13) +
' loginname = l.name ' + ',' + char(13) +
' datechecked = getdate() ' + char(13) +
'from ['+@dbname+']..sysusers u,' + char(13) +
'     ['+@dbname+']..sysusers g,' + char(13) +
'     ['+@dbname+']..sysmembers m,' + char(13) +
'            master.dbo.syslogins l' + char(13) +
'where   g.uid = m.groupuid' + char(13) +
'and g.issqlrole = 1' + char(13) +
'and u.uid = m.memberuid' + char(13) +
'and u.sid = l.sid' + char(13) +
'order by 1, 2'
-- print @sqlstring
insert into #dbuserinfo
exec (@sqlstring)

select @sqlstring =
'select servername = @@servername,' + char(13) +
' dbname = ' + '''' +@dbname+ '''' + ',' + char(13) +
' username = name' + char(13) +
'from ['+@dbname+']..sysusers' + char(13) +
'where issqlrole <> 1' + char(13) +
'and name not in ('+''''+'dbo'+''''+','+''''+'guest'+''''+','+''''+'information_schema'+''''+','+''''+'system_function_schema'+''''+')'
-- print @sqlstring
insert into #dbuserlist
exec (@sqlstring)
update #dbresumodb set qde_user = (select count(*) from #dbuserlist where dbname = @dbname) where dbname = @dbname

select @sqlstring =
'select servername = @@servername,' + char(13) +
'dbname = ' + '''' +@dbname+ '''' + ',' + char(13) +
'name as ' + '''' + 'name' + '''' + ',' + char(13) +
'crdate as ' + '''' + 'createdate' + '''' + ' from ['+@dbname+']..sysobjects ' + char(13) +
'where type = ' + '''' + 'u' + ''''+ char(13) +
'and name not in (' + '''' + 'dtproperties' + '''' + ') order by name'
-- print @sqlstring
insert into #dbtable
exec (@sqlstring)
update #dbresumodb set qde_table = (select count(*) from #dbtable where dbname = @dbname) where dbname = @dbname

select @sqlstring =
'select servername = @@servername,' + char(13) +
'dbname = ' + '''' +@dbname+ '''' + ',' + char(13) +
'name as ' + '''' + 'name' + '''' + ',' + char(13) +
'crdate as ' + '''' + 'createdate' + '''' + ' from ['+@dbname+']..sysobjects ' + char(13) +
'where type = ' + '''' + 'p' + '''' + char(13) +
'and name not in (' + '''' + 'dt_addtosourcecontrol'     + '''' + ',' + char(13) +
                      '''' + 'dt_addtosourcecontrol_u'   + '''' + ',' + char(13) +
                      '''' + 'dt_adduserobject'          + '''' + ',' + char(13) +
                      '''' + 'dt_adduserobject_vcs'      + '''' + ',' + char(13) +
                      '''' + 'dt_checkinobject'          + '''' + ',' + char(13) +
                      '''' + 'dt_checkinobject_u'        + '''' + ',' + char(13) +
                      '''' + 'dt_checkoutobject'         + '''' + ',' + char(13) +
                      '''' + 'dt_checkoutobject_u'       + '''' + ',' + char(13) +
                      '''' + 'dt_displayoaerror'         + '''' + ',' + char(13) +
                      '''' + 'dt_displayoaerror_u'       + '''' + ',' + char(13) +
                      '''' + 'dt_droppropertiesbyid'     + '''' + ',' + char(13) +
                      '''' + 'dt_dropuserobjectbyid'     + '''' + ',' + char(13) +
                      '''' + 'dt_generateansiname'       + '''' + ',' + char(13) +
                      '''' + 'dt_displayoaerror'         + '''' + ',' + char(13) +
                      '''' + 'dt_getobjwithprop'         + '''' + ',' + char(13) +
                      '''' + 'dt_getobjwithprop_u'       + '''' + ',' + char(13) +
                      '''' + 'dt_getpropertiesbyid'      + '''' + ',' + char(13) +
                      '''' + 'dt_getpropertiesbyid_u'    + '''' + ',' + char(13) +
                      '''' + 'dt_getpropertiesbyid_vcs'  + '''' + ',' + char(13) +
                      '''' + 'dt_getpropertiesbyid_vcs_u'+ '''' + ',' + char(13) +
                      '''' + 'dt_isundersourcecontrol'   + '''' + ',' + char(13) +
                      '''' + 'dt_isundersourcecontrol_u' + '''' + ',' + char(13) +
                      '''' + 'dt_removefromsourcecontrol'+ '''' + ',' + char(13) +
                      '''' + 'dt_setpropertybyid'        + '''' + ',' + char(13) +
                      '''' + 'dt_setpropertybyid_u'      + '''' + ',' + char(13) +
                      '''' + 'dt_validateloginparams'    + '''' + ',' + char(13) +
                      '''' + 'dt_validateloginparams_u'  + '''' + ',' + char(13) +
                      '''' + 'dt_vcsenabled'             + '''' + ',' + char(13) +
                      '''' + 'dt_verstamp006'            + '''' + ',' + char(13) +
                      '''' + 'dt_verstamp007'            + '''' + ',' + char(13) +
                      '''' + 'dt_whocheckedout'          + '''' + ',' + char(13) +
                      '''' + 'dt_whocheckedout_u'        + '''' + ') order by name'
--print @sqlstring
insert into #dbprocedure
exec (@sqlstring)
update #dbresumodb set qde_procedure = (select count(*) from #dbprocedure where dbname = @dbname) where dbname = @dbname

select @sqlstring =
'select servername = @@servername,' + char(13) +
'dbname = ' + '''' +@dbname+ '''' + ',' + char(13) +
'name as ' + '''' + 'name' + '''' + ',' + char(13) +
'crdate as ' + '''' + 'createdate' + '''' + ' from ['+@dbname+']..sysobjects ' + char(13) +
'where type = '   + '''' + 'fn'   + '''' + ' order by name'
-- print @sqlstring
insert into #dbfunction
exec (@sqlstring)
update #dbresumodb set qde_function = (select count(*) from #dbfunction where dbname = @dbname) where dbname = @dbname

select @sqlstring =
'select servername = @@servername,' + char(13) +
'dbname = ' + '''' +@dbname+ '''' + ',' + char(13) +
'name as ' + '''' + 'name' + '''' + ',' + char(13) +
'crdate as ' + '''' + 'createdate' + '''' + ' from ['+@dbname+']..sysobjects ' + char(13) +
'where type = ' + '''' + 'v' + ''''+ char(13) +
'and name not in (' + '''' + 'sysconstraints' + '''' + ',' + '''' + 'syssegments' + ''''+ ') order by name'
-- print @sqlstring
insert into #dbview
exec (@sqlstring)
update #dbresumodb set qde_view = (select count(*) from #dbview where dbname = @dbname) where dbname = @dbname

select @sqlstring =
'select servername = @@servername,'+
' dbname = '''+@dbname+''','+
' logicalfilename = [name],'+
' usagetype = case when (64&[status])=64 then ''log'' else ''data'' end,'+
' size_mb = [size]*8/1024.00,'+
' spaceused_mb = null,'+
' maxsize_mb = case [maxsize] when -1 then -1 when 0 then [size]*8/1024.00 else maxsize/1024.00*8 end,'+
' nextextent_mb = case when (1048576&[status])=1048576 then ([growth]/100.00)*([size]*8/1024.00) when [growth]=0 then 0 else [growth]*8/1024.00 end,'+
' growthtype = case when (1048576&[status])=1048576 then ''%'' else ''pages'' end,'+
' fileid = [fileid],'+
' groupid = [groupid],'+
' physicalfilename= [filename],'+
' curtimestamp = getdate()'+
'from ['+@dbname+']..sysfiles'
-- print @sqlstring
insert into #dbfileinfo
exec (@sqlstring)

update #dbfileinfo
set spaceused_mb = size_mb / 100.0 * (select logfileused from #logsizestats where dbname = @dbname)
where usagetype = 'log'

select @sqlstring = 'use [' + @dbname + '] dbcc showfilestats with no_infomsgs'

insert #datafilestats (fileid,[filegroup],totalextents,usedextents,[name],[filename])
execute(@sqlstring)

update #dbfileinfo
set [spaceused_mb] = s.[usedextents]*64/1024.00
from #dbfileinfo as f
inner join #datafilestats as s
on f.[fileid] = s.[fileid]
and f.[groupid] = s.[filegroup]
and f.[dbname] = @dbname

truncate table #datafilestats

select @minid = @minid + 1
end

/*********************************
*     select das informações     *
*********************************/
print 'resumo_instance'
select SERVERPROPERTY('servername') as Instance_Name,
       SERVERPROPERTY('IsClustered') as IsClustered, 
       SERVERPROPERTY('edition') as SQL_Edition,
       SERVERPROPERTY('productversion') as SQL_Version,
       SERVERPROPERTY('productlevel') as SQL_ServicePack,
       SERVERPROPERTY('collation') AS SQLServerCollation
select * from #dbresumo
print 'resumo_database'
select * from #dbresumodb
print 'logins_list'
select * from #dbloginlist
print 'dts_list'
select * from #dbdts
print 'ssis_list'
if  8 = (select substring(@version, 1, 1))
begin
print 'ssis a partir do sql 2005'
print ''
end
if  (select count(*) from msdb..sysobjects where name = 'sysssispackages') = ''
begin
print 'ssis não configurado'
print ''
end
else
begin
select * from #dbssis
end
print 'linkedserver_list'
select * from #dblinkedserver
print 'table_list'
select * from #dbtable
print 'procedure_list'
select * from #dbprocedure
print 'function_list'
select * from #dbfunction
print 'view_list'
select * from #dbview
print 'users_list'
select * from #dbuserlist
print 'login_privileges'
select * from #dblogininfo
print 'users_privileges'
select * from #dbuserinfo
print 'database properties'
select [servername],
[dbname],
[logicalfilename],
[usagetype] as segmentname,
b.mb_free as freespaceindrive,
[size_mb],
[spaceused_mb],
[size_mb] - [spaceused_mb] as freespace_mb,
cast(([size_mb] - [spaceused_mb]) / [size_mb] as decimal(4,2)) as freespace_pct,
[maxsize_mb],
[nextallocation_mb],
case maxsize_mb when -1 then cast(cast(([nextallocation_mb]/[size_mb])*100 as int) as varchar(10))+' %' else 'pages' end as [growthtype],
[fileid],
[groupid],
[physicalfilename],
[datechecked]
from #dbfileinfo as a
left join #fixeddrives as b
on substring(a.physicalfilename,1,1) = b.driveletter
order by dbname,groupid,fileid

/**********************************
* remoção das tabelas temporárias *
**********************************/
if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbloginlist'))
begin
drop table #dbloginlist
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbresumo'))
begin
drop table #dbresumo
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbresumodb'))
begin
drop table #dbresumodb
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbdts'))
begin
drop table #dbdts
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbssis'))
begin
drop table #dbssis
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dblinkedserver'))
begin
drop table #dblinkedserver
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbtable'))
begin
drop table #dbtable
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbprocedure'))
begin
drop table #dbprocedure
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbfunction'))
begin
drop table #dbfunction
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbview'))
begin
drop table #dbview
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbuserlist'))
begin
drop table #dbuserlist
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dblogininfotmp'))
begin
drop table #dblogininfotmp
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dblogininfo'))
begin
drop table #dblogininfo
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbuserinfo'))
begin
drop table #dbuserinfo
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#dbfileinfo'))
begin
drop table #dbfileinfo
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#logsizestats'))
begin
drop table #logsizestats
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#datafilestats'))
begin
drop table #datafilestats
end

if exists (select 1 from tempdb..sysobjects where [id] = object_id('tempdb..#fixeddrives'))
begin
drop table #fixeddrives
end