SELECT
	T.name as Tabela,
	C.name as Coluna,
	TY.name as Tipo,
	C.max_length AS Tamanho_Maximo, -- Tamanho em bytes, para nvarchar normalmente se divide este valor por 2
	C.precision AS Precisao, -- Para tipos numeric e decimal (tamanho)
	C.scale AS Escala -- Para tipos numeric e decimal (números após a virgula)
FROM 
	sys.columns C
INNER JOIN 
	sys.tables T
ON 
	T.object_id = C.object_id
INNER JOIN 
	sys.types TY
ON 
	TY.user_type_id = C.user_type_id
ORDER BY 
	T.name, 
	C.name