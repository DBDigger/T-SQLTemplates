-- Get tables and space in a FG
SELECT DS.name AS DataSpaceName 
      
      ,AU.total_pages / 128 AS TotalSizeMB 
      ,AU.used_pages / 128 AS UsedSizeMB 
     
      ,SCH.name AS SchemaName 
      ,OBJ.type_desc AS ObjectType       
      ,OBJ.name AS ObjectName 
      ,IDX.type_desc AS IndexType 
      ,IDX.name AS IndexName 

FROM sys.data_spaces AS DS with (nolock) 
     INNER JOIN sys.allocation_units AS AU with (nolock) 
         ON DS.data_space_id = AU.data_space_id 
     INNER JOIN sys.partitions AS PA  with (nolock)
         ON (AU.type IN (1, 3)  
             AND AU.container_id = PA.hobt_id) 
            OR 
            (AU.type = 2 
             AND AU.container_id = PA.partition_id) 
     INNER JOIN sys.objects AS OBJ  with (nolock)
         ON PA.object_id = OBJ.object_id 
     INNER JOIN sys.schemas AS SCH  with (nolock)
         ON OBJ.schema_id = SCH.schema_id 
     LEFT JOIN sys.indexes AS IDX  with (nolock)
         ON PA.object_id = IDX.object_id 
            AND PA.index_id = IDX.index_id 
            where DS.name = 'primary'
            and AU.total_pages / 128 > 0
ORDER BY AU.total_pages / 128 desc



Use TempDB
GO


--auto growth percentage for data and log files
SELECT DB_NAME(files.database_id) database_name
	,files.NAME logical_name
	,CONVERT(NUMERIC(15, 2), (convert(NUMERIC, size) * 8192) / 1048576) [file_size (MB)]
	,[next_auto_growth_size (MB)] = CASE is_percent_growth
		WHEN 1
			THEN CONVERT(NUMERIC(18, 2), (((convert(NUMERIC, size) * growth) / 100) * 8) / 1024)
		WHEN 0
			THEN CONVERT(NUMERIC(18, 2), (convert(NUMERIC, growth) * 8) / 1024)
		END
	,is_read_only = CASE is_read_only
		WHEN 1
			THEN 'Yes'
		WHEN 0
			THEN 'No'
		END
	,is_percent_growth = CASE is_percent_growth
		WHEN 1
			THEN 'Yes'
		WHEN 0
			THEN 'No'
		END
	,physical_name
FROM sys.master_files files
WHERE files.type IN (
		0
		,1
		)
	AND files.growth != 0

-- Get top 10 sessions consuming the tempDB
SELECT TOP 10 session_id, database_id, user_objects_alloc_page_count + internal_objects_alloc_page_count / 129 AS tempdb_usage_MB
FROM sys.dm_db_session_space_usage
ORDER BY user_objects_alloc_page_count + internal_objects_alloc_page_count DESC;


-- get query of SPID
DECLARE @sqltext VARBINARY(128)
SELECT @sqltext = sql_handle
FROM sys.sysprocesses
WHERE spid = (YourSessionID)
SELECT TEXT
FROM sys.dm_exec_sql_text(@sqltext)
GO

-- get temptables in tempDB currently
Select * from sys.objects where type = 'U'

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

-- Get objects and space 
SELECT
  sys.dm_exec_sessions.session_id AS [SESSION ID]
  ,DB_NAME(database_id) AS [DATABASE Name]
  ,HOST_NAME AS [System Name]
  ,program_name AS [Program Name]
  ,login_name AS [USER Name]
  ,status
  ,cpu_time AS [CPU TIME (in milisec)]
  ,total_scheduled_time AS [Total Scheduled TIME (in milisec)]
  ,total_elapsed_time AS    [Elapsed TIME (in milisec)]
  ,(memory_usage * 8)      AS [Memory USAGE (in KB)]
  ,(user_objects_alloc_page_count * 8) AS [SPACE Allocated FOR USER Objects (in KB)]
  ,(user_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR USER Objects (in KB)]
  ,(internal_objects_alloc_page_count * 8) AS [SPACE Allocated FOR Internal Objects (in KB)]
  ,(internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR Internal Objects (in KB)]
  ,CASE is_user_process
             WHEN 1      THEN 'user session'
             WHEN 0      THEN 'system session'
  END         AS [SESSION Type], row_count AS [ROW COUNT]
