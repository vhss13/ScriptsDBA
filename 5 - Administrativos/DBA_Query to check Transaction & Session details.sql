select
st.session_id,
st.transaction_id,
db_name(sp.dbid) db_name,
case is_user_transaction
	when 0 then 'system transaction'
	when 1 then 'user transaction' 
end as user_or_system_transaction,
case is_local
	when 0 then 'distributed transaction'
	when 1 then 'local transaction' 
end as transaction_origin,
sp.hostname,
sp.loginame,
sp.status,
sp.lastwaittype,
sqlt.text
from
sys.dm_tran_session_transactions st
join sys.sysprocesses sp on sp.spid = st.session_id
cross apply sys.dm_exec_sql_text(sp.sql_handle) sqlt
