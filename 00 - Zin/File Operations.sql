-- get data file space and locations
SELECT b.groupname AS 'File Group'
	,a.NAME
	,physical_name
	,CONVERT(INT, a.Size / 128.000, 2) AS [Currently Allocated Space (MB)]
	,CONVERT(INT, FILEPROPERTY(a.NAME, 'SpaceUsed') / 128.000, 2) AS [Space Used (MB)]
	,CONVERT(INT, a.max_Size / 128.000, 2) [Maximum Space (MB)]
	,CASE 
		WHEN a.IS_PERCENT_GROWTH = 0
			THEN CONVERT(VARCHAR, CONVERT(DECIMAL(15, 2), ROUND(a.growth / 128.000, 2))) + ' MB'
		ELSE CONVERT(VARCHAR, a.growth) + ' PERCENT'
		END [Growth]
	,CONVERT(INT, (a.Size - FILEPROPERTY(a.NAME, 'SpaceUsed')) / 128.000, 2) AS [Available Space (MB)]
	,(CONVERT(INT, ROUND((a.Size - FILEPROPERTY(a.NAME, 'SpaceUsed')) / 128.000, 2)) * 100) / (CONVERT(INT, ROUND(a.Size / 128.000, 2))) AS PercentFree
FROM sys.database_files a(NOLOCK)
LEFT OUTER JOIN sysfilegroups b(NOLOCK) ON a.data_space_id = b.groupid
ORDER BY PercentFree

-- Increase file max size
USE [master]
GO
ALTER DATABASE [wmpoperatorusage] MODIFY FILE ( NAME = N'wmpoperatorusage_log2', maxsIZE = 150000MB)
GO

-- Increase file size
USE [master]
GO
ALTER DATABASE [wmpoperatorusage] MODIFY FILE ( NAME = N'wmpoperatorusage_log2', sIZE = 150000MB)
GO


-- Empty a file
DBCC SHRINKFILE (N'wmpoperatourusage_log3' , EMPTYFILE)
GO

-- Remove a file from DB
ALTER DATABASE [wmpoperatorusage_nsisUAT_Package]  REMOVE FILE wmpoperatourusage_log3
GO

-- Change max size
USE [master]
GO
ALTER DATABASE [Billing] MODIFY FILE ( NAME = N'Billing', MAXSIZE = 2048000KB )
GO

-- Shrink Ops
USE [ITS_DB_ss]
GO

DBCC SHRINKFILE (N'ITS_DB_ss_log' , 200)
GO

DBCC SHRINKFILE (N'ITS_DB_ss_log' , 0, TRUNCATEONLY)
GO

-- Change autogrow
USE [master]
GO
ALTER DATABASE [DBDigger_Subsc] MODIFY FILE ( NAME = N'DBDigger_Subsc_log', FILEGROWTH = 10240KB )
GO

-- Create file group
USE [master];
ALTER DATABASE [wmp] ADD FILEGROUP [FG_CDC_E]
GO

-- Add file to file group
ALTER DATABASE [wmp] ADD FILE ( NAME = N'CDC_E2', FILENAME = N'J:\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\CDC_E2.ndf' , SIZE = 10240000KB , FILEGROWTH = 1024000KB ) TO FILEGROUP [FG_CDC_E]
GO


SELECT
    db.name AS DBName,
    type_desc AS FileType,
    Physical_Name AS Location
FROM
    sys.master_files mf
INNER JOIN 


    sys.databases db ON db.database_id = mf.database_id

--Calculated Disk Latency for your different database drives
SELECT  LEFT(physical_name, 1) AS drive,
        CAST(SUM(io_stall_read_ms) / 
            (1.0 + SUM(num_of_reads)) AS NUMERIC(10,1)) 
                          AS 'avg_read_disk_latency_ms',
        CAST(SUM(io_stall_write_ms) / 
            (1.0 + SUM(num_of_writes) ) AS NUMERIC(10,1)) 
                          AS 'avg_write_disk_latency_ms',
        CAST((SUM(io_stall)) / 
            (1.0 + SUM(num_of_reads + num_of_writes)) AS NUMERIC(10,1)) 
                          AS 'avg_disk_latency_ms'
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs
        JOIN sys.master_files AS mf ON mf.database_id = divfs.database_id
                                       AND mf.file_id = divfs.file_id
GROUP BY LEFT(physical_name, 1)
ORDER BY avg_disk_latency_ms DESC;



