-- mostra usuários x roles from instance
dbo.sp_helpsrvrolemember

select loginname, denylogin, hasaccess, sysadmin, securityadmin, serveradmin, setupadmin, processadmin, diskadmin, dbcreator, bulkadmin
From master..syslogins
Where Left(loginname, 2) <> '##'
Order by loginname



-- mostra usuários x roles from databases
sp_helprolemember

OU

select DbRole = g.name,
       MemberName = u.name,
       LoginName = l.name
from sysusers u,
     sysusers g,
     sysmembers m,
     master.dbo.syslogins l
where   g.uid = m.groupuid
and g.issqlrole = 1
and u.uid = m.memberuid
and u.sid = l.sid
order by 1, 2

/*  sp_helprolemember
select DbRole = g.name,
       MemberName = u.name,
       MemberSID = u.sid
from sysusers u,
     sysusers g,
     sysmembers m
where   g.uid = m.groupuid
and g.issqlrole = 1
and u.uid = m.memberuid
order by 1, 2
*/

-- procedures com descrição dos usuários
EXEC sp_helpuser <USER>           -- lista os grants do usuário
EXEC sp_helprotect '<TABLE>'      -- lista todas as permissões para a tabela.
EXEC sp_helprotect NULL, '<USER>' -- lista todos os objetos que o usuário tem permissão.


-------------------------------------------------------
-- Para listar privilegios dos usuários do databases --
-------------------------------------------------------

  executar o EXEC sp_helpuser
-- irá lista os usuários e roles
  depois executar a query
SELECT
	'O usuário ' + B.NAME 
	+ ' tem privilégio de ' + 
 	CASE 
		WHEN A.ACTION = 193 THEN 'SELECT'
		WHEN A.ACTION = 195 THEN 'INSERT'
		WHEN A.ACTION = 196 THEN 'DELETE'
		WHEN A.ACTION = 197 THEN 'UPDATE'
		WHEN A.ACTION = 224 THEN 'EXECUTE'
	END + 
	' no objeto ' +
        C.NAME + '.' +
        D.NAME	 
FROM SYSPROTECTS A, SYSUSERS B, SYSUSERS C, SYSOBJECTS D
WHERE A.UID = B.UID AND D.UID = C.UID AND A.ID = D.ID
AND A.ACTION IN (193,195,196,197,224) and a.uid <> 0

 OU

SELECT
        C.NAME as OWNER,
        D.NAME as OBJECT, 
 	CASE 
		WHEN A.ACTION = 193 THEN 'SELECT'
		WHEN A.ACTION = 195 THEN 'INSERT'
		WHEN A.ACTION = 196 THEN 'DELETE'
		WHEN A.ACTION = 197 THEN 'UPDATE'
		WHEN A.ACTION = 224 THEN 'EXECUTE'
	END as PRIVILEGE,
	B.NAME as USERS
FROM SYSPROTECTS A, SYSUSERS B, SYSUSERS C, SYSOBJECTS D
WHERE A.UID = B.UID AND D.UID = C.UID AND A.ID = D.ID
AND A.ACTION IN (193,195,196,197,224) and a.uid <> 0


  OU


SELECT
  B.NAME AS USUÁRIO,
  C.NAME AS OWNER,
  D.NAME AS TABELA
FROM SYSPROTECTS A, SYSUSERS B, SYSUSERS C, SYSOBJECTS D
WHERE A.UID = B.UID AND D.UID = C.UID AND A.ID = D.ID
AND A.ACTION IN (193,195,196,197,224) and a.uid <> 0
AND A.ACTION = 193
AND D.NAME in ('PACG051T_CUSTOMER','PACG071T_CUSTOMER')
ORDER BY C.NAME,D.NAME

