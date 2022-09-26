SELECT 'Index Name' = i.name, 
   'Statistics Date' = STATS_DATE(i.id, i.indid)
FROM sysobjects o, sysindexes i
WHERE o.name = 'BatchDocumentPartialRel' AND o.id = i.id
