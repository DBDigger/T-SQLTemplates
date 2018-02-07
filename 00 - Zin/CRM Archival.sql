-- Run job multiple times
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






-- Change Schema of a table
ALTER SCHEMA Arc TRANSFER dbo.APITransactionLog_archive_Feb2015;

-- Rename a table
EXEC sp_rename 'ARC.APITransactionLog_archive_Feb2015', 'APITransactionLog_Archive';
GO


DoItAgain:
DELETE TOP (1000)
FROM ExampleTable

IF @@ROWCOUNT > 0
GOTO DoItAgain


-- Delete in chunks
DECLARE @RowsDeleted INTEGER
SET @RowsDeleted = 1

WHILE (@RowsDeleted > 0)
    BEGIN
        -- delete 10,000 rows a time
        delete top(10000) from REQUESTS1
output deleted.*  into REQUESTS1_BkUp_Aug312014
where  created <= '2014-05-31'
        SET @RowsDeleted = @@ROWCOUNT
    END

	
	---------------------------------------- Orphaned records in requestdetails
select R.requestid, RD.requestdetailid 
from REQUESTS1 R with (nolock) 
right outer join REQUESTDETAILS1 RD with (nolock)  on R.REQUESTID = RD.REQUESTID_FK
where R.REQUESTID is null


--------------------------- Get parents without childs
select R.requestid, RD.requestdetailid 
from REQUESTS1 R with (nolock) 
left outer join REQUESTDETAILS1 RD with (nolock)  on R.REQUESTID = RD.REQUESTID_FK
where RD.requestdetailid  is null

-- ---------------------------Delete orphaned records from  requestdetails
DECLARE @RowsDeleted INTEGER
SET @RowsDeleted = 1

WHILE (@RowsDeleted > 0)
    BEGIN
        -- delete 10,000 rows a time
DELETE REQUESTDETAILS1 
output deleted.*  into REQUESTDETAILS1_BkUp_Aug312014
FROM REQUESTDETAILS1 D
LEFT OUTER JOIN
REQUESTS1 R  on D.REQUESTID_FK = R.REQUESTID 
where R.REQUESTID is null
SET @RowsDeleted = @@ROWCOUNT
    END
    


-- Delete parents without childs in details
DECLARE @RowsDeleted INTEGER
SET @RowsDeleted = 1

WHILE (@RowsDeleted > 0)
    BEGIN
        -- delete 10,000 rows a time
DELETE top (10000) REQUESTS1 
output deleted.*  into REQUESTS1_BkUp_Aug312014
FROM REQUESTS1 R
LEFT OUTER JOIN
REQUESTDETAILS1 D  on R.REQUESTID  = D.REQUESTID_FK
where D.REQUESTID_FK is null
SET @RowsDeleted = @@ROWCOUNT
    END

