--------------------------------------------
-- Script to identify table fragmentation --
--------------------------------------------

--Declare variables
DECLARE
@ID int,
@IndexID int,
@IndexName varchar(128)

--Set the table and index to be examined
SELECT @IndexName = 'index_name' --enter name of index
SET @ID = OBJECT_ID('table_name') --enter name of table

--Get the Index Values
SELECT @IndexID = IndID
FROM sysindexes
WHERE id = @ID AND name = @IndexName

--Display the fragmentation
DBCC SHOWCONTIG (@id, @IndexID)



------------------------------------------------
-- Script to identify ALL table fragmentation --
------------------------------------------------

SELECT 'dbcc showcontig (' +
CONVERT(varchar(20),i.id) + ',' + -- table id
CONVERT(varchar(20),i.indid) + ') -- ' + -- index id
object_name(i.id) + '.' + -- table name
i.name -- index name
from sysobjects o
inner join sysindexes i
on (o.id = i.id)
where o.type = 'U'
and i.indid < 2
and
i.id = object_id(o.name)
ORDER BY
object_name(i.id), i.indid