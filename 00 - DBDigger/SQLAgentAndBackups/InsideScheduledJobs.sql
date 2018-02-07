-- Get jobs status and last runs
USE msdb
GO

SELECT DISTINCT j.NAME AS "Job Name"
	,--j.job_id, 
	CASE j.enabled
		WHEN 1 	THEN 'Enable'
		WHEN 0	THEN 'Disable'
		END AS "Job Status"
	,jh.run_date AS [Last_Run_Date(YY-MM-DD)]
	,CASE jh.run_status
		WHEN 0	THEN 'Failed'
		WHEN 1	THEN 'Successful'
		WHEN 2	THEN 'Retry'
		WHEN 3	THEN 'Cancelled'
		WHEN 4	THEN 'In Progress'
		END AS Job_Execution_Status
FROM sysJobHistory jh
	,sysJobs j
WHERE j.job_id = jh.job_id
	AND jh.run_date = (
		SELECT max(hi.run_date)
		FROM sysJobHistory hi
		WHERE jh.job_id = hi.job_id
		) -- to get latest date

-- Get duration
select 
 j.name as 'JobName',
 s.step_id as 'Step',
 s.step_name as 'StepName',
 msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime',
 ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) 
         as 'RunDurationMinutes'
From msdb.dbo.sysjobs j 
INNER JOIN msdb.dbo.sysjobsteps s 
 ON j.job_id = s.job_id
INNER JOIN msdb.dbo.sysjobhistory h 
 ON s.job_id = h.job_id 
 AND s.step_id = h.step_id 
 AND h.step_id <> 0
where j.enabled = 1   --Only Enabled Jobs
--and j.name = 'TestJob' --Uncomment to search for a single job
/*
and msdb.dbo.agent_datetime(run_date, run_time) 
BETWEEN '12/08/2012' and '12/10/2012'  --Uncomment for date range queries
*/
order by JobName, RunDateTime desc




-- To generate steps history of all jobs

USE msdb
Go 

SELECT j.name JobName,h.step_name StepName, 
CONVERT(CHAR(10), CAST(STR(h.run_date,8, 0) AS dateTIME), 111) RunDate, 
STUFF(STUFF(RIGHT('000000' + CAST ( h.run_time AS VARCHAR(6 ) ) ,6),5,0,':'),3,0,':') RunTime, 
h.run_duration StepDuration,
case h.run_status when 0 then 'failed'
when 1 then 'Succeded' 
when 2 then 'Retry' 
when 3 then 'Cancelled' 
when 4 then 'In Progress' 
end as ExecutionStatus, 
h.message MessageGenerated
FROM sysjobhistory h inner join sysjobs j
ON j.job_id = h.job_id
ORDER BY j.name, h.run_date, h.run_time
GO


-- get job and step name
SELECT JOB.NAME AS JOB_NAME,
STEP.STEP_NAME AS STEP_NAME
FROM Msdb.dbo.SysJobs JOB
INNER JOIN Msdb.dbo.SysJobSteps STEP ON STEP.Job_Id = JOB.Job_Id
WHERE job.category_id not between 10 and 20


-- get job owners

SELECT   category_id ,s.name ,
        SUSER_SNAME(s.owner_sid) AS owner
FROM    msdb..sysjobs s 
where SUSER_SNAME(s.owner_sid)  <> 'sa'
ORDER BY name

-- get job and step name
SELECT JOB.NAME AS JOB_NAME,
STEP.STEP_NAME AS STEP_NAME, subsystem, database_name
FROM Msdb.dbo.SysJobs JOB
INNER JOIN Msdb.dbo.SysJobSteps STEP ON STEP.Job_Id = JOB.Job_Id
WHERE job.category_id not between 10 and 20
order by JOB_NAME,step_id


select name from sysjobs
where category_id not between 10 and 20
order by 1