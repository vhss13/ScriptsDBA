RESTORE DATABASE KOGA
   FROM DISK = 'D:\Program Files\Microsoft SQL Server\MSSQL$KOGA_TEST\BACKUP\Full\BkF200706210030KOGA'
   WITH NORECOVERY
RESTORE LOG KOGA
   FROM DISK = 'D:\Program Files\Microsoft SQL Server\MSSQL$KOGA_TEST\BACKUP\Log\BkL200706210300KOGA'
   WITH NORECOVERY
RESTORE LOG KOGA
   FROM DISK = 'D:\Program Files\Microsoft SQL Server\MSSQL$KOGA_TEST\BACKUP\Log\BkL200706210600KOGA'
   WITH NORECOVERY
RESTORE LOG KOGA
   FROM DISK = 'D:\Program Files\Microsoft SQL Server\MSSQL$KOGA_TEST\BACKUP\Log\BkL200706210900KOGA'
   WITH NORECOVERY
RESTORE LOG KOGA
   FROM DISK = 'D:\Program Files\Microsoft SQL Server\MSSQL$KOGA_TEST\BACKUP\Log\BkL200706211200KOGA'
   WITH RECOVERY, STOPAT = 'Jul 1, 1998 10:00 AM'