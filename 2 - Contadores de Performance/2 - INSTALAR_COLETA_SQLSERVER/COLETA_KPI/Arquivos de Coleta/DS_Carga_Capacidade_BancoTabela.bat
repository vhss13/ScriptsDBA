sqlcmd -S tcp:172.16.33.71,1433 -U dbativit -P dbativit -d DBATIVIT -h-1 -i "DS_Carga_Capacidade_BancoTabela.sql" -o "DS_Carga_Capacidade_BancoTabela.txt" -W -s";"