--Displaying I/O statistics by physical drive letter
SELECT left(f.physical_name, 1) AS DriveLetter, 
	DATEADD(MS,sample_ms * -1, GETDATE()) AS [Start Date],
	SUM(v.num_of_writes) AS total_num_of_writes, 
	SUM(v.num_of_bytes_written) AS total_num_of_bytes_written, 
	SUM(v.num_of_reads) AS total_num_of_reads, 
	SUM(v.num_of_bytes_read) AS total_num_of_bytes_read, 
	SUM(v.size_on_disk_bytes) AS total_size_on_disk_bytes
FROM sys.master_files f
INNER JOIN sys.dm_io_virtual_file_stats(NULL, NULL) v
ON f.database_id=v.database_id and f.file_id=v.file_id


GROUP BY left(f.physical_name, 1),DATEADD(MS,sample_ms * -1, GETDATE());
--amount of I/O performed by each database in the last 5 minutes

DECLARE @Sample TABLE (
  DBName varchar(128) 
 ,NumberOfReads bigint
 ,NumberOfWrites bigint)

INSERT INTO @Sample 
SELECT name AS 'DBName'
      ,SUM(num_of_reads) AS 'NumberOfRead'
      ,SUM(num_of_writes) AS 'NumberOfWrites' 
FROM sys.dm_io_virtual_file_stats(NULL, NULL) I
  INNER JOIN sys.databases D  
      ON I.database_id = d.database_id
GROUP BY name 

WAITFOR DELAY '00:05:00.000';

SELECT FirstSample.DBName
      ,(SecondSample.NumberOfReads - FirstSample.NumberOfReads) AS 'Number of Reads'
      ,(SecondSample.NumberOfWrites - FirstSample.NumberOfWrites) AS 'Number of Writes'
FROM 
(SELECT * FROM @Sample) FirstSample
INNER JOIN
(SELECT name AS 'DBName'
      ,SUM(num_of_reads) AS 'NumberOfReads'
      ,SUM(num_of_writes) AS 'NumberOfWrites' 
FROM sys.dm_io_virtual_file_stats(NULL, NULL) I
  INNER JOIN sys.databases D  
      ON I.database_id = d.database_id
GROUP BY name) AS SecondSample
ON FirstSample.DBName = SecondSample.DBName
ORDER BY 'Number of Reads' DESC;



-- total I/O for each database
SELECT name AS 'Database Name'
      ,SUM(num_of_reads) AS 'Number of Read'
      ,SUM(num_of_writes) AS 'Number of Writes' 
FROM sys.dm_io_virtual_file_stats(NULL, NULL) I
  INNER JOIN sys.databases D  
      ON I.database_id = d.database_id
GROUP BY name ORDER BY 'Number of Read' DESC;


-- IO stalls with volatile data
SELECT 
cast(DB_Name(a.database_id) as varchar) as Database_name,
b.physical_name, * 
FROM  
sys.dm_io_virtual_file_stats(null, null) a 
INNER JOIN sys.master_files b ON a.database_id = b.database_id and a.file_id = b.file_id
ORDER BY Database_Name

-- Get usage by file
select database_id, 
       file_id, 
       io_stall,
       io_pending_ms_ticks,
       scheduler_address 
from sys.dm_io_virtual_file_stats(NULL, NULL) iovfs,
     sys.dm_io_pending_io_requests as iopior
where iovfs.file_handle = iopior.io_handle


--Display the Top 25 Most expensive read I/O queries

SELECT TOP 25 cp.usecounts AS [execution_count]
      ,qs.total_worker_time AS CPU
      ,qs.total_elapsed_time AS ELAPSED_TIME
      ,qs.total_logical_reads AS LOGICAL_READS
      ,qs.total_logical_writes AS LOGICAL_WRITES
      ,qs.total_physical_reads AS PHYSICAL_READS 
      ,SUBSTRING(text, 
                   CASE WHEN statement_start_offset = 0 
                          OR statement_start_offset IS NULL  
                           THEN 1  
                           ELSE statement_start_offset/2 + 1 END, 
                   CASE WHEN statement_end_offset = 0 
                          OR statement_end_offset = -1  
                          OR statement_end_offset IS NULL  
                           THEN LEN(text)  
                           ELSE statement_end_offset/2 END - 
                     CASE WHEN statement_start_offset = 0 
                            OR statement_start_offset IS NULL 
                             THEN 1  
                             ELSE statement_start_offset/2  END + 1 
                  )  AS [Statement]        
FROM sys.dm_exec_query_stats qs  
   join sys.dm_exec_cached_plans cp on qs.plan_handle = cp.plan_handle 
   CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
ORDER BY qs.total_logical_reads DESC;