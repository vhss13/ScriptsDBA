/* Return Active/Open connections per database. */ 
   SELECT
      DB_NAME(dbid) [Database],
      hostname [Host],
      d.client_net_address [IPaddress],
      loginame [Login],
      COUNT(dbid) [NoOfConnections]
   FROM
      sys.sysprocesses s INNER JOIN sys.dm_exec_connections d
        ON s.spid = d.session_id
   WHERE
      d.session_id >= 51 -- << user sessions are >= 51
      and hostname='GALVATRON' or hostname='INDIANA'
   GROUP BY
      s.dbid,
      s.hostname, 
      d.client_net_address,
      s.loginame
      order by hostname

