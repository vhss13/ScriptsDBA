select 
	SPECIFIC_NAME AS procedureName, 
	SPECIFIC_CATALOG AS databaseName, 
	CREATED AS createDate, 
	LAST_ALTERED as lastAlteredDate
from 
	information_schema.routines 
where CREATED <> LAST_ALTERED