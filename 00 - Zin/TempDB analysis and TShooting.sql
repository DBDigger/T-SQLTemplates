-- Check tempDB performance
SELECT files.physical_name, files.name, 
	stats.num_of_writes, (1.0 * stats.io_stall_write_ms / stats.num_of_writes) AS avg_write_stall_ms,
	stats.num_of_reads, (1.0 * stats.io_stall_read_ms / stats.num_of_reads) AS avg_read_stall_ms
FROM sys.dm_io_virtual_file_stats(2, NULL) as stats
INNER JOIN master.sys.master_files AS files 
	ON stats.database_id = files.database_id
	AND stats.file_id = files.file_id
WHERE files.type_desc = 'ROWS'

USE TempDB
GO

-- identify the sessions that are utilizing most of your TempDB
SELECT session_id,(user_objects_alloc_page_count*8/1024) AS SpaceUsedByTheSessionMB,* 
FROM	sys.dm_db_session_space_usage DDSSU
WHERE	database_id=DB_ID('tempdb')
AND		user_objects_alloc_page_count > 0
order by spaceusedbythesessionmb desc

-- check the query that has been executed from that session_id.
DBCC INPUTBUFFER (129)

-- Get top 10 sessions consuming the tempDB
SELECT TOP 10 session_id
	,database_id
	,user_objects_alloc_page_count + internal_objects_alloc_page_count / 129 AS tempdb_usage_MB
FROM sys.dm_db_session_space_usage
ORDER BY user_objects_alloc_page_count + internal_objects_alloc_page_count DESC;

-- get temptables in tempDB currently
SELECT *
FROM sys.objects
WHERE type = 'U'

-- get data file space and locations
SELECT b.groupname AS 'File Group'
	,NAME
	,[Filename]
	,CONVERT(DECIMAL(15, 2), ROUND(a.Size / 128.000, 2)) [Currently Allocated Space (MB)]
	,CONVERT(DECIMAL(15, 2), ROUND(FILEPROPERTY(a.NAME, 'SpaceUsed') / 128.000, 2)) AS [Space Used (MB)]
	,CONVERT(DECIMAL(15, 2), ROUND((a.Size - FILEPROPERTY(a.NAME, 'SpaceUsed')) / 128.000, 2)) AS [Available Space (MB)]
FROM dbo.sysfiles a(NOLOCK)
JOIN sysfilegroups b(NOLOCK) ON a.groupid = b.groupid
ORDER BY b.groupname

-- Get free pages and free space
SELECT SUM(unallocated_extent_page_count) AS [free pages]
	,(SUM(unallocated_extent_page_count) * 1.0 / 128) AS [free space in MB]
FROM sys.dm_db_file_space_usage;

-- Get files name and available space
SELECT NAME
	,size / 128.0 - CAST(FILEPROPERTY(NAME, 'SpaceUsed') AS INT) / 128.0 AS AvailableSpaceInMB
FROM sys.database_files

-- Determining the Amount of Space Used by Internal Objects
SELECT SUM(internal_object_reserved_page_count) AS [internal object pages used]
	,(SUM(internal_object_reserved_page_count) * 1.0 / 128) AS [internal object space in MB]
FROM sys.dm_db_file_space_usage;

-- Determining the Amount of Space Used by User Objects
SELECT SUM(user_object_reserved_page_count) AS [user object pages used]
	,(SUM(user_object_reserved_page_count) * 1.0 / 128) AS [user object space in MB]
FROM sys.dm_db_file_space_usage;

-- Determining the Total Amount of Space (Free and Used)
SELECT SUM(size) * 1.0 / 128 AS [size in MB]
FROM tempdb.sys.database_files

-- Identify which type of tempdb objects are consuming  space
SELECT SUM(user_object_reserved_page_count) * 8 AS user_obj_kb
	,SUM(internal_object_reserved_page_count) * 8 AS internal_obj_kb
	,SUM(version_store_reserved_page_count) * 8 AS version_store_kb
	,SUM(unallocated_extent_page_count) * 8 AS freespace_kb
	,SUM(mixed_extent_page_count) * 8 AS mixedextent_kb
FROM sys.dm_db_file_space_usage

-- Currently active T-SQL query
SELECT es.host_name
	,es.login_name
	,es.program_name
	,st.dbid AS QueryExecContextDBID
	,DB_NAME(st.dbid) AS QueryExecContextDBNAME
	,st.objectid AS ModuleObjectId
	,SUBSTRING(st.TEXT, er.statement_start_offset / 2 + 1, (
			CASE 
				WHEN er.statement_end_offset = - 1
					THEN LEN(CONVERT(NVARCHAR(max), st.TEXT)) * 2
				ELSE er.statement_end_offset
				END - er.statement_start_offset
			) / 2) AS Query_Text
	,tsu.session_id
	,tsu.request_id
	,tsu.exec_context_id
	,(tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count) AS OutStanding_user_objects_page_counts
	,(tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) AS OutStanding_internal_objects_page_counts
	,er.start_time
	,er.command
	,er.open_transaction_count
	,er.percent_complete
	,er.estimated_completion_time
	,er.cpu_time
	,er.total_elapsed_time
	,er.reads
	,er.writes
	,er.logical_reads
	,er.granted_query_memory
FROM sys.dm_db_task_space_usage tsu
INNER JOIN sys.dm_exec_requests er ON (
		tsu.session_id = er.session_id
		AND tsu.request_id = er.request_id
		)
INNER JOIN sys.dm_exec_sessions es ON (tsu.session_id = es.session_id)
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) st
WHERE (tsu.internal_objects_alloc_page_count + tsu.user_objects_alloc_page_count) > 0
ORDER BY (tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count) + (tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) DESC

-- Tempdb and the Version Store
SELECT TOP 5 a.session_id
	,a.transaction_id
	,a.transaction_sequence_num
	,a.elapsed_time_seconds
	,b.program_name
	,b.open_tran
	,b.STATUS
FROM sys.dm_tran_active_snapshot_database_transactions a
JOIN sys.sysprocesses b ON a.session_id = b.spid
ORDER BY elapsed_time_seconds DESC