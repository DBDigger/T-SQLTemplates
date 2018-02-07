DECLARE @JobStatus INT
SET @JobStatus = 0

 WHILE @JobStatus <> 15
 BEGIN
  --First Check Job Status Execute the job if it is not running
  IF NOT EXISTS(SELECT sj.name
     ,DATEDIFF(SECOND,aj.start_execution_date,GetDate()) AS Seconds
      FROM msdb..sysjobactivity aj
      JOIN msdb..sysjobs sj on sj.job_id = aj.job_id
     WHERE aj.stop_execution_date IS NULL -- job hasn't stopped running
      AND aj.start_execution_date IS NOT NULL -- job is currently running
     and not exists( -- make sure this is the most recent run
      select 1
      from msdb..sysjobactivity new
      where new.job_id = aj.job_id
        and new.start_execution_date > aj.start_execution_date )
     AND sj.name ='PorthosArchivalManagement')
   BEGIN 
    EXEC MSDB.dbo.sp_start_job @Job_Name = 'PorthosArchivalManagement'
   END
   
   WAITFOR DELAY '00:01:30'
 
   SET @JobStatus = @JobStatus +1
   
   PRINT @JobStatus
 END