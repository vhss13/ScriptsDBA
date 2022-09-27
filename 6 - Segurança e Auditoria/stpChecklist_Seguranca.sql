IF (OBJECT_ID('dbo.stpChecklist_Seguranca') IS NULL) EXEC('CREATE PROCEDURE dbo.stpChecklist_Seguranca AS SELECT 1')
GO

--------------------------------------------------------------------------------------------------------------------
--
-- stpChecklist_Seguranca - 1.0.4 (11/04/2019)
-- Checklist de seguran�a para ambientes SQL Server - Mais de 70 valida��es de seguran�a!!
-- 
-- Precisa de ajuda para corrigir algum problema?
-- contato@fabriciolima.net
--
--------------------------------------------------------------------------------------------------------------------

ALTER PROCEDURE dbo.stpChecklist_Seguranca
AS 
BEGIN


    SET NOCOUNT ON


    IF (OBJECT_ID('tempdb..#Resultado') IS NOT NULL) DROP TABLE #Resultado
    CREATE TABLE #Resultado (
        Id_Verificacao INT NOT NULL PRIMARY KEY,
        Ds_Categoria VARCHAR(100) NOT NULL,
        Ds_Titulo VARCHAR(100) NOT NULL,
        Ds_Resultado VARCHAR(100) NOT NULL,
        Ds_Descricao VARCHAR(MAX) NOT NULL,
        Ds_Verificacao VARCHAR(MAX) NULL,
        Ds_Sugestao VARCHAR(MAX) NULL,
        Ds_Referencia VARCHAR(500) NULL,
        Ds_Detalhes XML NULL
    )
    

    DECLARE
        @Resultado XML,
        @ResultadoString VARCHAR(MAX),
        @Versao INT,
        @Quantidade INT,
        @Data DATETIME,
        @IsAmazonRDS BIT = (CASE WHEN LEFT(CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS VARCHAR(8000)), 8) = 'EC2AMAZ-' AND LEFT(CAST(SERVERPROPERTY('MachineName') AS VARCHAR(8000)), 8) = 'EC2AMAZ-' AND LEFT(CAST(SERVERPROPERTY('ServerName') AS VARCHAR(8000)), 8) = 'EC2AMAZ-' THEN 1 ELSE 0 END),
        @Query VARCHAR(MAX),
        @Dt_Hoje DATE = GETDATE()
    

    SET @Versao = (CASE LEFT(CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion')), 2)
        WHEN '8.' THEN 2000
        WHEN '9.' THEN 2005
        WHEN '10' THEN 2008
        WHEN '11' THEN 2012
        WHEN '12' THEN 2014
        WHEN '13' THEN 2016
        WHEN '14' THEN 2017
        WHEN '15' THEN 2019
        ELSE 2019
    END)

    
    ---------------------------------------------------------------------------------------------------------------
    -- Informa��es de inicializa��o
    ---------------------------------------------------------------------------------------------------------------

    IF (@IsAmazonRDS = 0)
    BEGIN


        DECLARE
            @RegHive VARCHAR(50),
            @RegKey VARCHAR(100)

        SET @RegHive = 'HKEY_LOCAL_MACHINE'
        SET @RegKey = 'Software\Microsoft\MSSQLSERVER\MSSQLServer\Parameters'

        DECLARE @SQLArgs TABLE
        (
            [Value] VARCHAR(50),
            [Data] VARCHAR(500),
            ArgNum AS CONVERT(INTEGER, REPLACE(Value, 'SQLArg', ''))
        )

        INSERT INTO @SQLArgs
        EXECUTE master.sys.xp_instance_regenumvalues @RegHive, @RegKey

    

        SET @Resultado = NULL

        SET @Resultado = (
            SELECT *
            FROM @SQLArgs
            FOR XML PATH, ROOT('Startup_Parameters')
        )


        DECLARE @GetInstances TABLE ( 
            [Value] nvarchar(100),
            InstanceNames nvarchar(100),
            [Data] nvarchar(100)
        )

        INSERT INTO @GetInstances
        EXECUTE master.dbo.xp_regread
            @rootkey = 'HKEY_LOCAL_MACHINE',
            @key = 'SOFTWARE\Microsoft\Microsoft SQL Server',
            @value_name = 'InstalledInstances'


        DECLARE 
            @Instancias VARCHAR(MAX),
            @Qt_Instancias INT = (SELECT COUNT(*) FROM @GetInstances)
    
        SET @Instancias = ''

        SELECT 
            @Instancias += (CASE WHEN @Instancias = '' THEN '' ELSE '; ' END) + A.InstanceNames
        FROM
            @GetInstances A


    END


    SET @Data = (SELECT sqlserver_start_time FROM sys.dm_os_sys_info)
    
    DECLARE @PortaUtilizada INT = (SELECT TOP(1) local_tcp_port FROM sys.dm_exec_connections WHERE local_tcp_port IS NOT NULL ORDER BY session_id)

    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Detalhes
    )
    VALUES
        (-8, 'Avisos', 'Copyright', 'Informativo', 'stpChecklist_Seguranca 1.0', '<Detalhes><Copyright>Stored Procedure desenvolvida por Dirceu Resende</Copyright><Website>https://www.dirceuresende.com</Website></Detalhes>'),
        (-7, 'Avisos', 'Vers�o', 'Informativo', @@VERSION, NULL),
        (-6, 'Avisos', 'Informa��es da m�quina', 'Informativo', 'ComputerNamePhysicalNetBIOS: ' + COALESCE(CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS VARCHAR(500)), '') + ' | Nome do servidor: ' + COALESCE(CAST(SERVERPROPERTY('MachineName') AS VARCHAR(500)), '') + ' | Inst�ncia: ' + COALESCE(ISNULL(CAST(SERVERPROPERTY('InstanceName') AS VARCHAR(500)), 'MSSQLSERVER'), '') + ' | Porta: ' + COALESCE(CAST(@PortaUtilizada AS VARCHAR(20)), '1433'), NULL),
        (-5, 'Avisos', 'Data de Inicializa��o', 'Informativo', CONVERT(VARCHAR(10), @Data, 103) + ' ' + CONVERT(VARCHAR(10), @Data, 108) + ' (' + CONVERT(VARCHAR(10), DATEDIFF(DAY, @Data, GETDATE())) + ' dias atr�s)', NULL)



    IF (@IsAmazonRDS = 0)
    BEGIN

        INSERT INTO #Resultado
        (
            Id_Verificacao,
            Ds_Categoria,
            Ds_Titulo,
            Ds_Resultado,
            Ds_Descricao,
            Ds_Detalhes
        )
        VALUES
            (-4, 'Avisos', 'Par�metros de Inicializa��o', 'Informativo', 'Verifica os par�metros de inicializa��o utilizados pela inst�ncia do SQL Server', @Resultado),
            (-3, 'Avisos', 'Inst�ncias no servidor', 'Informativo', CAST(@Qt_Instancias AS VARCHAR(10)) + ' inst�ncias instaladas: ' + @Instancias, NULL)

    END



    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Detalhes
    )
    VALUES
        (-2, 'Avisos', 'Inst�ncias rodando em CLUSTER', 'Informativo', (CASE WHEN CAST(SERVERPROPERTY('IsClustered') AS VARCHAR(10)) = '1' THEN 'SIM' ELSE 'N�O' END), NULL),
        (-1, 'Avisos', 'Ajuda', 'Informativo', 'Encontrou algum problema e precisa de ajuda? Solicite agora uma consultoria e protega seu ambiente com uma equipe de especialistas', '<Contatos><Whatsapp>https://bit.ly/dirceuresende</Whatsapp><Telegram>https://t.me/dirceuresende</Telegram><Skype>@dirceuresende</Skype><Email>contato@fabriciolima.net</Email></Contatos>'),
        (0, '----------------------', '----------------------', '----------------------', '----------------------', NULL)


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se o banco est� como TRUSTWORTHY
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name] 
        FROM 
            sys.databases 
        WHERE 
            is_trustworthy_on = 1 
            AND [name] <> 'msdb' 
        FOR XML PATH, ROOT('Databases')
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            1, 
            'Configura��o',
            'Trustworthy', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite executar comandos maliciosos dentro do database e "tomar o controle" de outros databases por usu�rios que est�o na role db_owner',
            'Verifica se algum database possui a propriedade "TRUSTWORTHY" habilitado',
            'Desative a propriedade "TRUSTWORTHY" de todos os databases. Caso utilize para assemblies SQLCLR, utilize chaves de criptografia',
            'https://www.dirceuresende.com/blog/sql-server-entendendo-os-riscos-da-propriedade-trustworthy-habilitada-em-um-database/',
            @Resultado
        )

    
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se a inst�ncia est� auditando falhas de login
    ---------------------------------------------------------------------------------------------------------------

    DECLARE @AuditLevel INT

    EXEC master.dbo.xp_instance_regread
        @rootkey = 'HKEY_LOCAL_MACHINE',
        @key = 'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer',
        @value_name = 'AuditLevel',
        @value = @AuditLevel OUTPUT


    SET @Resultado = NULL

    IF (@AuditLevel < 2)
    BEGIN

        SET @Resultado = (
            SELECT 
                (CASE @AuditLevel
                    WHEN 0 THEN '0 - Nenhum'
                    WHEN 1 THEN '1 - Apenas logins com sucesso'
                    ELSE NULL
                END) AS Nivel_Auditoria_Login
            FOR XML PATH, ROOT('Nivel_Auditoria_Login')
        )

    END
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            2, 
            'Configura��o',
            'Auditoria de Falhas de Login', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite auditar falhas de login na inst�ncia quando usu�rios erram a senha. Essa configura��o � recomend�vel estar ativada para conseguir identificar poss�veis ataques de for�a-bruta na inst�ncia', 
            'Verifica se a inst�ncia est� gravando no log quando o usu�rio erra uma senha',
            'Ativar a auditoria de conex�o para falhas de login',
            'https://www.mssqltips.com/sqlservertip/1735/auditing-failed-logins-in-sql-server/',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se a inst�ncia est� permitindo logins SQL Server
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Quantidade = CONVERT(INT, SERVERPROPERTY('IsIntegratedSecurityOnly'))
    
    
    SET @Resultado = NULL

    IF (@Quantidade = 0)
    BEGIN

        SET @Resultado = (
            SELECT 
                (CASE @Quantidade  
                    WHEN 0 THEN '0 - Autentica��o Windows e SQL Server'
                    ELSE NULL
                END) AS Nivel_Auditoria_Login
            FOR XML PATH, ROOT('Nivel_Auditoria_Login')
        )

    END
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            3, 
            'Configura��o',
            'Autentica��o Windows Apenas',
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite a autentica��o utilizando Seguran�a Integrada do Windows (mais seguro), mas tamb�m autentica��o SQL Server, utiliando usu�rio e senha (menos seguro). Essa configura��o n�o � exatamente um problema, pois existem aplica��es legadas que requerem autentica��o SQL Server, mas � uma boa pr�tica evitar esse cen�rio, quando poss�vel.',
            'Verifica se a inst�ncia est� permitindo conex�es de logins SQL Server',
            'Desativar a autentica��o de logins SQL Server, quando poss�vel',
            'https://docs.microsoft.com/pt-br/sql/relational-databases/security/choose-an-authentication-mode?view=sql-server-2017',
            @Resultado
        )

        
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se est� habilitado "Ad hoc distributed queries"
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'Ad hoc distributed queries'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            4, 
            'Configura��o',
            'Ad hoc distributed queries', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite executar poss�veis comandos remotamente atrav�s de OPENROWSET/OPENDATASOURCE. Os poss�veis problemas de seguran�a causados por essa configura��o � a possibilidade do provider conter algum bug de seguran�a, possibilidade de um servidor comprometido acessar dados de um servidor ainda n�o comprometido ou mesmo um servidor comprometido enviar de volta informa��es durante ataques hackers',
            'Verifica se a configura��o "Ad hoc distributed queries" est� habilitada no sp_configure',
            'Desativar a configura��o "Ad hoc distributed queries" caso n�o esteja utilizando OPENROWSET/OPENDATASOURCE e nem o SQL Server 2005',
            'https://cuttingedge.it/blogs/steven/pivot/entry.php?id=44',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se est� habilitado "cross db ownership chaining"
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'cross db ownership chaining'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            5, 
            'Configura��o',
            'cross db ownership chaining', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite que uma pessoa acesse objetos que ela n�o tenha acesso em outro database atrav�s de cen�rios espec�ficos de "cross db ownership chaining"',
            'Verifica se a configura��o "cross db ownership chaining" est� ativa no sp_configure',
            'Desative a configura��o "cross db ownership chaining" caso n�o esteja utilizando esse recurso (sua utiliza��o n�o � muito comum)',
            'http://www.sqlservercentral.com/articles/Stairway+Series/123545/',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se a m�quina n�o est� aplicando Windows Updates
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL
    SET @Quantidade = (SELECT DATEDIFF(DAY, sqlserver_start_time, GETDATE()) FROM sys.dm_os_sys_info)

    IF (@Quantidade > 60)
    BEGIN

        SET @Resultado = (
            SELECT 
                sqlserver_start_time 
            FROM 
                sys.dm_os_sys_info WITH(NOLOCK)
            FOR XML PATH, ROOT('Inicializa��o')
        )

    END
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            6, 
            'Configura��o',
            'Atualiza��es do SQL Server/Windows', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado (pelo menos ' + CONVERT(VARCHAR(10), @Quantidade) + ' dias sem atualiza��o)' END), 
            'Essa valida��o identifica quando a inst�ncia est� h� mais de 60 dias sem ser reiniciada, indicando que atualiza��es de Windows e do SQL Server n�o est�o sendo aplicados',
            'Verifica a quantos dias o servi�o do SQL Server est� online',
            'Aplique atualiza��es de Windows e tamb�m Service Packs e Cumulative Updates do SQL Server. Muitas atualiza��es s�o corre��es e pacotes de seguran�a',
            'https://sqlserverbuilds.blogspot.com/',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica databases sem verifica��o de p�gina
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name] AS 'Database/@name',
            page_verify_option_desc AS 'Database/@page_verify_option_desc',
            create_date AS 'Database/@create_date',
            [compatibility_level] AS 'Database/@compatibility_level',
            collation_name AS 'Database/@collation_name',
            user_access_desc AS 'Database/@user_access_desc',
            state_desc AS 'Database/@state_desc',
            recovery_model_desc AS 'Database/@recovery_model_desc'
        FROM 
            sys.databases WITH(NOLOCK) 
        WHERE
            page_verify_option <> 2 -- CHECKSUM
            AND [state] = 0 -- ONLINE
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Configuracao'), TYPE
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            7, 
            'Configura��o',
            'Databases sem verifica��o de p�gina', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite que o SQL Server grave um CHECKSUM em cada p�gina � medida que vai para o armazenamento e, em seguida, verifique o CHECKSUM novamente quando os dados s�o lidos do disco para tentar garantir a integridade dos dados. Isso pode gerar uma pequena sobrecarga de CPU, mas normalmente vale a pena recuperar-se da corrup��o',
            'Verifica se algum database est� utilizando algum algoritmo de valida��o de p�gina diferente do CHECKSUM (NONE ou TORN_PAGE)',
            'Altere o algoritmo de valida��o de p�gina de todos os databases para CHECKSUM',
            'https://www.brentozar.com/blitz/page-verification/',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se o default trace est� ativado
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            *
        FROM 
            sys.traces WITH(NOLOCK) 
        WHERE 
            is_default = 1
            AND [status] = 0
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            8, 
            'Configura��o',
            'Default trace habilitado', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite que o SQL Server colete algumas informa��es da inst�ncia pelo Default Trace, como alguns comandos de DDL, DCL, etc.',
            'Verifica se o trace padr�o do SQL Server est� habilitado e executando',
            'Habilite o trace padr�o do SQL Server para auditar eventos',
            'https://www.dirceuresende.com/blog/utilizando-o-trace-padrao-do-sql-server-para-auditar-eventos-fn_trace_gettable/',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se est� habilitado "scan for startup procs"
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'scan for startup procs'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            9, 
            'Configura��o',
            'scan for startup procs', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite que uma pessoa monitore quais objetos s�o executados na inicializa��o do SQL Server e crie c�digos maliciosos nesses objetos.',
            'Verifica se a configura��o "scan for startup procs" est� habilitada na inst�ncia atrav�s da sp_configure',
            'Desative essa configura��o caso n�o esteja realizando nenhuma valida��o do que � executado durante a inicializa��o do SQL Server',
            'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-scan-for-startup-procs-server-configuration-option?view=sql-server-2017',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se est� habilitado o DatabaseMail
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'Database Mail XPs'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            10, 
            'Configura��o',
            'DatabaseMail XPs', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite que uma pessoa envie e-mails e informa��es do banco para outras pessoas utilizando o DatabaseMail. Embora isso seja bastante utilizado por sistemas e alertas, voc� deve verificar se isso realmente � necess�rio na inst�ncia e se est� sendo utilizado. Caso n�o esteja, desative essa op��o.',
            'Verifica se a configura��o "Database Mail XPs" est� habilitada na sp_configure',
            'Desative essa configura��o caso n�o tenha nenhuma rotina que envie e-mails pelo banco de dados e que n�o possa ser enviado pelo SSIS, por exemplo',
            'https://www.sqlshack.com/securing-sql-server-surface-area/',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se est� habilitado o SQL Mail XP (antigo DatabaseMail)
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK)
        WHERE 
            [name] = 'SQL Mail XP'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            11, 
            'Configura��o',
            'SQL Mail XP', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite que uma pessoa envie e-mails e informa��es do banco para outras pessoas utilizando o SQL Mail XP (Dispon�vel at� o SQL Server 2012. Ap�s isso, foi substitu�do pelo DatabaseMail). Embora isso seja bastante utilizado por sistemas e alertas, voc� deve verificar se isso realmente � necess�rio na inst�ncia e se est� sendo utilizado. Caso n�o esteja, desative essa op��o.',
            'Verifica se a configura��o "SQL Mail XP" est� habilitada na sp_configure',
            'Desative essa configura��o caso n�o tenha nenhuma rotina que envie e-mails pelo banco de dados e que n�o possa ser enviado pelo SSIS, por exemplo',
            'https://www.sqlshack.com/securing-sql-server-surface-area/',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se est� habilitado o Remote Admin Connections (DAC)
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'remote admin connections'
            AND value_in_use = 0
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            12, 
            'Configura��o',
            'Remote Admin Connections (DAC)', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite que usu�rios administradores (sysadmin) possam logar na inst�ncia mesmo quando ela est� com algum problema que impede o logon ou quando o limite de conex�es da inst�ncia � atingido. Essa configura��o deve ser habilitada para que seja poss�vel utiliz�-la em casos de emerg�ncia.',
            'Verifica se a configura��o "remote admin connections" est� habilitada na sp_configure',
            'Habilite a configura��o "remote admin connections" na sp_configure',
            'https://www.dirceuresende.com/blog/habilitando-e-utilizando-a-conexao-remota-dedicada-para-administrador-dac-no-sql-server/',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se est� habilitado o Remote Connections
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'remote access'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            13, 
            'Configura��o',
            'Remote Access', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite que usu�rios executem Stored Procedures remotamente atrav�s de Linked Server, permitindo que um hacker possa utilizar uma inst�ncia comprometida para realizar ataques de DDoS em outra inst�ncia da rede. Esse par�metro est� marcado como Deprecated e caso n�o seja utilizado por nenhuma rotina, deve ser desativado.',
            'Verifica se a configura��o "remote access" est� habilitada na sp_configure',
            'Desabilite a configura��o "remote access" caso voc� n�o utilize Stored Procedures remotamente, utilizando Linked Servers',
            'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-remote-access-server-configuration-option?view=sql-server-2017',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se est� habilitado SMO and DMO XPs
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'SMO and DMO XPs'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            14, 
            'Configura��o',
            'SMO and DMO XPs', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite que usu�rios programem no SQL Server utilizando linguagens de programa��o como C#, VB e PowerShell. Caso n�o esteja sendo utilizado, a boa pr�tica � desativar esse recurso. Obs: Caso esteja utilizando o SSMS 17 para acessar o SQL Server 2005, pode ser necess�rio habilitar esse par�metro para conseguir utilizar o SSMS',
            'Verifica se a configura��o "SMO and DMO XPs" est� habilitada na sp_configure',
            'Desative a configura��o "SMO and DMO XPs" caso n�o utilize programa��o SMO',
            'https://www.stigviewer.com/stig/microsoft_sql_server_2005_instance/2015-04-03/finding/V-15211',
            @Resultado
        )


    
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se existe alguma trigger a n�vel de servidor
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT DISTINCT 
            A.[name] AS 'Trigger/@trigger_name', 
            B.event_group_type_desc AS 'Trigger/@event_group_type_desc'
        FROM 
            sys.server_triggers A WITH(NOLOCK)
            JOIN sys.server_trigger_events B WITH(NOLOCK) ON B.[object_id] = A.[object_id]
        WHERE
            A.is_ms_shipped = 0
            AND A.is_disabled = 0
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Configuracao_Server_Triggers'), TYPE
    )

    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            15, 
            'Configura��o',
            'Server Trigger Habilitada', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Essa configura��o valida se alguma trigger a n�vel de servidor est� habilitada no ambiente. Esse recurso pode ser utilizado por hackers para impedir o logon de determinados usu�rios',
            'Verifica se alguma trigger a n�vel de servidor est� habilitada na inst�ncia',
            'Valide se essa server trigger est� correta e n�o influi em nenhum risco para os usu�rios',
            NULL,
            @Resultado
        )

        
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se existe algum trace habilitado no servidor
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            id AS 'Trace/@id',
            [status] AS 'Trace/@status',
            [path] AS 'Trace/@path',
            max_size AS 'Trace/@max_size',
            stop_time AS 'Trace/@stop_time',
            max_files AS 'Trace/@max_files',
            is_rowset AS 'Trace/@is_rowset',
            is_rollover AS 'Trace/@is_rollover',
            is_shutdown AS 'Trace/@is_shutdown',
            is_default AS 'Trace/@is_default',
            buffer_count AS 'Trace/@buffer_count',
            buffer_size AS 'Trace/@buffer_size',
            file_position AS 'Trace/@file_position',
            reader_spid AS 'Trace/@reader_spid',
            start_time AS 'Trace/@start_time',
            last_event_time AS 'Trace/@last_event_time',
            event_count AS 'Trace/@event_count',
            dropped_event_count AS 'Trace/@dropped_event_count'
        FROM
            sys.traces WITH(NOLOCK)
        WHERE
            is_default = 0
            AND [status] = 1
            AND [path] NOT LIKE '%Traces\Duracao.trc'
        FOR XML PATH(''), ROOT('Configuracao_Trace_Habilitado'), TYPE
    )


    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            16, 
            'Configura��o',
            'Trace Habilitado',
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Essa configura��o valida se algum trace est� habilitado no ambiente. Esse recurso permite analisar e capturar informa��es das consultas executadas no banco. Da mesma forma que isso pode ser utilizado para fins de auditoria, pode tamb�m ser utilizado para capturar dados sens�veis por pessoas mal intencionadas',
            'Verifica se algum trace (que n�o o trace default) est� habilitado na inst�ncia',
            'Valide se esse trace realmente foi criado pelo time de DBA e n�o influi em nenhum risco para os usu�rios',
            NULL,
            @Resultado
        )

        

    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se existe algum Extended Event (XE) habilitado no servidor
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT
            A.event_session_id AS 'Extended_Event/@event_session_id',
            A.[name] AS 'Extended_Event/@name',
            B.create_time AS 'Extended_Event/@create_time',
            C.target_name AS 'Extended_Event/@target_name',
            C.execution_count AS 'Extended_Event/@execution_count',
            C.execution_duration_ms AS 'Extended_Event/@execution_duration_ms',
            A.event_retention_mode_desc AS 'Extended_Event/@event_retention_mode_desc',
            CAST(C.target_data AS VARCHAR(MAX)) AS 'Extended_Event/@targetdata'
        FROM
            sys.server_event_sessions AS A WITH(NOLOCK) 
            LEFT JOIN sys.dm_xe_sessions AS B WITH(NOLOCK) ON A.[name] = B.[name]
            LEFT JOIN sys.dm_xe_session_targets AS C WITH(NOLOCK) ON C.event_session_address = B.[address]
        WHERE
            A.[name] NOT IN ( 'system_health', 'StretchDatabase_Health', 'telemetry_xevents', 'hkenginexesession', 'sp_server_diagnostics session', 'AlwaysOn_health', 'QuickSessionStandard', 'QuickSessionTSQL' )
        ORDER BY
            2
        FOR XML PATH(''), ROOT('Configuracao_XE_Habilitado'), TYPE
    )


    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            17, 
            'Configura��o',
            'Extended Events (XE) Habilitado',
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Essa configura��o valida se algum Extended Event (XE) est� habilitado no ambiente. Esse recurso permite analisar e capturar informa��es das consultas executadas no banco. Da mesma forma que isso pode ser utilizado para fins de auditoria, pode tamb�m ser utilizado para capturar dados sens�veis por pessoas mal intencionadas',
            'Verifica se algum Extended Event (que n�o os padr�es do SQL Server) est� habilitado na inst�ncia',
            'Valide se esse XE realmente foi criado pelo time de DBA e n�o influi em nenhum risco para os usu�rios',
            NULL,
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se existem erros no log de falha de login
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL
    
    DECLARE @Login_Failed TABLE ( [LogDate] datetime, [ProcessInfo] nvarchar(12), [Text] nvarchar(3999) )
        
    
    IF (@IsAmazonRDS = 0)
    BEGIN
    
        INSERT INTO @Login_Failed
        EXEC master.dbo.sp_readerrorlog 0, 1, 'Password did not match that for the login provided' 
    
    END
    
    
    SET @Resultado = (
        SELECT 
            LogDate AS 'Log/@Date',
            [Text] AS 'Log/@Mensagem'
        FROM 
            @Login_Failed
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Erro_Login_Senha_Incorreta'), TYPE
    )


    SELECT @Quantidade = COUNT(*) FROM @Login_Failed

    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
        Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            100, 
            'Seguran�a de Usu�rios',
            'Falha de usu�rio/senha', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado (' + CAST(@Quantidade AS VARCHAR(10)) + ' tentativas)' END), 
            'Verifica quantas tentativas de login tiveram falha por usu�rio e senha incorretos',
            'Verifica no log do SQL Server os eventos de falha de login por senha incorreta',
            'Verifique a origem dessas conex�es e caso n�o as conhe�a, bloqueie o IP no Firewall. Uma boa sugest�o � alterar periodicamente a senha dos usu�rios SQL e utilizar senhas fortes para evitar invas�es',
            'https://www.hackingarticles.in/4-ways-to-hack-ms-sql-login-password/',
            @Resultado
        )
    

    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rio "SA" habilitado
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.[name] AS [login],
            A.principal_id,
            A.[sid],
            A.[type_desc],
            A.is_disabled,
            A.create_date,
            A.modify_date
        FROM
            sys.server_principals A WITH(NOLOCK)
        WHERE
            A.principal_id = 1 -- sa
            AND A.is_disabled = 0
        FOR XML PATH, ROOT('Usuario_SA_Habilitado')
    )

    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            101, 
            'Seguran�a de Usu�rios',
            'Usu�rio SA', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Usu�rio padr�o do SQL Server que possui a permiss�o mais elevada poss�vel (sysadmin). Deve ser desativado e renomeado para evitar poss�veis ataques hackers',
            'Verifica se o usu�rio "sa" est� habilitado',
            'Desative o usu�rio "sa" e altere o nome desse usu�rio',
            'https://www.mssqltips.com/sqlservertip/2221/different-ways-to-secure-the-sql-server-sa-login/',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rios �rf�os
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE @Usuarios_Orfaos TABLE ( Ds_Database VARCHAR(256), Ds_Usuario VARCHAR(256) )

    SET @Query = '
