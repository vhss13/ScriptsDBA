Use <Database>
SELECT
     DB_Name() As DBName 
    ,Referencing.DBObject_Schema As Object_Schema
    ,Referencing.DBObject As [Object_Name]
    ,Referenced.Child_DBBObject_Schema As [Child_Schema]
    ,Referenced.Child_DBObject As [Child_Name]
    ,Referenced.Child_DBObject_Type As [Child_Type]
FROM
(
    SELECT
         [Object_ID] As DBObject_Id
        ,Schema_Name([Schema_ID]) As DBObject_Schema
        ,Name As DBObject
        ,Type_Desc As DBObject_Type
    FROM
        sys.objects
    WHERE
        Type Not In('D','IT','PK','SQ','UQ','U','S','TR')
) Referencing
LEFT OUTER JOIN
(
    SELECT
         Id As Parent_DBObject_Id
        ,DepId As Child_DBObject_Id
        ,Schema_Name([Schema_ID]) As Child_DBBObject_Schema
        ,Name As Child_DBObject
        ,Type_Desc As Child_DBObject_Type
    FROM
        sysdepends 
    JOIN   
        sys.objects
    ON
        [Object_ID] = DepId
    GROUP BY
        Id, DepId, [Schema_Id], Name, Type_Desc
) Referenced
ON
    Referencing.DBObject_Id = Referenced.Parent_DBObject_Id
Se você quiser obter as dependências de um objeto especifico, a cláusula WHERE deve ficar desta maneira:
1
2
3
4
5
(...)
ON
    Referencing.DBObject_Id = Referenced.Parent_DBObject_Id
WHERE
    Referencing.DBObject = 'ObjectName'
Ou caso você queria obter os objetos pais de um objeto especifico (são referenciados), a cláusula WHERE deve ficar desta maneira:
1
2
3
4
5
(...)
ON
    Referencing.DBObject_Id = Referenced.Parent_DBObject_Id
WHERE
    Referenced.Child_DBObject = 'ObjectName'