EXEC sp_change_users_login 'Report'
--alternativa 1
EXEC sp_change_users_login 'Auto_Fix', 'NomeUsuario'
-- alternativa 2
EXEC sp_change_users_login ' Update_One', 'NomeUsuario', 'LoginDiferente'
-- alternativa 3
EXEC sp_change_users_login ' Update_One', 'NomeUsuario', 'NovoLogin’, 'Senha'