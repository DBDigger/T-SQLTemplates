----------------------------------------------------------------------------------------------------------------
-- The sample scripts are not supported under any Microsoft standard support 
-- program or service. The sample scripts are provided AS IS without warranty  
-- of any kind. Microsoft further disclaims all implied warranties including,  
-- without limitation, any implied warranties of merchantability or of fitness for 
-- a particular purpose. The entire risk arising out of the use or performance of  
-- the sample scripts and documentation remains with you. In no event shall 
-- Microsoft, its authors, or anyone else involved in the creation, production, or 
-- delivery of the scripts be liable for any damages whatsoever (including, 
-- without limitation, damages for loss of business profits, business interruption, 
-- loss of business information, or other pecuniary loss) arising out of the use 
-- of or inability to use the sample scripts or documentation, even if Microsoft 
-- has been advised of the possibility of such damages 
-----------------------------------------------------------------------------------------------------------------
-- Check the cumulative I/O per database file and related information, such as latencies, read vs. write load or overall I/O usage.

SELECT f.database_id, DB_NAME(f.database_id) AS database_name, f.name AS logical_file_name, f.[file_id], f.type_desc, 
	CAST (CASE 
		-- Handle UNC paths (e.g. '\\fileserver\readonlydbs\dept_dw.ndf')
		WHEN LEFT (LTRIM (f.physical_name), 2) = '\\' 
			THEN LEFT (LTRIM (f.physical_name),CHARINDEX('\',LTRIM(f.physical_name),CHARINDEX('\',LTRIM(f.physical_name), 3) + 1) - 1)
			-- Handle local paths (e.g. 'C:\Program Files\...\master.mdf') 
			WHEN CHARINDEX('\', LTRIM(f.physical_name), 3) > 0 
			THEN UPPER(LEFT(LTRIM(f.physical_name), CHARINDEX ('\', LTRIM(f.physical_name), 3) - 1))
		ELSE f.physical_name
	END AS NVARCHAR(255)) AS logical_disk,
	fs.size_on_disk_bytes/1024/1024 AS size_on_disk_Mbytes,
	fs.num_of_reads, fs.num_of_writes,
	fs.num_of_bytes_read/1024/1024 AS num_of_Mbytes_read,
	fs.num_of_bytes_written/1024/1024 AS num_of_Mbytes_written,
	fs.io_stall/1000/60 AS io_stall_min, 
	fs.io_stall_read_ms/1000/60 AS io_stall_read_min, 
	fs.io_stall_write_ms/1000/60 AS io_stall_write_min,
	(fs.io_stall_read_ms / (1.0 + fs.num_of_reads)) AS avg_read_latency_ms,
	(fs.io_stall_write_ms / (1.0 + fs.num_of_writes)) AS avg_write_latency_ms,
	((fs.io_stall_read_ms/1000/60)*100)/(CASE WHEN fs.io_stall/1000/60 = 0 THEN 1 ELSE fs.io_stall/1000/60 END) AS io_stall_read_pct, 
	((fs.io_stall_write_ms/1000/60)*100)/(CASE WHEN fs.io_stall/1000/60 = 0 THEN 1 ELSE fs.io_stall/1000/60 END) AS io_stall_write_pct,
	ABS((sample_ms/1000)/60/60) AS 'sample_HH', 
	((fs.io_stall/1000/60)*100)/(ABS((sample_ms/1000)/60))AS 'io_stall_pct_of_overall_sample' --Number of milliseconds since the computer was started.
FROM sys.dm_io_virtual_file_stats (default, default) AS fs
INNER JOIN sys.master_files AS f ON fs.database_id = f.database_id AND fs.[file_id] = f.[file_id]
ORDER BY 18 DESC
GO


