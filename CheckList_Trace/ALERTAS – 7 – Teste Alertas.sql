-- delete from DBA_MON..Alerta where Dt_Alerta = getdate()-1
/*
Instrucoes para realizar os testes.

Colocar a execucao da procedure EXEC [dbo].[stpAlerta_Queries_Demoradas] no JOB de Traces.

Testar o alerta de lock sozinho

Executar os outros testes


*/


/*******************************************************************************************************************************
--	Cria a database de teste - Deve ser excluida no final do teste
*******************************************************************************************************************************/
USE [master]

IF EXISTS (SELECT NULL FROM sys.databases WHERE NAME = 'Teste_Alerta')
	DROP DATABASE [Teste_Alerta]

CREATE DATABASE [Teste_Alerta]

ALTER DATABASE [Teste_Alerta] SET RECOVERY SIMPLE

GO

/*******************************************************************************************************************************
--	Processo Bloqueado
*******************************************************************************************************************************/
USE [Teste_Alerta]

-- Cria uma tabela de teste
CREATE TABLE [dbo].[Teste_Lock] ([cod] INT)
	
INSERT INTO [dbo].[Teste_Lock] ([cod]) VALUES (6)
	
-- Executar em outra conexao (Conexao 1)
BEGIN TRAN
UPDATE [dbo].[Teste_Lock]
SET [cod] = [cod]

-- COMMIT
	
-- Executar em outra conexao (Conexao 2) - Ira ficar bloqueada!
BEGIN TRAN
UPDATE [dbo].[Teste_Lock]
SET [cod] = [cod]
	
-- COMMIT

-- Para conferir os Processos Bloqueados
EXEC [dbo].[sp_WhoIsActive]

-- ALERTA
-- Apos 2 minutos de Lock, executar a procedure abaixo para enviar o ALERTA
EXEC [DBA_MON].[dbo].[stpAlerta_Processo_Bloqueado]

-- CLEAR
-- Executar o COMMIT nas Conexoes 1 e 2. Por fim, executar a procedure abaixo para enviar o CLEAR
EXEC [DBA_MON].[dbo].[stpAlerta_Processo_Bloqueado]

-- Exclui a tabela de Teste
DROP TABLE [dbo].[Teste_Lock]

GO

/*******************************************************************************************************************************
--	Arquivo de Log Full
*******************************************************************************************************************************/
USE [DBA_MON]

-- ALERTA
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 1
WHERE Nm_Alerta = 'Arquivo de Log Full'

EXEC [dbo].[stpAlerta_Arquivo_Log_Full]

SELECT * FROM [dbo].[Alerta] ORDER BY [Dt_Alerta] DESC
select * from [Alerta_Parametro] where Nm_Alerta = 'Arquivo de Log Full'

-- CLEAR
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 85
WHERE Nm_Alerta = 'Arquivo de Log Full'

EXEC [dbo].[stpAlerta_Arquivo_Log_Full]

GO 5

/*******************************************************************************************************************************
--	Espaco Disco
*******************************************************************************************************************************/
USE [DBA_MON]

-- ALERTA
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 1
WHERE Nm_Alerta = 'Espaco Disco'

EXEC [dbo].[stpAlerta_Espaco_Disco]

-- CLEAR
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 85
WHERE Nm_Alerta = 'Espaco Disco'

EXEC [dbo].[stpAlerta_Espaco_Disco]

GO

/*******************************************************************************************************************************
--	Consumo CPU
*******************************************************************************************************************************/
USE [DBA_MON]

-- ALERTA
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 1
WHERE Nm_Alerta = 'Consumo CPU'

EXEC [dbo].[stpAlerta_Consumo_CPU]

-- CLEAR
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 85
WHERE Nm_Alerta = 'Consumo CPU'

EXEC [dbo].[stpAlerta_Consumo_CPU]

GO

/*
/*******************************************************************************************************************************
--	MaxSize Arquivo SQL
*******************************************************************************************************************************/
USE [master]

-- ALERTA
ALTER DATABASE [Teste_Alerta] 
MODIFY FILE ( NAME = N'Teste_Alerta', SIZE = 7144KB, MAXSIZE = 10240KB , FILEGROWTH = 10120KB )

EXEC [DBA_MON].[dbo].[stpAlerta_MaxSize_Arquivo_SQL]
	
-- CLEAR
ALTER DATABASE [Teste_Alerta] 
MODIFY FILE ( NAME = N'Teste_Alerta', FILEGROWTH = 216KB )

EXEC [DBA_MON].[dbo].[stpAlerta_MaxSize_Arquivo_SQL]

GO
*/
/*******************************************************************************************************************************
--	Tamanho Arquivo MDF Tempdb
*******************************************************************************************************************************/
USE [DBA_MON]

