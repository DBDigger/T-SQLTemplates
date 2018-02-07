-- Top 20 CPU consumers
SELECT TOP 20
	qs.sql_handle,
	qs.execution_count,
	qs.total_worker_time AS Total_CPU,
	total_CPU_inSeconds = --Converted from microseconds
	qs.total_worker_time/1000000,
	average_CPU_inSeconds = --Converted from microseconds
	(qs.total_worker_time/1000000) / qs.execution_count,
	qs.total_elapsed_time,
	total_elapsed_time_inSeconds = --Converted from microseconds
	qs.total_elapsed_time/1000000,
	st.text,
	qp.query_plan
FROM
	sys.dm_exec_query_stats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
		CROSS apply sys.dm_exec_query_plan (qs.plan_handle) AS qp
ORDER BY qs.total_worker_time DESC



-- CPU utilization history from cache
SELECT SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
((CASE qs.statement_end_offset
WHEN -1 THEN DATALENGTH(qt.TEXT)
ELSE qs.statement_end_offset
END - qs.statement_start_offset)/2)+1),
qs.execution_count,
qs.total_logical_reads, qs.last_logical_reads,
qs.total_logical_writes, qs.last_logical_writes,
qs.total_worker_time,
qs.last_worker_time,
qs.total_elapsed_time/1000000 total_elapsed_time_in_S,
qs.last_elapsed_time/1000000 last_elapsed_time_in_S,
qs.last_execution_time,
qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.total_worker_time DESC -- CPU time



DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info); 

SELECT top 2000 SQLProcessUtilization AS [SQLServerProcessCPUUtilization], 
               SystemIdle AS [SystemIdleProcess], 
               100 - SystemIdle - SQLProcessUtilization AS [OtherProcessCPUUtilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [EventTime] 
FROM ( 
      SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
            record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
            AS [SystemIdle], 
            record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
            'int') 
            AS [SQLProcessUtilization], [timestamp] 
      FROM ( 
            SELECT [timestamp], CONVERT(xml, record) AS [record] 
            FROM sys.dm_os_ring_buffers 
            WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
            AND record LIKE '%<SystemHealth>%') AS x 
      ) AS y 
ORDER BY SQLProcessUtilization DESC;





SELECT total_worker_time/execution_count AS AvgCPU  
, total_elapsed_time/execution_count AS AvgDuration  
, (total_logical_reads+total_physical_reads)/execution_count AS AvgReads 
, execution_count   
, SUBSTRING(st.TEXT, 1,500) AS txt  
FROM sys.dm_exec_query_stats AS qs  
cross apply sys.dm_exec_sql_text(qs.sql_handle) AS st  
where st.text like '%EIMAsyncResponseLog_TMUS%'