FROM sys.dm_db_session_space_usage with (nolock) 
INNER join sys.dm_exec_sessions with (nolock) 
ON  sys.dm_db_session_space_usage.session_id = sys.dm_exec_sessions.session_id



-- Estimate objects and space
CREATE VIEW all_task_usage
AS 
    SELECT session_id, 
      SUM(internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
      SUM(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count 
    FROM sys.dm_db_task_space_usage 
    GROUP BY session_id;
GO
SELECT R1.session_id,
        R1.internal_objects_alloc_page_count 
        + R2.task_internal_objects_alloc_page_count AS session_internal_objects_alloc_page_count,
        R1.internal_objects_dealloc_page_count 
        + R2.task_internal_objects_dealloc_page_count AS session_internal_objects_dealloc_page_count
    FROM sys.dm_db_session_space_usage AS R1 
    INNER JOIN all_task_usage AS R2 ON R1.session_id = R2.session_id;
-- drop view all_task_usage


-- Table size
SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM 
    sys.tables t with (nolock)
INNER JOIN      
    sys.indexes i  with (nolock) ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p with (nolock) ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a with (nolock) ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s with (nolock) ON t.schema_id = s.schema_id
WHERE 
    t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    UnusedSpaceKB desc
    

-- Get free pages and free space
SELECT SUM(unallocated_extent_page_count) AS [free pages], 
(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM sys.dm_db_file_space_usage;

-- Get files name and available space
 SELECT name, size/128.0 -CAST(FILEPROPERTY(name,'SpaceUsed') AS int)/128.0 AS AvailableSpaceInMB
FROM sys.database_files

-- Determining the Amount of Space Used by Internal Objects
SELECT SUM(internal_object_reserved_page_count) AS [internal object pages used],
(SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB]
FROM sys.dm_db_file_space_usage;

-- Determining the Amount of Space Used by User Objects
SELECT SUM(user_object_reserved_page_count) AS [user object pages used],
(SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
FROM sys.dm_db_file_space_usage;


-- Determining the Total Amount of Space (Free and Used)
SELECT SUM(size)*1.0/128 AS [size in MB]
FROM tempdb.sys.database_files


 -- Identify which type of tempdb objects are consuming  space
SELECT
SUM (user_object_reserved_page_count)*8 as user_obj_kb,
SUM (internal_object_reserved_page_count)*8 as internal_obj_kb,
SUM (version_store_reserved_page_count)*8  as version_store_kb,
SUM (unallocated_extent_page_count)*8 as freespace_kb,
SUM (mixed_extent_page_count)*8 as mixedextent_kb
FROM sys.dm_db_file_space_usage

-- Currently active T-SQL query
SELECT es.host_name , es.login_name , es.program_name,
st.dbid as QueryExecContextDBID, DB_NAME(st.dbid) as QueryExecContextDBNAME, st.objectid as ModuleObjectId,
SUBSTRING(st.text, er.statement_start_offset/2 + 1,(CASE WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max),st.text)) * 2 ELSE er.statement_end_offset 
END - er.statement_start_offset)/2) as Query_Text,
tsu.session_id ,tsu.request_id, tsu.exec_context_id, 
(tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count) as OutStanding_user_objects_page_counts,
(tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) as OutStanding_internal_objects_page_counts,
er.start_time, er.command, er.open_transaction_count, er.percent_complete, er.estimated_completion_time, er.cpu_time, er.total_elapsed_time, er.reads,er.writes, 
er.logical_reads, er.granted_query_memory
FROM sys.dm_db_task_space_usage tsu inner join sys.dm_exec_requests er 
 ON ( tsu.session_id = er.session_id and tsu.request_id = er.request_id) 
inner join sys.dm_exec_sessions es ON ( tsu.session_id = es.session_id ) 
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) st
WHERE (tsu.internal_objects_alloc_page_count+tsu.user_objects_alloc_page_count) > 0
ORDER BY (tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count)+(tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) 
DESC