SELECT
    ''?'' AS [database_name],
    [name] AS [user]
FROM
    [?].sys.database_principals WITH(NOLOCK)
WHERE
    [sid] NOT IN
    (
        SELECT
            [sid]
        FROM
            [?].sys.server_principals WITH(NOLOCK)
    )
    ' + (CASE WHEN @Versao > 2008 THEN 'AND authentication_type_desc = ''INSTANCE''' ELSE '' END) + '
    AND [type] = ''S''
    AND principal_id > 4
    AND DATALENGTH([sid]) <= 28
    AND [name] <> ''MS_DataCollectorInternalUser''
    AND [name] NOT LIKE ''##MS_%'''


    INSERT INTO @Usuarios_Orfaos (Ds_Database, Ds_Usuario)
    EXEC master.dbo.sp_MSforeachdb @Query


    SELECT @Quantidade = COUNT(*)
    FROM @Usuarios_Orfaos


    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            Ds_Database AS 'Usuario/@database',
            Ds_Usuario AS 'Usuario/@usuario'
        FROM 
            @Usuarios_Orfaos
        ORDER BY
            1, 2
        FOR XML PATH(''), ROOT('Usuarios_Orfaos'), TYPE
    )

    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            102, 
            'Seguran�a de Usu�rios',
            'Usu�rios �rf�os', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado (' + CAST(@Quantidade AS VARCHAR(10)) + ' usu�rios)' END), 
            'Usu�rios que n�o possuem logins associados. Provavelmente algum erro de mapeamento. Esses usu�rios devem ser removidos ou remapeados com o respectivo login. Esse tipo de situa��o pode ser utilizada por hackers para tentar acessar bases que esses usu�rios possuem permiss�o',
            'Verifica usu�rios criados nos databases e que n�o possuem logins associados na inst�ncia',
            'Tente refazer o mapeamento com a sp_change_users_login. Caso o login realmente n�o exista, tenta analisar se esse usu�rio pode ser removido',
            'https://www.dirceuresende.com/blog/identificando-e-resolvendo-problemas-de-usuarios-orfaos-no-sql-server-com-a-sp_change_users_login/',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rios sem pol�ticas de troca de senha
    ---------------------------------------------------------------------------------------------------------------

    DECLARE @UsuariosPoliticaSenha TABLE ( [login] nvarchar(128), [principal_id] int, [sid] varbinary(85), [type_desc] nvarchar(60), [is_policy_checked] bit, [is_expiration_checked] bit, [DaysUntilExpiration] INT, [PasswordLastSetTime] DATETIME, [IsExpired] BIT, [IsMustChange] BIT )

    INSERT INTO @UsuariosPoliticaSenha
    SELECT 
        A.[name] AS [login],
        A.principal_id,
        A.[sid],
        A.[type_desc],
        B.is_policy_checked,
        B.is_expiration_checked,
        CONVERT(INT, LOGINPROPERTY(B.[name], 'DaysUntilExpiration')) DaysUntilExpiration,
        CONVERT(DATETIME, LOGINPROPERTY(B.[name], 'PasswordLastSetTime')) PasswordLastSetTime,
        CONVERT(BIT, LOGINPROPERTY(B.[name], 'IsExpired')) IsExpired,
        CONVERT(BIT, LOGINPROPERTY(B.[name], 'IsMustChange')) IsMustChange
    FROM
        sys.server_principals A WITH(NOLOCK)
        JOIN sys.sql_logins B WITH(NOLOCK) ON B.[sid] = A.[sid]
    WHERE
        A.is_disabled = 0
        AND A.principal_id > 10


    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [login] AS 'Usuario/@login',
            principal_id AS 'Usuario/@principal_id',
            is_policy_checked AS 'Usuario/@is_policy_checked',
            is_expiration_checked AS 'Usuario/@is_expiration_checked',
            DaysUntilExpiration AS 'Usuario/@DaysUntilExpiration',
            PasswordLastSetTime AS 'Usuario/@PasswordLastSetTime',
            IsExpired AS 'Usuario/@IsExpired',
            IsMustChange AS 'Usuario/@IsMustChange'
        FROM
            @UsuariosPoliticaSenha
        WHERE
            is_policy_checked = 0 
            OR is_expiration_checked = 0
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Usuarios_Sem_Politica_de_Senha'), TYPE
    )


    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            103, 
            'Seguran�a de Usu�rios',
            'Usu�rios sem pol�ticas de troca de senha', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Logins SQL Server que n�o possuem pol�tica de senha, ou seja, a senha n�o expira e/ou n�o tem exig�ncias de complexidade definidas. Caso seja um usu�rio de aplica��o, esse alerta pode ser ignorado, mas caso seja login de um usu�rio, ele deve ser for�ado a trocar a senha regularmente e ter senhas dif�ceis de serem quebradas',
            'Verifica os logins que n�o possuem as op��es de expira��o de senha e/ou conformidade com as pol�ticas de senha',
            'Habilite as op��es de "enforce password policy" e "enforce password expiration" na tela de propriedades do login',
            'https://docs.microsoft.com/pt-br/sql/relational-databases/security/password-policy?view=sql-server-2017',
            @Resultado
        )


    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [login] AS 'Usuario/@login',
			PasswordLastSetTime AS 'Usuario/@PasswordLastSetTime',
            principal_id AS 'Usuario/@principal_id',
            is_policy_checked AS 'Usuario/@is_policy_checked',
            is_expiration_checked AS 'Usuario/@is_expiration_checked',
            DaysUntilExpiration AS 'Usuario/@DaysUntilExpiration',
            IsExpired AS 'Usuario/@IsExpired',
            IsMustChange AS 'Usuario/@IsMustChange'
        FROM
            @UsuariosPoliticaSenha
        WHERE
            is_expiration_checked = 0
            AND DaysUntilExpiration IS NULL
            AND DATEDIFF(DAY, PasswordLastSetTime, GETDATE()) > 180
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Usuarios_Senha_Antiga'), TYPE
    )


    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            104, 
            'Seguran�a de Usu�rios',
            'Usu�rios com senha antiga', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Logins SQL Server que a senha n�o expira e n�o � alterada h� mais de 180 dias. Mesmo sendo um usu�rio de aplica��o, a senha do usu�rio deve ser alterada regularmente para evitar poss�veis ataques hackers',
            'Verifica se a senha do login SQL Server n�o � alterada h� mais de 180 dias',
            'Altere a senha de todos os logins SQL Server regularmente para evitar vazamentos de senhas',
            'https://docs.microsoft.com/pt-br/sql/relational-databases/security/password-policy?view=sql-server-2017',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rios com senhas fracas
    ---------------------------------------------------------------------------------------------------------------

    DECLARE 
        @Contador INT, 
        @Total INT, 
        @Contador2 INT, 
        @Total2 INT, 
        @Atual VARCHAR(100)

    SELECT
        @Contador = 1,
        @Total = 10,
        @Contador2 = 1,
        @Total2 = 10,
        @Atual = ''
    
    DECLARE @Senhas TABLE ( Senha VARCHAR(100) )
    DECLARE @Usuarios_Senha_Fraca TABLE ( [Login] nvarchar(256), is_disabled BIT, is_policy_checked BIT, [Senha] NVARCHAR(200) )


    INSERT INTO @Senhas
    VALUES 
        ('teste'), ('TESTE'), ('password'), ('qwerty'),
        ('football'), ('baseball'), ('welcome'), ('abc123'),
        ('1qaz2wsx'), ('dragon'), ('master'), ('monkey'), ('letmein'),
        ('login'), ('princess'), ('qwertyuiop'), ('solo'), ('passw0rd'), 
        ('starwars'), ('teste123'), ('TESTE123'), ('deuseamor'), ('jesuscristo'),
        ('iloveyou'), ('MARCELO'), ('jc2512'), ('maria'), ('jose'), ('batman'),
        ('123123'), ('123123123'), ('FaMiLia'), (''), (' '), ('sexy'),
        ('abel123'), ('freedom'), ('whatever'), ('qazwsx'), ('trustno1'), ('sucesso'),
        ('1q2w3e4r'), ('1qaz2wsx'), ('1qazxsw2'), ('zaq12wsx'), ('! qaz2wsx'),
        ('!qaz2wsx'), ('123mudar'), ('gabriel'), ('102030'), ('010203'), ('101010'), ('131313'),
        ('vitoria'), ('flamengo'), ('felipe'), ('brasil'), ('felicidade'), ('mariana'), ('101010')
    

    -- N�meros repetidos
    WHILE(@Contador < @Total)
    BEGIN
    
        WHILE(@Contador2 < @Total2)
        BEGIN
        
            INSERT INTO @Senhas
            SELECT REPLICATE(CAST(@Contador AS VARCHAR(100)), @Contador2)

            SET @Contador2 += 1

        END

        SET @Contador += 1
        SET @Contador2 = 1

    END


    SET @Contador = 12
    SET @Contador2 = 1

    -- Letras repetidos
    WHILE(@Contador < 126)
    BEGIN
    
        WHILE(@Contador2 < @Total2)
        BEGIN
        
            INSERT INTO @Senhas
            SELECT REPLICATE(CHAR(@Contador), @Contador2)

            SET @Contador2 += 1

        END

        SET @Contador += 1
        SET @Contador2 = 1

    END


    -- Sequ�ncias
    SET @Contador = 0

    WHILE(@Contador <= @Total)
    BEGIN
    
        SET @Atual = @Atual + CAST((CASE WHEN @Contador = 10 THEN 0 ELSE @Contador END) AS VARCHAR(100))

        INSERT INTO @Senhas
        SELECT @Atual
    
        SET @Contador = @Contador + 1
    
    END


    SET @Contador = 1
    SET @Atual = ''

    WHILE(@Contador <= @Total)
    BEGIN
    
        SET @Atual = @Atual + CAST((CASE WHEN @Contador = 10 THEN 0 ELSE @Contador END) AS VARCHAR(100))

        INSERT INTO @Senhas
        SELECT @Atual
    
        SET @Contador = @Contador + 1
    
    END


    -- Logins
    INSERT INTO @Senhas
    SELECT [name]
    FROM sys.sql_logins WITH(NOLOCK)

    INSERT INTO @Senhas
    SELECT LOWER([name])
    FROM sys.sql_logins WITH(NOLOCK)

    INSERT INTO @Senhas
    SELECT UPPER([name])
    FROM sys.sql_logins WITH(NOLOCK)

    INSERT INTO @Senhas
    SELECT DISTINCT REVERSE(Senha)
    FROM @Senhas

    
    INSERT INTO @Usuarios_Senha_Fraca
    SELECT
        A.[name],
        A.is_disabled,
        A.is_policy_checked,
        B.Senha
    FROM 
        sys.sql_logins		    A WITH(NOLOCK)
        CROSS APPLY @Senhas		B
    WHERE
        PWDCOMPARE(B.Senha, A.password_hash) = 1

   

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT DISTINCT
            [Login] AS 'Usuario/@Login',
            Senha AS 'Usuario/@Senha',
            is_disabled AS 'Usuario/@is_disabled',
            is_policy_checked AS 'Usuario/@is_policy_checked'
        FROM
            @Usuarios_Senha_Fraca
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Usuarios_Senha_Fraca'), TYPE
    )


    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            105, 
            'Seguran�a de Usu�rios',
            'Usu�rios com senha fraca', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Logins SQL Server que possuem senhas fracas e que foram facilmente quebradas utilizando essa Stored Procedure',
            'Tenta quebrar a senha dos logins SQL utilizando a fun��o PWDCOMPARE e uma pequena base de senhas mais comuns',
            'Altere regularmente a senha dos logins SQL e utilize senhas fortes e complexas para dificultar ataques de for�a bruta',
            'https://www.dirceuresende.com/blog/sql-server-como-identificar-senhas-frageis-vazias-ou-iguais-ao-nome-do-usuario/',
            @Resultado
        )


	---------------------------------------------------------------------------------------------------------------
    -- Usu�rios sem Permiss�o
    ---------------------------------------------------------------------------------------------------------------
	
	DECLARE @Usuarios_Sem_Permissao TABLE ( [database_name] nvarchar(128), [name] nvarchar(128), [principal_id] int, [type_desc] nvarchar(60), [default_schema_name] nvarchar(128), [create_date] datetime, [modify_date] datetime )

    
	INSERT INTO @Usuarios_Sem_Permissao
    EXEC master.dbo.sp_MSforeachdb 'SELECT
    ''?'' AS [database_name],
	A.[name],
	A.principal_id,
	A.[type_desc],
	A.default_schema_name,
	A.create_date,
	A.modify_date
