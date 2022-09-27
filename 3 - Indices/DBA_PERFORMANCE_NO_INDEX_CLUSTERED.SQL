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
                 approximate_rows                                                     as 'Approximate Rows',
                 avg_fragmentation_in_percent,
                 CASE 
					WHEN avg_fragmentation_in_percent >= 30 THEN N'High'
					WHEN avg_fragmentation_in_percent >= 5 THEN N'Moderate'
					WHEN avg_fragmentation_in_percent > 0 THEN N'Low'
					ELSE '(n/a)'
 				 END AS FragmentationLevel

            from (
          select su.name as owner_name, 
                 object_name(so.object_id) as object_name,
                 (case objectproperty(si.object_id, 'TableHasClustIndex')
                       when 1 then 'Clustered'
                       when 0 then 'Heap'
                   end) as index_type,
                 count(si.index_id) as index_count,
                 max(dmv.record_count) as approximate_rows,
--                 max(dmv.rows) as approximate_rows,
				 cast (max(dmv.avg_fragmentation_in_percent) as decimal (6,2)) as avg_fragmentation_in_percent
            from sys.indexes si
            join sys.objects so
              on so.object_id = si.object_id
             and so.type = N'U' 
             and indexproperty(so.object_id, si.name, 'IsStatistics') = 0
--  DMV is marginally more accurate but imposes massive performance overhead
            join sys.dm_db_index_physical_stats (@dbid, default, default, default, N'sampled') dmv
              on so.object_id = dmv.object_id
             and si.index_id  = dmv.index_id
            --join sysindexes dmv
            --  on so.object_id = dmv.id
            -- and si.index_id  = dmv.indid
            join sys.schemas su 
              on su.schema_id = so.schema_id
           where so.is_ms_shipped = 0
             and so.object_id not in (select major_id from sys.extended_properties where name = N'microsoft_database_tools_support')

           group by su.name, 
                    object_name(so.object_id),
                   (case objectproperty(si.object_id, 'TableHasClustIndex')
                         when 1 then 'Clustered'
                         when 0 then 'Heap'
                     end)
            ) a
            where index_type = 'Heap'
              and index_count >= 2

           order by owner_name, object_name
     end
 else -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin

          select distinct serverproperty('machinename')                               as 'Server Name',                                           
                 isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                 db_name()                                                            as 'Database Name',                                                              
                 owner_name                                                           as 'Owner Name',       
                 object_name                                                          as 'Object Name',
                 index_type                                                           as 'Clustered / Heap',
                 approximate_rows                                                     as 'Approximate Rows',
                 avg_fragmentation_in_percent,
                 CASE 
					WHEN avg_fragmentation_in_percent >= 30 THEN N'High'
					WHEN avg_fragmentation_in_percent >= 5 THEN N'Moderate'
					WHEN avg_fragmentation_in_percent > 0 THEN N'Low'
					ELSE '(n/a)'
 				 END AS FragmentationLevel

            from (
          select su.name as owner_name, 
                 object_name(so.object_id) as object_name,
                 (case objectproperty(si.object_id, 'TableHasClustIndex')
                       when 1 then 'Clustered'
                       when 0 then 'Heap'
                   end) as index_type,
                 count(si.index_id) as index_count,
                 max(dmv.record_count) as approximate_rows,
--                 max(dmv.rows) as approximate_rows,
				 cast (max(dmv.avg_fragmentation_in_percent) as decimal (6,2)) as avg_fragmentation_in_percent
            from sys.indexes si
            join sys.objects so
              on so.object_id = si.object_id
             and so.type = N'U' 
             and indexproperty(so.object_id, si.name, 'IsStatistics') = 0
--  DMV is marginally more accurate but imposes massive performance overhead
            join sys.dm_db_index_physical_stats (@dbid, default, default, default, N'sampled') dmv
              on so.object_id = dmv.object_id
             and si.index_id  = dmv.index_id
            --join sysindexes dmv
            --  on so.object_id = dmv.id
            -- and si.index_id  = dmv.indid
            join sys.schemas su 
              on su.schema_id = so.schema_id
           where so.is_ms_shipped = 0
             and so.object_id not in (select major_id from sys.extended_properties where name = N'microsoft_database_tools_support')

           group by su.name, 
                    object_name(so.object_id),
                   (case objectproperty(si.object_id, 'TableHasClustIndex')
                         when 1 then 'Clustered'
                         when 0 then 'Heap'
                     end)
            ) a
            where index_type = 'Heap'
              and index_count >= 2

           order by owner_name, object_name
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
         
            CREATE TABLE [dbo].[#tbl_INDEX_FRAGMENTATION] (
	            [ObjectName] [Nchar] (255) NOT NULL ,
	            [ObjectID] [int] NOT NULL ,
	            [IndexName] [Nchar] (255) NOT NULL ,
	            [Indexid] [int] NOT NULL ,
	            [Lvl] [int] NULL ,
	            [CountPages] [int] NULL ,
	            [CountRows] [int] NULL ,
	            [MinRecSize] [int] NULL ,
	            [MaxRecSize] [int] NULL ,
	            [AvgRecSize] [int] NULL ,
	            [ForRecCount] [int] NULL ,
	            [Extents] [int] NULL ,
	            [ExtentSwitches] [int] NULL ,
	            [AvgFreeBytes] [int] NULL ,
	            [AvgPageDensity] [int] NULL ,
	            [ScanDensity] [decimal](18, 0) NULL ,
	            [BestCount] [int] NULL ,
	            [ActualCount] [int] NULL ,
	            [LogicalFrag] [decimal](18, 2) NULL ,
	            [ExtentFrag] [decimal](18, 0) NULL ,
	            [Database_Name] [NVARCHAR] (150) NOT NULL DEFAULT (db_name()),
	            [Index_depth] [int] NULL ,
	            [Auto_Statistics] [bit] NULL ,
	            [Statistic] [bit] NULL
            ) ON [PRIMARY]

            CREATE TABLE [dbo].[#tmp_fraglist] (
	            [ObjectName] [Nchar] (255) NULL ,
	            [ObjectID] [int] NULL ,
	            [IndexName] [Nchar] (255) NULL ,
	            [Indexid] [int] NULL ,
	            [Lvl] [int] NULL ,
	            [CountPages] [int] NULL ,
	            [CountRows] [int] NULL ,
	            [MinRecSize] [int] NULL ,
	            [MaxRecSize] [int] NULL ,
	            [AvgRecSize] [int] NULL ,
	            [ForRecCount] [int] NULL ,
	            [Extents] [int] NULL ,
	            [ExtentSwitches] [int] NULL ,
	            [AvgFreeBytes] [int] NULL ,
	            [AvgPageDensity] [int] NULL ,
	            [ScanDensity] [decimal](18, 0) NULL ,
	            [BestCount] [int] NULL ,
	            [ActualCount] [int] NULL ,
	            [LogicalFrag] [decimal](18, 0) NULL ,
	            [ExtentFrag] [decimal](18, 0) NULL ,
	            [Database_Name] [NVARCHAR] (150) NULL DEFAULT (db_name()),
	            [Index_depth] [int] NULL ,
	            [Auto_Statistics] [bit] NULL ,
	            [Statistic] [bit] NULL
            ) ON [PRIMARY]

            DECLARE 
	            @SQLSTR NVARCHAR(4000),
	            @Database_Name NVARCHAR(200),
	            @TableName NVARCHAR (300),
	            @TableName2 NVARCHAR (300),
				@Owner		NVARCHAR(255),
	            @execstr   VARCHAR (255),
	            @ObjectID  INT,
	            @indexid   INT,
	            @frag      DECIMAL,
	            @indexname varchar (255),
	            @NumberToDefrag INT,
	            @NumberToReindex INT,
	            @NoIndex Bit,
	            @NoClusteredIndex Bit,
	            @DuplicateIndex Bit,
	            @IndexColumnRatio Bit,
	            @HypotheticalIndex Bit,
	            @PinTable Bit,
	            @UserObjects Bit,
	            @LogicalFragmentation Bit,
	            @CheckSingleDB Bit,
	            @SingleDBName NVARCHAR(255),
	            @InstanceID INT,
	            @NumberOfDB INT

            /* Declare cursor*/
            DECLARE tables CURSOR FOR
               SELECT DISTINCT so.name, USER_NAME(so.uid)
               FROM   sysobjects so
               JOIN   sysindexes si
               ON     so.id = si.id
