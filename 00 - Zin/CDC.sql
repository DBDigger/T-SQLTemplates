Use prod_master
GO
exec sys.sp_cdc_add_job 'capture'
GO
exec sys.sp_cdc_add_job 'cleanup'
GO

sp_cdc_change_job @job_type='cleanup', @retention=43200
GO

SELECT [retention]
  FROM [msdb].[dbo].[cdc_jobs]
  WHERE [database_id] = DB_ID()
  AND [job_type] = 'cleanup'



  GO


USE [DBAServices];
CREATE TABLE [dbo].[CDCArchivals](	[tablename] [varchar](100) NULL,	[ConditionDate] [datetime] NULL,	
[ArchivalDate] [datetime] NULL) 
GO


-- Populate log table
insert into [CDCArchivals] values ('cdc.DBO_APITRANSACTIONLOG_CT','2014-01-01',GETDATE())
GO

  

select top 50 *
from cdc.lsn_time_mapping;

select top 50 *
from cdc.DBO_CONTRACTPRODUCTBALANCE_CT;

-- Get count 
select count(*) from cdc.DBO_APITRANSACTIONLOG_CT ct with (nolock)inner join  cdc.lsn_time_mapping lg with (nolock)
on ct.__$start_lsn = lg.start_lsn
where lg.tran_begin_time < '2014-01-01'


-- Deletion loop
  DECLARE @RowsDeleted INTEGER
Declare @counter int
Declare @MailBody Varchar(300)
SET @counter =1



SET @RowsDeleted = 1


WHILE (@RowsDeleted > 0)
    BEGIN

        -- delete 300000 rows a time
        delete top (70000) from cdc.DBO_APITRANSACTIONLOG_CT 
        output deleted.*  into cdc_db..DBO_APITRANSACTIONLOG_CT
        from cdc.DBO_APITRANSACTIONLOG_CT ct inner join  cdc.lsn_time_mapping lg 
on ct.__$start_lsn = lg.start_lsn

where lg.tran_begin_time < '2014-01-01'
		

        SET @RowsDeleted = @@ROWCOUNT
         
        SET @counter = @counter +1 
      
        SET @MailBody = 'Loop # ' + cast(@counter as varchar) + ' in Process for table DBO_APITRANSACTIONLOG_CT .Further Loops in process.'
         
		waitfor delay '00:00:08'
     
    EXEC msdb.dbo.sp_send_dbmail @recipients=N'atif.shahzad@zintechnologies.com',
    @subject = 'Loop in Process for table DBO_APITRANSACTIONLOG_CT.',
    @profile_name ='dba_mail',
    @body = @MailBody,
    @body_format = 'HTML' ;
end
Go

--------------------------------------------------------------------------------
-- Get CDC status for DBs
select name, is_cdc_enabled from sys.databases


-- Enable CDC for DB
EXEC sys.sp_cdc_enable_db

-- Disable CDC for DB
EXEC sys.sp_cdc_disable_db


-- Get CDC enabled tables
select object_name(source_object_id) as SourceTable, object_name(object_id) as CDCTable from cdc.change_tables


-- Enable CDC for table
EXEC sys.sp_cdc_enable_table
@source_schema = N'dbo',
@source_name   = N'contractproductbalance',
@role_name     = N'cdc',
@filegroup_name = N'cdc',
@supports_net_changes = 1
GO


-- Disable CDC for table
EXEC sys.sp_cdc_disable_table
@source_schema = N'dbo',
@source_name   = N'contractproductbalance',
@capture_instance = N'dbo_contractproductbalance'
GO


-- Drop objects if error occurs
--The database '%' cannot be enabled for Change Data Capture because a database user named 'cdc' or a schema named 'cdc' already exists in the current database. These objects are required exclusively by Change Data Capture. Drop or rename the user or schema and retry the operation.


-- Drop cdc objects
DECLARE @tableName NVARCHAR(100);
DECLARE myCursor CURSOR FORWARD_ONLY FAST_FORWARD READ_ONLY
FOR
    SELECT  QUOTENAME(t.name) AS name
    FROM    sys.tables t
            JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE   s.name = 'cdc'
