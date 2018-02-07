-- Mark for automatic execution
USE MASTER;
EXEC SP_PROCOPTION DBA_Failoveralert, 'STARTUP', 'ON'
GO

-- List startup procedures
SELECT ROUTINE_NAME FROM MASTER.INFORMATION_SCHEMA.ROUTINES
WHERE OBJECTPROPERTY(OBJECT_ID(ROUTINE_NAME),'ExecIsStartup') = 1
GO

USE [master]
GO

/****** Object:  StoredProcedure [dbo].[DBA_SqlServer_Start_Alert]    Script Date: 9/3/2015 3:13:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE Procedure [dbo].[DBA_SqlServer_Start_Alert]
AS

 DECLARE @xml NVARCHAR(MAX)
 DECLARE @body NVARCHAR(MAX)
 DECLARE @subj NVARCHAR(MAX);

 SET @subj = 'SQL Service on ' + @@SERVERNAME +  ' is started.';
 SET @body = 'SQL Service on ' + @@SERVERNAME +  ' is started. <br> <br> Kind Regards <br> DBAdmin';

EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBA_Mail'
  ,@body = @body
  ,@body_format = 'HTML'
  ,@recipients = 'DBA@zintechnologies.com' 
  ,@subject =  @subj;



GO

EXEC sp_procoption N'[dbo].[DBA_SqlServer_Start_Alert]', 'startup', '1'

GO


