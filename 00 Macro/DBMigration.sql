
select name, user_access, state_desc, create_date 
from sys.databases 
where name in 
 (
'AD_MgmtMaster','AdSync','ASI_ADmaster','StatsStgArea', 'AuditHist', 'LOAD_Proof', 'WEIT_Admin'

)
order by name


--Transfer Logins
Transfer all missing logins that are on Source but missing on destination.
EXEC sp_help_revlogin
GO



--Verify Logins transfer by using following script
SELECT DestinationServer.NAME , SourceServer.NAME
FROM syslogins AS DestinationServer
RIGHT OUTER JOIN [SourceServer].master.dbo.syslogins AS SourceServer
ON DestinationServer.sid  = SourceServer.sid
WHERE DestinationServer.NAME IS NULL
ORDER BY SourceServer.NAME

-- get job and step name
SELECT JOB.NAME AS JOB_NAME, enabled FROM Msdb.dbo.SysJobs JOB
WHERE job.category_id not between 10 and 20 order by JOB_NAME


-- Get link server list
SELECT name,  data_source
FROM sys.Servers 
where server_id <> 0
order by name




--Note DB properties
select name, is_published, is_subscribed, is_cdc_enabled, is_trustworthy_on, is_read_only from sys.databases where name in 
(
'AD_MgmtMaster','AdSync','ASI_ADmaster','StatsStgArea', 'AuditHist', 'LOAD_Proof', 'WEIT_Admin'

)
order by name

--Database Size
SELECT DB_NAME(database_id) AS DatabaseName, type_desc,   
 cast(sum( size* 8.0 / 1024)/1024 as DECIMAL(18,3)) [Size(GB)]  
 FROM sys.master_files  
 where DB_NAME(database_id) in 
(
'AD_MgmtMaster','AdSync','ASI_ADmaster','StatsStgArea', 'AuditHist', 'LOAD_Proof', 'WEIT_Admin'

)
 GROUP BY DB_NAME(database_id), type_desc  
 ORDER BY DB_NAME(database_id), type_desc DESC


--Transfer Agent alerts 
USE [msdb]
GO

/****** Object:  Alert [Replace DM_Stats]    Script Date: 1/16/2017 7:12:09 AM ******/
EXEC sp_addmessage   
    @msgnum = 51020,  
    @severity = 10,  
    @msgtext = N'Replace DM_Stats',   
  @with_log= 'TRUE',
    @lang = 'us_english'
GO

select * from sysmessages where error = 51020

 

--Set DBs to READ ONLY and Restricted mode on source server
ALTER AVAILABILITY GROUP [asi-sqlUpcdg1-09] REMOVE DATABASE [AD_MgmtMaster]
GO
ALTER DATABASE [AD_MgmtMaster] SET  READ_ONLY WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE [AD_MgmtMaster] SET  RESTRICTED_USER WITH ROLLBACK IMMEDIATE
GO

--Backup databases through following script on source server
-- Declare cursor for database names
DECLARE BackupCursor CURSOR FOR  
 SELECT name FROM sys.databases  
 WHERE name in 
 (
'ABSOLUTEFM','AD_MgmtMaster','AdSync','ASI_ADmaster','StatsStgArea', 'AuditHist', 'LOAD_Proof', 'WEIT_Admin'

) 


-- Declare variable to hold DBName
declare @Db_name varchar(100)

 
 OPEN BackupCursor  
 FETCH NEXT FROM BackupCursor INTO @Db_name  
  
 WHILE (@@FETCH_STATUS <> -1)  
 BEGIN  
 
 -- Backup code
declare @Backup_Path Varchar(500) = '\\asinetwork.local\Backups\SQL Backups 2\PRD\asi-sqlPcn1-09\RECOVERY\ADsMigrationJan2017'

DECLARE @fileName VARCHAR(400)  = @Backup_Path +'\'+ replace(@@servername, '\','_' ) + '_' + @Db_name+ '_' + 'FULL'+ '_' + LEFT(CONVERT(VARCHAR,getdate(), 120), 10) 
+'.BAK'   -- filename for backup

DECLARE @sqlCommand varchar(1000)
SET @sqlCommand = 'BACKUP DATABASE ['+ @Db_name+'] TO DISK ='+   ''''+@fileName+ ''' WITH COPY_ONLY, CHECKSUM, INIT,COMPRESSION, STATS = 10;'

  EXEC (@sqlCommand)
    
    RESTORE  verifyonly from disk = @fileName
	print 'Backup file path is '+@fileName
  
 FETCH NEXT FROM BackupCursor INTO @Db_name  
 END  
 -- Close and deallocate the cursor  
 CLOSE BackupCursor  
 DEALLOCATE BackupCursor  




