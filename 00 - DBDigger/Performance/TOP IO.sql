-- Top Io comsumers
SELECT TOP 50 
(total_logical_reads + total_logical_writes) AS total_logical_io,
(total_logical_reads / execution_count) AS avg_logical_reads,
(total_logical_writes / execution_count) AS avg_logical_writes,
(total_physical_reads / execution_count) AS avg_phys_reads,
substring(
st.text,
(qs.statement_start_offset / 2) + 1,
((CASE qs.statement_end_offset
WHEN -1 THEN datalength(st.text)
ELSE qs.statement_end_offset
END -
qs.statement_start_offset) / 2) + 1)
AS statement_text,
last_execution_time,execution_count,total_worker_time,last_worker_time,min_worker_time,max_worker_time,
total_physical_reads,last_physical_reads,min_physical_reads,max_physical_reads,total_logical_writes,
last_logical_writes,min_logical_writes,max_logical_writes,total_logical_reads,last_logical_reads,
min_logical_reads,max_logical_reads,
total_rows,last_rows,min_rows,max_rows
FROM
sys.dm_exec_query_stats AS qs
CROSS APPLY
sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY
total_logical_io DESC