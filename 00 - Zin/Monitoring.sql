select COUNT(*) as IOPending from sys.dm_io_pending_io_requests 
where io_type = 'disk' and io_pending_ms_ticks > 20

 --EXEC sp_serveroption 'WYLN0-CLUDB02\CLUDB02', 'DATA ACCESS', TRUE
  
SELECT name, enabled, category, current_execution_step, has_schedule
FROM OPENQUERY ([WYLN0-CLUDB02\CLUDB02], 
  'msdb..sp_help_job @execution_status =  1'); 
  
  
-- Percent complete
SELECT 
percent_complete
,command
,session_id
,start_time 
,getdate() as 'Time Now' 
,DATEDIFF(mi, start_time, getdate()) as 'Duration (Mins)'
,    (((100/percent_complete)*DATEDIFF(mi, start_time, getdate()))
    -DATEDIFF(mi, start_time, getdate()))/60 as 'Hours Remaining' 
,t.text
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE percent_complete > 0



-- Get sessions info 
SELECT 
DB_NAME(req.database_id) as [Database],
sqltext.TEXT,
req.session_id,
s.login_time,
req.status,
req.command,
req.cpu_time,
req.total_elapsed_time,
s.login_name, s.last_request_start_time,
req.reads, req.writes
FROM sys.dm_exec_requests req
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
left join sys.dm_exec_sessions s on s.session_id = req.session_id
inner join sys.databases d on d.database_id = req.database_id
where req.session_id > 50


sp_help_job 
@job_name =  'job_name'  
 ,  @owner_login_name =  'login_name' 
 , @enabled =  1
 , @execution_status =  1
 , @date_created =  date_created 
 , @date_last_modified =  date_modified 


 -- Get long running queries
 SELECT TOP 100
    qs.total_elapsed_time / qs.execution_count / 1000000.0 AS average_seconds,
    qs.total_elapsed_time / 1000000.0 AS total_seconds,
    qs.execution_count,
    SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) AS individual_query,
    o.name AS object_name,
    DB_NAME(qt.dbid) AS database_name
  FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
    LEFT OUTER JOIN sys.objects o ON qt.objectid = o.object_id
where qt.dbid = DB_ID()
  ORDER BY average_seconds DESC;



  -- Finding the Queries Running Frequently
DECLARE @MinCount BIGINT ;
SET @MinCount = 5000;
SELECT st.[text], qs.execution_count
FROM sys .dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text( qs.sql_handle ) AS st
WHERE qs.execution_count > @MinCount
ORDER BY qs.execution_count DESC;


-- Looking at Total Elapsed Time
DECLARE @MinCount BIGINT ;
SET @MinCount = 5000;
SELECT st.[text], qs.execution_count, qs.total_elapsed_time
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text( qs.sql_handle ) AS st
WHERE qs.execution_count > @MinCount
ORDER BY qs.total_elapsed_time DESC;


-- get table rows
Select OBJECT_NAME(object_id) As TBName,
    SUM(rows) As TotalRows
From sys.partitions
Where index_id In (0, 1)
Group By object_id
Order By TotalRows desc;