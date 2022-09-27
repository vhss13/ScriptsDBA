-- useless indexes “User reads = 0” has not been used.

declare @dbid int
select @dbid = db_id()
--- sys.dm_db_index_usage_stats
select 'object' = object_name(s.object_id), i.name
                        ,'user reads' = user_seeks + user_scans + user_lookups
from sys.dm_db_index_usage_stats s, sys.indexes i
where objectproperty(s.object_id,'IsUserTable') = 1
and database_id = @dbid
and i.object_id = s.object_id
and i.index_id = s.index_id
order by 'user reads'


-----Index usage

select object_id, index_id, user_seeks, user_scans, user_lookups  
from sys.dm_db_index_usage_stats  
order by object_id, index_id

--All indexes which haven’t been used yet can be retrieved with the following statement:

select object_name(object_id), i.name  
from sys.indexes i  
where  i.index_id NOT IN (select s.index_id  
                          from sys.dm_db_index_usage_stats s  
                          where s.object_id=i.object_id and  
                          i.index_id=s.index_id and  
                          database_id = @dbid ) 
order by object_name(object_id) asc


--Duplicates indexes (written by Paul and Itzik)

-- exact duplicates
--with indexcols as
(
select object_id as id, index_id as indid, name,
(select case keyno when 0 then NULL else colid end as [data()]
from sys.sysindexkeys as k
where k.id = i.object_id
and k.indid = i.index_id
order by keyno, colid
for xml path('')) as cols,
(select case keyno when 0 then colid else NULL end as [data()]
from sys.sysindexkeys as k
where k.id = i.object_id
and k.indid = i.index_id
order by colid
for xml path('')) as inc
from sys.indexes as i
)
select
object_schema_name(c1.id) + '.' + object_name(c1.id) as 'table',
c1.name as 'index',
c2.name as 'exactduplicate'
from indexcols as c1
join indexcols as c2
on c1.id = c2.id
and c1.indid < c2.indid
and c1.cols = c2.cols
and c1.inc = c2.inc;

-- outro

select object_name(i.object_id) as ObjectName, i.name as [Unused Index]
from sys.indexes i
left join sys.dm_db_index_usage_stats s on s.object_id = i.object_id
   and i.index_id = s.index_id
   and s.database_id = db_id() 
where objectproperty(i.object_id, 'IsIndexable') = 1
AND objectproperty(i.object_id, 'IsIndexed') = 1 
and s.index_id is null -- and dm_db_index_usage_stats has no reference to this index
or (s.user_updates > 0 and s.user_seeks = 0 and s.user_scans = 0 and s.user_lookups = 0) -- index is being updated, but not used by seeks/scans/lookups
order by object_name(i.object_id) asc

-- mais um

--declare @dbid int
select @dbid = db_id()
select object_name(s.object_id) as ObjName
, i.name as IndName
, i.index_id
, user_seeks + user_scans + user_lookups as reads
, user_updates as writes
, sum(p.rows) as rows
from sys.dm_db_index_usage_stats s join sys.indexes i on s.object_id = i.object_id and i.index_id = s.index_id
join sys.partitions p on s.object_id = p.object_id and p.index_id = s.index_id
where objectproperty(s.object_id,'IsUserTable') = 1 and s.index_id > 0 and s.database_id = @dbid
group by object_name(s.object_id), i.name, i.index_id, user_seeks + user_scans + user_lookups, user_updates
order by reads, writes desc

--

select d.* 

        , s.avg_total_user_cost 

        , s.avg_user_impact 

        , s.last_user_seek 

        ,s.unique_compiles 

from sys.dm_db_missing_index_group_stats s 

        ,sys.dm_db_missing_index_groups g 

        ,sys.dm_db_missing_index_details d 

where s.group_handle = g.index_group_handle 

and d.index_handle = g.index_handle 

order by s.avg_user_impact desc 

go 

--- suggested index columns & usage 

declare @handle int 


select @handle = d.index_handle 

from sys.dm_db_missing_index_group_stats s 

        ,sys.dm_db_missing_index_groups g 

        ,sys.dm_db_missing_index_details d 

where s.group_handle = g.index_group_handle 

and d.index_handle = g.index_handle 

 

select *  

from sys.dm_db_missing_index_columns(@handle) 

order by column_id 