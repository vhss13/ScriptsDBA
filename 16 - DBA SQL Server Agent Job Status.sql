SELECT DISTINCT
SUBSTRING(SYSJOBS.name, 1, 100) AS [Job Name] ,
SYSJOBSTEPS.step_name AS JobStep ,
SYSJOBSTEPS.command,
SYSCATEGORIES.name AS category ,
--SYSJOBS.description AS JobDescription ,
SYSJOBS.date_created AS CreateDate ,
'Enabled' = CASE WHEN SYSSCHEDULES.enabled = 0 THEN 'DISABLED'
WHEN SYSSCHEDULES.enabled = 1 THEN 'ENABLED'
END ,
-- substring(SYSSCHEDULES.name,1,30) AS [Name of the schedule],
'Job Frequency ' = CASE WHEN SYSSCHEDULES.freq_type = 1 THEN 'ONCE'
WHEN SYSSCHEDULES.freq_type = 4 THEN 'DAILY'
WHEN SYSSCHEDULES.freq_type = 8 THEN 'WEEKLY'
WHEN SYSSCHEDULES.freq_type = 16
THEN 'Monthly'
WHEN SYSSCHEDULES.freq_type = 32
THEN 'MONTHLY RELATIVE'
WHEN SYSSCHEDULES.freq_type = 32
THEN 'START AUTOMATICALLY WHEN SQL AGENT STARTS'
END ,
'Days jobs run' = CASE WHEN SYSSCHEDULES.[freq_interval] = 1
THEN ' SUNDAY'
WHEN SYSSCHEDULES.[freq_interval] = 2
THEN ' MONDAY'
WHEN SYSSCHEDULES.[freq_interval] = 3
THEN ' TUESDAY'
WHEN SYSSCHEDULES.[freq_interval] = 4
THEN ' WEDNESDAY'
WHEN SYSSCHEDULES.[freq_interval] = 5
THEN ' THURSDAY'
WHEN SYSSCHEDULES.[freq_interval] = 6
THEN ' FRIDAY'
WHEN SYSSCHEDULES.[freq_interval] = 7
THEN ' SATURDAY'
WHEN SYSSCHEDULES.[freq_interval] = 8
THEN ' DAILY'
WHEN SYSSCHEDULES.[freq_interval] = 9
THEN ' WEEKLY'
WHEN SYSSCHEDULES.[freq_interval] = 10
THEN 'WEEKEND'
WHEN SYSSCHEDULES.[freq_interval] = 62
THEN 'MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY'
WHEN SYSSCHEDULES.[freq_interval] = 64
THEN 'SATURDAY'
WHEN SYSSCHEDULES.[freq_interval] = 65
THEN 'SATURDAY, SUNDAY'
WHEN SYSSCHEDULES.[freq_interval] = 126
THEN 'MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY'
END ,
'INTERVAL TYPE' = CASE WHEN SYSSCHEDULES.freq_subday_type = 1
THEN 'At the specified time'
WHEN SYSSCHEDULES.freq_subday_type = 2
THEN 'Seconds'
WHEN SYSSCHEDULES.freq_subday_type = 4
THEN 'Minutes'
WHEN SYSSCHEDULES.freq_subday_type = 8
THEN 'Hours'
END ,
CAST(CAST(SYSSCHEDULES.active_start_date AS VARCHAR(15)) AS DATETIME) AS StartDate ,
CAST(CAST(SYSSCHEDULES.active_end_date AS VARCHAR(15)) AS DATETIME) AS EndDate ,
STUFF(STUFF(RIGHT('000000'
+ CAST(SYSJOBSCHEDULES.next_run_time AS VARCHAR), 6),
3, 0, ':'), 6, 0, ':') AS Run_Time
FROM    msdb..sysjobs SYSJOBS
INNER JOIN msdb..sysjobhistory SYSJOBHISTORY ON SYSJOBHISTORY.job_id = SYSJOBS.job_id
INNER JOIN msdb..sysJobschedules SYSJOBSCHEDULES ON SYSJOBSCHEDULES.job_id = SYSJOBS.job_id
INNER JOIN msdb..SysSchedules SYSSCHEDULES ON SYSSCHEDULES.Schedule_id = SYSJOBSCHEDULES.Schedule_id
INNER JOIN msdb..sysjobsteps SYSJOBSTEPS ON SYSJOBSTEPS.job_id = SYSJOBS.job_id
INNER JOIN msdb..syscategories SYSCATEGORIES ON SYSCATEGORIES.category_id = SYSJOBS.category_id