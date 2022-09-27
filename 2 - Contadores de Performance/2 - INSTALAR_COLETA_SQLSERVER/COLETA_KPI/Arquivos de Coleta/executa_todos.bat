@echo off
cls
call DS_Carga_Capacidade_BancoDatafile.bat
call DS_Carga_Capacidade_BancoTabela.bat
call DS_Carga_Capacidade_Disco.bat
call DS_Carga_Parametros_Banco.bat
call DS_Carga_PerfmonCollector.bat
