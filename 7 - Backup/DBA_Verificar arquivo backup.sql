-- Mostra informações do backup

RESTORE HEADERONLY
FROM DISK = 'd:\temp\master176.bak'



-- Verifica integridade do backup

RESTORE VERIFYONLY FROM DISK='D:\Program Files\Microsoft SQL Server\MSSQL\Full\BkF200807232330SCMEVAL'