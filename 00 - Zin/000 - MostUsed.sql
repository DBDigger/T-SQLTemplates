 sp_whoisactive
 
-- Get log reader log
SELECT top 100 time, CAST(comments AS XML) AS comments, runstatus, duration, 
xact_seqno, delivered_transactions, delivered_commands, average_commands, 
delivery_time, delivery_rate, delivery_latency / ( 1000 * 60 ) AS delivery_latency_Min 
FROM distribution.dbo.mslogreader_history WITH (nolock)  
ORDER BY time DESC 

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

 -- Get log reader latency
sp_replcounters
 
-- Get running jobs 
exec msdb.dbo.sp_help_job @execution_status=1 


SELECT  name, enabled, current_execution_step
INTO    #RunningJobs
FROM    OPENQUERY([WYLN0-CLUDB02\CLUDB02], ' exec msdb.dbo.sp_help_job @execution_status=1');

select * from #RunningJobs;
drop table #RunningJobs;



---- Change password
--ALTER LOGIN [login.name] WITH PASSWORD = '12345' OLD_PASSWORD = '67890'

-- Get job step name by ID
use msdb;
SELECT * FROM msdb.dbo.sysjobs
WHERE job_id = dbo.GetJobIdFromProgramName ('')

-- Fix Orphaned user
EXEC sp_change_users_login 'Auto_Fix', 'TestUser2'
GO