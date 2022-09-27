-- Alterar BDID e/ou configurar clausula where para o kill

set nocount on
declare @cont int,
          @spid int,
          @command varchar(2000)

IF EXISTS (SELECT 1 FROM Tempdb..Sysobjects WHERE [Id] = OBJECT_ID('Tempdb..#tmpspid'))
BEGIN
DROP TABLE #tmpspid
END

select identity(int,1,1) as id , spid
into #tmpspid from master.dbo.sysprocesses
where dbid = 8
-- and original_login_name = 'teste'
-- and program_name like 'Microsoft SQL Server Management Studio%'

set @cont = @@rowcount
while @cont <> 0
begin
      select @spid = spid from #tmpspid where id = @cont
      if (@spid) is not null
      begin
            set @command='kill '+convert(varchar(5),@spid)
            print (@command)
            exec (@command)
      end
      set @cont = @cont-1
end
set nocount off
