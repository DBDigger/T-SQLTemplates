-- Get database backup status in running job
SELECT CONVERT(NUMERIC(6, 2), r.percent_complete) AS [percent_complete]
	,CONVERT(VARCHAR(20), DATEADD(ms, r.estimated_completion_time, GetDate()), 20) AS [estimated_completion_time]
FROM sys.dm_exec_requests r
WHERE command IN (
		'RESTORE DATABASE'
		,'BACKUP DATABASE'
		)