-- Tempdb and the Version Store
SELECT top 5 a.session_id, a.transaction_id, a.transaction_sequence_num, a.elapsed_time_seconds,
b.program_name, b.open_tran, b.status
FROM sys.dm_tran_active_snapshot_database_transactions a
join sys.sysprocesses b
on a.session_id = b.spid
ORDER BY elapsed_time_seconds DESC


-- Get tables and space in a FG
SELECT DS.name AS DataSpaceName 
      
      
     
      ,SCH.name AS SchemaName 
            
      ,OBJ.name AS ObjectName 
     ,sum(AU.total_pages / 128) AS TotalSizeMB 

FROM sys.data_spaces AS DS with (nolock) 
     INNER JOIN sys.allocation_units AS AU with (nolock) 
         ON DS.data_space_id = AU.data_space_id 
     INNER JOIN sys.partitions AS PA  with (nolock)
         ON (AU.type IN (1, 3)  
             AND AU.container_id = PA.hobt_id) 
            OR 
            (AU.type = 2 
             AND AU.container_id = PA.partition_id) 
     INNER JOIN sys.objects AS OBJ  with (nolock)
         ON PA.object_id = OBJ.object_id 
     INNER JOIN sys.schemas AS SCH  with (nolock)
         ON OBJ.schema_id = SCH.schema_id 
     LEFT JOIN sys.indexes AS IDX  with (nolock)
         ON PA.object_id = IDX.object_id 
            AND PA.index_id = IDX.index_id 
          
           where AU.total_pages / 128 > 0
           group by DS.name ,SCH.name,OBJ.name
           order by TotalSizeMB  desc

		   -------------------------------
		   -- Get tables and space in a FG
SELECT DS.name AS DataSpaceName 
      
      , case  when ps.data_space_id  is null  then 'No' else 'Yes' end as IsPartitioned 
     
      ,SCH.name AS SchemaName 
            
      ,OBJ.name AS ObjectName 
     ,sum(AU.total_pages / 128) AS TotalSizeMB 

FROM sys.data_spaces AS DS with (nolock) 
     INNER JOIN sys.allocation_units AS AU with (nolock) 
         ON DS.data_space_id = AU.data_space_id 
     INNER JOIN sys.partitions AS PA  with (nolock)
         ON (AU.type IN (1, 3)  
             AND AU.container_id = PA.hobt_id) 
            OR 
            (AU.type = 2 
             AND AU.container_id = PA.partition_id) 
     INNER JOIN sys.objects AS OBJ  with (nolock)
         ON PA.object_id = OBJ.object_id 
     INNER JOIN sys.schemas AS SCH  with (nolock)
         ON OBJ.schema_id = SCH.schema_id 
     LEFT JOIN sys.indexes AS IDX  with (nolock)

         ON PA.object_id = IDX.object_id 
            AND PA.index_id = IDX.index_id
			 left JOIN sys.partition_schemes ps ON ps.data_space_id = idx.data_space_id 
          
           where AU.total_pages / 128 > 0
           group by DS.name ,SCH.name,OBJ.name, ps.data_space_id
           order by TotalSizeMB  desc

		   -- Get row count in table
		   SELECT 
    t.NAME AS TableName,    sum(p.[Rows])
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id

WHERE 
    t.name in (
'_Backup_STAT_APRR14',
)
GROUP BY 
    t.NAME
ORDER BY 2