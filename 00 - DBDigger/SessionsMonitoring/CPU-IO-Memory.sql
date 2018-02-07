-- Hardware information from SQL Server 2008 
-- (Cannot distinguish between HT and multi-core)
SELECT  cpu_count AS [Logical CPU Count] ,
        hyperthread_ratio AS [Hyperthread Ratio] ,
        cpu_count / hyperthread_ratio AS [Physical CPU Count] ,
        physical_memory_in_bytes / 1048576 AS [Physical Memory (MB)] ,
        sqlserver_start_time
FROM    sys.dm_os_sys_info ;


-- Top Cached SPs By Total Logical Reads (SQL 2008 only).
-- Logical reads relate to memory pressure
SELECT TOP ( 25 )
        p.name AS [SP Name] ,
        qs.total_logical_reads AS [TotalLogicalReads] ,
        qs.total_logical_reads / qs.execution_count AS [AvgLogicalReads] ,
        qs.execution_count ,
        ISNULL(qs.execution_count / 
                 DATEDIFF(Second, qs.cached_time, GETDATE()),
               0) AS [Calls/Second] ,
        qs.total_elapsed_time ,
        qs.total_elapsed_time / qs.execution_count AS [avg_elapsed_time] ,
        qs.cached_time
FROM    sys.procedures AS p
        INNER JOIN sys.dm_exec_procedure_stats AS qs
                              ON p.[object_id] = qs.[object_id]
WHERE   qs.database_id = DB_ID()
ORDER BY qs.total_logical_reads DESC ;


-- Top Cached SPs By Total Physical Reads (SQL 2008 only) 
-- Physical reads relate to disk I/O pressure
SELECT TOP ( 25 )
        p.name AS [SP Name] ,
        qs.total_physical_reads AS [TotalPhysicalReads] ,
        qs.total_physical_reads / qs.execution_count AS [AvgPhysicalReads] ,
        qs.execution_count ,
        ISNULL(qs.execution_count / 
                 DATEDIFF(Second, qs.cached_time, GETDATE()),
               0) AS [Calls/Second] ,
        qs.total_elapsed_time ,
        qs.total_elapsed_time / qs.execution_count AS [avg_elapsed_time] ,
        qs.cached_time
FROM    sys.procedures AS p
        INNER JOIN sys.dm_exec_procedure_stats AS qs
                              ON p.[object_id] = qs.[object_id]
WHERE   qs.database_id = DB_ID()
ORDER BY qs.total_physical_reads DESC ;

-- Shows the memory required by both running (non-null grant_time) 
-- and waiting queries (null grant_time)
-- SQL Server 2008 version
SELECT  DB_NAME(st.dbid) AS [DatabaseName] ,
        mg.requested_memory_kb ,
        mg.ideal_memory_kb ,
        mg.request_time ,
        mg.grant_time ,
        mg.query_cost ,
        mg.dop ,
        st.[text]
FROM    sys.dm_exec_query_memory_grants AS mg
        CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE   mg.request_time < COALESCE(grant_time, '99991231')
ORDER BY mg.requested_memory_kb DESC ;


-- Calculates average stalls per read, per write, and per total input/output
-- for each database file. 
SELECT  DB_NAME(database_id) AS [Database Name] ,
        file_id ,
        io_stall_read_ms ,
        num_of_reads ,
        CAST(io_stall_read_ms / ( 1.0 + num_of_reads ) AS NUMERIC(10, 1))
            AS [avg_read_stall_ms] ,
        io_stall_write_ms ,
        num_of_writes ,
        CAST(io_stall_write_ms / ( 1.0 + num_of_writes ) AS NUMERIC(10, 1))
            AS [avg_write_stall_ms] ,
        io_stall_read_ms + io_stall_write_ms AS [io_stalls] ,
        num_of_reads + num_of_writes AS [total_io] ,
        CAST(( io_stall_read_ms + io_stall_write_ms ) / ( 1.0 + num_of_reads
                                                          + num_of_writes)
           AS NUMERIC(10,1)) AS [avg_io_stall_ms]
FROM    sys.dm_io_virtual_file_stats(NULL, NULL)
ORDER BY avg_io_stall_ms DESC ;


-- Look at pending I/O requests by file
SELECT  DB_NAME(mf.database_id) AS [Database] ,
        mf.physical_name ,
        r.io_pending ,
        r.io_pending_ms_ticks ,
        r.io_type ,
        fs.num_of_reads ,
        fs.num_of_writes
FROM    sys.dm_io_pending_io_requests AS r
        INNER JOIN sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
                                          ON r.io_handle = fs.file_handle
        INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
                                             AND fs.file_id = mf.file_id
ORDER BY r.io_pending ,
        r.io_pending_ms_ticks DESC ;


-- Get CPU Utilization History for last 30 minutes (in one minute intervals)
-- This version works with SQL Server 2008 and SQL Server 2008 R2 only
DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info); 

SELECT TOP(30) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               SystemIdle AS [System Idle Process], 
               100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
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
			AND record LIKE N'%<SystemHealth>%') AS x 
	  ) AS y 
ORDER BY record_id DESC;



-- Get Avg task count and Avg runnable task count
SELECT  AVG(current_tasks_count) AS [Avg Task Count] ,
        AVG(runnable_tasks_count) AS [Avg Runnable Task Count]
FROM    sys.dm_os_schedulers
WHERE   scheduler_id < 255
        AND [status] = 'VISIBLE ONLINE' ;
        
        
-- Script 26
-- Is NUMA enabled
SELECT  CASE COUNT(DISTINCT parent_node_id)
          WHEN 1 THEN 'NUMA disabled'
          ELSE 'NUMA enabled'
        END
FROM    sys.dm_os_schedulers
WHERE   parent_node_id <> 32 ;


-- Script 27
-- Good basic information about memory amounts and state
-- SQL Server 2008 and 2008 R2 only
SELECT  total_physical_memory_kb ,
        available_physical_memory_kb ,
        total_page_file_kb ,
        available_page_file_kb ,
        system_memory_state_desc
FROM    sys.dm_os_sys_memory ;


-- Script 28
-- SQL Server Process Address space info (SQL 2008 and 2008 R2 only)
--(shows whether locked pages is enabled, among other things)
SELECT  physical_memory_in_use_kb ,
        locked_page_allocations_kb ,
        page_fault_count ,
        memory_utilization_percentage ,
        available_commit_limit_kb ,
        process_physical_memory_low ,
        process_virtual_memory_low
FROM    sys.dm_os_process_memory ;