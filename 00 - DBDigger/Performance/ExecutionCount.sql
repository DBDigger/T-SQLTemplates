SELECT
    OBJECT_NAME(qt.objectid)
  , qs.execution_count AS [Execution Count]
  
FROM
    sys.dm_exec_query_stats AS qs
CROSS APPLY 
    sys.dm_exec_sql_text(qs.[sql_handle]) AS qt
WHERE
    qt.[dbid] = DB_ID()
	order by [Execution Count] desc
OPTION (RECOMPILE);

SELECT
    OBJECT_NAME(qt.objectid)
  , qs.execution_count AS [Execution Count]
  , qs.execution_count / DATEDIFF(Second, qs.creation_time, GETDATE()) AS [Calls/Second]
  , qs.total_worker_time / qs.execution_count AS [AvgWorkerTime]
  , qs.total_worker_time AS [TotalWorkerTime]
  , qs.total_elapsed_time / qs.execution_count AS [AvgElapsedTime]
  , qs.max_logical_reads
  , qs.max_logical_writes
  , qs.total_physical_reads
  , DATEDIFF(Minute, qs.creation_time, GETDATE()) AS [Age in Cache]
FROM
    sys.dm_exec_query_stats AS qs
CROSS APPLY 
    sys.dm_exec_sql_text(qs.[sql_handle]) AS qt
WHERE
    qt.[dbid] = DB_ID()
AND qt.objectid = OBJECT_ID('SFTPFileExistsCheck_get')
OPTION (RECOMPILE);