--               AND    si.indid = 0 -- heap
               WHERE  OBJECTPROPERTYEX(so.id, 'IsMSShipped') = 0
               AND    so.id NOT IN (
					    SELECT object_id(objname)
					    FROM   ::fn_listextendedproperty ('microsoft_database_tools_support', default, default, default, default, NULL, NULL)
					    WHERE value = 1)
               AND    UPPER(type) = N'U'
               

            /* Open the cursor*/
            OPEN tables

            /* Loop through all the TABLEs in the DATAbase*/
            FETCH NEXT
               FROM tables
               INTO @TableName,
					@Owner

            WHILE @@FETCH_STATUS = 0
            BEGIN
            /* Do the showcontig of all indexes of the TABLE*/
               IF CHARINDEX(@TableName,CHAR(39),0)=0 -- bug 367932; CHAR(39) is a single quote
                  BEGIN  
                     SELECT @TableName2=REPLACE(@TableName,CHAR(39),CHAR(39)+CHAR(39)) -- bug 367932
                     INSERT INTO #tmp_fraglist 
	            (ObjectName, ObjectID, IndexName, Indexid, Lvl, CountPages, CountRows, MinRecSize, MaxRecSize, AvgRecSize, ForRecCount, Extents, ExtentSwitches, AvgFreeBytes, AvgPageDensity, ScanDensity, BestCount, ActualCount, LogicalFrag, ExtentFrag)
                     EXEC ('DBCC SHOWCONTIG (''[' + @Owner + N'].[' + @TableName2 + ']'') WITH FAST, TABLERESULTS, ALL_INDEXES, NO_INFOMSGS')
                     /* catch indexes FROM tables which are empty (by default no fragmention)*/
                     SET @SQLSTR='IF NOT EXISTS(SELECT * FROM [' + @Owner + N'].[' + @TableName + ']) AND NOT EXISTS(SELECT * FROM #tmp_fraglist WHERE ObjectID=Object_id(''[' + @Owner + N'].[' + @TableName2 + ']''))
               BEGIN
                  INSERT INTO #tmp_fraglist (ObjectName,ObjectID,IndexName,Indexid,Database_Name,LogicalFrag,Index_depth)
                  SELECT sysobjects.name,sysobjects.id,sysindexes.name,sysindexes.indid,db_name(),0,1 FROM sysindexes INNER JOIN sysobjects on sysindexes.id=sysobjects.id WHERE sysindexes.indid>0 AND NOT(sysindexes.name COLLATE Latin1_General_BIN LIKE ''_WA_%'') AND sysobjects.id=object_id(''['+ @Owner + N'].[' + @TableName2 + ']'')
               END '
                  END
               ELSE
                  BEGIN
                     INSERT INTO #tmp_fraglist 
	            (ObjectName, ObjectID, IndexName, Indexid, Lvl, CountPages, CountRows, MinRecSize, MaxRecSize, AvgRecSize, ForRecCount, Extents, ExtentSwitches, AvgFreeBytes, AvgPageDensity, ScanDensity, BestCount, ActualCount, LogicalFrag, ExtentFrag)
                     EXEC ('DBCC SHOWCONTIG (''[' + @Owner + N'].[' + @TableName + ']'') WITH FAST, TABLERESULTS, ALL_INDEXES, NO_INFOMSGS')
                     /* catch indexes FROM tables which are empty (by default no fragmention)*/
                     SET @SQLSTR='IF NOT EXISTS(SELECT * FROM [' + @Owner + N'].[' + @TableName + ']) AND NOT EXISTS(SELECT * FROM #tmp_fraglist WHERE ObjectID=Object_id(''[' + @Owner + N'].[' + @TableName + ']''))
               BEGIN
                  INSERT INTO #tmp_fraglist (ObjectName,ObjectID,IndexName,Indexid,Database_Name,LogicalFrag,Index_depth)
                  SELECT sysobjects.name,sysobjects.id,sysindexes.name,sysindexes.indid,db_name(),0,1 FROM sysindexes INNER JOIN sysobjects on sysindexes.id=sysobjects.id WHERE sysindexes.indid>0 AND NOT(sysindexes.name COLLATE Latin1_General_BIN LIKE ''_WA_%'') AND sysobjects.id=object_id(''['+ @Owner + N'].[' + @TableName + ']'')
               END '
                  END

               EXEC sp_executesql @SQLSTR

               UPDATE
	            #tmp_fraglist
               SET 
	            Database_Name=@Database_Name
               WHERE 
	            Database_Name IS NULL

               SET @execstr='UPDATE #tmp_fraglist SET Index_depth=INDEXPROPERTY (ObjectID, IndexName, ''IndexDepth'') WHERE Index_depth IS null'

               EXEC (@execstr)

               SET @execstr='UPDATE #tmp_fraglist SET Auto_Statistics=INDEXPROPERTY (ObjectID, IndexName, ''IsAutoStatistics'') WHERE Auto_Statistics IS null'
               EXEC (@execstr)

               SET @execstr='UPDATE #tmp_fraglist SET Statistic=INDEXPROPERTY (ObjectID, IndexName, ''IsStatistics'') WHERE Statistic IS null'
               EXEC (@execstr)


            DELETE FROM #tmp_fraglist WHERE ObjectName='dtproperties'

            INSERT INTO #tbl_INDEX_FRAGMENTATION
	            (ObjectName, ObjectID, IndexName, Indexid, Lvl, CountPages, CountRows, MinRecSize, MaxRecSize, AvgRecSize, ForRecCount, Extents, ExtentSwitches, AvgFreeBytes, AvgPageDensity, ScanDensity, BestCount, ActualCount, LogicalFrag, ExtentFrag, Database_Name, Index_depth, Auto_Statistics, Statistic)
            SELECT 
	            ObjectName, ObjectID, IndexName, Indexid, Lvl, CountPages, CountRows, MinRecSize, MaxRecSize, AvgRecSize, ForRecCount, Extents, ExtentSwitches, AvgFreeBytes, AvgPageDensity, ScanDensity, BestCount, ActualCount, LogicalFrag, ExtentFrag, Database_Name, Index_depth, Auto_Statistics, Statistic
            FROM 
	            #tmp_fraglist

            TRUNCATE TABLE #tmp_fraglist

               FETCH NEXT
                  FROM tables
                  INTO @TableName,
					   @Owner
            END

            CLOSE tables
            DEALLOCATE tables

               select distinct serverproperty('machinename')                               as 'Server Name',                                           
                      isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',  
                      db_name()                                                            as 'Database Name',                                                              
                      owner_name                                                           as 'Owner Name',       
                      object_name                                                          as 'Object Name',
                      index_type                                                           as 'Clustered / Heap',
                      approximate_rows                                                     as 'Approximate Rows',
                     avg_fragmentation_in_percent,
                     CASE 
					    WHEN avg_fragmentation_in_percent >= 30 THEN N'High'
					    WHEN avg_fragmentation_in_percent >= 5 THEN N'Moderate'
					    WHEN avg_fragmentation_in_percent > 0 THEN N'Low'
					    ELSE '(n/a)'
 				     END AS FragmentationLevel
                 from (
              select user_name(so.uid) as owner_name,
                     object_name(so.id) as object_name,
                     (case objectproperty(si.id, 'TableHasClustIndex')
                           when 1 then 'Clustered'
                           when 0 then 'Heap'
                       end) as index_type,
                     count(si.indid) as index_count,
                     max(si.rows) as approximate_rows,
                     max(s.LogicalFrag)   AS avg_fragmentation_in_percent
 
                from sysindexes si
                join sysobjects so
                  on so.id = si.id
                 and so.xtype = N'U' 
                 and OBJECTPROPERTYEX(so.id, 'IsMSShipped') = 0
                 and so.id not in (
					select object_id(objname)
					from   ::fn_listextendedproperty ('microsoft_database_tools_support', default, default, default, default, NULL, NULL)
					where value = 1)
                 and si.indid < 255
                 and (si.status & (64 | 8388608)) = 0
                INNER JOIN
                        #tbl_INDEX_FRAGMENTATION s
                ON      si.[id]=s.[ObjectID]
                and     si.indid=s.Indexid
 
               group by user_name(so.uid), 
                        object_name(so.id),
                        (case objectproperty(si.id, 'TableHasClustIndex')
                              when 1 then 'Clustered'
                              when 0 then 'Heap'
                          end)
                ) a
                where index_type = 'Heap'
                  and index_count >= 2                
                order by owner_name, object_name 

            drop table #tmp_fraglist
            
            drop table #tbl_INDEX_FRAGMENTATION

         end;