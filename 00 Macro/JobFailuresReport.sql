-- Get ID
select * from [ADM_Support].[dbo].[MAINT_FailedJobs_Arch]
where ServerName = 'ASI-SQLUCN1-10'
and JobName = 'DailyServerDataTasks'
and StepName = 'PROD_Master: Remove rows with auditstatus_cd = ''H'''
order by archid desc

-- Add FailureReason
update [ADM_Support].[dbo].[MAINT_FailedJobs_Arch]
set FailureReason = 'Add job failure reason here', 
ignore = 0
where archid = 1579
GO

-- Add ResolveComment
update [ADM_Support].[dbo].[MAINT_FailedJobs_Arch]
set ResolveDate = getdate(),
ResolvedBy = suser_sname() ,
ResolveComment = 'Add resolution detail here'
where archid = 1579
GO

-- Get duplicate failures
SELECT   a.ServerName, a.JobName, a.StepName, a.ExecDate, a.RunStatus, a.SRVR_Type_CD, a.JobStatus  
 FROM [ADM_Support].[dbo].[MAINT_FailedJobs_Arch] a  
 join  
 (SELECT   ServerName, JobName, StepName, ExecDate, RunStatus, SRVR_Type_CD, JobStatus   
 FROM [ADM_Support].[dbo].[MAINT_FailedJobs_Arch]  
 GROUP BY   ServerName, JobName, StepName, ExecDate, RunStatus, SRVR_Type_CD, JobStatus
 HAVING count(*) >  1) b   
 ON  a.ServerName = b.ServerName  
  and a.JobName = b.JobName 
   and a.StepName = b.StepName 
    and a.ExecDate = b.ExecDate 
	 and a.RunStatus = b.RunStatus 
	  and a.SRVR_Type_CD = b.SRVR_Type_CD 
	   and a.JobStatus = b.JobStatus 
 ORDER BY a.ServerName, a.JobName, a.StepName, a.ExecDate, a.RunStatus, a.SRVR_Type_CD, a.JobStatus  
 GO 

-- Remove duplicate failures
WITH CTE AS 
( 
SELECT ROW_NUMBER() OVER 
(PARTITION BY ServerName, JobName, StepName, ExecDate, RunStatus, SRVR_Type_CD, JobStatus 
Order BY ServerName desc, JobName desc, StepName desc, ExecDate desc, RunStatus desc, SRVR_Type_CD desc, JobStatus  desc ) 
AS RowNumber, 
ServerName, JobName, StepName, ExecDate, RunStatus, SRVR_Type_CD, JobStatus  
FROM [ADM_Support].[dbo].[MAINT_FailedJobs_Arch] tbl ) 
DELETE FROM CTE Where RowNumber > 1
GO 

-- Monthly Failure Summary as per environment
select count(*) as TotalFailures,
sum(case when SRVR_Type_CD = 'PRD'  then 1 else 0 end) as PRDFailureCount , 
sum(case when SRVR_Type_CD = 'UAT'  then 1 else 0 end) as UATFailureCount ,
sum(case when SRVR_Type_CD = 'STG'  then 1 else 0 end) as STGFailureCount ,
sum(case when SRVR_Type_CD = 'DEV'  then 1 else 0 end) as DEVFailureCount 
from ADM_Support.dbo.MAINT_FailedJobs_Arch
where ignore = 0
and ExecDate >= dateadd(dd,-30,getdate())
GO

-- Failure Count as per jobs
select ServerName, JobName, StepName, count(*) as FailureCount
from ADM_Support.dbo.MAINT_FailedJobs_Arch
where SRVR_Type_CD = 'PRD'
and ignore = 0 
and ExecDate >= dateadd(dd,-30,getdate())
group by ServerName, JobName, StepName
order by FailureCount desc
GO

-- Failure and resolution comparison
select ServerName, JobName, StepName,ResolveComment,  count(*) FailureCount,  
sum(case when ResolveComment IS NULL  then 0 else 1 end) Resolvecount
from ADM_Support.dbo.MAINT_FailedJobs_Arch
where SRVR_Type_CD = 'PRD'
and ignore = 0 
and ExecDate >= dateadd(dd,-30,getdate())
group by ServerName, JobName, StepName, ResolveComment
order by Resolvecount desc
