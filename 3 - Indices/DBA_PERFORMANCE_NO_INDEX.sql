set nocount on

declare @version char(12),
        @dbid int;
set     @version =  convert(char(12),serverproperty('productversion'));
set     @dbid = db_id()

 if  '10' = (select substring(@version, 1, 2)) -- CR 375891
     begin
 

          select distinct serverproperty('machinename')                               as 'Server Name',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                 db_name()                                                            as 'Database Name',                                                              
                 owner_name                                                           as 'Owner Name',       
                 object_name                                                          as 'Object Name',
                 index_type                                                           as 'Clustered / Heap',
                 approximate_rows                                                     as 'Approximate Rows'
            from (
          select su.name as owner_name, 
                 object_name(so.object_id) as object_name,
                 (case objectproperty(si.object_id, 'TableHasClustIndex')
                       when 1 then 'Clustered'
                       when 0 then 'Heap'
                   end) as index_type,
                 count(si.index_id) as index_count,
--                 max(dmv.record_count) as approximate_rows
                 max(dmv.rows) as approximate_rows
            from sys.indexes si
            join sys.objects so
              on so.object_id = si.object_id 
             and so.type = N'U' -- user table
--  DMV is marginally more accurate but imposes massive performance overhead
--            join sys.dm_db_index_physical_stats (@dbid, default, default, default, N'sampled') dmv
--              on so.object_id = dmv.object_id
--             and si.index_id  = dmv.index_id
            join sysindexes dmv
              on so.object_id = dmv.id
             and si.index_id  = dmv.indid
            join sys.schemas su 
              on su.schema_id = so.schema_id
           where so.is_ms_shipped = 0
              and indexproperty(so.object_id, si.name, 'IsStatistics') = 0
           group by su.name, 
                    object_name(so.object_id),
                   (case objectproperty(si.object_id, 'TableHasClustIndex')
                         when 1 then 'Clustered'
                         when 0 then 'Heap'
                     end)
            ) a
            where index_type = 'Heap'
              and index_count <= 1
           order by owner_name, object_name
     end
 else  -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin
 

          select distinct serverproperty('machinename')                               as 'Server Name',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                 db_name()                                                            as 'Database Name',                                                              
                 owner_name                                                           as 'Owner Name',       
                 object_name                                                          as 'Object Name',
                 index_type                                                           as 'Clustered / Heap',
                 approximate_rows                                                     as 'Approximate Rows'
            from (
          select su.name as owner_name, 
                 object_name(so.object_id) as object_name,
                 (case objectproperty(si.object_id, 'TableHasClustIndex')
                       when 1 then 'Clustered'
                       when 0 then 'Heap'
                   end) as index_type,
                 count(si.index_id) as index_count,
--                 max(dmv.record_count) as approximate_rows
                 max(dmv.rows) as approximate_rows
            from sys.indexes si
            join sys.objects so
              on so.object_id = si.object_id 
             and so.type = N'U' -- user table
--  DMV is marginally more accurate but imposes massive performance overhead
--            join sys.dm_db_index_physical_stats (@dbid, default, default, default, N'sampled') dmv
--              on so.object_id = dmv.object_id
--             and si.index_id  = dmv.index_id
            join sysindexes dmv
              on so.object_id = dmv.id
             and si.index_id  = dmv.indid
            join sys.schemas su 
              on su.schema_id = so.schema_id
           where so.is_ms_shipped = 0
              and indexproperty(so.object_id, si.name, 'IsStatistics') = 0
           group by su.name, 
                    object_name(so.object_id),
                   (case objectproperty(si.object_id, 'TableHasClustIndex')
                         when 1 then 'Clustered'
                         when 0 then 'Heap'
                     end)
            ) a
            where index_type = 'Heap'
              and index_count <= 1
           order by owner_name, object_name
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin

               select distinct serverproperty('machinename')                               as 'Server Name',                                           
                      isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                      db_name()                                                            as 'Database Name',                                                              
                      owner_name                                                           as 'Owner Name',       
                      object_name                                                          as 'Object Name',
                      index_type                                                           as 'Clustered / Heap',
                      approximate_rows                                                     as 'Approximate Rows'
                 from (
              select user_name(so.uid) as owner_name,
                     object_name(so.id) as object_name,
                     (case objectproperty(si.id, 'TableHasClustIndex')
                           when 1 then 'Clustered'
                           when 0 then 'Heap'
                       end) as index_type,
                     count(si.indid) as index_count,
                     max(si.rows) as approximate_rows
                from sysindexes si
                join sysobjects so
                  on so.id = si.id 
                 and OBJECTPROPERTYEX(so.id, 'IsMSShipped') = 0
                 and si.indid < 255
                 and (si.status & (64 | 8388608)) = 0 
                 and so.xtype = 'U'
               group by user_name(so.uid), 
                        object_name(so.id),
                        (case objectproperty(si.id, 'TableHasClustIndex')
                              when 1 then 'Clustered'
                              when 0 then 'Heap'
                          end)
                ) a
                where index_type = 'Heap'
                  and index_count <= 1
                order by owner_name, object_name 

         end;