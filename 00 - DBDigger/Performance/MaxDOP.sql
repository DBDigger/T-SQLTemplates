SELECT max_workers_count FROM sys.dm_os_sys_info
select COUNT(*) from sys.dm_os_workers
--select 512 + ((16 - 4) * 16)

select * from sys.dm_os_schedulers where is_idle = 1


SELECT SUM(current_workers_count) as [Current worker thread] FROM sys.dm_os_schedulers

SELECT AVG(current_tasks_count) AS [Avg Current Task], 
AVG(runnable_tasks_count) AS [Avg Wait Task]
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255
AND status = 'VISIBLE ONLINE'

SELECT COUNT(*) AS proc# 
FROM sys.dm_os_schedulers 
WHERE status = 'VISIBLE ONLINE' 
AND is_online = 1


SELECT s2.text, session_id,start_time,status, cpu_time, blocking_session_id, wait_type,wait_time, wait_resource, open_transaction_count
FROM sys.dm_exec_requests a CROSS APPLY sys.dm_exec_sql_text(a.sql_handle) AS s2  
WHERE status <> 'background'


SELECT 
a.scheduler_id ,
b.session_id,
 (SELECT TOP 1 SUBSTRING(s2.text,statement_start_offset / 2+1 , 
      ( (CASE WHEN statement_end_offset = -1 
         THEN (LEN(CONVERT(nvarchar(max),s2.text)) * 2) 
         ELSE statement_end_offset END)  - statement_start_offset) / 2+1))  AS sql_statement
FROM sys.dm_os_schedulers a 
INNER JOIN sys.dm_os_tasks b on a.active_worker_address = b.worker_address
INNER JOIN sys.dm_exec_requests c on b.task_address = c.task_address
CROSS APPLY sys.dm_exec_sql_text(c.sql_handle) AS s2 