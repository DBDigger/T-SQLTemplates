SELECT
    ja.job_id,
    j.name AS job_name,
    ja.start_execution_date,      
    ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id,
    Js.step_name
FROM msdb.dbo.sysjobactivity ja 
LEFT JOIN msdb.dbo.sysjobhistory jh 
    ON ja.job_history_id = jh.instance_id
JOIN msdb.dbo.sysjobs j 
ON ja.job_id = j.job_id
JOIN msdb.dbo.sysjobsteps js
    ON ja.job_id = js.job_id
    AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY agent_start_date DESC)
AND start_execution_date is not null
AND stop_execution_date is null;


 exec msdb.dbo.sp_help_job @execution_status=1 
 
 SELECT  name, enabled, current_execution_step
INTO    #RunningJobs
FROM    OPENQUERY([WYLN0-CLUDB02\CLUDB02], ' exec msdb.dbo.sp_help_job @execution_status=1');

select * from #RunningJobs;
drop table #RunningJobs;


CREATE TABLE #xp_results 
  
    ( 
    job_id                UNIQUEIDENTIFIER NOT NULL,   
    last_run_date         INT              NOT NULL,   
    last_run_time         INT              NOT NULL,   
    next_run_date         INT              NOT NULL,   
    next_run_time         INT              NOT NULL,   
    next_run_schedule_id  INT              NOT NULL,   
    requested_to_run      INT              NOT NULL, -- BOOL   
    request_source        INT              NOT NULL,   
    request_source_id     sysname          COLLATE database_default NULL,   
    running               INT              NOT NULL, -- BOOL   
    current_step          INT              NOT NULL,   
    current_retry_attempt INT              NOT NULL,   
    job_state             INT              NOT NULL
    )   
  
INSERT INTO  #xp_results  
EXECUTE master.dbo.xp_sqlagent_enum_jobs 1, 'sa'  
SELECT j.name, * FROM #xp_results r
INNER JOIN msdb..sysjobs j
ON r.job_id = j.job_id
WHERE running = 1