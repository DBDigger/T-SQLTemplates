-- Get message status
select * from sys.messages where language_id = 1033 and message_id = 1205 

-- Get traces that are Enabled
DBCC TRACESTATUS


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

-- Set trace on for deadlock details
DBCC TRACEON (1204, -1)
GO

-- Set trace on for XML plan
DBCC TRACEON (1222, -1)
GO

-- http://sqlmag.com/blog/enabling-email-alerts-sql-server-deadlocks


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

