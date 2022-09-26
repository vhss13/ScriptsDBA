SELECT OBJECT_NAME(object_id), *
FROM sys.sql_modules
WHERE definition LIKE '%menphis%'