--Restore latest backups on destination servers
--Restore latest backups on destination servers
SET NOCOUNT ON;

-- Declare cusrsor toinclude multiple DBs
DECLARE Restorecursor CURSOR FOR
SELECT  name FROM sys.databases
WHERE name NOT IN
('master', 'msdb', 'touchy')

-- Declare variable to hold DB names from cursor
DECLARE @db_name sysname

-- Open cursor
OPEN Restorecursor
FETCH NEXT FROM Restorecursor INTO @Db_name

WHILE (@@FETCH_STATUS <> -1)
BEGIN
  DECLARE @tmp TABLE ( RestorePart varchar(2000), FilePart varchar(max)   )

-- Insert restore statement in temp table for current DB in curosr  
     INSERT @tmp
      SELECT 'Restore database ' + s.[database_name] +' 
       From Disk = ''' + Replace (replace (B.[physical_device_name], 'SQL Backups 2', 'SQL Backups 2'), 'DROPOFF', 'RECOVERY') + '''
       with replace, keep_cdc, recovery, stats =1 ' as RestorePart    , 
       '      , Move ''' + f.[logical_name] + ''''
       + ' TO ''' + f.[physical_name] + '''' as FilePart
         FROM [msdb].[dbo].[backupset] S
         inner join [msdb].[dbo].[backupfile] F
                     on S.backup_set_id = f.backup_set_id
         inner join [msdb].[dbo].[backupmediafamily] B
                     on s.media_set_id = b.media_set_id
      WHERE s.type = 'd'
      AND s.database_name = @Db_name
      AND s.backup_start_date = (
							SELECT MAX(s.backup_start_date) FROM [msdb].[dbo].[backupset] s
							WHERE s.type = 'd'
							AND s.database_name = @Db_name
							)
      ORDER BY s.backup_set_id DESC

 -- Select combined stement from parts
	 SELECT DISTINCT RestorePart FROM @tmp
    UNION ALL
    SELECT FilePart FROM @tmp
    UNION ALL
    SELECT 'GO'

    DELETE FROM @tmp
 
  
  FETCH NEXT FROM Restorecursor INTO @Db_name
END
-- Close and deallocate the cursor  
CLOSE Restorecursor
DEALLOCATE Restorecursor
SET NOCOUNT OFF






--------------------------------------------------------------------------------------------------
--Run this script against primary replica to generate restore statement for the database..
--Restore statement will be genrereated for the latest full backup.
--Differential Backup/restore needs to be done separately.

Set nocount on 


Declare @DBName varchar(128)  

Declare @tmp table
	(StartDT datetime,
	 BKP_Type char(1),
	 RestorePart Varchar(2000),
	 FilePart varchar(max)
	)

DECLARE DB_Cursor CURSOR FOR 
	--select 'Set @dbname = ''' + name + '''' from sys.databases
	select  name from sys.databases
	where database_id>4
	order by 1;

open DB_Cursor;

FETCH NEXT FROM DB_Cursor into @dbname;
WHILE @@FETCH_STATUS = 0 
Begin
	--Set @dbname = 'webstats'  --Change databases name here.


	--Set @dbname = 'ADM_Support'
	--Set @dbname = 'bi_audit'
	--Set @dbname = 'bi_BO_Commentary'
	--Set @dbname = 'bi_cms'
	--Set @dbname = 'BI_Data_Factory'
	--Set @dbname = 'BI_Data_Staging'
	--Set @dbname = 'BI_Distributor_Datamart_US_ENU_EST'
	--Set @dbname = 'BI_EDW'
	--Set @dbname = 'BI_MDM'
	--Set @dbname = 'BI_Supplier_Datamart_US_ENU_EST'
	--Set @dbname = 'DQS_MAIN'
	--Set @dbname = 'DQS_PROJECTS'
	--Set @dbname = 'DQS_STAGING_DATA'
	--Set @dbname = 'mds'
	--Set @dbname = 'OPR_Support'
	--Set @dbname = 'TSqlToolbox'




	If exists (select name from sys.databases where name = @DBName)

	begin

		Insert @tmp 
		SELECT s.[backup_start_date] ,s.[type]
		,'Restore database ' + s.[database_name] +' 
		From Disk = ''' + Replace (replace (B.[physical_device_name], 'SQL Backups 2', 'SQL Backups 2'), 'DROPOFF', 'RECOVERY') + '''
		with Replace, recovery, stats =1 ' as RestorePart	, 
		'	, Move ''' + f.[logical_name] + ''''
		+ ' TO ''' + f.[physical_name] + '''' as FilePart
		  FROM [msdb].[dbo].[backupset] S
		  inner join [msdb].[dbo].[backupfile] F
				on S.backup_set_id = f.backup_set_id
		  inner join [msdb].[dbo].[backupmediafamily] B
				on s.media_set_id = b.media_set_id
		  where s.type ='D'
				and s.database_name = @DBName 
				and s.backup_start_date = 
					(select max(s.backup_start_date) 
						from [msdb].[dbo].[backupset] s
						where s.type ='D' and s.database_name = @dbname ) 
		  order by s.backup_set_id desc

		  --select * from @tmp

		  select distinct '-- Latest Full backup for database ' + @DBName + ' is from ' + cast(StartDT as varchar(20)) 
		  from @tmp

		Select '--Run this on DR replica for initial restore:'
		union all
		Select Distinct RestorePart as [--RestoreStatement]
		from @tmp
		union all
		select FilePart from @tmp
		Union all 
		Select 'GO		'

/*	
		--take a differential when ready:
		Select '--Run this on Primary replica for differential backup:
		backup database ' + @dbname  --SharedMaster_SN
		+ '
		to disk = ''\\asinetwork.local\Backups\SQL Backups 3\PRD\' + @@servername +  '\' + @dbname + '_diff.bak''
		with differential, stats = 1, init'

		Select '--Run this on DR replica to restore from differential backup:
		Restore database ' + @dbname  --SharedMaster_SN
		+ '
		FROM disk = ''\\asinetwork.local\Backups\SQL Backups 3\PRD\' + @@servername +  '\' + @dbname + '_diff.bak''
		with Replace, norecovery, stats =1'
*/
	End 
	ELSE
		Select 'Database ' + @DBName + ' does not exist on ' + @@Servername 
--set @DBName  = ''
delete @tmp
FETCH NEXT FROM DB_Cursor into @dbname;
--select @DBName
End
	Set nocount off

CLOSE DB_Cursor ;  
DEALLOCATE DB_Cursor ;  
-----------------------------------------------------------------------------------------------------









--Set databases to READ WRITE mode on destination server
ALTER DATABASE [AD_MgmtMaster] SET  MULTI_USER WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE [AD_MgmtMaster] SET  READ_WRITE WITH ROLLBACK IMMEDIATE
GO


--Map and Verify Orphaned users
EXECUTE master.sys.sp_MSforeachdb 'EXEC	 [dbo].[spFixOrphanUsers]	@DatabaseNM = [?]'

--Verify the orphaned users status with following commands
CREATE TABLE ##ORPHANUSER 
( 
DBNAME VARCHAR(100), 
USERNAME VARCHAR(100), 
CREATEDATE VARCHAR(100), 
USERTYPE VARCHAR(100) 
) 
 
EXEC SP_MSFOREACHDB' USE [?] 
INSERT INTO ##ORPHANUSER 
SELECT DB_NAME() DBNAME, NAME,CREATEDATE, 
(CASE  
WHEN ISNTGROUP = 0 AND ISNTUSER = 0 THEN ''SQL LOGIN'' 
WHEN ISNTGROUP = 1 THEN ''NT GROUP'' 
WHEN ISNTGROUP = 0 AND ISNTUSER = 1 THEN ''NT LOGIN'' 
END) [LOGIN TYPE] FROM sys.sysusers 
WHERE SID IS NOT NULL AND SID <> 0X0 AND ISLOGIN =1 AND 
SID NOT IN (SELECT SID FROM sys.syslogins)' 
 
SELECT dbname, ''''+username+''',' FROM ##ORPHANUSER  order by 2
 
