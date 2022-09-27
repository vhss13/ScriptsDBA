-- Amount of memory allocated to the buffer pool
select
    sum(single_pages_kb 
        + virtual_memory_committed_kb
        + shared_memory_committed_kb
        + awe_allocated_kb) as [Used by BPool with AWE, Kb]
from 
    sys.dm_os_memory_clerks 
where 
    type = 'MEMORYCLERK_SQLBUFFERPOOL'

-- how many buffer pool is allocated
select sum(single_pages_kb) as bpool, sum(multi_pages_kb) as resevered_mem
from sys.dm_os_memory_cache_counters

-- how many pages in the buffer pool by database
select db_name(database_id), 
count(page_id)as number_pages
 from sys.dm_os_buffer_descriptors 
where database_id !=32767
group by database_id
order by database_id

-- how many pages in the buffer pool by type_x_database
select db_name(database_id) as database_name, page_type, count(page_id)as number_pages
 from sys.dm_os_buffer_descriptors 
where database_id !=32767
group by database_id, page_type
order by database_id
