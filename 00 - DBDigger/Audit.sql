-- get jobs without failure notification
USE [msdb];
SELECT j.[name] AS [JobWithoutFailureNotification]
FROM [dbo].[sysjobs] j
LEFT JOIN [dbo].[sysoperators] o ON (j.[notify_email_operator_id] = o.[id])
WHERE j.[enabled] = 1
    AND j.[notify_level_email] NOT IN (1, 2, 3)
GO


-- Get 23 configured agent alerts status
SELECT count(*)
  FROM [msdb].[dbo].[sysalerts]
  where enabled = 1
  and name in (
'1205 - Deadlock Detected',
'17890 - Large memory paged out',
'3619 - Log is out of space',
'5145 - File Autogrow',
'5182 - New log file',
'601 - Data Movement',
'708 - Low virtual address space',
'833 - IO Requests taking longer',
'CPUAlert',
'Error Number 823',
'Error Number 824',
'Error Number 825',
'LongRunning',
'Page RestorePending (829) detected',
'Severity 016',
'Severity 017',
'Severity 018',
'Severity 019',
'Severity 020',
'Severity 021',
'Severity 022',
'Severity 023',
'Severity 024'
  )



-- Get Principals with sysadmin login
SELECT spm.name
FROM sys.server_role_members srm, sys.server_principals sp, sys.server_principals spm WHERE sp.name = 'sysadmin'
AND sp.principal_id = srm.role_principal_id AND spm.principal_id = srm.member_principal_id;

-- Identity columns near limit
WITH CTE_1
AS (
	SELECT OBJECT_NAME(a.Object_id) AS table_name
		,a.NAME AS columnname
		,CONVERT(BIGINT, ISNULL(a.last_value, 0)) AS last_value
		,CASE 
			WHEN b.NAME = 'tinyint'
				THEN 255
			WHEN b.NAME = 'smallint'
				THEN 32767
			WHEN b.NAME = 'int'
				THEN 2147483647
			WHEN b.NAME = 'bigint'
				THEN 9223372036854775807
			END AS dt_value
	FROM sys.identity_columns a
	INNER JOIN sys.types AS b ON a.system_type_id = b.system_type_id
	)
	,CTE_2
AS (
	SELECT *
		,CONVERT(NUMERIC(18, 2), ((CONVERT(FLOAT, last_value) / CONVERT(FLOAT, dt_value)) * 100)) AS "Percent"
	FROM CTE_1
	)
SELECT *
FROM CTE_2
ORDER BY "Percent" DESC;


-- Time since last restore
SELECT DATEDIFF(MINUTE, restore_date, GETDATE())
FROM (
	SELECT TOP 1 restore_date
	FROM msdb.dbo.restorehistory
	WHERE destination_database_name = DB_NAME()
	ORDER BY restore_date DESC
	) rd;
       
      
 -- Buffer cache used per database in MB   
      SELECT (COUNT(*) * 8.0) / 1024 AS MB
  FROM sys.dm_os_buffer_descriptors AS dobd
  WHERE [dobd].[database_id] = DB_ID();
       
-- Percentage of blocked connections 
SELECT  CAST(SUM(CASE WHEN blocking_session_id <> 0 THEN 100.00
                      ELSE 0.00
                 END) / COUNT(*) AS NUMERIC(10, 2))
FROM    sys.dm_exec_requests
WHERE database_id = DB_ID();



-- Plan cache hit ratio
WITH cte1
AS (
	SELECT [dopc].[object_name]
		,[dopc].[instance_name]
		,[dopc].[counter_name]
		,[dopc].[cntr_value]
		,[dopc].[cntr_type]
		,ROW_NUMBER() OVER (
			PARTITION BY [dopc].[object_name]
			,[dopc].[instance_name] ORDER BY [dopc].[counter_name]
			) AS r_n
	FROM [sys].[dm_os_performance_counters] AS dopc
	WHERE [dopc].[counter_name] LIKE '%Cache Hit Ratio%'
		AND (
			[dopc].[object_name] LIKE '%Plan Cache%'
			OR [dopc].[object_name] LIKE '%Buffer Cache%'
			)
		AND [dopc].[instance_name] LIKE '%_Total%'
	)
SELECT CONVERT(DECIMAL(16, 2), ([c].[cntr_value] * 1.0 / [c1].[cntr_value]) * 100.0) AS [hit_pct]
FROM [cte1] AS c
INNER JOIN [cte1] AS c1 ON c.[object_name] = c1.[object_name]
	AND c.[instance_name] = c1.[instance_name]
WHERE [c].[r_n] = 1
	AND [c1].[r_n] = 2;
	
	
-- Plan cache reuse	
	DECLARE @single DECIMAL(18, 2)
DECLARE @reused DECIMAL(18, 2)
DECLARE @total DECIMAL(18, 2)
-- the above variables may need a precision greater than 18 on VLDB instances. This will incur a storage penalty in the RedgateMonitor database however.
SELECT @single = SUM(CASE ( usecounts )
                       WHEN 1 THEN 1
                       ELSE 0
                     END) * 1.0 ,
        @reused = SUM(CASE ( usecounts )
                        WHEN 1 THEN 0
                        ELSE 1
                      END) * 1.0 ,
        @total = COUNT(usecounts) * 1.0
    FROM sys.dm_exec_cached_plans;
 
 
SELECT ( @single / @total ) * 100.0;



-- Total waits are wait_time_ms (high signal waits indicates CPU pressure)
SELECT  CAST(100.0 * SUM(signal_wait_time_ms) / SUM(wait_time_ms)
                              AS NUMERIC(20,2)) AS signal_cpu_waits
FROM    sys.dm_os_wait_stats ;




-- Get autogrowth events
DECLARE @filename NVARCHAR(1000)
 
SELECT @filename = CAST(value AS NVARCHAR(1000))
FROM sys.fn_trace_getinfo(DEFAULT)
WHERE traceid = 1 AND property = 2
 
/*separate file name into pieces*/
DECLARE @bc INT,
@ec INT,
@bfn VARCHAR(1000),
@efn VARCHAR(10)
 
SET @filename = REVERSE(@filename)
SET @bc = CHARINDEX('.',@filename)
SET @ec = CHARINDEX('_',@filename)+1
SET @efn = REVERSE(SUBSTRING(@filename,1,@bc))
SET @bfn = REVERSE(SUBSTRING(@filename,@ec,LEN(@filename)))
 
/*set filename without rollover number*/
SET @filename = @bfn + @efn
 
/*process all trace files and insert data into DB_AutoGrow_Log*/
SELECT ftg.StartTime,
te.name 'EventName',
DB_NAME(ftg.databaseid) 'DatabaseName',
ftg.[Filename] 'FileName',
(ftg.IntegerData*8)/1024.0 'GrowthMB',
(ftg.duration)/1000000.0 'Duration_Secs'
FROM fn_trace_gettable(@filename, DEFAULT) AS ftg INNER JOIN sys.trace_events AS te ON ftg.EventClass = te.trace_event_id
WHERE (ftg.EventClass = 92 OR ftg.EventClass = 93) -- Date File Auto-grow, Log File Auto-grow
AND DatabaseID = DB_ID()
AND ftg.StartTime > DATEADD(dd, -1, GETDATE())