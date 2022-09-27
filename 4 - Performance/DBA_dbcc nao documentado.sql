DBCC - Undocumented commands
 
These commands may affect system performance and/or force table-level locks.
 There is no guarantee these commands will remain available in any future release of SQL server.
 
DBCC activecursors [(spid)]
 
DBCC addextendedproc (function_name, dll_name) 

DBCC addinstance (objectname, instancename) 

DBCC adduserobject (name) 

DBCC auditevent (eventclass, eventsubclass, success, loginname, rolename, dbusername, loginid) 

DBCC autopilot (typeid, dbid, tabid, indid, pages [,flag]) 

DBCC balancefactor (variance_percent) 

DBCC bufcount [(number_of_buffers)] 

DBCC buffer ( {'dbname' | dbid} [, objid [, number [, printopt={0|1|2} ] [, dirty | io | kept | rlock | ioerr | hashed ]]]) 

DBCC bytes ( startaddress, length ) 

DBCC cachestats 

DBCC callfulltext 

DBCC checkdbts (dbid, newTimestamp)] 

DBCC checkprimaryfile ( {'FileName'} [, opt={0|1|2|3} ]) 

DBCC cacheprofile [( {actionid} [, bucketid]) 

DBCC clearspacecaches ('database_name'|database_id, 'table_name'|table_id, 'index_name'|index_id) 

DBCC collectstats (on | off) 

DBCC config 

DBCC cursorstats ([spid [,'clear']]) 

DBCC dbinfo [('dbname')] 

DBCC dbrecover (dbname [, IgnoreErrors]) 

DBCC dbreindexall (db_name/db_id, type_bitmap) 

DBCC dbrepair ('dbname', DROPDB [, NOINIT]) 

DBCC dbtable [({'dbname' | dbid})] 

DBCC debugbreak 

DBCC deleteinstance (objectname, instancename) 

DBCC des [( {'dbname' | dbid} [, {'objname' | objid} ])] 

DBCC detachdb [( 'dbname' )] 

DBCC dropextendedproc (function_name) 

DBCC dropuserobject ('object_name') 

DBCC dumptrigger ({'BREAK', {0 | 1}} | 'DISPLAY' | {'SET', exception_number} | {'CLEAR', exception_number}) 

DBCC errorlog 

DBCC extentinfo [({'database_name'| dbid | 0} [,{'table_name' | table_id} [, {'index_name' | index_id | -1}]])] 

DBCC fileheader [( {'dbname' | dbid} [, fileid]) 

DBCC fixallocation [({'ADD' | 'REMOVE'}, {'PAGE' | 'SINGLEPAGE' | 'EXTENT' | 'MIXEDEXTENT'} , filenum, pagenum [, objectid, indid]) 

DBCC flush ('data' | 'log', dbid) 

DBCC flushprocindb (database) 

DBCC freeze_io (db) 

DBCC getvalue (name) 

DBCC icecapquery ('dbname', stored_proc_name [, #_times_to_icecap (-1 infinite, 0 turns off)])
 Use 'dbcc icecapquery (printlist)' to see list of SP's to profile.
 Use 'dbcc icecapquery (icecapall)' to profile all SP's.
 
DBCC incrementinstance (objectname, countername, instancename, value) 

DBCC ind ( { 'dbname' | dbid }, { 'objname' | objid }, { indid | 0 | -1 | -2 } )
 
DBCC invalidate_textptr (textptr)
 
DBCC invalidate_textptr_objid (objid)
 
DBCC iotrace ( { 'dbname' | dbid | 0 | -1 } , { fileid | 0 }, bufsize, [ { numIOs | -1 } [, { timeout (sec) | -1 } [, printopt={ 0 | 1 }]]] ) 

DBCC latch ( address [, 'owners'] [, 'stackdumps']) 

DBCC lock ([{'DUMPTABLE' | 'DUMPSTATS' | 'RESETSTATS' | 'HASH'}] | [{'STALLREPORTTHESHOLD', stallthreshold}]) 

DBCC lockobjectschema ('object_name') 

DBCC log ([dbid[,{0|1|2|3|4}[,['lsn','[0x]x:y:z']|['numrecs',num]|['xdesid','x:y'] | ['extent','x:y']|['pageid','x:y']|['objid',{x,'y'}]|['logrecs', {'lop'|op}...]|['output',x,['filename','x']]...]]])
 
DBCC loginfo [({'database_name' | dbid})] 

DBCC matview ({'PERSIST' | 'ENDPERSIST' | 'FREE' | 'USE' | 'ENDUSE'}) 

DBCC memobjlist [(memory object)] 

DBCC memorymap 

DBCC memorystatus 

DBCC memospy 

DBCC memusage ([IDS | NAMES], [Number of rows to output]) 

DBCC monitorevents ('sink' [, 'filter-expression']) 

DBCC newalloc - please use checkalloc instead 

DBCC no_textptr (table_id , max_inline) 

DBCC page ( {'dbname' | dbid}, filenum, pagenum [, printopt={0|1|2|3} ][, cache={0|1} ]) 

DBCC perflog 

DBCC perfmon 

DBCC pglinkage (dbid, startfile, startpg, number, printopt={0|1|2} , targetfile, targetpg, order={1|0}) 

DBCC procbuf [({'dbname' | dbid}[, {'objname' | objid} [, nbufs[, printopt = { 0 | 1 } ]]] )] 

DBCC prtipage (dbid, objid, indexid [, [{{level, 0} | {filenum, pagenum}}] [,printopt]]) 

DBCC pss [(uid[, spid[, printopt = { 1 | 0 }]] )] 

DBCC readpage ({ dbid, 'dbname' }, fileid, pageid , formatstr [, printopt = { 0 | 1} ]) 

DBCC rebuild_log (dbname [, filename]) 

DBCC renamecolumn (object_name, old_name, new_name) 

DBCC resource 

DBCC row_lock (dbid, tableid, set) - Not Needed 

DBCC ruleoff ({ rulenum | rulestring } [, { rulenum | rulestring } ]+) 

DBCC ruleon ( rulenum | rulestring } [, { rulenum | rulestring } ]+) 

DBCC setcpuweight (weight) 

DBCC setinstance (objectname, countername, instancename, value) 

DBCC setioweight (weight) 

DBCC showdbaffinity 

DBCC showfilestats [(file_num)] 

DBCC showoffrules 

DBCC showonrules 

DBCC showtableaffinity (table) 

DBCC showtext ('dbname', {textpointer | {fileid, pageid, slotid[,option]}})
 
DBCC showweights
 
DBCC sqlmgrstats 

DBCC stackdump [( {uid[, spid[, ecid]} | {threadId, 'THREADID'}] )] 

DBCC tab ( dbid, objid ) 

DBCC tape_control {'query' | 'release'}[,('\\.\tape')] 

DBCC tec [( uid[, spid[, ecid]] )] 

DBCC textall [({'database_name'|database_id}[, 'FULL' | FAST] )] 

DBCC textalloc ({'table_name'|table_id}[, 'FULL' | FAST]) 

DBCC thaw_io (db) 

DBCC upgradedb (db) 

DBCC usagegovernor (command, value) 

DBCC useplan [(number_of_plan)] 

DBCC wakeup (spid) 

DBCC writepage ({ dbid, 'dbname' }, fileid, pageid, offset, length, data)
 
In early versions of SQL Server - DBCC stood for "Database Consistency Checker", now renamed as Database Console Command.
 
Related (current) commands:
 
DBCC CHECK... 
DBCC CLEANTABLE 
DBCC dllname 
DBCC DROPCLEANBUFFERS 
DBCC FREE... CACHE 
DBCC HELP 
DBCC INPUTBUFFER 
DBCC OPENTRAN 
DBCC OUTPUTBUFFER 
DBCC PROCCACHE 
DBCC SHOW_STATISTICS 
DBCC SHRINKDATABASE 
DBCC SHRINKFILE 
DBCC SQLPERF 
DBCC TRACE... 
DBCC UPDATEUSAGE 
DBCC USEROPTIONS
