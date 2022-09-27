set nocount on

declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));


 if  '10' = (select substring(@version, 1, 2)) -- CR 375891
     begin
         select distinct serverproperty('machinename')                               as 'Server Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                db_name()                                                            as 'Database Name',
                e.name                                                               as 'Owner Name',   
                a.name                                                               as 'Table Name',
				ISNULL(b.IndexCount,0)												 as 'Number of Indexes',
				ISNULL(d.ColumnCount,0)											     as 'Number of Columns'
           from sys.objects a
           full outer join (select object_id, count(1) as IndexCount 
				 from sys.indexes
				 where index_id >= 1
				 and [name] not like '_WA%' -- bug 363758
				 group by object_id) b 
           on b.object_id = a.object_id
           full outer join (select object_id, count(1) as ColumnCount
				 from sys.columns
				 group by object_id) d 
           on d.object_id = a.object_id
           join sys.schemas e 
             on e.schema_id = a.schema_id
          where a.type = 'U'
		  and a.is_ms_shipped = 0
		  and a.object_id not in (select major_id from sys.extended_properties where name = N'microsoft_database_tools_support')
		  and b.IndexCount > d.ColumnCount
     end
 else  -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin
         select distinct serverproperty('machinename')                               as 'Server Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                db_name()                                                            as 'Database Name',
                e.name                                                               as 'Owner Name',   
                a.name                                                               as 'Table Name',
				ISNULL(b.IndexCount,0)												 as 'Number of Indexes',
				ISNULL(d.ColumnCount,0)											     as 'Number of Columns'
           from sys.objects a
           full outer join (select object_id, count(1) as IndexCount 
				 from sys.indexes
				 where index_id >= 1
				 and [name] not like '_WA%' -- bug 363758
				 group by object_id) b 
           on b.object_id = a.object_id
           full outer join (select object_id, count(1) as ColumnCount
				 from sys.columns
				 group by object_id) d 
           on d.object_id = a.object_id
           join sys.schemas e 
             on e.schema_id = a.schema_id
          where a.type = 'U'
		  and a.is_ms_shipped = 0
		  and a.object_id not in (select major_id from sys.extended_properties where name = N'microsoft_database_tools_support')
		  and b.IndexCount > d.ColumnCount
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
			 select distinct serverproperty('machinename')                               as 'Server Name',                                           
					isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
					db_name()                                                            as 'Database Name',
					e.name                                                               as 'Owner Name',   
					a.name                                                               as 'Table Name',
					ISNULL(b.IndexCount,0)												 as 'Number of Indexes',
					ISNULL(d.ColumnCount,0)											     as 'Number of Columns'
			   from sysobjects a
			   full outer join (select id, count(1) as IndexCount 
					 from sysindexes
					 where indid >= 1
					 and [name] not like '_WA%' -- bug 363758
					 group by id) b 
			   on b.id = a.id
			   full outer join (select id, count(1) as ColumnCount
					 from syscolumns
					 group by id) d 
			   on d.id = a.id
			   join sysusers e 
				 on e.uid = a.uid
			  where a.xtype = 'U'
                and OBJECTPROPERTYEX(a.id,'IsMSShipped') = 0
                and a.id not in (
				  select object_id(objname)
				  from   ::fn_listextendedproperty ('microsoft_database_tools_support', default, default, default, default, NULL, NULL)
				  where value = 1)
			  and b.IndexCount > d.ColumnCount
         end;

