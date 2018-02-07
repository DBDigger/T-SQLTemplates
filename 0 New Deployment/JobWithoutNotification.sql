USE [msdb];
SELECT j.[name] AS [JobWithoutFailureNotification]
FROM [dbo].[sysjobs] j
LEFT JOIN [dbo].[sysoperators] o ON (j.[notify_email_operator_id] = o.[id])
WHERE j.[enabled] = 1
    AND j.[notify_level_email] NOT IN (1, 2, 3)
    order by [JobWithoutFailureNotification]
GO




select 'EXEC msdb.dbo.sp_update_job @job_name=N'''+j.name+''', @notify_level_email=2, 
@notify_level_netsend=2, @notify_level_page=2, @notify_email_operator_name=N''DBAdmins''' 
from msdb..sysjobs j
LEFT JOIN [dbo].[sysoperators] o ON (j.[notify_email_operator_id] = o.[id])
WHERE  j.[notify_level_email] NOT IN (1, 2, 3)