FROM
	[?].sys.database_principals A WITH(NOLOCK)
	LEFT JOIN [?].sys.database_role_members B WITH(NOLOCK) ON A.principal_id = B.member_principal_id
	LEFT JOIN [?].sys.database_permissions C WITH(NOLOCK) ON A.principal_id = C.grantee_principal_id
WHERE
	B.member_principal_id IS NULL
	AND C.grantee_principal_id IS NULL
	AND A.is_fixed_role = 0
    AND A.principal_id > 4'

    

    SELECT @Quantidade = COUNT(*)
    FROM @Usuarios_Sem_Permissao


    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [database_name] AS 'Usuario/@database',
            [name] AS 'Usuario/@name',
            principal_id AS 'Usuario/@principal_id',
            [type_desc] AS 'Usuario/@type_desc',
            default_schema_name AS 'Usuario/@default_schema_name',
            create_date AS 'Usuario/@create_date',
            modify_date AS 'Usuario/@modify_date'
        FROM 
            @Usuarios_Sem_Permissao
        ORDER BY
            1, 2
        FOR XML PATH(''), ROOT('Usuarios_Sem_Permissao'), TYPE
    )

    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            106, 
            'Seguran�a de Usu�rios',
            'Usu�rios sem Permiss�o', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado (' + CAST(@Quantidade AS VARCHAR(10)) + ' usu�rios)' END), 
            'Usu�rios que n�o possuem nenhuma permiss�o no database, ou seja, devem estar criados no banco sem nenhuma necessidade. Esses usu�rios provavelmente podem ser exclu�dos do database com seguran�a.',
            'Identifica usu�rios de databases que n�o est�o em nenhuma role e nem possuem nenhuma permiss�o no banco',
            'Analise se esses usu�rios podem ser removidos',
            NULL,
            @Resultado
        )

        

    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rios utilizando autentica��o AD sem utilizar o protocolo de autentica��o Kerberos
    ---------------------------------------------------------------------------------------------------------------
	
    DECLARE
        @Qt_NTLM INT, @Qt_Kerberos INT

    SELECT
        @Qt_NTLM = SUM(CASE WHEN A.auth_scheme = 'NTLM' THEN 1 ELSE 0 END),
        @Qt_Kerberos = SUM(CASE WHEN A.auth_scheme = 'Kerberos' THEN 1 ELSE 0 END)
    FROM 
        sys.dm_exec_connections A
        JOIN sys.dm_exec_sessions B ON B.session_id = A.session_id
        JOIN sys.server_principals C ON B.original_security_id = C.[sid]
    WHERE
        C.[type_desc] = 'WINDOWS_LOGIN'
        AND C.principal_id > 10
        AND B.nt_domain NOT LIKE 'NT Service%'
        

	SET @Resultado = NULL

    SET @Resultado = (
        SELECT
            A.session_id AS 'Sessao/@session_id',
            B.login_name AS 'Sessao/@login_name',
            B.nt_domain AS 'Sessao/@nt_domain',
            B.nt_user_name AS 'Sessao/@nt_user_name',
            A.net_transport AS 'Sessao/@net_transport',
            A.auth_scheme AS 'Sessao/@auth_scheme',
            B.[host_name] AS 'Sessao/@host_name',
            B.[program_name] AS 'Sessao/@program_name',
            A.connect_time AS 'Sessao/@connect_time',
            A.encrypt_option AS 'Sessao/@encrypt_option'
        FROM 
            sys.dm_exec_connections A
            JOIN sys.dm_exec_sessions B ON B.session_id = A.session_id
            JOIN sys.server_principals C ON B.original_security_id = C.[sid]
        WHERE
            C.[type_desc] = 'WINDOWS_LOGIN'
            AND C.principal_id > 10
            AND B.nt_domain NOT LIKE 'NT Service%'
            AND A.auth_scheme <> 'Kerberos'
        ORDER BY
            2
        FOR XML PATH(''), ROOT('Usuarios_AD_Sem_Kerberos'), TYPE
    )


    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            107, 
            'Seguran�a de Usu�rios',
            'Usu�rios AD sem utilizar Kerberos', 
            (CASE WHEN ISNULL(@Qt_Kerberos, 0) >= ISNULL(@Qt_NTLM, 0) THEN 'OK' ELSE 'Poss�vel problema encontrado (' + CAST(ISNULL(@Qt_NTLM, 0) AS VARCHAR(10)) + ' conex�es)' END), 
            'Identifica se o protocolo de autentica��o Kerberos est� sendo utilizado ao inv�s do NTLM, que � um protocolo mais seguro de comunica��o entre servidores e permite do Double-Hop',
            'Identifica usu�rios com autentica��o AD na sys.dm_exec_connections que n�o est�o utilizando o Kerberos',
            'Analise se o SPN da inst�ncia est� configurado corretamente nos registros do AD',
            'https://www.dirceuresende.com/blog/sql-server-autenticacao-ad-kerberos-ntlm-login-failed-for-user-nt-authorityanonymous-logon/',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rios SQL com permiss�o VIEW ANY DATABASE
    ---------------------------------------------------------------------------------------------------------------
	
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.[name] AS 'Usuario/@name',
            A.principal_id AS 'Usuario/@principal_id',
            A.create_date AS 'Usuario/@create_date',
            A.modify_date AS 'Usuario/@modify_date',
            A.[type_desc] AS 'Usuario/@type_desc',
            B.state_desc AS 'Usuario/@state_desc'
        FROM
            sys.server_principals A
            JOIN sys.server_permissions B ON A.principal_id = B.grantee_principal_id
        WHERE
            B.[permission_name] = 'VIEW ANY DATABASE'
            AND B.[state] IN ('G', 'W')
            AND A.is_disabled = 0
            AND A.[type] NOT IN ('CERTIFICATE_MAPPED_LOGIN', 'WINDOWS_LOGIN', 'WINDOWS_GROUP')
            AND A.[name] = 'public'
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Permissao_View_Any_Database'), TYPE
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            108, 
            'Seguran�a de Usu�rios',
            'Permiss�o VIEW ANY DATABASE', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Identifica se existe algum usu�rio com permiss�o de VIEW ANY DATABASE, permitindo assim, que ele veja o nome de todos os databases da inst�ncia',
            'Analisa na DMV sys.server_permissions se algum usu�rio com autentica��o SQL tenha permiss�o de VIEW ANY DATABASE',
            'Remova a permiss�o VIEW ANY DATABASE da role padr�o public e de todos os usu�rios que n�o acessam o SQL Server pelo SSMS, especialmente sistemas. Utilizar o grupo do AD DOMINIO\Domain Users pode ser uma alternativa mais segura ao public',
            'https://www.dirceuresende.com/blog/sql-server-como-ocultar-os-databases-para-usuarios-nao-autorizados/',
            @Resultado
        )

    
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se comandos xp_cmdshell est�o permitidos na inst�ncia
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            configuration_id,
            [name],
            [value],
            value_in_use,
            [description]
        FROM 
            sys.configurations WITH(NOLOCK)
        WHERE 
            [name] = 'xp_cmdshell'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuration')
    )

    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            200, 
            'Programa��o',
            'xp_cmdshell', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite executar comandos maliciosos dentro do database atrav�s do xp_cmdshell',
            'Verifique se a configura��o "xp_cmdshell" est� habilitada na sp_configure',
            'Desabilite essa configura��o caso n�o esteja utilizando em nenhuma rotina. Caso esteja, tente utilizar outra solu��o, como o SQLCLR, para prover essa funcionalidade',
            'http://www.sqlservercentral.com/blogs/brian_kelley/2009/11/13/why-we-recommend-against-xp-cmdshell/',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se comandos OLE Automation est�o permitidos na inst�ncia
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            configuration_id,
            [name],
            [value],
            value_in_use,
            [description]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'Ole Automation Procedures'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuration')
    )

    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            201, 
            'Programa��o',
            'Ole Automation', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite executar comandos maliciosos dentro do database atrav�s de procedures OLE Automation',
            'Verifique se a configura��o "Ole Automation Procedures" est� habilitada na sp_configure',
            'Desabilite essa configura��o caso n�o esteja utilizando em nenhuma rotina. Caso esteja, tente utilizar outra solu��o, como o SQLCLR, para prover essa funcionalidade',
            'https://www.stigviewer.com/stig/microsoft_sql_server_2005_instance/2015-04-03/finding/V-2472',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se comandos SQLCLR est�o permitidos na inst�ncia
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            configuration_id,
            [name],
            [value],
            value_in_use,
            [description]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'clr enabled'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuration')
    )

    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            202, 
            'Programa��o',
            'SQLCLR', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite executar comandos maliciosos dentro do database atrav�s de procedures SQLCLR',
            'Verifica se a configura��o "clr enabled" est� habilitada na sp_configure',
            'Desabilite a configura��o "clr enabled" caso n�o esteja utilizando nenhuma biblioteca SQLCLR',
            'https://docs.microsoft.com/en-us/sql/relational-databases/clr-integration/security/clr-integration-code-access-security?view=sql-server-2017',
            @Resultado
        )

        
   
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se comandos SQLCLR est�o permitidos na inst�ncia
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE @DadosSQLCLR TABLE ( [database_name] NVARCHAR(128), [assembly_name] nvarchar(128), [clr_name] nvarchar(256), [permission_set_desc] nvarchar(60), [create_date] datetime, [modify_date] datetime )

    INSERT INTO @DadosSQLCLR
    (
        [database_name],
        assembly_name,
        clr_name,
        permission_set_desc,
        create_date,
        modify_date
    )
    EXEC sys.sp_MSforeachdb
        @command1 = N'SELECT 
    ''?'',
    [name],
    clr_name,
    permission_set_desc,
    create_date,
    modify_date
FROM 
   [?].sys.assemblies WITH(NOLOCK)
