-- List expensive queries 
DECLARE @MinExecutions int; 
SET @MinExecutions = 5 
 
SELECT EQS.total_worker_time AS TotalWorkerTime 
      ,EQS.total_logical_reads + EQS.total_logical_writes AS TotalLogicalIO 
      ,EQS.execution_count As ExeCnt 
      ,EQS.last_execution_time AS LastUsage 
      ,EQS.total_worker_time / EQS.execution_count as AvgCPUTimeMiS 
      ,(EQS.total_logical_reads + EQS.total_logical_writes) / EQS.execution_count  
       AS AvgLogicalIO 
      ,DB.name AS DatabaseName 
      ,SUBSTRING(EST.text 
                ,1 + EQS.statement_start_offset / 2 
                ,(CASE WHEN EQS.statement_end_offset = -1  
                       THEN LEN(convert(nvarchar(max), EST.text)) * 2  
                       ELSE EQS.statement_end_offset END  
                 - EQS.statement_start_offset) / 2 
                ) AS SqlStatement 
      -- Optional with Query plan; remove comment to show, but then the query takes !!much longer time!! 
      --,EQP.[query_plan] AS [QueryPlan] 
FROM sys.dm_exec_query_stats AS EQS 
     CROSS APPLY sys.dm_exec_sql_text(EQS.sql_handle) AS EST 
     CROSS APPLY sys.dm_exec_query_plan(EQS.plan_handle) AS EQP 
     LEFT JOIN sys.databases AS DB 
         ON EST.dbid = DB.database_id      
WHERE EQS.execution_count > @MinExecutions 
      AND EQS.last_execution_time > DATEDIFF(MONTH, -1, GETDATE()) 
ORDER BY --AvgLogicalIo DESC 
        AvgCPUTimeMiS DESC


-- Top CPU consumers
SELECT TOP 50 qs.total_worker_time / execution_count AS avg_worker_time,
substring(st.text,(qs.statement_start_offset / 2) + 1, ((CASE qs.statement_end_offset
WHEN -1 THEN datalength(st.text)
ELSE qs.statement_end_offset
END -
qs.statement_start_offset) / 2) + 1)
AS statement_text,
last_execution_time,execution_count,--total_worker_time,last_worker_time,min_worker_time,max_worker_time,
--total_physical_reads,last_physical_reads,min_physical_reads,max_physical_reads,total_logical_writes,
--last_logical_writes,min_logical_writes,max_logical_writes,total_logical_reads,last_logical_reads,
--min_logical_reads,max_logical_reads,
total_rows,last_rows,min_rows,max_rows
FROM
sys.dm_exec_query_stats AS qs
CROSS APPLY
sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY
avg_worker_time DESC


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