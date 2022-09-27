USE DBAFMU
GO 

/*
select * from [DisplayToID]
select * from [CounterDetails]
select * from [CounterData] order by GUID, RecordIndex, CounterID

select * from [DBA_DB_SIZE]
select * from [DBA_DB_TABLESIZE]

select count(*) from [dbo].[DisplayToID]
select count(*) from [dbo].[CounterDetails]
select count(*) from [dbo].[CounterData]

select count(*) from [DBA_DB_SIZE]
select count(*) from [DBA_DB_TABLESIZE]

select * from [DBATIVIT_VW_Carga_Capacidade_Disco]
select * from [DBATIVIT_VW_Carga_Capacidade_BancoDatafile]
select * from [DBATIVIT_VW_Carga_Capacidade_BancoTabela]
select * from [DBATIVIT_VW_Carga_Parametros_Banco]
select * from [DBATIVIT_VW_Carga_PerfmonCollector]

SELECT * FROM [DS_Carga_Capacidade_Disco]
SELECT * FROM [DS_Carga_Capacidade_BancoDatafile]
SELECT * FROM [DS_Carga_Capacidade_BancoTabela]
SELECT * FROM [DS_Carga_Parametros_Banco]
SELECT * FROM [DS_Carga_PerfmonCollector]


SELECT COUNT(*) FROM [DS_Carga_Capacidade_Disco]
SELECT COUNT(*) FROM [DS_Carga_Capacidade_BancoDatafile]
SELECT COUNT(*) FROM [DS_Carga_Capacidade_BancoTabela]
SELECT COUNT(*) FROM [DS_Carga_Parametros_Banco]
SELECT COUNT(*) FROM [DS_Carga_PerfmonCollector]

TRUNCATE TABLE [DS_Carga_Capacidade_Disco]
TRUNCATE TABLE [DS_Carga_Capacidade_BancoDatafile]
TRUNCATE TABLE [DS_Carga_Capacidade_BancoTabela]
TRUNCATE TABLE [DS_Carga_Parametros_Banco]
TRUNCATE TABLE [DS_Carga_PerfmonCollector]

INSERT INTO [DS_Carga_Capacidade_Disco]			SELECT * FROM [DBAFMU_VW_Carga_Capacidade_Disco] 
INSERT INTO [DS_Carga_Capacidade_BancoDatafile]	SELECT * FROM [DBAFMU_VW_Carga_Capacidade_BancoDatafile]
INSERT INTO [DS_Carga_Capacidade_BancoTabela]	SELECT * FROM [DBAFMU_VW_Carga_Capacidade_BancoTabela]
INSERT INTO [DS_Carga_Parametros_Banco]			SELECT * FROM [DBAFMU_VW_Carga_Parametros_Banco]
INSERT INTO [DS_Carga_PerfmonCollector]			SELECT * FROM [DBAFMU_VW_Carga_PerfmonCollector]

*/

SELECT * FROM [DS_Carga_Capacidade_Disco] 
SELECT * FROM [DS_Carga_Capacidade_BancoDatafile]
SELECT * FROM [DS_Carga_Capacidade_BancoTabela]
SELECT * FROM [DS_Carga_Parametros_Banco]
SELECT * FROM [DS_Carga_PerfmonCollector]
