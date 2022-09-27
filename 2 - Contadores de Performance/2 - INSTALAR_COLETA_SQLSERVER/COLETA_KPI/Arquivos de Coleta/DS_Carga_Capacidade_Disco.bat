sqlcmd -S tcp:172.16.33.71,1433 -U dbativit -P dbativit -d DBATIVIT -h-1 -i "DS_Carga_Capacidade_Disco.sql" -o "DS_Carga_Capacidade_Disco.txt" -W -s";"