DROP TABLE ##ORPHANUSER 



---------------------------------------------------------------------------------------------------------------
-- find real orphaned windows user
set nocount on;
declare @name varchar(128);
declare @t table (name varchar(128))
declare @tmp table (acct varchar(128), type varchar(20)
, privilege varchar(20), mlogin varchar(128)
, permission varchar(128));
 
declare @c cursor;
set @c = CURSOR for
select  dp.name 
from sys.database_principals dp
left join sys.server_principals sp
on dp.sid = sp.sid
where dp.type ='U' -- only for window users
and dp.principal_id > 4; -- 0..4 are system users which will be ignored
 
open @c;
fetch next from @c into @name;
while @@FETCH_STATUS = 0
begin
   begin try
      insert into @tmp exec xp_logininfo @name;
      if @@ROWCOUNT = 0 
         insert into @t (name) values (@name);
   end try
   
   begin catch
      insert into @t (name) values (@name);
   end catch 
   
   fetch next from @c into @name; 
end
select * from @t
-----------------------------------------------------------------------------------------------------------------


--Update DB properties

-- Set DB owner to sa
select suser_sname(owner_sid) , 'ALTER AUTHORIZATION ON DATABASE::'+name+'  TO sa;' 
from sys.databases 
where suser_sname(owner_sid) <> 'sa'

