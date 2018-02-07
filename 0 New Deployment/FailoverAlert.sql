-- Mark for automatic execution
USE MASTER;
EXEC SP_PROCOPTION DBA_Failoveralert, 'STARTUP', 'ON'
GO

-- List startup procedures
SELECT ROUTINE_NAME FROM MASTER.INFORMATION_SCHEMA.ROUTINES
WHERE OBJECTPROPERTY(OBJECT_ID(ROUTINE_NAME),'ExecIsStartup') = 1
GO

------------------------------------------------------------------------------------------------

select CONVERT(sysname, SERVERPROPERTY('ComputerNamePhysicalNetBIOS'))
select   CONVERT(sysname, SERVERPROPERTY('MachineName'))
GO

insert into dbaservices..serverinfo values ('NYCPORREPDB01','NYCHUBREPDBCLU')
GO

select * from [SERVERInfo]
GO
--------------------------------------------Create table code 
USE [DBAServices];

/****** Object:  Table [dbo].[SERVERInfo]    Script Date: 9/10/2014 6:25:05 PM ******/
CREATE TABLE [dbo].[SERVERInfo](	[ID] [int] IDENTITY(1,1) NOT NULL,	[MachineName] [varchar](50) NULL,
	[InstanceName] [varchar](50) NULL) ON [PRIMARY]

GO

----------------------------------------------------------------------- Create USP code
USE [master]
GO

CREATE PROCEDURE [dbo].[DBA_Failoveralert]
AS 
BEGIN
DECLARE @ServerNodeName varchar(MAX), 
		@MachineName varchar(Max), 
		@NodeName varchar(MAX), 
		@header VARCHAR(128), 
		@Message VARCHAR(max),
		@node VARCHAR(128);
SET @ServerNodeName = CONVERT(sysname, SERVERPROPERTY('ComputerNamePhysicalNetBIOS'))
SET @MachineName =  CONVERT(sysname, SERVERPROPERTY('MachineName'))
select @NodeName = MachineName from dbASERVICES.dbo.SERVERInfo
where InstanceName = @MachineName 
IF (@ServerNodeName = @NodeName)
 BEGIN
 SET @header =  'SQL Server '+ UPPER(@@servername) + ' restarted!!'
 SET @Message = 'SQL is running on the correct node; no action necessary';
  exec msdb.dbo.sp_send_dbmail @profile_name = 'DBA_MAIL' --uses the default profile
     ,  @recipients = 'tauseef.ahmad@zintechnologies.com;riaz.ahmad@wyless.com;asim.aslam@zintechnologies.com;atif.shahzad@zintechnologies.com;support@wyless.com;brian.odonnell@wyless.com;ahmad.dar@wyless.com;usman.akram@zintechnologies.com'
     ,  @subject = @header
     ,  @body =  @message
     ,  @body_format = 'HTML' --default is TEXT
 END
ELSE
BEGIN
SET @node   = CONVERT(VARCHAR(128), SERVERPROPERTY('ComputerNamePhysicalNetBIOS'))
SET @header =  'SQL Server '+ UPPER(@@servername) + ' restarted!!'
SET @Message = 'SQL Server '+ UPPER(@@servername) + ' Node has Failed over and is running on the incorrect node named ' + @node 

exec msdb.dbo.sp_send_dbmail @profile_name = 'DBA_MAIL' --uses the default profile
     ,  @recipients = 'tauseef.ahmad@zintechnologies.com;riaz.ahmad@wyless.com;asim.aslam@zintechnologies.com;atif.shahzad@zintechnologies.com;support@wyless.com;brian.odonnell@wyless.com;ahmad.dar@wyless.com;usman.akram@zintechnologies.com'
     ,  @subject = @header
     ,  @body =  @message
     ,  @body_format = 'HTML' --default is TEXT
 END
END

GO





