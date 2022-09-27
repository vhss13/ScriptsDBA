dbcc updateusage(0)   --Voce deve executar este commando antes para atualizar o catalogo
go


select 
 db_name() DatabaseName
,object_name(id) TableName
,filegroup_name(groupid) FilegroupName
,sum(rows) QtdRows
,convert(int,(sum(reserved) * 8.192 /1024.0)) as AllocatedMb
,convert(int,(sum(used) * 8.192  /1024.0)) as UsedMb
from sysindexes 
where indid in (0,1,255) 
group by id, groupid


/*
dbcc updateusage(0)   --Voce deve executar este commando antes para atualizar o catalogo
GO

select 
 db_name() DatabaseName
,object_name(id) TableName
,filegroup_name(groupid) FilegroupName
,sum(rows) QtdRows
,sum(reserved) * 8.192 /1024.0 Allocated
,sum(used) * 8.192  /1024.0 Used
from sysindexes 
where indid in (0,1,255) 
group by id, groupid
GO
*/