-- Calculates average stalls per read, per write, and per total input/output
-- for each database file. 
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
where db_name (a.database_id) = 'wmpoperatorusage'
ORDER BY a.io_stall DESC



-- Get IO Stalls
SELECT a.io_stall, a.io_stall_read_ms, a.io_stall_write_ms, a.num_of_reads,
a.num_of_writes,
--a.sample_ms, a.num_of_bytes_read, a.num_of_bytes_written, a.io_stall_write_ms,
( ( a.size_on_disk_bytes / 1024 ) / 1024.0 ) AS size_on_disk_mb,
db_name(a.database_id) AS dbname,
b.name, a.file_id,
db_file_type = CASE
                   WHEN a.file_id = 2 THEN 'Log'
                   ELSE 'Data'
                   END,
UPPER(SUBSTRING(b.physical_name, 1, 2)) AS disk_location
FROM sys.dm_io_virtual_file_stats (NULL, NULL) a
JOIN sys.master_files b ON a.file_id = b.file_id
AND a.database_id = b.database_id
ORDER BY a.io_stall DESC 






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