OPEN myCursor 
FETCH FROM myCursor INTO @TableName 
WHILE ( @@Fetch_Status = 0 ) 
    BEGIN 

        EXEC ( 'drop table cdc.' + @TableName + '; ' );
        FETCH NEXT FROM myCursor INTO @TableName 
    END  
CLOSE myCursor 
DEALLOCATE myCursor;
go

DECLARE @prName NVARCHAR(100);
DECLARE myCursor2 CURSOR FORWARD_ONLY FAST_FORWARD READ_ONLY
FOR
    SELECT  QUOTENAME(pr.name) AS name
    FROM    sys.procedures pr
            JOIN sys.schemas s ON pr.schema_id = s.schema_id
    WHERE   s.name = 'cdc'
OPEN myCursor2 
FETCH FROM myCursor2 INTO @prName 
WHILE ( @@Fetch_Status = 0 ) 
    BEGIN 
        EXEC ( 'drop procedure cdc.' + @prName + '; ' );
        FETCH NEXT FROM myCursor2 INTO @prName 
    END  
CLOSE myCursor2
DEALLOCATE myCursor2 

GO

DECLARE @fnName NVARCHAR(100);
DECLARE myCursor3 CURSOR FORWARD_ONLY FAST_FORWARD READ_ONLY
FOR
    SELECT  QUOTENAME(fn.name) AS name
    FROM    sys.objects fn
            JOIN sys.schemas s ON fn.schema_id = s.schema_id
    WHERE   fn.type IN ( 'FN', 'IF', 'TF' )
            AND s.name = 'cdc'
OPEN myCursor3 
FETCH FROM myCursor3 INTO @fnName 
WHILE ( @@Fetch_Status = 0 ) 
    BEGIN 
        EXEC ( 'drop function cdc.' + @fnName + '; ' );
        FETCH NEXT FROM myCursor3 INTO @fnName 
    END  
CLOSE myCursor3
DEALLOCATE myCursor3 
go
DECLARE @ruleName NVARCHAR(100);
SELECT  @ruleName = DP1.name
FROM    sys.database_principals AS DP1
        JOIN sys.database_principals AS DP2 ON DP1.owning_principal_id = DP2.principal_id
WHERE   DP1.type = 'R'
        AND DP2.name = 'cdc';
EXEC ('ALTER AUTHORIZATION ON ROLE::'+@ruleName+' TO dbo; ')
go 
DROP SCHEMA [cdc]
GO
DROP USER [cdc]
GO

-----------------------------------------------------------------------------------------------------------------



-------------------------------- Deletion loop

    DECLARE @RowsDeleted INTEGER
Declare @counter int
Declare @MailBody Varchar(300)
SET @counter =1



SET @RowsDeleted = 1


WHILE (@RowsDeleted > 0)
    BEGIN



        -- delete 300000 rows a time
        delete top (71000) from cdc.DBO_APITRANSACTIONLOG_CT 
        output deleted.*  into cdc_db..DBO_APITRANSACTIONLOG_CT
        from cdc.DBO_APITRANSACTIONLOG_CT ct inner join  cdc.lsn_time_mapping lg 
on ct.__$start_lsn = lg.start_lsn

where lg.tran_begin_time < '2014-01-01'
		

        SET @RowsDeleted = @@ROWCOUNT
         
        SET @counter = @counter +1 
      
        SET @MailBody = 'Loop # ' + cast(@counter as varchar) + ' in Process for table DBO_APITRANSACTIONLOG_CT .Further Loops in process.'
         
		waitfor delay '00:00:13'
     
    EXEC msdb.dbo.sp_send_dbmail @recipients=N'atif.shahzad@zintechnologies.com',
    @subject = 'Loop in Process for table DBO_APITRANSACTIONLOG_CT.',
    @profile_name ='dba_mail',
    @body = @MailBody,
    @body_format = 'HTML' ;
end
Go



-- Get CDC Retention days
SELECT d.name as database_name,(j.[retention]/60)/24 RetentionDays
  FROM [msdb].[dbo].[cdc_jobs] j
  inner join sys.databases d 
  on j.database_id = d.database_id
   WHERE
  [job_type]  like '%cleanup%'
