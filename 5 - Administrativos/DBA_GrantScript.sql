
-- Cria script de adicao dos usuarios nas roles (selecionar o banco desejado)
select 'EXEC sp_addrolemember N' + '''' + g.name + '''' + ', N' + '''' + u.name + ''''
from sysusers u,sysusers g,sysmembers m
where   g.uid = m.groupuid
and g.issqlrole = 1
and u.uid = m.memberuid
and u.name <> 'dbo'

-- Cria script para conceder privilegios no objetos aos usuarios (selecionar o banco desejado)
SELECT 'GRANT ' +
       CASE
         WHEN A.ACTION = 193 THEN 'SELECT'
         WHEN A.ACTION = 195 THEN 'INSERT'
         WHEN A.ACTION = 196 THEN 'DELETE'
         WHEN A.ACTION = 197 THEN 'UPDATE'
         WHEN A.ACTION = 224 THEN 'EXECUTE'
       END +
       ' on ' + C.NAME + '.' + D.NAME +
       ' to ' + B.NAME 
FROM SYSPROTECTS A, SYSUSERS B, SYSUSERS C, SYSOBJECTS D
WHERE A.UID = B.UID AND D.UID = C.UID AND A.ID = D.ID
AND A.ACTION IN (193,195,196,197,224) and a.uid <> 0

-- cria script de sinconismo login_x_usuario (selectionar o banco desejado)
set nocount on
select 'EXEC sp_change_users_login ' + '''' + 'UPDATE_ONE' + '''' + 
       ', ' + '''' + u.name + '''' + ', ' + ''''+ l.name + ''''
from sysusers u,
     sysusers g,
     sysmembers m,
     master.dbo.syslogins l
where   g.uid = m.groupuid
and g.issqlrole = 1
and l.isntuser = 0
and u.uid = m.memberuid
and u.sid = l.sid
and u.name <> 'dbo'
order by 1
select 'EXEC sp_change_users_login ' + '''' + 'AUTO_FIX' + '''' + 
       ', ' + '''' + u.name + ''''
from sysusers u,
     sysusers g,
     sysmembers m,
     master.dbo.syslogins l
where   g.uid = m.groupuid
and g.issqlrole = 1
and l.isntuser = 1
and u.uid = m.memberuid
and u.sid = l.sid
and u.name <> 'dbo'
order by 1
SELECT 'EXEC sp_changedbowner ' + '''' + SUSER_SNAME(sid) + ''''
FROM master.dbo.sysdatabases
WHERE SUSER_SNAME(sid) IS NOT NULL
AND name = (select db_name())