-- Set compatibility level
select 'ALTER DATABASE ['+name+'] SET COMPATIBILITY_LEVEL = 120;' 
from sys.databases 
where COMPATIBILITY_LEVEL <> 120

-- Set AutoCreateStats
select 'ALTER DATABASE ['+name+'] SET AUTO_CREATE_STATISTICS ON;' 
from sys.databases 
where is_auto_create_stats_on = 0

-- Set AutoUpdateStats
select 'ALTER DATABASE ['+name+'] SET AUTO_UPDATE_STATISTICS ON;' 
from sys.databases 
where is_auto_update_stats_on = 0
 
--Repoint Link Servers to new server
-- Get link server list
SELECT a.server_id,a.name, product, data_source, remote_name
FROM sys.Servers a
LEFT OUTER JOIN sys.linked_logins b ON b.server_id = a.server_id
LEFT OUTER JOIN sys.server_principals c ON c.principal_id = b.local_principal_id
where data_source like '%09%'





--Perform index maintenance and stats update in restored databases.

USE WEIT_Admin 
GO

select name,  'ALTER INDEX ALL ON [' + schema_name(schema_id)+'].['+name + '] REBUILD  ;'
from sys.objects where type = 'U'
order by schema_id
GO





 
-- Update Stats
USE AD_MgmtMaster 
GO

EXEC sp_updatestats
GO


 
--Add new databases in AG 
SELECT
AG.name AS [AvailabilityGroupName],
ISNULL(agstates.primary_replica, '') AS [PrimaryReplicaServerName],
dbcs.database_name AS [DatabaseName]
FROM master.sys.availability_groups AS AG
LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states as agstates
   ON AG.group_id = agstates.group_id
INNER JOIN master.sys.availability_replicas AS AR
   ON AG.group_id = AR.group_id
INNER JOIN master.sys.dm_hadr_availability_replica_states AS arstates
   ON AR.replica_id = arstates.replica_id AND arstates.is_local = 1
INNER JOIN master.sys.dm_hadr_database_replica_cluster_states AS dbcs
   ON arstates.replica_id = dbcs.replica_id
   where dbcs.database_name in (
'AD_MgmtMaster','AdSync','ASI_ADmaster','StatsStgArea'
)


--Free Cache if required 
DBCC FREEPROCCACHE;
DBCC FREESYSTEMCACHE ('ALL');



 
--Verify Job status 

SELECT NAME, enabled, date_created 
FROM   msdb.dbo.sysjobs 
WHERE  NAME IN 
( 
'AD_MAINT_DAILY',
'AD_MgmtMaster - Data Cleanup',
'AD_MgmtMaster - Migrate Ads to ASI_AdMaster',
'AD_MgmtMaster - Populate Missing AdHistory',
'AD_MgmtMaster - Process Ad Order Renewals',
'AD_MgmtMaster - Update Advertiser Counts per page',
'AD_Randomizer_Weekly',
'AdSync - Monitor Trigger Error',
'ASI_ADmaster_Load_POTD',
'Distribute ASI_Advertising',
'DM_Stats_Replace',
'RPRT_Daily_Reports',
'Start ASI_Advertising Distribution'


) 
ORDER  BY NAME 



--Verify Link Servers
SELECT name,  data_source
FROM sys.Servers 
where name in 
(
'ASI-SQL-43',
'ASI-SQLPCDG1-06',
'ASI-SQLPCDG1-14',
'ASI-SQLPCDG2-03',
'ASI-SQLPCDG2-04',
'ASI-SQLPCDG2-06',
'ASI-SQLPCDG2-07',
'ASI-SQLPCDG2-11',
'ASI-SQLPCN1-06',
'ASI-SQLPCN1-14',
'ASI-SQLPCN2-06',
'ASI-SQLUCDG2-11',
'BI_SERVER',
'MMS_SCTY_REMOTECALL'

)

 

