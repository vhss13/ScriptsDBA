set nocount on
declare @cont int,
	@name varchar(200),
	@command varchar(2000)

if object_id('tempdb..#tmpnamedb') is not null
begin
	drop table #tmpnamedb
end

select 'id'=identity(int,1,1), name into #tmpnamedb from master..sysdatabases order by name desc
set @cont = @@rowcount
while @cont <> 0
begin
	select @name = name from #tmpnamedb where id = @cont
	if (@name) is not null
	begin
		set @command="use ["+@name+"]"+char(13)+char(10)+
				"print '["+@name+"]'"+char(13)+char(10)+
				'select "sp_change_users_login ' + Char(39) + 'Auto_fix' + "','" + Char(34) + " + name" + 
				' + ' + Char(34) + Char(39) + Char(34) + ' from sysusers Where name not in (' +
				"'public', 'INFORMATION_SCHEMA', 'system_function_sc'," +
				" 'db_owner', 'db_accessadmin', 'db_securityadmin', 'db_ddladmin', 'db_backupoperator'," +
				"'db_datareader', 'db_datawriter', 'db_denydatareader', 'db_denydatawriter', 'guest', " +
				"'system_function_schema', 'dbo')" + char(13)+char(10)--+ 'Go' + Char(13) + Char(10)
--		print (@command)
		exec (@command)
	end
	set @cont = @cont-1
end
set nocount off
