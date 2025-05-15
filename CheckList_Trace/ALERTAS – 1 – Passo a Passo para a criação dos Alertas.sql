/*******************************************************************************************************************************
--	Sequencia de execucao de Scripts para criar os Alertas do Banco de Dados.
*******************************************************************************************************************************/

--------------------------------------------------------------------------------------------------------------------------------
-- 1)	Criar o Operator para colocar na Notificacao de Falha dos JOBS que serao criados e tambem nos Alertas de Severidade
--		Cria a Base Traces
--------------------------------------------------------------------------------------------------------------------------------
USE [msdb]

GO

EXEC [msdb].[dbo].[sp_add_operator]
		@name = N'Alerta_BD',
		@enabled = 1,
		@pager_days = 0,
		@email_address = N'victor.silva@pointsystems.com.br'	-- Para colocar mais destinatarios, basta separar o email com ponto e virgula ";"
GO

/* 
-- Caso nao tenha a base "Traces", execute o codigo abaixo (lembre de alterar o caminho tambem).
USE master

GO

--------------------------------------------------------------------------------------------------------------------------------
--	1.1) Alterar o caminho para um local existente no seu servidor.
--------------------------------------------------------------------------------------------------------------------------------
CREATE DATABASE [Traces] 
	ON  PRIMARY ( 
		NAME = N'Traces', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.DBA01\MSSQL\DATA\Traces.mdf' , 
		SIZE = 102400KB , FILEGROWTH = 102400KB 
	)
	LOG ON ( 
		NAME = N'Traces_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.DBA01\MSSQL\DATA\Traces_log.ldf' , 
		SIZE = 30720KB , FILEGROWTH = 30720KB 
	)
GO

--------------------------------------------------------------------------------------------------------------------------------
-- 1.2) Utilizar o Recovery Model SIMPLE, pois nao tem muito impacto perder 1 dia de informacao nessa base de log.
--------------------------------------------------------------------------------------------------------------------------------
ALTER DATABASE [Traces] SET RECOVERY SIMPLE

GO
*/

--------------------------------------------------------------------------------------------------------------------------------
-- 2)	Abrir o script "..\Caminho\ALERTAS - 2 - Criacao da Tabela de Controle dos Alertas.txt", ler as instrucoes e executa-lo.
--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
-- 3)	Abrir o script "..\Caminho\ALERTAS - 3 - PreRequisito - QueriesDemoradas.txt", ler as instrucoes e executa-lo.
--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
-- 4)	Abrir o script "..\Caminho\ALERTAS - 4 - Criacao das Procedures dos Alertas.txt", ler as instrucoes e executa-lo.
--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
-- 5)	Abrir o script "..\Caminho\ALERTAS - 5 - Criacao dos JOBS dos Alertas.txt", ler as instrucoes e executa-lo.
--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
-- 6)	Abrir o script "..\Caminho\ALERTAS - 6 - Criacao dos Alertas de Severidade.txt", ler as instrucoes e executa-lo.
--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
-- 7)	Abrir o script "..\Caminho\ALERTAS - 7 - Teste Alertas.txt", ler as instrucoes e executa-lo.
--------------------------------------------------------------------------------------------------------------------------------