WHERE 
    [permission_set] <> 1 
    AND is_user_defined = 1'
    
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [database_name] AS 'Assembly/@database_name',
            assembly_name AS 'Assembly/@assembly_name',
            clr_name AS 'Assembly/@clr_name',
            permission_set_desc AS 'Assembly/@permission_set_desc',
            create_date AS 'Assembly/@create_date',
            modify_date AS 'Assembly/@modify_date'
        FROM 
            @DadosSQLCLR
        ORDER BY
            1, 2, 3
        FOR XML PATH(''), ROOT('Configuration'), TYPE
    )

    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            203, 
            'Programa��o',
            'SQLCLR Unsafe/External Access', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite executar comandos maliciosos dentro do database atrav�s de procedures SQLCLR com permiss�o Unsafe/External Access',
            'Verifica se algum assembly, de algum database, foi criado com a PERMISSION_SET = UNSAFE ou EXTERNAL_ACCESS',
            'Valide se essa biblioteca est� realmente sendo utilizada e assine o assembly utilizando certificado de criptografia',
            'https://docs.microsoft.com/en-us/sql/relational-databases/clr-integration/security/clr-integration-code-access-security?view=sql-server-2017',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se comandos externos est�o permitidos na inst�ncia
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            configuration_id,
            [name],
            [value],
            value_in_use,
            [description]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'external scripts enabled'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuration')
    )

    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            204, 
            'Programa��o',
            'Scripts Externos (R, Python ou Java)', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite executar comandos maliciosos dentro do database atrav�s de scripts em linguagem R (SQL 2016), Python (SQL 2017) ou Java (SQL 2019)',
            'Verifica se a configura��o "external scripts enabled" est� habilitada na sp_configure',
            'Desabilite a configura��o "external scripts enabled" caso n�o utilize scripts Python, R ou Java no SQL Server',
            'https://www.stigviewer.com/stig/ms_sql_server_2016_instance/2018-03-09/finding/V-79347',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se a base suporta TDE e se est� ativado
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    IF (@Versao >= 2008)
    BEGIN

        SET @Resultado = (
            SELECT
                A.[name] AS 'Database/@name',
                A.[compatibility_level] AS 'Database/@compatibility_level'
            FROM
                sys.databases A WITH(NOLOCK)
                LEFT JOIN sys.dm_database_encryption_keys B WITH(NOLOCK) ON B.database_id = A.database_id
            WHERE
                B.database_id IS NULL
                AND A.[name] NOT IN ('master', 'model', 'msdb', 'tempdb', 'ReportServer', 'ReportServerTempDB')
                AND A.[state] = 0 -- ONLINE
            ORDER BY
                1
            FOR XML PATH(''), ROOT('Databases_Sem_TDE'), TYPE
        )

    END


    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            300, 
            'Seguran�a dos Dados',
            'Transparent Data Encryption (TDE)', 
            (CASE WHEN @Versao < 2008 THEN 'N�o suportado' WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Configura��o que permite criptografar os dados do banco, backups e logs para evitar acesso indevido aos dados',
            'Valida os databases que n�o possuem o TDE habilitado',
            'Habilite o TDE nas bases do SQL Server 2008+ para criptografar os dados, logs e backups automaticamente',
            'https://www.dirceuresende.com/blog/sql-server-2008-como-criptografar-seus-dados-utilizando-transparent-data-encryption-tde/',
            @Resultado
        )


    

    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se os databases est�o com backup atualizado
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.[Name] AS 'Database/@Name',
            COALESCE(CONVERT(VARCHAR(12), MAX(B.backup_finish_date), 103) + ' ' + CONVERT(VARCHAR(12), MAX(B.backup_finish_date), 108) , '-') AS 'Database/@LastBackUpTime',
            DATEDIFF(DAY, ISNULL(MAX(B.backup_finish_date), MAX(A.create_date)), GETDATE()) AS 'Database/@Qt_Dias_Sem_Backup'
        FROM
            sys.databases A WITH(NOLOCK)
            LEFT JOIN msdb.dbo.backupset B WITH(NOLOCK) ON B.[database_name] = A.[name]
        WHERE
            A.[state] = 0 -- ONLINE
            AND A.[name] <> 'tempdb'
        GROUP BY
            A.[Name]
        HAVING
            DATEDIFF(DAY, ISNULL(MAX(B.backup_finish_date), MAX(A.create_date)), GETDATE()) > 7
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Databases_Sem_Backup'), TYPE
    )

    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            301, 
            'Seguran�a dos Dados',
            'Databases sem Backup', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Valida��o que identifica bancos de dados SEM BACKUP, o que pode causar um trag�dia caso algum dado fique corrompido',
            'Verifica bancos de dados que n�o possuem nenhum tipo de BACKUP',
            'Crie rotinas autom�ticas para backup FULL + DIFF + LOG em ambiente de produ��o ou backup FULL di�rio para ambientes n�o cr�ticos',
            'https://edvaldocastro.com/politicabkp/',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se foi realizado algum backup sem criptografia
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    IF (@Versao > 2012)
    BEGIN

        DECLARE @Backups_Sem_Criptografia TABLE ( 
            [database_name] NVARCHAR(128),
            key_algorithm NVARCHAR(32),
            encryptor_thumbprint VARBINARY(20),
            encryptor_type NVARCHAR(32),
	        media_set_id INT,
            is_encrypted BIT,
	        [type] CHAR(1),
            is_compressed BIT,
	        physical_device_name NVARCHAR(260)
        )


        INSERT INTO @Backups_Sem_Criptografia
        EXEC('SELECT TOP(100)
            b.[database_name],
            b.key_algorithm,
            b.encryptor_thumbprint,
            b.encryptor_type,
	        b.media_set_id,
            m.is_encrypted, 
	        b.[type],
            m.is_compressed,
	        bf.physical_device_name
        FROM
            msdb.dbo.backupset b WITH(NOLOCK)
            JOIN msdb.dbo.backupmediaset m WITH(NOLOCK) ON b.media_set_id = m.media_set_id
            JOIN msdb.dbo.backupmediafamily bf WITH(NOLOCK) on bf.media_set_id=b.media_set_id
        WHERE 
            m.is_encrypted = 0
        ORDER BY
            b.backup_start_date DESC')


        SET @Resultado = (
            SELECT 
                [database_name] AS 'Backup/@database_name',
                key_algorithm AS 'Backup/@key_algorithm',
                encryptor_thumbprint AS 'Backup/@encryptor_thumbprint',
                encryptor_type AS 'Backup/@encryptor_type',
                media_set_id AS 'Backup/@media_set_id',
                is_encrypted AS 'Backup/@is_encrypted',
                [type] AS 'Backup/@type',
                is_compressed AS 'Backup/@is_compressed',
                physical_device_name AS 'Backup/@physical_device_name'
            FROM 
                @Backups_Sem_Criptografia
            ORDER BY
                1
            FOR XML PATH(''), ROOT('Backups_Sem_Criptografia'), TYPE
        )

    END
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            302, 
            'Seguran�a dos Dados',
            'Backups sem Criptografia', 
            (CASE WHEN @Versao <= 2008 THEN 'N�o suportado' WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Valida��o que identifica bancos de dados com backup sem criptografia, o que possibilita que terceiros consigam ler os dados caso eles consigam acesso os arquivos de backup',
            'Verifica backups de bancos de dados sem criptografia',
            'Implemente TDE no database ou altere a sua rotina de backup para criptografar os backups',
            'https://www.tiagoneves.net/blog/criando-um-backup-criptografado-no-sql-server/',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se existem databases com Recovery Model FULL e sem backup de LOG
    ---------------------------------------------------------------------------------------------------------------

    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT
            A.[name] AS 'Database/@name',
            MAX(B.backup_finish_date) AS 'Database/@backup_finish_date'
        FROM
            sys.databases A WITH(NOLOCK)
            LEFT JOIN msdb..backupset B WITH(NOLOCK) ON B.[database_name] = A.[name] AND B.[type] = 'L'
        WHERE
            A.recovery_model = 1 -- FULL
            AND A.[name] NOT IN ('master', 'msdb', 'tempdb', 'model')
            AND A.[state] = 0 -- ONLINE
        GROUP BY
            A.[name]
        HAVING
            DATEDIFF(DAY, ISNULL(MAX(B.backup_finish_date), '1900-01-01'), GETDATE()) > 1
        ORDER BY
            2 DESC
        FOR XML PATH(''), ROOT('Databases_Sem_Backup_de_LOG'), TYPE
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            303, 
            'Seguran�a dos Dados',
            'Recovery Model FULL sem Backup de LOG', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Valida��o que identifica bancos de dados com recovery model definido como FULL, mas sem rotina de backup de log configurada, o que provavelmente � uma configura��o incorreta ou falta de rotina de backup',
            'Verifica bancos de dados com recovery model FULL, mas sem rotina de backup de log',
            'Implemente uma rotina autom�tica de backup de log ou altere o Recovery Model para SIMPLE, caso n�o seja um ambiente cr�tico e dados ap�s o �ltimo possam ser perdidos em caso de falha',
            'https://www.brentozar.com/blitz/full-recovery-mode-without-log-backups/',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica a extens�o dos arquivos do SQL Server
    ---------------------------------------------------------------------------------------------------------------
        
    SET @Resultado = (
        SELECT 
            [name] AS 'Database/@name',
            database_id AS 'Database/@database_id',
            [state_desc] AS 'Database/@state_desc',
            physical_name AS 'Database/@physical_name',
            size AS 'Database/@size',
            max_size AS 'Database/@max_size',
            growth AS 'Database/@growth',
            is_percent_growth AS 'Database/@is_percent_growth',
            is_read_only AS 'Database/@is_read_only',
            is_media_read_only AS 'Database/@is_media_read_only'                
        FROM
            sys.master_files
        WHERE
            RIGHT(physical_name, 3) IN ('ndf', 'ldf', 'mdf')
        FOR XML PATH(''), ROOT('Extensao_Padrao_Arquivos_SQL'), TYPE
    )

    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            304, 
            'Seguran�a dos Dados',
            'Extens�o dos arquivos dos databases',
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Essa configura��o valida se o SQL Server est� utilizando as extens�es padr�o para arquivo de dados, logs e backups, que s�o alvos de Ransomwares, como o WannaCry',
            'Verifica se os databases do SQL Server est�o utilizando as extens�o padr�o para arquivos de dados (MDF) e logs (LDF)',
            'Utilize extens�es personalizadas para os arquivos de dados, logs e backups, dificultando que v�rus e ransonwares ataquem os arquivos de database do SQL Server',
            'https://www.dirceuresende.com/blog/sql-server-como-evitar-e-se-proteger-de-ataques-de-ransomware-como-wannacry-no-seu-servidor-de-banco-de-dados/',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica a extens�o dos arquivos de backup do SQL Server
    --------------------------------------------------------------------------------------------------------------- 

    IF (OBJECT_ID('tempdb..#Informacoes_Backups') IS NOT NULL) DROP TABLE #Informacoes_Backups
    SELECT 
        B.[database_name],
        A.logical_device_name,
        A.physical_device_name,
        B.[backup_start_date],
        B.[backup_finish_date],
        B.expiration_date,
        (CASE B.[type] 
            WHEN 'D' THEN 'Full'
            WHEN 'I' THEN 'Diferencial'
            WHEN 'L' THEN 'Log' 
        END) AS backup_type,
        A.device_type,
        (CASE A.device_type 
            WHEN 2 THEN 'Disco' 
            WHEN 5 THEN 'Fita' 
            WHEN 7 THEN 'Dispositivo Virtual'
            WHEN 9 THEN 'Azure Storage' 
            WHEN 105 THEN 'Unidade de Backup' 
        END) AS device_type_desc,
        B.backup_size,
        B.[name] AS backupset_name,
        B.[description]
    INTO
        #Informacoes_Backups
    FROM
        msdb.dbo.backupmediafamily A WITH(NOLOCK)
        JOIN msdb.dbo.backupset B WITH(NOLOCK) ON A.media_set_id = B.media_set_id
        
       

    SET @Resultado = (
        SELECT TOP(50)
            A.[database_name] AS 'Database/@database_name',
            A.logical_device_name AS 'Database/@logical_device_name',
            A.physical_device_name AS 'Database/@physical_device_name',
            A.[backup_start_date] AS 'Database/@backup_start_date',
            A.[backup_finish_date] AS 'Database/@backup_finish_date',
            A.expiration_date AS 'Database/@expiration_date',
            A.backup_type AS 'Database/@backup_type',
            A.backup_size AS 'Database/@backup_size',
            A.backupset_name AS 'Database/@backupset_name',
            A.[description] AS 'Database/@description'
        FROM
            #Informacoes_Backups A
        WHERE
            device_type IN (2, 5) -- Disco e Fita
            AND A.backup_start_date >= DATEADD(DAY, -7, @Dt_Hoje )
            AND RIGHT(A.physical_device_name, 3) = 'bak'
        ORDER BY
            A.[database_name],
            A.backup_finish_date
        FOR XML PATH(''), ROOT('Extensao_Padrao_Backups_SQL'), TYPE
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            305, 
            'Seguran�a dos Dados',
            'Extens�o dos arquivos de backup',
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Essa configura��o valida se o SQL Server est� utilizando as extens�es padr�o para arquivo de backup do banco, que s�o alvos de Ransomwares, como o WannaCry',
            'Verifica se os databases do SQL Server est�o utilizando as extens�o padr�o para arquivos de dados (BAK)',
            'Utilize extens�es personalizadas para os arquivos de dados, logs e backups, dificultando que v�rus e ransonwares ataquem os arquivos de database do SQL Server',
            'https://www.dirceuresende.com/blog/sql-server-como-evitar-e-se-proteger-de-ataques-de-ransomware-como-wannacry-no-seu-servidor-de-banco-de-dados/',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se a inst�ncia possui alguma solu��o de backup al�m de backup em disco
    ---------------------------------------------------------------------------------------------------------------
        
    SET @Resultado = (
        SELECT 
            A.[database_name] AS 'Database/@database_name',
            A.logical_device_name AS 'Database/@logical_device_name',
            COUNT(*) AS 'Database/@backup_count',
            MAX(A.[backup_start_date]) AS 'Database/@last_backup_start_date',
            MAX(A.[backup_finish_date]) AS 'Database/@last_backup_finish_date',
            MAX(A.expiration_date) AS 'Database/@last_expiration_date',
            A.device_type AS 'Database/@backup_type',
            A.device_type_desc AS 'Database/@backup_type_desc',
            A.[backupset_name] AS 'Database/@backupset_name',
            A.[description] AS 'Database/@description'
        FROM
            #Informacoes_Backups A
        WHERE
            A.backup_start_date >= DATEADD(DAY, -7, @Dt_Hoje )
            AND A.device_type = 2 -- Disco
            AND NOT EXISTS(SELECT NULL FROM #Informacoes_Backups WHERE [database_name] = A.[database_name] AND device_type <> 2 AND backup_start_date >= DATEADD(DAY, -7, @Dt_Hoje ) )
        GROUP BY
            A.[database_name],
            A.logical_device_name,
            A.device_type,
            A.device_type_desc,
            A.[backupset_name],
            A.[description]
        ORDER BY
            A.[database_name]
        FOR XML PATH(''), ROOT('Armazenamento_Backups_SQL'), TYPE
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            306, 
            'Seguran�a dos Dados',
            'Armazenamento dos Backups',
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Essa configura��o valida se o SQL Server est� configurado para utilizar outro destino de backup que n�o seja apenas o disco',
            'Verifica se os databases do SQL Server est�o utilizando solu��es alternativas para armazenamento dos arquivos de backup, como nuvem e/ou fita',
            'Utilize mais de um local para armazenar seus arquivos de backup do SQL Server, pois caso voc� armazene em um local f�sico apenas, voc� pode perder todos os casos em caso de cat�strofe',
            'https://www.dirceuresende.com/blog/sql-server-como-evitar-e-se-proteger-de-ataques-de-ransomware-como-wannacry-no-seu-servidor-de-banco-de-dados/',
            @Resultado
        )


        
    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rios com permiss�o CONTROL SERVER
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.[name] AS 'Usuario/@login',
            A.principal_id AS 'Usuario/@principal_id',
			B.[permission_name] AS 'Usuario/@permission_name',
            A.[type_desc] AS 'Usuario/@type_desc',
            A.is_disabled AS 'Usuario/@is_disabled'
        FROM
            sys.server_principals A WITH(NOLOCK)
            JOIN (
                SELECT 
                    grantee_principal_id,
                    [permission_name] COLLATE SQL_Latin1_General_CP1_CI_AI AS [permission_name]
                FROM 
                    sys.server_permissions WITH(NOLOCK)
                WHERE 
                    class_desc = 'SERVER' 
                    AND [permission_name] IN (
                        'Administer bulk operations',
                        'Alter any availability group',
                        'Alter any connection',
                        'Alter any credential',
                        'Alter any database',
                        'Alter any endpoint',
                        'Alter any event notification',
                        'Alter any event session',
                        'Alter any linked server',
                        'Alter any login',
                        'Alter any server audit',
                        'Alter any server role',
                        'Alter resources',
                        'Alter server state',
                        'Alter Settings',
                        'Alter trace',
                        'Authenticate server',
                        'Control server',
                        'Create any database',
                        'Create availability group',
                        'Create DDL event notification',
                        'Create endpoint',
                        'Create server role',
                        'Create trace event notification',
                        'Shutdown'
                    ) 
                    AND [state] IN ('G', 'W')
                ) B ON A.principal_id = B.grantee_principal_id
            WHERE
                A.principal_id > 10
                AND A.[name] NOT IN ('##MS_PolicySigningCertificate##', '##MS_SQLReplicationSigningCertificate##', '##MS_SQLAuthenticatorCertificate##', 'NT AUTHORITY\SYSTEM', 'AUTORIDADE NT\SISTEMA')
                AND A.[name] NOT LIKE 'NT SERVICE\%'
                AND A.is_disabled = 0
            ORDER BY
                1
        FOR XML PATH(''), ROOT('Users'), TYPE
    )

    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            400, 
            'Permiss�es',
            'Permiss�o CONTROL SERVER', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Permiss�o elevada que permite controlar e at� mesmo, desligar a inst�ncia SQL Server',
            'Verifica usu�rios com permiss�o de CONTROL SERVER ou permiss�es elevadas na inst�ncia',
            'Remova as permiss�es elevadas desses usu�rios, caso n�o sejam DBAs e as permiss�es sejam realmente necess�rias e justific�veis',
            'https://www.stigviewer.com/stig/microsoft_sql_server_2012_database_instance/2017-04-03/finding/V-41268',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rios nas roles sysadmin/securityadmin
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.[name] AS 'Login/@name',
            B.[permission_name] AS 'Login/@permission_name',
            A.[type_desc] AS 'Login/@type_desc',
            A.is_disabled AS 'Login/@is_disabled',
            A.principal_id AS 'Login/@principal_id',
            A.[sid] AS 'Login/@sid'
        FROM
            sys.server_principals A WITH(NOLOCK)
            JOIN (
                SELECT 
                    a1.member_principal_id AS grantee_principal_id,
                    a2.[name] COLLATE SQL_Latin1_General_CP1_CI_AI AS [permission_name]
                FROM 
                    sys.server_role_members AS a1 WITH(NOLOCK)
                    JOIN sys.server_principals AS a2 WITH(NOLOCK) ON a1.role_principal_id = a2.principal_id 
                WHERE 
                    a2.[name] IN ('sysadmin', 'securityadmin')
            ) B ON A.principal_id = B.grantee_principal_id
        WHERE
            A.principal_id > 10
            AND A.[name] <> '##MS_PolicySigningCertificate##'
            AND A.is_disabled = 0
            AND A.[name] NOT LIKE 'NT SERVICE\%'
            AND A.[name] NOT LIKE 'SERVI�O NT\%'
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Permissoes_Sysadmin_SecurityAdmin'), TYPE
    )
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            401, 
            'Permiss�es',
            'Usu�rios nas roles sysadmin/securityadmin', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Permiss�o elevada que permite executar comandos como outro login, controlar e at� mesmo, desligar a inst�ncia SQL Server',
            'Verifica os usu�rios que est�o nas server roles sysadmin e/ou securityadmin',
            'Remova esses usu�rios dessas duas roles caso n�o sejam DBAs e seja realmente necess�rio e justific�vel que esses usu�rios estejam nessas roles',
            'https://renatomsiqueira.com/category/security/roles-security/',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rios com IMPERSONATE ANY LOGIN
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.class AS 'Login/@class',
            A.class_desc AS 'Login/@class_desc',
            A.[type] AS 'Login/@type',
            A.[permission_name] AS 'Login/@permission_name',
            A.[state] AS 'Login/@state',
            A.state_desc AS 'Login/@state_desc',
            B.[name] AS 'Login/@grantee', -- quem recebeu a permiss�o
            C.[name] AS 'Login/@grantor' -- quem concedeu a permiss�o
        FROM 
            sys.server_permissions A WITH(NOLOCK)
            JOIN sys.server_principals B WITH(NOLOCK) ON A.grantee_principal_id = B.principal_id
            LEFT JOIN sys.server_principals C WITH(NOLOCK) ON A.grantor_principal_id = C.principal_id
        WHERE
            A.[type] = 'IAL'
            AND A.[state] = 'G'
        ORDER BY
            7
        FOR XML PATH(''), ROOT('Usuarios_Impersonate_Any_Login'), TYPE
    )

    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            402, 
            'Permiss�es',
            'IMPERSONATE ANY LOGIN', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Permiss�o que possibilita que um determinado login possa executar comandos como QUALQUER USU�RIO, inclusive, um usu�rio sysadmin',
            'Verifica os usu�rios que possuem a permiss�o "IMPERSONATE ANY LOGIN" na inst�ncia',
            'Remova essa permiss�o desses usu�rios',
            'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
            @Resultado
        )
        


    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rios com IMPERSONATE LOGIN
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.class AS 'Login/@class',
            A.class_desc AS 'Login/@class_desc',
            A.[type] AS 'Login/@type',
            A.[permission_name] AS 'Login/@permission_name',
            A.[state] AS 'Login/@state',
            A.state_desc AS 'Login/@state_desc',
            B.[name] AS 'Login/@grantee', -- quem recebeu a permiss�o
            C.[name] AS 'Login/@grantor' -- quem concedeu a permiss�o
        FROM 
            sys.server_permissions A WITH(NOLOCK)
            JOIN sys.server_principals B WITH(NOLOCK) ON A.grantee_principal_id = B.principal_id
            LEFT JOIN sys.server_principals C WITH(NOLOCK) ON A.grantor_principal_id = C.principal_id
        WHERE
            A.[type] = 'IM'
            AND A.[state] = 'G'
        ORDER BY
            7
        FOR XML PATH(''), ROOT('Usuarios_Impersonate_Login'), TYPE
    )

    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            403, 
            'Permiss�es',
            'IMPERSONATE LOGIN', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Permiss�o que possibilita que um determinado login possa executar comandos como determinados logins da inst�ncia. Verificar se os login imperson�veis possuem permiss�es elevadas',
            'Verifica os usu�rios que possuem a permiss�o "IMPERSONATE LOGIN" na inst�ncia',
            'Remova essa permiss�o dos usu�rios, a n�o ser que exista algum motivo plaus�vel que justifique que um login para executar comandos como outra pessoa',
            'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rios com sysadmin/securityadmin que podem ser personificados
    ---------------------------------------------------------------------------------------------------------------

    -- DECLARE @Resultado XML
    SET @Resultado = NULL

    ;WITH cte
    AS (
   
        SELECT
            grantee_principal_id
        FROM
            sys.server_permissions WITH(NOLOCK)
        WHERE
            [permission_name] = 'IMPERSONATE'
            AND class_desc = 'SERVER_PRINCIPAL'
            AND major_id IN (

                SELECT 
                    grantee_principal_id
                FROM 
                    sys.server_permissions WITH(NOLOCK)
                WHERE 
                    class_desc = 'SERVER' 
                    AND [permission_name] IN (
                        'Administer bulk operations',
                        'Alter any availability group',
                        'Alter any connection',
                        'Alter any credential',
                        'Alter any database',
                        'Alter any endpoint',
                        'Alter any event notification',
                        'Alter any event session',
                        'Alter any linked server',
                        'Alter any login',
                        'Alter any server audit',
                        'Alter any server role',
                        'Alter resources',
                        'Alter server state',
                        'Alter Settings',
                        'Alter trace',
                        'Authenticate server',
                        'Control server',
                        'Create any database',
                        'Create availability group',
                        'Create DDL event notification',
                        'Create endpoint',
                        'Create server role',
                        'Create trace event notification',
                        'Shutdown',
                        'IMPERSONATE ANY LOGIN'
                    )
                    AND [state] IN ('G', 'W')

                UNION

                SELECT 
                    a1.member_principal_id
                FROM 
                    sys.server_role_members AS a1 WITH(NOLOCK)
                    JOIN sys.server_principals AS a2 WITH(NOLOCK) ON a1.role_principal_id = a2.principal_id 
                WHERE 
                    a2.[name] IN ('sysadmin', 'securityadmin')
            )

        UNION ALL

        SELECT
            p.grantee_principal_id
        FROM
            cte
            JOIN sys.server_permissions AS p WITH(NOLOCK) ON p.[permission_name] = 'IMPERSONATE' AND p.class_desc = 'SERVER_PRINCIPAL' AND p.major_id = cte.grantee_principal_id 
    )
    SELECT @Resultado = (
        SELECT
            A.[name] AS [login]
        FROM
            master.sys.server_principals AS A WITH(NOLOCK)
        WHERE
            A.principal_id IN
            (
                SELECT
                    grantee_principal_id
                FROM
                    cte
            )
        ORDER BY
            1
        FOR XML PATH, ROOT('Usuarios_Impersonate_Login_Sysadmin')
    )


    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            404, 
            'Permiss�es',
            'IMPERSONATE LOGIN em logins sysadmin/securityadmin', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Permiss�o que possibilita que um determinado login possa executar comandos como determinados logins da inst�ncia em usu�rios com permiss�es elevadas (securityadmin/sysadmin/CONTROL SERVER/IMPERSONATE ANY LOGIN)',
            'Identifica usu�rios com privil�gio de "IMPERSONATE LOGIN" em contas de usu�rios que s�o sysadmin/security admin ou possuem privil�gios elevados',
            'Remova essa permiss�o de IMPERSONATE LOGIN" desses usu�rios',
            'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rios nas database roles db_owner/db_securityadmin
    ---------------------------------------------------------------------------------------------------------------

    DECLARE @Usuarios_DB_Owners TABLE ( [database_name] VARCHAR(256), [user] VARCHAR(256), [database_role] VARCHAR(256) )
    
    INSERT INTO @Usuarios_DB_Owners
    EXEC master.dbo.sp_MSforeachdb '
    SELECT 
        ''?'' AS [database],
        B.[name] AS [user],
        C.[name] AS [database_role]
    FROM
        [?].sys.database_role_members A WITH(NOLOCK)
        JOIN [?].sys.database_principals B WITH(NOLOCK) ON A.member_principal_id = B.principal_id
        JOIN [?].sys.database_principals C WITH(NOLOCK) ON A.role_principal_id = C.principal_id
    WHERE
        C.[name] IN (''db_owner'', ''db_securityadmin'')
        AND B.[name] <> ''dbo''
        AND B.[name] <> ''RSExecRole'''



    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [database_name] AS 'Usuario/@database_name',
            [user] AS 'Usuario/@user',
            database_role AS 'Usuario/@database_role'
        FROM
            @Usuarios_DB_Owners
        ORDER BY
            1, 2, 3
        FOR XML PATH(''), ROOT('Usuarios_DB_Owners'), TYPE
    )


    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            405, 
            'Permiss�es',
            'db_owner e db_securityadmin', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Permiss�o que possibilita que um determinado usu�rio possa executar qualquer a��o em um database espec�fico',
            'Verifica em todos os databases, quem s�o os usu�rios nas roles db_owner e db_securityadmin',
            'Remova esses usu�rios dessas database roles e analise como substitu�-las, como uma db_ddladmin, por exemplo, ou outra role com ainda menos permiss�es',
            'https://docs.microsoft.com/pt-br/sql/relational-databases/security/authentication-access/database-level-roles?view=sql-server-2017',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rios com privil�gios de IMPERSONATE USER no database
    ---------------------------------------------------------------------------------------------------------------

    DECLARE @Impersonate_User TABLE ( [database] nvarchar(128), [class_desc] nvarchar(60), [permission_name] nvarchar(128), [state_desc] nvarchar(60), [grantee] nvarchar(128), [impersonated_user] nvarchar(128) )

    INSERT INTO @Impersonate_User
    EXEC sys.sp_MSforeachdb '
    SELECT
        ''?'' as [database],
        A.class_desc,
        A.state_desc,
        A.[permission_name],
        B.[name] AS grantee,
        C.[name] AS impersonated_user
    FROM
        [?].sys.database_permissions A WITH(NOLOCK)
        JOIN [?].sys.database_principals B WITH(NOLOCK) ON A.grantee_principal_id = B.principal_id
        LEFT JOIN [?].sys.database_principals C WITH(NOLOCK) ON A.grantor_principal_id = C.principal_id
    WHERE
        A.[type] = ''IM''
        AND A.[state] IN (''G'', ''W'')
        AND C.[name] <> ''MS_DataCollectorInternalUser'''


    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [database] AS 'Usuario/@database',
            class_desc AS 'Usuario/@class_desc',
            [permission_name] AS 'Usuario/@permission_name',
            state_desc AS 'Usuario/@state_desc',
            grantee AS 'Usuario/@grantee',
            impersonated_user AS 'Usuario/@impersonated_user'
        FROM
            @Impersonate_User
        ORDER BY
            6, 1
        FOR XML PATH(''), ROOT('Usuarios_Impersonate_User'), TYPE
    )


    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            406, 
            'Permiss�es',
            'IMPERSONATE USER', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Permiss�o que possibilita que um determinado usu�rio possa executar a��es como se fosse outro usu�rio',
            'Verifica em todos os databases quais s�o os usu�rios que possuem permiss�o de "IMPERSONATE USER"',
            'Remove essa permiss�o dos usu�rios caso n�o haja nenhuma justificativa v�lida para um usu�rio executar comandos no database como se fosse outra pessoa',
            'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
            @Resultado
        )

        
    ---------------------------------------------------------------------------------------------------------------
    -- Permiss�es da role PUBLIC
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE @Permissoes_Public TABLE ( [database] nvarchar(128), [class_desc] nvarchar(60), [state_desc] nvarchar(60), [permission_name] nvarchar(128), [object_name] nvarchar(128), is_ms_shipped bit  )

    INSERT INTO @Permissoes_Public
    EXEC sys.sp_MSforeachdb '
    SELECT
        ''?'' as [database],
        A.class_desc,
        A.state_desc,
        A.[permission_name],
        B.[name],
        B.is_ms_shipped
    FROM 
        [?].sys.database_permissions A WITH(NOLOCK)
        LEFT JOIN [?].sys.all_objects B WITH(NOLOCK) ON A.major_id = B.[object_id]
    WHERE 
        A.grantee_principal_id = 0
        AND A.state IN (''G'', ''W'')
        AND (A.major_id = 0 OR B.[object_id] IS NOT NULL)
        AND ''?'' <> ''tempdb'''

    
    SET @Resultado = NULL

    IF (EXISTS(SELECT NULL FROM @Permissoes_Public))
    BEGIN

        SET @Resultado = (
            SELECT NULL,
            (
                SELECT TOP(50)
                    [database] AS 'Objetos_Sistema/@database',
                    class_desc AS 'Objetos_Sistema/@class_desc',
                    state_desc AS 'Objetos_Sistema/@state_desc',
                    [permission_name] AS 'Objetos_Sistema/@permission_name',
                    [object_name] AS 'Objetos_Sistema/@object_name'
                FROM
                    @Permissoes_Public
                WHERE
                    is_ms_shipped = 1
                    OR (
                        [database] = 'msdb'
                        AND [object_name] LIKE 'sp_DTA_%'
                    )
                    OR ([object_name] IN ('fn_diagramobjects', 'sp_alterdiagram', 'sp_creatediagram', 'sp_dropdiagram', 'sp_helpdiagramdefinition', 'sp_helpdiagrams', 'sp_renamediagram', 'dt_whocheckedout_u'))
                ORDER BY
                    1, 5
                FOR
                    XML PATH(''), ROOT('Sistema'), TYPE
            ),
            (
                SELECT TOP(50)
                    [database] AS 'Objetos_Usuario/@database',
                    class_desc AS 'Objetos_Usuario/@class_desc',
                    state_desc AS 'Objetos_Usuario/@state_desc',
                    [permission_name] AS 'Objetos_Usuario/@permission_name',
                    [object_name] AS 'Objetos_Usuario/@object_name'
                FROM
                    @Permissoes_Public
                WHERE
                    is_ms_shipped = 0
                    AND NOT (
                        [database] = 'msdb'
                        AND [object_name] LIKE 'sp_DTA_%'
                    )
                    AND NOT ([object_name] IN ('fn_diagramobjects', 'sp_alterdiagram', 'sp_creatediagram', 'sp_dropdiagram', 'sp_helpdiagramdefinition', 'sp_helpdiagrams', 'sp_renamediagram', 'dt_whocheckedout_u'))
                ORDER BY
                    1, 5
                FOR
                    XML PATH(''), ROOT('Usuario'), TYPE
            )
            FOR XML PATH(''), ROOT('Permissoes_Public')
        )

    END

    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            407, 
            'Permiss�es',
            'Role PUBLIC com permiss�es', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Valida��o que garante que a role PUBLIC n�o tem nenhuma permiss�o elevada na inst�ncia, j� que todos os usu�rios da inst�ncia est�o nessa role automaticamente. Todas as permiss�es que essa role possuir, podem ser utilizadas por QUALQUER usu�rio da inst�ncia.',
            'Verifica em todos os databases e na inst�ncia, todas as permiss�es que a role PUBLIC possui',
            'Remova todas as permiss�es da role public',
            'https://basitaalishan.com/2013/04/04/the-public-role-do-not-use-it-for-database-access/',
            @Resultado
        )

        
    ---------------------------------------------------------------------------------------------------------------
    -- Permiss�es do usu�rio GUEST
    ---------------------------------------------------------------------------------------------------------------

    DECLARE @Permissoes_Guest TABLE ( [database] nvarchar(128), [class_desc] nvarchar(60), [state_desc] nvarchar(60), [permission_name] nvarchar(128), [object_name] nvarchar(128), is_ms_shipped bit )

    INSERT INTO @Permissoes_Guest
    EXEC sys.sp_MSforeachdb '
    SELECT
        ''?'' as [database],
        A.class_desc,
        A.state_desc,
        A.[permission_name],
        B.[name],
        ISNULL(B.is_ms_shipped, 0) AS is_ms_shipped
    FROM 
        [?].sys.database_permissions A WITH(NOLOCK)
        LEFT JOIN [?].sys.all_objects B WITH(NOLOCK) ON A.major_id = B.[object_id]
    WHERE 
        A.grantee_principal_id = 2
        AND A.state IN (''G'', ''W'')
        AND (A.major_id = 0 OR B.[object_id] IS NOT NULL)
        AND NOT(''?'' IN (''master'', ''tempdb'', ''model'', ''msdb'') AND A.[permission_name] = ''CONNECT'')'

	
    
    SET @Resultado = NULL

    IF (EXISTS(SELECT NULL FROM @Permissoes_Guest))
    BEGIN

        SET @Resultado = (
            SELECT NULL,
            (
                SELECT 
                    [database] AS 'Objetos_Sistema/@database',
                    class_desc AS 'Objetos_Sistema/@class_desc',
                    state_desc AS 'Objetos_Sistema/@state_desc',
                    [permission_name] AS 'Objetos_Sistema/@permission_name',
                    [object_name] AS 'Objetos_Sistema/@object_name'
                FROM
                    @Permissoes_Guest
                WHERE
                    is_ms_shipped = 1
                    OR (
                        [database] = 'msdb'
                        AND [object_name] LIKE 'sp_DTA_%'
                    )
                    OR ([object_name] IN ('fn_diagramobjects', 'sp_alterdiagram', 'sp_creatediagram', 'sp_dropdiagram', 'sp_helpdiagramdefinition', 'sp_helpdiagrams', 'sp_renamediagram', 'dt_whocheckedout_u'))
                ORDER BY
                    1, 5
                FOR
                    XML PATH(''), ROOT('Sistema'), TYPE
            ),
            (
                SELECT 
                    [database] AS 'Objetos_Usuario/@database',
                    class_desc AS 'Objetos_Usuario/@class_desc',
                    state_desc AS 'Objetos_Usuario/@state_desc',
                    [permission_name] AS 'Objetos_Usuario/@permission_name',
                    [object_name] AS 'Objetos_Usuario/@object_name'
                FROM
                    @Permissoes_Guest
                WHERE
                    is_ms_shipped = 0
                    AND NOT (
                        [database] = 'msdb'
                        AND [object_name] LIKE 'sp_DTA_%'
                    )
                    AND NOT ([object_name] IN ('fn_diagramobjects', 'sp_alterdiagram', 'sp_creatediagram', 'sp_dropdiagram', 'sp_helpdiagramdefinition', 'sp_helpdiagrams', 'sp_renamediagram', 'dt_whocheckedout_u'))
                ORDER BY
                    1, 5
                FOR
                    XML PATH(''), ROOT('Usuario'), TYPE
            )
            FOR XML PATH, ROOT('Permissoes_Guest')
        )

    END



    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            408, 
            'Permiss�es',
            'Usu�rio GUEST com permiss�es', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Valida��o que garante que o usu�rio GUEST n�o tem nenhuma permiss�o na inst�ncia. Esse usu�rio especial permite acesso a qualquer login que n�o tenha usu�rio mapeado em um database e por isso, deve ter o privil�gio de CONNECT revogado em todos os databases',
            'Verifica se o usu�rio GUEST possui alguma permiss�o na inst�ncia',
            'Remova todas as permiss�es do usu�rio GUEST que n�o seja CONNECT nas databases msdb, master e tempdb',
            'https://basitaalishan.com/2012/08/28/sql-server-guest-user-still-a-serious-security-threat/',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rios com permiss�es UNSAFE/EXTERNAL ASSEMBLY
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT
            A.[name] AS 'Usuario/@login',
            B.class_desc AS 'Usuario/@class_desc',
            B.state_desc AS 'Usuario/@state_desc',
            B.[permission_name] AS 'Usuario/@permission_name'
        FROM
            sys.server_principals A WITH(NOLOCK)
            JOIN sys.server_permissions B WITH(NOLOCK) ON A.principal_id = B.grantee_principal_id
        WHERE
            B.[type] IN ('XU', 'XA')
            AND B.[state] IN ('G', 'W')
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Usuarios_Unsafe_External_Assembly'), TYPE
    )

    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            409, 
            'Permiss�es',
            'Usu�rios com permiss�o UNSAFE/EXTERNAL ASSEMBLY', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Permiss�o que possibilita que um determinado login possa criar assemblies com o modo de seguran�a UNSAFE/EXTERNAL ACCESS no ambiente',
            'Verifica os usu�rios que possuem permiss�es a n�vel de servidor "XU" (UNSAFE ASSEMBLY) e "XA" (EXTERNAL ACCESS ASSEMBLY)',
            'Remova essas permiss�es caso esses usu�rios n�o precisem fazer deploy de assemblies SQLCLR nesses 2 modos de seguran�a',
            'http://www.sqlservercentral.com/articles/Stairway+Series/112888/',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Usu�rios com permiss�es em extended procedures (xp_%)
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT
            u.[name] AS 'Permissao/@usuario',
            o.[name] AS 'Permissao/@stored_procedure',
            u.[type_desc] AS 'Permissao/@type',
            p.class_desc AS 'Permissao/@class_desc',
            p.[permission_name] AS 'Permissao/@permission_name',
            p.state_desc AS 'Permissao/@state_desc',
            'REVOKE ' + p.[permission_name] + ' ON sys.[' + o.[name] COLLATE DATABASE_DEFAULT + '] FROM [' + u.[name] + '];' AS 'Permissao/@RevokeCommand',
            'GRANT ' + p.[permission_name] + ' ON sys.[' + o.[name] COLLATE DATABASE_DEFAULT + '] TO [' + u.[name] + '];' AS 'Permissao/@GrantCommand'
        FROM
            [master].sys.system_objects o
            JOIN [master].sys.database_permissions p ON o.[object_id] = p.major_id
            JOIN [master].sys.database_principals u ON p.grantee_principal_id = u.principal_id
        WHERE
            (o.[name] LIKE 'xp_%')
            AND o.[name] NOT IN ('xp_msver', 'xp_qv') /*'xp_instance_regread'*/ -- SP's necess�rias pelo Object Explorer do SSMS
            --AND p.[type] = 'EX'
            AND p.[state] IN ('G', 'W') 
        ORDER BY
            o.[name],
            u.[name]
        FOR XML PATH(''), ROOT('Permissoes_Extended_Procedures'), TYPE
    )

    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            410, 
            'Permiss�es',
            'Permiss�es em Extended Procedures (xp_%)', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Permiss�o que possibilita que um determinado login possa utilizar Extended Procedures na inst�ncia, que s�o comandos que podem ler/gravar informa��es do registro do Windows, al�m de v�rias outras tarefas que podem causar risco para o ambiente',
            'Verifica os usu�rios que possuem permiss�es em objetos de sistema que comecem com xp_%',
            'Remova essas permiss�es',
            'https://www.stigviewer.com/stig/microsoft_sql_server_2005_instance/2015-06-16/finding/V-2473',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Objetos com IMPERSONATE
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE @Objetos_Com_Impersonate TABLE ( [Ds_Database] nvarchar(256), [Ds_Objeto] nvarchar(256), [Ds_Tipo] nvarchar(128), [Ds_Usuario] nvarchar(256) )

    INSERT INTO @Objetos_Com_Impersonate
    EXEC sys.sp_MSforeachdb '
	IF (''?'' <> ''tempdb'')
	BEGIN

		SELECT 
			''?'' AS Ds_Database,
			B.[name],
			B.[type_desc],
			(CASE WHEN A.execute_as_principal_id = -2 THEN ''OWNER'' ELSE C.[name] END) AS Ds_Execute_As
		FROM
			[?].sys.sql_modules A WITH(NOLOCK)
			JOIN [?].sys.objects B WITH(NOLOCK) ON B.[object_id] = A.[object_id]
			LEFT JOIN [?].sys.database_principals C WITH(NOLOCK) ON A.execute_as_principal_id = C.principal_id
		WHERE
			A.execute_as_principal_id IS NOT NULL
			AND C.[name] <> ''dbo''
			AND B.is_ms_shipped = 0
			
	END'


    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            Ds_Database AS 'Objeto/@database',
            Ds_Objeto AS 'Objeto/@objeto',
            Ds_Tipo AS 'Objeto/@tipo',
            Ds_Usuario AS 'Objeto/@usuario'
        FROM
            @Objetos_Com_Impersonate
        ORDER BY
            1, 2, 4
        FOR XML PATH(''), ROOT('Objetos_Com_IMPERSONATE'), TYPE
    )


    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            500, 
            'Vulnerabilidades em C�digo',
            'Objetos com IMPERSONATE', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Verifica��o de procura por objetos (Stored Procedures, Functions, etc) que s�o executados como outro usu�rio que n�o o executor da Procedure',
            'Verifica no c�digo-fonte de todos os objetos, de todos os databases, os que objetos que s�o executados com as permiss�es de um usu�rio fixo (IMPERSONATE)',
            'Remova o comando "EXECUTE AS" da declara��o desses objetos, caso n�o seja necess�rio',
            'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Objetos com query din�mica
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE @Objetos_Query_Dinamica TABLE ( [Ds_Database] nvarchar(256), [Ds_Objeto] nvarchar(256), [Ds_Tipo] nvarchar(128) )


    IF (OBJECT_ID('tempdb.dbo.#Palavras_Exec') IS NOT NULL) DROP TABLE #Palavras_Exec
    CREATE TABLE #Palavras_Exec (
	    Palavra VARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AI
    )

    INSERT INTO #Palavras_Exec
    VALUES('%EXEC (%'), ('%EXEC(%'), ('%EXECUTE (%'), ('%EXECUTE(%'), ('%sp_executesql%')


    INSERT INTO @Objetos_Query_Dinamica
    EXEC sys.sp_MSforeachdb '
	IF (''?'' <> ''tempdb'')
	BEGIN

		SELECT DISTINCT TOP(100)
			''?'' AS Ds_Database,
			B.[name],
			B.[type_desc]
		FROM
			[?].sys.sql_modules A WITH(NOLOCK)
			JOIN [?].sys.objects B WITH(NOLOCK) ON B.[object_id] = A.[object_id]
            JOIN #Palavras_Exec C WITH(NOLOCK) ON A.[definition] COLLATE SQL_Latin1_General_CP1_CI_AI LIKE C.Palavra
		WHERE
			B.is_ms_shipped = 0
			AND ''?'' <> ''ReportServer''
			AND B.[name] NOT IN (''stpChecklist_Seguranca'', ''sp_WhoIsActive'', ''sp_showindex'', ''sp_AllNightLog'', ''sp_AllNightLog_Setup'', ''sp_Blitz'', ''sp_BlitzBackups'', ''sp_BlitzCache'', ''sp_BlitzFirst'', ''sp_BlitzIndex'', ''sp_BlitzLock'', ''sp_BlitzQueryStore'', ''sp_BlitzWho'', ''sp_DatabaseRestore'')
            AND NOT (B.[name] LIKE ''stp_DTA_%'' AND ''?'' = ''msdb'')
            AND NOT (B.[name] = ''sp_readrequest'' AND ''?'' = ''master'')
			AND EXISTS (
                SELECT NULL
                FROM [?].sys.parameters X1 WITH(NOLOCK)
                JOIN [?].sys.types X2 WITH(NOLOCK) ON X1.system_type_id = X2.user_type_id
                WHERE A.[object_id] = X1.[object_id]
                AND X2.[name] IN (''text'', ''ntext'', ''varchar'', ''nvarchar'')
                AND (X1.max_length > 10 OR X1.max_length < 0)
            )
			
	END'

    
        
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            Ds_Database AS 'Objeto/@Database',
            Ds_Objeto AS 'Objeto/@Objeto',
            Ds_Tipo AS 'Objeto/@Tipo'
        FROM
            @Objetos_Query_Dinamica
        ORDER BY
            1, 2
        FOR XML PATH(''), ROOT('Objetos_Query_Dinamica'), TYPE
    )

    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            501, 
            'Vulnerabilidades em C�digo',
            'Objetos com Query Din�mica', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Verifica��o de procura por objetos (Stored Procedures, Functions, etc) que possuem execu��o de c�digos com query din�mica, permitindo ataques como SQL Injection em suas aplica��es e execu��o de c�digos maliciosos',
            'Verifica no c�digo-fonte de todos os objetos, de todos os databases, os que objetos que utilizam query din�mica e que s�o o prov�vel motivo dessa configura��o estar habilitada',
            'Remova o uso de query din�mica sempre que poss�vel. Quando n�o for poss�vel, valide o uso da query din�mica para garantir que os par�metros de entrada est�o sendo tratados e que n�o s�o vulner�veis a ataques de SQL Injection',
            'https://www.dirceuresende.com/blog/sql-server-como-evitar-sql-injection-pare-de-utilizar-query-dinamica-como-execquery-agora/',
            @Resultado
        )
        


    ---------------------------------------------------------------------------------------------------------------
    -- Objetos utilizando xp_cmdshell
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE @Objetos_xp_cmdshell TABLE ( [Ds_Database] nvarchar(256), [Ds_Objeto] nvarchar(256), [Ds_Tipo] nvarchar(128) )

    INSERT INTO @Objetos_xp_cmdshell
    EXEC sys.sp_MSforeachdb '
	IF (''?'' <> ''tempdb'')
	BEGIN

		SELECT TOP 100
			''?'' AS Ds_Database,
			B.[name],
			B.[type_desc]
		FROM
			[?].sys.sql_modules A WITH(NOLOCK)
			JOIN [?].sys.objects B WITH(NOLOCK) ON B.[object_id] = A.[object_id]
		WHERE
			B.is_ms_shipped = 0
			AND ''?'' <> ''ReportServer''
			AND B.[name] NOT IN (''stpChecklist_Seguranca'', ''sp_WhoIsActive'', ''sp_showindex'', ''sp_AllNightLog'', ''sp_AllNightLog_Setup'', ''sp_Blitz'', ''sp_BlitzBackups'', ''sp_BlitzCache'', ''sp_BlitzFirst'', ''sp_BlitzIndex'', ''sp_BlitzLock'', ''sp_BlitzQueryStore'', ''sp_BlitzWho'', ''sp_DatabaseRestore'')
			AND A.definition LIKE ''%xp_cmdshell%''
	
	END'

        
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            Ds_Database AS 'Objeto/@Database',
            Ds_Objeto AS 'Objeto/@Objeto',
            Ds_Tipo AS 'Objeto/@Tipo'
        FROM
            @Objetos_xp_cmdshell
        ORDER BY
            1, 2
        FOR XML PATH(''), ROOT('Objetos_Utilizando_xp_cmdshell'), TYPE
    )

    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            502, 
            'Vulnerabilidades em C�digo',
            'Objetos utilizando xp_cmdshell', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Verifica��o de procura por objetos (Stored Procedures, Functions, etc) que possuem execu��o de c�digos utilizando xp_cmdshell, permitindo que um usu�rio com acesso � essa SP possa executar qualquer comando que o usu�rio do servi�o do SQL Server tenha acesso',
            'Verifica no c�digo-fonte de todos os objetos, de todos os databases, os que objetos que utilizam xp_cmdshell e que s�o o prov�vel motivo dessa configura��o estar habilitada',
            'Remova o uso de comandos xp_cmdshell. Ao inv�s dele, opte por SQLCLR ou pacotes do SSIS',
            'https://hydrasky.com/network-security/mssql-server-injection-tutorial/',
            @Resultado
        )

        

    ---------------------------------------------------------------------------------------------------------------
    -- Objetos utilizando OLE Automation Procedures
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE @Objetos_OLE_Automation TABLE ( [Ds_Database] nvarchar(256), [Ds_Objeto] nvarchar(256), [Ds_Tipo] nvarchar(128) )

    INSERT INTO @Objetos_OLE_Automation
    EXEC sys.sp_MSforeachdb '
	IF (''?'' <> ''tempdb'')
	BEGIN

		SELECT TOP(100)
			''?'' AS Ds_Database,
			B.[name],
			B.[type_desc]
		FROM
			[?].sys.sql_modules A WITH(NOLOCK)
			JOIN [?].sys.objects B WITH(NOLOCK) ON B.[object_id] = A.[object_id]
		WHERE
			B.is_ms_shipped = 0
			AND ''?'' <> ''ReportServer''
			AND B.[name] NOT IN (''stpChecklist_Seguranca'', ''sp_WhoIsActive'', ''sp_showindex'', ''sp_AllNightLog'', ''sp_AllNightLog_Setup'', ''sp_Blitz'', ''sp_BlitzBackups'', ''sp_BlitzCache'', ''sp_BlitzFirst'', ''sp_BlitzIndex'', ''sp_BlitzLock'', ''sp_BlitzQueryStore'', ''sp_BlitzWho'', ''sp_DatabaseRestore'')
            AND B.[name] NOT IN (''dt_addtosourcecontrol'', ''dt_addtosourcecontrol_u'', ''dt_adduserobject'', ''dt_adduserobject_vcs'', ''dt_checkinobject'', ''dt_checkinobject_u'', ''dt_checkoutobject'', ''dt_checkoutobject_u'', ''dt_displayoaerror'', ''dt_displayoaerror_u'', ''dt_droppropertiesbyid'', ''dt_dropuserobjectbyid'', ''dt_generateansiname'', ''dt_getobjwithprop'', ''dt_getobjwithprop_u'', ''dt_getpropertiesbyid'', ''dt_getpropertiesbyid_u'', ''dt_getpropertiesbyid_vcs'', ''dt_getpropertiesbyid_vcs_u'', ''dt_isundersourcecontrol'', ''dt_isundersourcecontrol_u'', ''dt_removefromsourcecontrol'', ''dt_setpropertybyid'', ''dt_setpropertybyid_u'', ''dt_validateloginparams'', ''dt_validateloginparams_u'', ''dt_vcsenabled'', ''dt_verstamp006'', ''dt_verstamp007'', ''dt_whocheckedout'', ''dt_whocheckedout_u'')
			AND A.definition LIKE ''%sp_OACreate%''
			
	END'

        
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT
            Ds_Database AS 'Objeto/@Database',
            Ds_Objeto AS 'Objeto/@Objeto',
            Ds_Tipo AS 'Objeto/@Tipo'
        FROM
            @Objetos_OLE_Automation
        ORDER BY
            1, 2
        FOR XML PATH(''), ROOT('Objetos_Utilizando_OLE_Automation'), TYPE
    )

    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            503, 
            'Vulnerabilidades em C�digo',
            'Objetos utilizando OLE Automation', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Verifica��o de procura por objetos (Stored Procedures, Functions, etc) que possuem execu��o de c�digos utilizando OLE Automation Procedures, que s�o conhecidas por poss�veis memory dumps, vazamentos de mem�ria e acessos externos diversos, como escrever arquivos, enviar requisi��es HTTP, etc.',
            'Verifica no c�digo-fonte de todos os objetos, de todos os databases, os que objetos que utilizam OLE Automation e que s�o o prov�vel motivo dessa configura��o estar habilitada',
            'Remova o uso de comandos OLE Automation. Ao inv�s dele, opte por SQLCLR ou pacotes do SSIS',
            'https://visualstudiomagazine.com/articles/2005/09/01/when-to-use-sqlclr-and-when-not-to.aspx',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Procedures executadas automaticamente na inicializa��o do SQL Server
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE @Procedures_Executadas_Automaticamente TABLE ( [Ds_Database] nvarchar(256), [Ds_Objeto] nvarchar(256), [Ds_Tipo] nvarchar(128), [Dt_Criacao] datetime, [Dt_Modificacao] datetime, [SP_Microsoft] bit )

    INSERT INTO @Procedures_Executadas_Automaticamente
    EXEC sys.sp_MSforeachdb '
    SELECT TOP 100
        ''?'' AS Ds_Database,
        [name],
        [type_desc],
        [create_date],
        [modify_date],
        is_ms_shipped
    FROM 
        sys.procedures WITH(NOLOCK)
    WHERE 
        is_auto_executed = 1'

        
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            Ds_Database AS 'Procedure/@database',
            Ds_Objeto AS 'Procedure/@name',
            Ds_Tipo AS 'Procedure/@type_desc',
            Dt_Criacao AS 'Procedure/@create_date',
            Dt_Modificacao AS 'Procedure/@modify_date',
            SP_Microsoft AS 'Procedure/@is_ms_shipped'
        FROM
            @Procedures_Executadas_Automaticamente
        ORDER BY
            1, 2
        FOR XML PATH(''), ROOT('Procedures_Executadas_Automaticamente'), TYPE
    )

    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            504, 
            'Vulnerabilidades em C�digo',
            'Procedures Executadas Automaticamente', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Verifica��o de procura por objetos que s�o executados automaticamente na inicializa��o do SQL Server, o que pode ser utilizado por invasores para executar c�digos maliciosos toda vez que o servi�o for iniciado',
            'Verifica na DMV sys.procedures de todos os databases, quais procedures possuem a propriedade is_auto_executed = 1',
            'Remova essas SPs da inicializa��o do SQL Server utilizando a SP sp_procoption ou dropando e recriando essa SP',
            'http://blogs.lessthandot.com/index.php/datamgmt/datadesign/list-all-stored-procedures-that/',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Objetos com comandos de GRANT
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE @Objetos_Com_Grant TABLE ( [Ds_Database] nvarchar(256), [Ds_Objeto] nvarchar(256), [Ds_Tipo] nvarchar(128) )

    INSERT INTO @Objetos_Com_Grant
    EXEC sys.sp_MSforeachdb '
	IF (''?'' <> ''tempdb'')
	BEGIN

		SELECT TOP(100)
			''?'' AS Ds_Database,
			B.[name],
			B.[type_desc]
		FROM
			[?].sys.sql_modules A WITH(NOLOCK)
			JOIN [?].sys.objects B WITH(NOLOCK) ON B.[object_id] = A.[object_id]
		WHERE
			B.is_ms_shipped = 0
			AND A.definition LIKE ''%GRANT %''
            AND ''?'' NOT IN (''master'', ''ReportServer'')
            AND B.[name] NOT IN (''dt_addtosourcecontrol'', ''dt_addtosourcecontrol_u'', ''dt_adduserobject'', ''dt_adduserobject_vcs'', ''dt_checkinobject'', ''dt_checkinobject_u'', ''dt_checkoutobject'', ''dt_checkoutobject_u'', ''dt_displayoaerror'', ''dt_displayoaerror_u'', ''dt_droppropertiesbyid'', ''dt_dropuserobjectbyid'', ''dt_generateansiname'', ''dt_getobjwithprop'', ''dt_getobjwithprop_u'', ''dt_getpropertiesbyid'', ''dt_getpropertiesbyid_u'', ''dt_getpropertiesbyid_vcs'', ''dt_getpropertiesbyid_vcs_u'', ''dt_isundersourcecontrol'', ''dt_isundersourcecontrol_u'', ''dt_removefromsourcecontrol'', ''dt_setpropertybyid'', ''dt_setpropertybyid_u'', ''dt_validateloginparams'', ''dt_validateloginparams_u'', ''dt_vcsenabled'', ''dt_verstamp006'', ''dt_verstamp007'', ''dt_whocheckedout'', ''dt_whocheckedout_u'', ''stpChecklist_Seguranca'')
			
	END'

        
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            Ds_Database AS 'Objeto/@database',
            Ds_Objeto AS 'Objeto/@objeto',
            Ds_Tipo AS 'Objeto/@tipo'
        FROM
            @Objetos_Com_Grant
        ORDER BY
            1, 2
        FOR XML PATH(''), ROOT('Objetos_Utilizando_Grant'), TYPE
    )

    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            505, 
            'Vulnerabilidades em C�digo',
            'Objetos utilizando GRANT', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Verifica��o de procura por objetos (Stored Procedures, Functions, etc) que possuem execu��o de c�digos utilizando comandos de GRANT, liberando permiss�es que podem ser perigosas no ambiente, especialmente se estiver dentro de jobs e rotinas autom�ticas',
            'Verifica no c�digo-fonte de todos os objetos, de todos os databases, os que objetos que utilizam comandos de GRANT para liberar permiss�es',
            'Remova o uso de comandos GRANT de objetos',
            NULL,
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Linked Servers que utilizam usu�rio fixo
    ---------------------------------------------------------------------------------------------------------------


    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.server_id AS 'LinkedServer/@server_id',
            A.[name] AS 'LinkedServer/@name',
            B.remote_name AS 'LinkedServer/@remote_name',
            A.product AS 'LinkedServer/@product',
            A.[provider] AS 'LinkedServer/@provider',
            A.[data_source] AS 'LinkedServer/@data_source',
            A.[catalog] AS 'LinkedServer/@catalog'
        FROM 
            sys.servers A WITH(NOLOCK)
            JOIN sys.linked_logins B WITH(NOLOCK) ON B.server_id = A.server_id
        WHERE
            A.is_linked = 1
            AND B.uses_self_credential = 0
        ORDER BY
            2, 3
        FOR XML PATH(''), ROOT('LinkedServer_Usuario_Fixo'), TYPE
    )

    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            506, 
            'Vulnerabilidades em C�digo',
            'Linked Server com usu�rio Fixo', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Verifica��o de procura por Linked Servers que utilizam um usu�rio fixo ao inv�s do usu�rio atual',
            'Verifica nas DMVs sys.servers e sys.linked_logins se existe Linked Server com usu�rio fixo (uses_self_credential = 0)',
            'Se poss�vel, troque a autentica��o do Linked Server pelo usu�rio atual da conex�o',
            NULL,
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se o SQL Server est� sendo executado na porta padr�o 1433
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    IF (@PortaUtilizada = 1433)
    BEGIN

        SET @Resultado = (
            SELECT @PortaUtilizada AS Porta_Utilizada
            FOR XML PATH, ROOT('Porta_Utilizada')
        )

    END
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            600, 
            'Instala��o',
            'Porta Padr�o (1433)', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Essa verifica��o valida se o SQL Server est� utilizando a porta padr�o (1433) para conex�es. Utilizar a porta padr�o pode significar um risco de seguran�a, pois � a primeira porta que qualquer hacker tentaria invadir num poss�vel ataque',
            'Verifica se o SQL Server est� utilizando a porta padr�o (1433) para conex�es',
            'Altere a porta do SQL Server para algum porta diferente do padr�o, a fim de prover mais uma camada de seguran�a, dificultando ataques hackers',
            'https://thomaslarock.com/2016/12/using-non-default-ports-for-sql-server/',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se o SQL Browser est� sendo executado sem necessidade (apenas 1 inst�ncia)
    ---------------------------------------------------------------------------------------------------------------

    IF (@IsAmazonRDS = 0)
    BEGIN


        SET @Resultado = NULL

        IF ((SELECT COUNT(*) FROM @GetInstances) <= 1)
        BEGIN

            DECLARE @SQL_Browser_Instalado TABLE ( Valor INT )

            INSERT INTO @SQL_Browser_Instalado (Valor)
            EXEC master.sys.xp_regread 'HKEY_LOCAL_MACHINE', 'System\CurrentControlSet\Services\SQLBrowser'

            IF ((SELECT TOP(1) Valor FROM @SQL_Browser_Instalado) = 1)
            BEGIN
    
                DECLARE @SQL_Browser_Ativo TABLE ( Resultado VARCHAR(100) )

                INSERT INTO @SQL_Browser_Ativo ( Resultado )
                EXEC master.dbo.xp_servicecontrol N'QUERYSTATE',N'sqlbrowser'

                IF ((SELECT TOP(1) Resultado FROM @SQL_Browser_Ativo) LIKE '%Running%')
                BEGIN
        
                    SET @Resultado = (
                        SELECT *
                        FROM @GetInstances
                        FOR XML PATH, ROOT('SQL_Browser_Rodando_Apenas_1_Instancia')
                    )

                END

            END

        END


        INSERT INTO #Resultado
        (
            Id_Verificacao,
            Ds_Categoria,
            Ds_Titulo,
            Ds_Resultado,
            Ds_Descricao,
            Ds_Verificacao,
            Ds_Sugestao,
		    Ds_Referencia,
            Ds_Detalhes
        )
        VALUES
            (
                601, 
                'Instala��o',
                'SQL Browser executando com apenas 1 inst�ncia', 
                (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
                'Essa configura��o valida se o SQL Browser est� sendo executado em ambientes com apenas 1 inst�ncia, o que n�o justifica a execu��o desse servi�o, que serve para fornecer informa��es das inst�ncias instaladas no servidor e pode facilitar ataques maliciosos ao expor os nomes das inst�ncias na rede. Caso essa inst�ncia n�o fa�a parte de um cluster, analise se o servi�o pode ser desativado e se portas customizadas est�o sendo utilizadas.',
                'Verifica se o SQL Browser est� sendo executado em ambientes com apenas 1 inst�ncia',
                'Desabilite o SQL Browser caso voc� esteja utilizando a inst�ncia padr�o do SQL Server OU se na string de conex�o voc� j� utiliza o formato "SERVIDOR\INSTANCIA,PORTA"',
                'https://www.stigviewer.com/stig/ms_sql_server_2014_instance/2016-11-16/finding/V-70623',
                @Resultado
            )

    END



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se a configura��o "Hide Instance" est� ativada
    ---------------------------------------------------------------------------------------------------------------

    IF (@IsAmazonRDS = 0)
    BEGIN

    
        DECLARE @HideInstance INT 

        EXEC master..xp_instance_regread 
              @rootkey = N'HKEY_LOCAL_MACHINE', 
              @key = N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib', 
              @value_name = N'HideInstance',
              @value = @HideInstance OUTPUT

    
        SET @Resultado = NULL

        IF (@HideInstance = 0)
        BEGIN

            SET @Resultado = (
                SELECT @HideInstance AS [HideInstance]
                FOR XML PATH, ROOT('Configuracao_HideInstance')
            )

        END


        INSERT INTO #Resultado
        (
            Id_Verificacao,
            Ds_Categoria,
            Ds_Titulo,
            Ds_Resultado,
            Ds_Descricao,
            Ds_Verificacao,
            Ds_Sugestao,
		    Ds_Referencia,
            Ds_Detalhes
        )
        VALUES
            (
                602, 
                'Instala��o',
                'Nome da inst�ncia exposta na rede', 
                (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
                'Essa configura��o valida se o nome da inst�ncia est� exposta na rede, permitindo que ela seja listada atrav�s da op��o "Browse.." do SQL Server Management Studio (SSMS)',
                'Verifica se o par�metro HideInstance est� ativado no SQL Configuration Manager',
                'Ative o par�metro "Hide Instance" dessa inst�ncia no SQL Configuration Manager, abaixo de "SQL Server Network Configuration" -> "Protocols for <Sua Instancia>"',
                'https://www.mytechmantra.com/LearnSQLServer/How_to_Hide_an_Instance_of_SQL_Server.html',
                @Resultado
            )


    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica as contas que o SQL Server est� utilizando para iniciar os servi�os
    ---------------------------------------------------------------------------------------------------------------

    IF (@IsAmazonRDS = 0)
    BEGIN

        DECLARE 
            @DBEngineLogin VARCHAR(100),
            @AgentLogin VARCHAR(100)

        EXECUTE master.dbo.xp_instance_regread
            @rootkey = N'HKEY_LOCAL_MACHINE',
            @key = N'SYSTEM\CurrentControlSet\Services\MSSQLServer',
            @value_name = N'ObjectName',
            @value = @DBEngineLogin OUTPUT

        EXECUTE master.dbo.xp_instance_regread
            @rootkey = N'HKEY_LOCAL_MACHINE',
            @key = N'SYSTEM\CurrentControlSet\Services\SQLServerAgent',
            @value_name = N'ObjectName',
            @value = @AgentLogin OUTPUT


        SET @Resultado = NULL

        IF (@DBEngineLogin LIKE 'NT SERVICE\%' OR @AgentLogin LIKE 'NT SERVICE\%' OR @DBEngineLogin = 'LocalSystem' OR @AgentLogin = 'LocalSystem' OR @DBEngineLogin LIKE 'NT AUTHORITY\%' OR @AgentLogin LIKE 'NT AUTHORITY\%')
        BEGIN

            SET @Resultado = (
                SELECT
                    @DBEngineLogin AS [DBEngineLogin],
                    @AgentLogin AS [AgentLogin]
                FOR XML PATH, ROOT('Configuracao_Usuario_Servico')
            )

        END
    

        INSERT INTO #Resultado
        (
            Id_Verificacao,
            Ds_Categoria,
            Ds_Titulo,
            Ds_Resultado,
            Ds_Descricao,
            Ds_Verificacao,
            Ds_Sugestao,
		    Ds_Referencia,
            Ds_Detalhes
        )
        VALUES
            (
                603, 
                'Instala��o',
                'Usu�rio dos Servi�os de SQL',
                (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
                'Essa configura��o valida os usu�rios utilizados para iniciar os servi�os do SQL Server. A recomenda��o � que sejam utilizados usu�rios do AD, para que a manuten��o desses usu�rios seja f�cil pelo time de Infra. Usu�rios locais n�o devem ser utilizados, pois ele possuem permiss�es elevadas nos diret�rios do SO',
                'Verifica se os usu�rios utilizados pelos servi�os s�o os usu�rios padr�o do SQL Server',
                'Altere o usu�rio dos servi�os SQL por usu�rios do AD, com permiss�es restritas, caso seu servidor precise de acesso � rede ou a outros servidores. Caso contr�rio, utilize a conta Local User Account',
                'https://sqlcommunity.com/best-practices-for-sql-server-service-account/',
                @Resultado
            )

    END



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se o SQL Server est� instalado em uma vers�o antiga do Windows Server ou se � vers�o "Pessoal" do Windows
    ---------------------------------------------------------------------------------------------------------------

    IF (@IsAmazonRDS = 0)
    BEGIN

        DECLARE 
            @VersaoWindows_ProductName VARCHAR(200),
            @VersaoWindows_CurrentVersion VARCHAR(200),
            @VersaoWindows_CurrentBuild VARCHAR(200),
            @VersaoWindows_Language VARCHAR(20)

        EXEC master.dbo.xp_regread @rootkey = 'HKEY_LOCAL_MACHINE', @key = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion', @value_name = 'ProductName', @value = @VersaoWindows_ProductName OUT
        EXEC master.dbo.xp_regread @rootkey = 'HKEY_LOCAL_MACHINE', @key = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion', @value_name = 'CurrentVersion', @value = @VersaoWindows_CurrentVersion OUT
        EXEC master.dbo.xp_regread @rootkey = 'HKEY_LOCAL_MACHINE', @key = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion', @value_name = 'CurrentBuild', @value = @VersaoWindows_CurrentBuild OUT
        EXEC master.dbo.xp_regread @rootkey = 'HKEY_LOCAL_MACHINE', @key = 'SYSTEM\CurrentControlSet\Control\Nls\Language', @value_name = 'InstallLanguage', @value = @VersaoWindows_Language OUT
    
    
        SET @Resultado = NULL

    
        SET @Resultado = (
            SELECT 
                @VersaoWindows_ProductName AS [Product_Name],
                @VersaoWindows_CurrentBuild AS CurrentBuild, 
                @VersaoWindows_CurrentVersion AS CurrentVersion,
                @VersaoWindows_Language AS [Language]
            FOR XML PATH, ROOT('Instalacao_Versao_Windows')
        )
    

        INSERT INTO #Resultado
        (
            Id_Verificacao,
            Ds_Categoria,
            Ds_Titulo,
            Ds_Resultado,
            Ds_Descricao,
            Ds_Verificacao,
            Ds_Sugestao,
		    Ds_Referencia,
            Ds_Detalhes
        )
        VALUES
            (
                604, 
                'Instala��o',
                'SQL Server em Windows com vers�o antiga ou pessoal', 
                (CASE WHEN @VersaoWindows_ProductName LIKE '% Server %' AND (@VersaoWindows_ProductName LIKE '% Server 2016%' OR @VersaoWindows_ProductName LIKE '% Server 2019%') THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
                'Essa configura��o valida se o SQL Server est� instalado em uma vers�o desatualizada do Windows Server ou se est� instalado numa vers�o pessoal do Windows',
                'Verifica a vers�o do Windows para identificar se est� utilizando a vers�o mais recente do Windows Server',
                'Utilize sempre a vers�o mais recente do Windows Server para garantir a utiliza��o de novas recursos e corre��es de seguran�a',
                'https://www.microsoft.com/pt-br/cloud-platform/windows-server',
                @Resultado
            )


    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se a vers�o do SQL Server ainda � suportada pela Microsoft
    ---------------------------------------------------------------------------------------------------------------

    DECLARE @Versoes_SQL_Server TABLE (
        [ProductName] VARCHAR(50),
        [ProductVersion] VARCHAR(100),
        [ProductLevel] VARCHAR(100),
        [Edition] VARCHAR(100),
        [EditionID] BIGINT,
        [EngineEdition] INT,
        [EngineEditionDescription] VARCHAR(100),
        [ProductBuild] INT,
        [ProductBuildType] VARCHAR(20),
        [ProductMajorVersion] INT,
        [ProductMinorVersion] INT,
        [ProductUpdateLevel] VARCHAR(100),
        [ProductUpdateReference] VARCHAR(100),
        [BuildClrVersion] VARCHAR(100),
        [LicenseType] VARCHAR(100),
        [ResourceVersion] VARCHAR(100)
    )

    
    INSERT INTO @Versoes_SQL_Server
    SELECT
        (CASE
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '8%' THEN 'SQL Server 2000'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '9%' THEN 'SQL Server 2005'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '10.0%' THEN 'SQL Server 2008'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '10.5%' THEN 'SQL Server 2008 R2'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '11%' THEN 'SQL Server 2012'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '12%' THEN 'SQL Server 2014'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '13%' THEN 'SQL Server 2016'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '14%' THEN 'SQL Server 2017'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '15%' THEN 'SQL Server 2019'
            ELSE 'Desconhecido'
        END) AS ProductName,
        CONVERT(VARCHAR(100), SERVERPROPERTY('ProductVersion')) AS ProductVersion,
        CONVERT(VARCHAR(20), SERVERPROPERTY('ProductLevel')) AS ProductLevel,
        CONVERT(VARCHAR(100), SERVERPROPERTY('Edition')) AS Edition,
        CONVERT(BIGINT, SERVERPROPERTY('EditionID')) AS EditionID,
        CONVERT(INT, SERVERPROPERTY('EngineEdition')) AS EngineEdition,
        (CASE CONVERT(INT, SERVERPROPERTY('EngineEdition'))
            WHEN '1' THEN 'Personal ou Desktop Engine (N�o dispon�vel no SQL Server 2005 e em vers�es posteriores)'
            WHEN '2' THEN 'Standard (Retornada para Standard, Web e Business Intelligence)'
            WHEN '3' THEN 'Enterprise (Retornado para Evaluation, Developer e Enterprise)'
            WHEN '4' THEN 'Express (Retornada para Express, Express with Tools e Express com Advanced Services)'
            WHEN '5' THEN 'SQL Database'
            WHEN '6' THEN 'SQL Data Warehouse'
            WHEN '8' THEN 'Managed Instance'
        END) AS EngineEditionDescription,
        CONVERT(INT, SERVERPROPERTY('ProductBuild')) AS ProductBuild,
        CONVERT(VARCHAR(20), SERVERPROPERTY('ProductBuildType')) AS ProductBuildType,
        CONVERT(INT, SERVERPROPERTY('ProductMajorVersion')) AS ProductMajorVersion,
        CONVERT(INT, SERVERPROPERTY('ProductMinorVersion')) AS ProductMinorVersion,
        CONVERT(VARCHAR(100), SERVERPROPERTY('ProductUpdateLevel')) AS ProductUpdateLevel,
        CONVERT(VARCHAR(100), SERVERPROPERTY('ProductUpdateReference')) AS ProductUpdateReference,
        CONVERT(VARCHAR(100), SERVERPROPERTY('BuildClrVersion')) AS BuildClrVersion,
        CONVERT(VARCHAR(100), SERVERPROPERTY('LicenseType')) AS LicenseType,
        CONVERT(VARCHAR(100), SERVERPROPERTY('ResourceVersion')) AS ResourceVersion


    SET @Resultado = NULL

    
    SET @Resultado = (
        SELECT *
        FROM @Versoes_SQL_Server
        FOR XML PATH, ROOT('Instalacao_Versao_Nao_Suportada')
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            605, 
            'Instala��o',
            'Vers�o do SQL Server n�o suportada',
            (CASE WHEN CONVERT(INT, SERVERPROPERTY('ProductMajorVersion')) >= 11 THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Essa configura��o valida se o SQL Server possui uma vers�o que ainda tem suporte e atualiza��es pela Microsoft',
            'Verifica a vers�o do SQL Server ainda � suportada pela Microsoft',
            'Atualize a vers�o do SQL Server para receber atualiza��es de seguran�a e utilizar novos recursos',
            'https://www.microsoft.com/pt-br/sql-server/sql-server-downloads',
            @Resultado
        )


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica a �ltima atualiza��o do SQL Server
    ---------------------------------------------------------------------------------------------------------------

    IF (@IsAmazonRDS = 0)
    BEGIN

        DECLARE @Fl_Ole_Automation_Ativado BIT = (SELECT (CASE WHEN CAST([value] AS VARCHAR(MAX)) = '1' THEN 1 ELSE 0 END) FROM sys.configurations WHERE [name] = 'Ole Automation Procedures')
 
        IF (@Fl_Ole_Automation_Ativado = 0)
        BEGIN
 
            EXEC sp_configure 'show advanced options', 1
            RECONFIGURE WITH OVERRIDE
    
            EXEC sp_configure 'Ole Automation Procedures', 1
            RECONFIGURE WITH OVERRIDE
    
        END


    
        DECLARE 
            @obj INT,
            @Url VARCHAR(8000),
            @xml VARCHAR(MAX),
            @resposta VARCHAR(MAX)
        
        SET @Url = 'http://sqlserverbuilds.blogspot.com/'
 
        EXEC sys.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT
        EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, false
        EXEC sys.sp_OAMethod @obj, 'send'
 
 
        DECLARE @xml_versao_sql TABLE (
            Ds_Dados VARCHAR(MAX)
        )
 
        INSERT INTO @xml_versao_sql(Ds_Dados)
        EXEC sys.sp_OAGetProperty @obj, 'responseText' --, @resposta OUT
    
    
        EXEC sys.sp_OADestroy @obj



        IF (@Fl_Ole_Automation_Ativado = 0)
        BEGIN
 
            EXEC sp_configure 'Ole Automation Procedures', 0
            RECONFIGURE WITH OVERRIDE
 
            EXEC sp_configure 'show advanced options', 0
            RECONFIGURE WITH OVERRIDE
 
        END
 
    

        DECLARE
            @Versao_SQL_Build VARCHAR(10)
    
        SET @Versao_SQL_Build = (CASE LEFT(CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion')), 2)
            WHEN '8.' THEN '2000'
            WHEN '9.' THEN '2005'
            WHEN '10' THEN (
                CASE
                    WHEN LEFT(CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion')), 4) = '10.5' THEN '2008 R2' 
                    WHEN LEFT(CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion')), 4) = '10.0' THEN '2008' 
                END)
            WHEN '11' THEN '2012'
            WHEN '12' THEN '2014'
            WHEN '13' THEN '2016'
            WHEN '14' THEN '2017'
            WHEN '15' THEN '2019'
            ELSE '2019'
        END)


        SELECT TOP 1 @resposta = Ds_Dados FROM @xml_versao_sql
 
    
        SET @xml = @resposta COLLATE SQL_Latin1_General_CP1251_CS_AS

        DECLARE
            @PosicaoInicialVersao INT,
            @PosicaoFinalVersao INT,
            @ExpressaoBuscar VARCHAR(100) = 'Microsoft SQL Server ' + @Versao_SQL_Build + ' Builds',
            @RetornoTabela VARCHAR(MAX),
            @dadosXML XML

        SET @PosicaoInicialVersao = CHARINDEX(@ExpressaoBuscar, @xml) + LEN(@ExpressaoBuscar) + 6
        SET @PosicaoFinalVersao = CHARINDEX('</table>', @xml, @PosicaoInicialVersao)
        SET @RetornoTabela = SUBSTRING(@xml, @PosicaoInicialVersao, @PosicaoFinalVersao - @PosicaoInicialVersao + 8)


        -- Corrigindo classes sem aspas duplas ("")
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' border=1 cellpadding=4 cellspacing=0 bordercolor="#CCCCCC" style="border-collapse:collapse"', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' target=_blank rel=nofollow', ' target="_blank" rel="nofollow"')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=h', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=lsp', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=cu', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=sp', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=rtm', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' width=580', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' width=125', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=lcu', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=cve', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=lrtm', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=beta', '')

        -- Corrigindo elementos n�o fechados corretamente
        SET @RetornoTabela = REPLACE(@RetornoTabela, '<th>', '</th><th>')
        SET @RetornoTabela = REPLACE(@RetornoTabela, '<tr></th>', '<tr>')
        SET @RetornoTabela = REPLACE(@RetornoTabela, '<th>Release Date</tr>', '<th>Release Date</th></tr>')

        SET @RetornoTabela = REPLACE(@RetornoTabela, '<td>', '</td><td>')
        SET @RetornoTabela = REPLACE(@RetornoTabela, '<tr></td>', '<tr>')

        SET @RetornoTabela = REPLACE(@RetornoTabela, '</tr>', '</td></tr>')
        SET @RetornoTabela = REPLACE(@RetornoTabela, '</th></td>', '</th>')
        SET @RetornoTabela = REPLACE(@RetornoTabela, '</td></td>', '</td>')

        -- Removendo elementos de entidades HTML
        SET @RetornoTabela = REPLACE(@RetornoTabela, '&nbsp;', ' ')
        SET @RetornoTabela = REPLACE(@RetornoTabela, '&kbln', '&amp;kbln')
        SET @RetornoTabela = REPLACE(@RetornoTabela, '<br>', '<br/>')

        SET @dadosXML = CONVERT(XML, @RetornoTabela)


        DECLARE @Atualizacoes_SQL_Server TABLE
        (
            [Ultimo_Build] VARCHAR(100),
            [Ultimo_Build_SQLSERVR.EXE] VARCHAR(100),
            [Versao_Arquivo] VARCHAR(100),
            [Q] VARCHAR(100),
            [KB] VARCHAR(100),
            [Descricao_KB] VARCHAR(100),
            [Lancamento_KB] VARCHAR(100),
            [Download_Ultimo_Build] VARCHAR(100)
        )


        INSERT INTO @Atualizacoes_SQL_Server
        SELECT
            @dadosXML.value('(//table/tr/td[1])[1]','varchar(100)') AS Ultimo_Build,
            @dadosXML.value('(//table/tr/td[2])[1]','varchar(100)') AS [Ultimo_Build_SQLSERVR.EXE],
            @dadosXML.value('(//table/tr/td[3])[1]','varchar(100)') AS Versao_Arquivo,
            @dadosXML.value('(//table/tr/td[4])[1]','varchar(100)') AS [Q],
            @dadosXML.value('(//table/tr/td[5])[1]','varchar(100)') AS KB,
            @dadosXML.value('(//table/tr/td[6]/a)[1]','varchar(100)') AS Descricao_KB,
            @dadosXML.value('(//table/tr/td[7])[1]','varchar(100)') AS Lancamento_KB,
            @dadosXML.value('(//table/tr/td[6]/a/@href)[1]','varchar(100)') AS Download_Ultimo_Build
    

        DECLARE 
            @Url_Ultima_Versao_SQL VARCHAR(500) = (SELECT TOP(1) Download_Ultimo_Build FROM @Atualizacoes_SQL_Server),
            @Ultimo_Build VARCHAR(100) = (SELECT TOP(1) Ultimo_Build FROM @Atualizacoes_SQL_Server)

        SET @Resultado = NULL

    
        SET @Resultado = (
            SELECT *
            FROM @Atualizacoes_SQL_Server
            FOR XML PATH, ROOT('Instalacao_Atualizacoes_SQL')
        )
    
    
        INSERT INTO #Resultado
        (
            Id_Verificacao,
            Ds_Categoria,
            Ds_Titulo,
            Ds_Resultado,
            Ds_Descricao,
            Ds_Verificacao,
            Ds_Sugestao,
		    Ds_Referencia,
            Ds_Detalhes
        )
        VALUES
            (
                606, 
                'Instala��o',
                'SQL Server desatualizado', 
                (CASE WHEN CONVERT(VARCHAR(100), SERVERPROPERTY('ProductVersion')) >= @Ultimo_Build THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
                'Essa configura��o valida se o SQL Server est� instalado com a �ltima vers�o dos Service Pack e Cumulative Updates dispon�veis. Estar sempre atualizado � importante para a seguran�a, pois garante que falhas cr�ticas estejam sempre atualizadas e corrigidas',
                'Verifica se o build mais recente do SQL Server � o mesmo do build instalado',
                'Utilize sempre a vers�o mais recente SQL Server e o mantenha atualizado com a �ltima vers�o do Service Pack e Cumulative Updates',
                @Url_Ultima_Versao_SQL,
                @Resultado
            )


    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se existem bases de dados "p�blicas" na inst�ncia
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    
    SET @Resultado = (
        SELECT 
            [name] AS 'Database/@name',
            database_id AS 'Database/@database_id',
            [compatibility_level] AS 'Database/@compatibility_level',
            [state_desc] AS 'Database/@state_desc',
            recovery_model_desc AS 'Database/@recovery_model_desc',
            page_verify_option_desc AS 'Database/@page_verify_option_desc'
        FROM
            sys.databases
        WHERE
            [name] IN ('pub', 'Northwind', 'AdventureWorks', 'AdventureWorksLT', 'AdventureWorksDW', 'WideWorldImporters', 'WideWorldImportersDW')
        FOR XML PATH(''), ROOT('Databases_Publicas_Instaladas'), TYPE
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            607, 
            'Instala��o',
            'Databases p�blicas instaladas', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Essa configura��o valida se algum dos databases p�blicos s�o instalados na inst�ncia, servindo como uma poss�vel porta de entrada para ataques, j� que sua estrutura � amplamente conhecida',
            'Verifica se os databases pub, Northwind, AdventureWorks, AdventureWorksLT, AdventureWorksDW, WideWorldImporters ou WideWorldImportersDW est�o instalados',
            'Caso seja uma base de produ��o, remova esses databases e crie-os em inst�ncias de testes/desenvolvimento',
            'https://www.stigviewer.com/stig/ms_sql_server_2014_instance/2017-11-30/finding/V-67817',
            @Resultado
        )



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se existem bases de dados "p�blicas" na inst�ncia
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    
    SET @Resultado = (
        SELECT DISTINCT 
            net_transport 
        FROM 
            sys.dm_exec_connections 
        WHERE 
            net_transport NOT IN ('Session', 'TCP', 'Shared Memory')
        FOR XML PATH, ROOT('Protocolos_de_Rede')
    )
    
    
    INSERT INTO #Resultado
    (
        Id_Verificacao,
        Ds_Categoria,
        Ds_Titulo,
        Ds_Resultado,
        Ds_Descricao,
        Ds_Verificacao,
        Ds_Sugestao,
		Ds_Referencia,
        Ds_Detalhes
    )
    VALUES
        (
            608, 
            'Instala��o',
            'Protocolos de rede n�o necess�rios', 
            (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
            'Essa configura��o valida quais os protocolos de rede sendo utilizados na inst�ncia. Por padr�o, o protocolo TCP/IP � o �nico necess�rio, enquanto o Shared Memory � indicado para conex�es feita no pr�prio servidor, e o Named Pipes � uma conex�o que deve ser utilizada quando ocorrem problemas no TCP/IP',
            'Verifica se quais os protocolos de rede utilizados na sys.dm_exec_connections',
            'Desative os protocolos de rede que n�o s�o estritamente necess�rios, como o VIVA, Named Pipes e Shared Memory',
            'https://blogs.msdn.microsoft.com/securesql/2018/03/the-sql-server-defensive-dozen-part-1-hardening-sql-network-components/',
            @Resultado
        )

        

    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se o Firewall do Windows est� ativado
    ---------------------------------------------------------------------------------------------------------------

    IF (@IsAmazonRDS = 0)
    BEGIN

        
        DECLARE @Windows_Firewall INT

        EXEC master.dbo.xp_regread @rootkey = 'HKEY_LOCAL_MACHINE', @key = 'SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile', @value_name = 'EnableFirewall', @value = @Windows_Firewall OUT
    
    
        SET @Resultado = NULL


        IF (@Windows_Firewall = 0)
        BEGIN
    
            SET @Resultado = (
                SELECT
                    'SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile' AS [Chave],
                    @Windows_Firewall AS [EnableFirewall]
                FOR XML PATH, ROOT('Windows_Firewall')
            )

        END

        
    
        INSERT INTO #Resultado
        (
            Id_Verificacao,
            Ds_Categoria,
            Ds_Titulo,
            Ds_Resultado,
            Ds_Descricao,
            Ds_Verificacao,
            Ds_Sugestao,
		    Ds_Referencia,
            Ds_Detalhes
        )
        VALUES
            (
                609, 
                'Instala��o',
                'Windows Firewall desativado', 
                (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Poss�vel problema encontrado' END), 
                'Essa configura��o valida se o Firewall do Windows est� ativado no servidor',
                'Verifica no registro do Windows se o Firewall est� ativo',
                'Verifique se existe outro software de Firewall no servidor. Caso n�o tenha, ative o Firewall do Windows',
                NULL,
                @Resultado
            )


    END


        
    ---------------------------------------------------------------------------------------------------------------
    -- Mostra os resultados
    ---------------------------------------------------------------------------------------------------------------
    
    SELECT 
        Id_Verificacao AS [C�digo],
        Ds_Categoria AS [Categoria],
        Ds_Titulo AS [O que � verificado],
        Ds_Resultado AS [Avalia��o],
        Ds_Descricao AS [Descri��o do Problema],
        Ds_Verificacao AS [Detalhamento da Verifica��o],
        Ds_Sugestao AS [Sugest�o de Corre��o],
        Ds_Detalhes AS [Resultados da Valida��o],
        CONVERT(XML, Ds_Referencia) AS [URL de Refer�ncia]
    FROM 
        #Resultado
 

END



-- EXEC dbo.stpChecklist_Seguranca