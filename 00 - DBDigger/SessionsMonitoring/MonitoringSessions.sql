-- Script 1
-- Get a count of SQL connections by IP address
SELECT  ec.client_net_address ,
        es.[program_name] ,
        es.[host_name] ,
        es.login_name ,
        COUNT(ec.session_id) AS [connection count]
FROM    sys.dm_exec_sessions AS es
        INNER JOIN sys.dm_exec_connections AS ec
                                   ON es.session_id = ec.session_id
GROUP BY ec.client_net_address ,
        es.[program_name] ,
        es.[host_name] ,
        es.login_name
ORDER BY ec.client_net_address ,
        es.[program_name] ;


-- Script 2
--  Get SQL users that are connected and how many sessions they have 
SELECT  login_name ,
        COUNT(session_id) AS [session_count]
FROM    sys.dm_exec_sessions
GROUP BY login_name
ORDER BY COUNT(session_id) DESC ;


-- Monitoring transaction activity
SELECT  st.session_id ,
        DB_NAME(dt.database_id) AS database_name ,
        CASE WHEN dt.database_transaction_begin_time IS NULL THEN 'read-only'
             ELSE 'read-write'
        END AS transaction_state ,
        dt.database_transaction_begin_time AS read_write_start_time ,
        dt.database_transaction_log_record_count ,
        dt.database_transaction_log_bytes_used
FROM    sys.dm_tran_session_transactions AS st
        INNER JOIN sys.dm_tran_database_transactions AS dt
            ON st.transaction_id = dt.transaction_id
ORDER BY st.session_id ,
        database_name
        
        
 -- Look at active Lock Manager resources for current database
SELECT  request_session_id ,
        DB_NAME(resource_database_id) AS [Database] ,
        resource_type ,
        resource_subtype ,
        request_type ,
        request_mode ,
        resource_description ,
        request_mode ,
        request_owner_type
FROM    sys.dm_tran_locks
WHERE   request_session_id > 50
        AND resource_database_id = DB_ID()
        AND request_session_id <> @@SPID
ORDER BY request_session_id ;



-- Find long running SQL/CLR tasks
SELECT  os.task_address ,
        os.[state] ,
        os.last_wait_type ,
        clr.[state] ,
        clr.forced_yield_count
FROM    sys.dm_os_workers AS os
        INNER JOIN sys.dm_clr_tasks AS clr
                     ON ( os.task_address = clr.sos_task_address )
WHERE   clr.[type] = 'E_TYPE_USER' ;


-- Details of processes on server
SELECT spid AS SQLServerProcess, blocked AS BlockedBy, waittime AS WaitTimeInMS, lastwaittype AS LastWaitType, waitresource AS WaitResource, db_Name(dbid) AS SubjectDB, uid AS UserID, cpu AS ComulCPUTime, physical_io AS [ComulDskR-W], memusage AS PagesInProcCache, login_time AS LoggedToServerAt, last_batch AS LastExecutionAt, ecid AS ExeContextID, STATUS, HostName, program_name AS ProgramName, cmd
FROM sys.sysprocesses


-- Details of sessions
SELECT session_id, login_time AS SessionEstablishedAT, host_name AS HostName, STATUS, cpu_time CPUTimeMS, memory_usage KB8PagesUsed, total_scheduled_time SchTimeMS, total_elapsed_time ElapTimeMS, reads PhysicalReads, writes PhysicalWrites, logical_reads, is_user_process, row_count AS RowsReturned
FROM sys.dm_exec_sessions


select session_id, start_time, status, command, db_name(database_id) as SubjectDB, user_name(user_id) as UserName,  blocking_session_id, wait_type, wait_time, last_wait_type, wait_resource, open_transaction_count, open_resultset_count, transaction_id,estimated_completion_time, cpu_time, total_elapsed_time, scheduler_id,  reads, writes, logical_reads
from sys.dm_exec_requests

--------------------------------------------------------------------------------------
-- Troubleshoot high CPU resource utilizer
SELECT spid AS SQLServerProcess, blocked AS BlockedBy, waittime AS WaitTimeInMS, lastwaittype AS LastWaitType, waitresource AS WaitResource, db_Name(dbid) AS SubjectDB, uid AS UserID, cpu AS ComulCPUTime, physical_io AS [ComulDskR-W], memusage AS PagesInProcCache, login_time AS LoggedToServerAt, last_batch AS LastExecutionAt, ecid AS ExeContextID, STATUS, HostName, program_name AS ProgramName, cmd
FROM master..sysprocesses WHERE status = 'runnable' ORDER BY cpu desc

DECLARE @handle binary(20)
SELECT @handle = sql_handle FROM master..sysprocesses WHERE spid = 53
SELECT [text] FROM ::fn_get_sql(@handle)

------------------------------------------------