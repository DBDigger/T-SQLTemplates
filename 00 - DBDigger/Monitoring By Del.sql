-- Disk and file performance
SELECT db_name (a.database_id) AS [DatabaseName],
b.name AS [FileName],
a.File_ID AS [FileID],
CASE WHEN a.file_id = 2 THEN 'Log' ELSE 'Data' END AS [FileType],
a.Num_of_Reads AS [NumReads],
a.num_of_bytes_read AS [NumBytesRead],
a.io_stall_read_ms AS [IOStallReadsMS],
a.num_of_writes AS [NumWrites],
a.num_of_bytes_written AS [NumBytesWritten],
a.io_stall_write_ms AS [IOStallWritesMS],
a.io_stall [TotalIOStallMS],
DATEADD (ms, -a.sample_ms, GETDATE ()) [LastReset],
( (a.size_on_disk_bytes / 1024) / 1024.0) AS [SizeOnDiskMB],
UPPER (LEFT (b.physical_name, 2)) AS [DiskLocation]
FROM sys.dm_io_virtual_file_stats (NULL, NULL) a
JOIN sys.master_files b
ON a.file_id = b.file_id AND a.database_id = b.database_id
ORDER BY a.io_stall DESC



-- Top IO consumers
SELECT TOP 50
(total_logical_reads + total_logical_writes) AS total_logical_io,
(total_logical_reads / execution_count) AS avg_logical_reads,
(total_logical_writes / execution_count) AS avg_logical_writes,
(total_physical_reads / execution_count) AS avg_phys_reads,
substring (st.text,
(qs.statement_start_offset / 2) + 1,
((CASE qs.statement_end_offset WHEN -1
THEN datalength (st.text)
ELSE qs.statement_end_offset END
- qs.statement_start_offset)/ 2)+ 1)
AS statement_text,
plan_generation_num, execution_count, total_worker_time, last_worker_time, min_worker_time, max_worker_time, total_physical_reads, last_physical_reads, min_physical_reads, max_physical_reads, total_logical_writes, last_logical_writes, min_logical_writes, max_logical_writes,total_logical_reads,total_logical_reads, last_logical_reads, min_logical_reads, max_logical_reads,  total_elapsed_time,    last_elapsed_time, min_elapsed_time,  max_elapsed_time
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text (qs.sql_handle) AS st
ORDER BY total_logical_io DESC


-- Top CPU consumers
SELECT TOP 50
qs.total_worker_time / execution_count AS avg_worker_time,
substring (st.text, (qs.statement_start_offset / 2) + 1,
( ( CASE qs.statement_end_offset WHEN -1
THEN datalength (st.text)
ELSE qs.statement_end_offset END
- qs.statement_start_offset)/ 2)+ 1)
AS statement_text,
plan_generation_num, execution_count, total_worker_time, last_worker_time, min_worker_time, max_worker_time, total_physical_reads, last_physical_reads, min_physical_reads, max_physical_reads, total_logical_writes, last_logical_writes, min_logical_writes, max_logical_writes,total_logical_reads,total_logical_reads, last_logical_reads, min_logical_reads, max_logical_reads,  total_elapsed_time,    last_elapsed_time, min_elapsed_time,  max_elapsed_time
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text (qs.sql_handle) AS st
ORDER BY
avg_worker_time DESC
