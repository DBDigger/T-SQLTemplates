USE [msdb]
GO

/****** Object:  Operator [DBAdmins]    Script Date: 7/5/2014 10:11:47 AM ******/
EXEC msdb.dbo.sp_add_operator @name=N'DBAdmins', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'atif.shahzad@zintechnologies.com; aasim.aslam@zintechnologies.com', 
		@category_name=N'[Uncategorized]'
GO

-- Get the deadlocks logged in SQL server logs
EXEC master..sp_altermessage 1205, 'WITH_LOG', TRUE;
GO

-- Create Alert
USE msdb
GO
EXEC msdb.dbo.sp_add_alert
        @name = N'1205 - Deadlock Detected',
    @message_id = 1205,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 0,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
        @alert_name = N'1205 - Deadlock Detected',
        @operator_name = N'DBAdmins', -- name of profile here
        @notification_method = 1;
GO

---------------------------OTHER ALERTS
-- Get the deadlocks logged in SQL server logs
EXEC master..sp_altermessage 601, 'WITH_LOG', TRUE;
GO

-- Create Alert
USE msdb
GO
EXEC msdb.dbo.sp_add_alert
        @name = N'601 - Data Movement',
    @message_id = 601,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 0,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
        @alert_name = N'601 - Data Movement',
        @operator_name = N'DBAdmins', -- name of profile here
        @notification_method = 1;
GO


-----------------------------------------------------------------------708 - Low virtual address space
-- Create Alert
USE msdb
GO
EXEC msdb.dbo.sp_add_alert
        @name = N'708 - Low virtual address space',
    @message_id = 708,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 0,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
        @alert_name = N'708 - Low virtual address space',
        @operator_name = N'DBAdmins', -- name of profile here
        @notification_method = 1;
GO



----------------------------------------------------------------833 - IO Requests taking longer
-- Get the deadlocks logged in SQL server logs
EXEC master..sp_altermessage 833, 'WITH_LOG', TRUE;
GO

-- Create Alert
USE msdb
GO
EXEC msdb.dbo.sp_add_alert
        @name = N'833 - IO Requests taking longer',
    @message_id = 833,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 0,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
        @alert_name = N'833 - IO Requests taking longer',
        @operator_name = N'DBAdmins', -- name of profile here
        @notification_method = 1;
GO



----------------------------------------------------------------3619 - Log is out of space
-- Create Alert
USE msdb
GO
EXEC msdb.dbo.sp_add_alert
        @name = N'3619 - Log is out of space',
    @message_id = 3619,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 0,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
        @alert_name = N'3619 - Log is out of space',
        @operator_name = N'DBAdmins', -- name of profile here
        @notification_method = 1;
GO




----------------------------------------------------------------5145 - File Autogrow
-- Create Alert
USE msdb
GO
EXEC msdb.dbo.sp_add_alert
        @name = N'5145 - File Autogrow',
    @message_id = 5145,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 0,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
        @alert_name = N'5145 - File Autogrow',
        @operator_name = N'DBAdmins', -- name of profile here
        @notification_method = 1;
GO



----------------------------------------------------------------5182 - New log file
-- Create Alert
USE msdb
GO
EXEC msdb.dbo.sp_add_alert
        @name = N'5182 - New log file',
    @message_id = 5182,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 0,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
        @alert_name = N'5182 - New log file',
        @operator_name = N'DBAdmins', -- name of profile here
        @notification_method = 1;
GO



----------------------------------------------------------------17890 - Large memory paged out
-- Create Alert
USE msdb
GO
EXEC msdb.dbo.sp_add_alert
        @name = N'17890 - Large memory paged out',
    @message_id = 17890,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 0,
    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification
        @alert_name = N'17890 - Large memory paged out',
        @operator_name = N'DBAdmins', -- name of profile here
        @notification_method = 1;
GO


USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 016',
@message_id=0,
@severity=16,
@enabled=1,
@delay_between_responses=300,
@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 016', @operator_name=N'DBAdmins', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity 017',
@message_id=0,
@severity=17,
@enabled=1,
@delay_between_responses=300,
@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 017', @operator_name=N'DBAdmins', @notification_method = 1;
GO


EXEC msdb.dbo.sp_add_alert @name=N'Severity 018',
@message_id=0,
@severity=18,
@enabled=1,
@delay_between_responses=300,
@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 018', @operator_name=N'DBAdmins', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity 019',
@message_id=0,
@severity=19,
@enabled=1,
@delay_between_responses=300,
@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 019', @operator_name=N'DBAdmins', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity 020',
@message_id=0,
@severity=20,
@enabled=1,
@delay_between_responses=300,
@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 020', @operator_name=N'DBAdmins', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity 021',
@message_id=0,
@severity=21,
@enabled=1,
@delay_between_responses=300,
@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 021', @operator_name=N'DBAdmins', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity 022',
@message_id=0,
@severity=22,
@enabled=1,
@delay_between_responses=300,
@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 022', @operator_name=N'DBAdmins', @notification_method = 1;
GO


EXEC msdb.dbo.sp_add_alert @name=N'Severity 023',
@message_id=0,
@severity=23,
@enabled=1,
@delay_between_responses=300,
@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 023', @operator_name=N'DBAdmins', @notification_method = 1;
GO


EXEC msdb.dbo.sp_add_alert @name=N'Severity 024',
@message_id=0,
@severity=24,
@enabled=1,
@delay_between_responses=300,
@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 024', @operator_name=N'DBAdmins', @notification_method = 1;
GO


EXEC msdb.dbo.sp_add_alert @name=N'Severity 025',
@message_id=0,
@severity=25,
@enabled=1,
@delay_between_responses=300,
@include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 025', @operator_name=N'DBAdmins', @notification_method = 1;
GO


EXEC msdb.dbo.sp_add_alert @name=N'Error Number 823',
@message_id=823,
 @severity=0,
 @enabled=1,
 @delay_between_responses=300,
 @include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 823', @operator_name=N'DBAdmins', @notification_method = 1;
GO


EXEC msdb.dbo.sp_add_alert @name=N'Error Number 824',
 @message_id=824,
 @severity=0,
 @enabled=1,
 @delay_between_responses=300,
 @include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 824', @operator_name=N'DBAdmins', @notification_method = 1;
GO


EXEC msdb.dbo.sp_add_alert @name=N'Error Number 825',
 @message_id=825,
 @severity=0,
 @enabled=1,
 @delay_between_responses=300,
 @include_event_description_in=1
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 825', @operator_name=N'DBAdmins', @notification_method = 1;
GO


USE [msdb]
GO

/****** Object:  Alert [High-CPU]   */
EXEC msdb.dbo.sp_add_alert @name=N'High-CPU', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=1, 
		@performance_condition=N'MSSQL$MATRIX4SQL2:Resource Pool Stats|CPU usage %|default|>|0.95',
		-- @performance_condition=N'SQLServer:Resource Pool Stats|CPU usage %|default|>|0.95', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'High-CPU', @operator_name=N'DBAdmins', @notification_method = 1
GO

-----------------------------------
-- Create alert
Exec msdb.dbo.sp_add_alert
        @name=N'Page RestorePending (829) detected', 
        @message_id=829,
        @enabled=1;
        
-- Assign operator to alert
Exec msdb.dbo.sp_add_notification
        @alert_name=N'Page RestorePending (829) detected',
        @operator_name=N'DBAdmins',
        @notification_method = 1;
Go