-- ALERTA
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 0
WHERE Nm_Alerta = 'Tempdb Utilizacao Arquivo MDF'

EXEC [dbo].[stpAlerta_Tempdb_Utilizacao_Arquivo_MDF]

-- CLEAR
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 70
WHERE Nm_Alerta = 'Tempdb Utilizacao Arquivo MDF'

EXEC [dbo].[stpAlerta_Tempdb_Utilizacao_Arquivo_MDF]

GO

/*******************************************************************************************************************************
--	Conexao SQL Server
*******************************************************************************************************************************/
USE [DBA_MON]

-- ALERTA
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 2
WHERE Nm_Alerta = 'Conexao SQL Server'

EXEC [dbo].[stpAlerta_Conexao_SQLServer]

-- CLEAR
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 2000
WHERE Nm_Alerta = 'Conexao SQL Server'

EXEC [dbo].[stpAlerta_Conexao_SQLServer]

GO

/*******************************************************************************************************************************
--	Status Database / Pagina Corrompida
*******************************************************************************************************************************/
USE [master]

-- ALERTA
ALTER DATABASE [Teste_Alerta] SET OFFLINE

EXEC [DBA_MON].[dbo].[stpAlerta_Erro_Banco_Dados]

-- CLEAR
ALTER DATABASE [Teste_Alerta] SET ONLINE

EXEC [DBA_MON].[dbo].[stpAlerta_Erro_Banco_Dados]

GO

/*******************************************************************************************************************************
--	Queries Demoradas
*******************************************************************************************************************************/
USE [DBA_MON]

-- ALERTA
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 1
WHERE Nm_Alerta = 'Queries Demoradas'

EXEC [dbo].[stpAlerta_Queries_Demoradas]

-- Volta para o valor Default
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 100
WHERE Nm_Alerta = 'Queries Demoradas'

GO

/*******************************************************************************************************************************
--	Jobs Falharam
*******************************************************************************************************************************/
USE [DBA_MON]

-- ALERTA
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 48
WHERE Nm_Alerta = 'Job Falha'

EXEC [dbo].[stpAlerta_Job_Falha]

-- Volta para o valor Default
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 24
WHERE Nm_Alerta = 'Job Falha'

GO

/*******************************************************************************************************************************
--	SQL Server Reiniciado
*******************************************************************************************************************************/
USE [DBA_MON]

-- ALERTA
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 500000
WHERE Nm_Alerta = 'SQL Server Reiniciado'

EXEC [dbo].[stpAlerta_SQL_Server_Reiniciado]

-- Volta para o valor Default
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 20
WHERE Nm_Alerta = 'SQL Server Reiniciado'

GO

/*******************************************************************************************************************************
--	Database Criada
*******************************************************************************************************************************/
USE [DBA_MON]

-- ALERTA
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 48
WHERE Nm_Alerta = 'Database Criada'

EXEC [dbo].[stpAlerta_Database_Criada]

-- Volta para o valor Default
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 24
WHERE Nm_Alerta = 'Database Criada'

GO

/*******************************************************************************************************************************
--	Database sem Backup
*******************************************************************************************************************************/
USE [DBA_MON]

-- ALERTA
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 0
WHERE Nm_Alerta = 'Database sem Backup'

EXEC [dbo].[stpAlerta_Database_Sem_Backup]

-- Volta para o valor Default
UPDATE [dbo].[Alerta_Parametro]
SET [Vl_Parametro] = 24
WHERE Nm_Alerta = 'Database sem Backup'

GO

/*******************************************************************************************************************************
--	Processos em execucao
*******************************************************************************************************************************/
USE [DBA_MON]

EXEC [dbo].[stpEnvia_Email_Processos_Execucao]

GO

/*******************************************************************************************************************************
--	Alertas de Severidade
*******************************************************************************************************************************/
RAISERROR ('Teste Erro de Severidade', 21, 1) WITH LOG

GO

/*******************************************************************************************************************************
--	Confere o Resultado dos Testes dos Alertas
*******************************************************************************************************************************/
USE [DBA_MON]

SELECT * FROM DBA_MON..[dbo].[Alerta_Parametro] ORDER BY [Id_Alerta_Parametro]

SELECT * FROM DBA_MON..[dbo].[Alerta] ORDER BY [Dt_Alerta] DESC
DELETE  FROM DBA_MON..[Alerta]
DROP DATABASE DBA_MON..[Teste_Alerta]



select * from DBA_MON..[Alerta_Parametro] where Id_Alerta_Parametro <> 2

update DBA_MON..[Alerta_Parametro] set Ds_Email = 'vhss13@gmail.com, victor@silva@pointsystems.com.br' where Id_Alerta_Parametro <> 2

