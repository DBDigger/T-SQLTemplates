USE [msdb]
GO

/****** Object:  Trigger [dbo].[tr_Jobs_enabled]    Script Date: 07/08/2014 11:33:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tr_Jobs_enabled] 
ON [dbo].[sysjobs] 
FOR UPDATE AS 
---------------------------------------------------------------------------- 
-- Object Type : Trigger 
-- Object Name : msdb..tr_SysJobs_enabled 
-- Description : trigger to email DBA team when a job is enabled or disabled 
-- Author : Mir Ahmad Mahmood
-- Date : Dec 2012
---------------------------------------------------------------------------- 
SET NOCOUNT ON 

DECLARE @UserName VARCHAR(50), 
@HostName VARCHAR(50), 
@JobName VARCHAR(100), 
@DeletedJobName VARCHAR(100), 
@New_Enabled INT, 
@Old_Enabled INT, 
@Bodytext VARCHAR(200), 
@SubjectText VARCHAR(200),
@Servername VARCHAR(50)

SELECT @UserName = SYSTEM_USER, @HostName = HOST_NAME() 
SELECT @New_Enabled = Enabled FROM Inserted 
SELECT @Old_Enabled = Enabled FROM Deleted 
SELECT @JobName = Name FROM Inserted 
SELECT @Servername = @@servername

-- check if the enabled flag has been updated.
IF @New_Enabled <> @Old_Enabled 
BEGIN 

  IF @New_Enabled = 1 
  BEGIN 
    SET @bodytext = 'User: '+@username+' from '+@hostname+
        ' ENABLED SQL Job ['+@jobname+'] at '+CONVERT(VARCHAR(20),GETUTCDATE(),100) 
    SET @subjecttext ='Enabled "'+  @jobname+ +'" job on '+@Servername+ ' at ' + CONVERT(VARCHAR(20),GETUTCDATE(),100); 
  END 

  IF @New_Enabled = 0 
  BEGIN 
    SET @bodytext = 'User: '+@username+' from '+@hostname+
        ' DISABLED SQL Job ['+@jobname+'] at '+CONVERT(VARCHAR(20),GETUTCDATE(),100) 
    SET @subjecttext ='Disabled "'+  @jobname+ +'" job on '+@Servername+ ' at ' + CONVERT(VARCHAR(20),GETUTCDATE(),100);
  END 

 -- SET @subjecttext = 'SQL Job on ' + @subjecttext 

  -- send out alert email
  EXEC msdb.dbo.sp_send_dbmail 
  @profile_name = 'DBA_MAil',
  @recipients = 'asim.aslam@zintechnologies.com;atif.shahzad@zintechnologies.com', 
  @body = @bodytext, 
  @subject = @subjecttext 

END
GO


