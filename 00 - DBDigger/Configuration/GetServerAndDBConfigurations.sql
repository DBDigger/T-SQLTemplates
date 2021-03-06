USE master
GO

SET NOCOUNT ON 
GO

--setup temp tables and variables 
CREATE TABLE #Instance (value VARCHAR(50),data VARCHAR(50)) 
CREATE TABLE #AuditData (value VARCHAR(50),data VARCHAR(100)) 
CREATE TABLE #msver (indx INT, name VARCHAR(50), internal_value INT, character_value VARCHAR(255)) 
CREATE TABLE #WinverSP (value    VARCHAR (255),data VARCHAR(255)) 
 
DECLARE @Instance VARCHAR(50) 
DECLARE @InstanceLoc VARCHAR(50) 
DECLARE @RegKey VARCHAR(255) 
DECLARE @CPUCount INT 
DECLARE @CPUID INT 
DECLARE @AffinityMask INT 
DECLARE @CPUList VARCHAR(50) 
DECLARE @InstCPUCount INT 
DECLARE @sql VARCHAR(255) 
DECLARE @Database VARCHAR(50) 
DECLARE @WINVERSP VARCHAR(255) 
 
INSERT INTO #msver EXEC xp_msver  
 
--get Windows server version and its service pack 
SET @RegKey = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion' 
INSERT INTO #WinverSP EXEC xp_regread 'HKEY_LOCAL_MACHINE',@regkey,'ProductName' 
INSERT INTO #WinverSP EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'CSDVersion' 
 
PRINT '' 
PRINT 'Windows Server version and Service pack values' 
SELECT CAST(value AS VARCHAR(50)) AS value,  
       CAST(data AS VARCHAR(50)) AS data  
  FROM #WinverSP 
 
--get instance location FROM registry 
SET @RegKey = 'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' 
 
INSERT INTO #Instance EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, @@servicename 
 
SELECT @InstanceLoc=data FROM #Instance WHERE VALUE = @@servicename 
 
--get audit data FROM registry and insert into #AuditData 
 
SET @RegKey = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @InstanceLoc + '\Setup' 
 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'Edition' 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'SqlCluster' 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'SqlProgramDir' 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'SQLDataRoot' 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'SQLPath' 
 
SET @RegKey = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @InstanceLoc + '\MSSQLSERVER' 
 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'AuditLevel' 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'LoginMode' 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'DefaultData' 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'DefaultLog' 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'BackupDirectory' 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'NumErrorLogs' 
 
SET @RegKey = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @InstanceLoc + '\SQLServerAgent' 
 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'RestartSQLServer' 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'RestartServer' 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'UseDatabaseMail' 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'DatabaseMailProfile' 
 
SET @RegKey = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @InstanceLoc + '\MSSQLSERVER\SuperSocketNetLib\Tcp\IPAll' 
 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'TcpDynamicPorts' 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE', @RegKey, 'TcpPort' 
INSERT INTO #AuditData EXEC xp_regread 'HKEY_LOCAL_MACHINE','SOFTWARE\McAfee\VSCore\On Access Scanner\McShield\Configuration\Default', 'szExcludeExts' 
 
 
UPDATE #AuditData  
   SET value = 'Antivirusprofile' where  value = 'szExcludeExts' 
   
UPDATE #AuditData  
   SET data =   
      CASE  
         WHEN data = 0 THEN 'captures no logins' 
         WHEN data = 1 THEN 'captures only success login attempts' 
         WHEN data = 2 THEN 'captures only failed login attempts' 
         WHEN data = 3 THEN 'captures both success and failed login attempts' 
         ELSE data  
      END 
 WHERE value IN ('AuditLevel') 
 
UPDATE #AuditData  
   SET data =   
      CASE  
         WHEN data = 1 THEN 'Windows Authentication' 
         WHEN data = 2 THEN 'Mixed Mode Authentication' 
         ELSE data  
      END 
 WHERE value IN ('LoginMode') 
 
UPDATE #AuditData  
   SET data =   
      CASE  
         WHEN data = 0 THEN 'FALSE' 
         WHEN data = 1 THEN 'TRUE' 
         ELSE data  
      END 
 WHERE value IN ('RestartServer','RestartSQLServer','SqlCluster','UseDatabaseMail') 
 
--return results 
PRINT '' 
PRINT 'return SQL instance name' 
SELECT CAST(@@servicename AS VARCHAR(25)) AS instance 
 
PRINT '' 
PRINT 'return instance location' 
SELECT CAST(value AS VARCHAR(25)) AS instance,  
       CAST(data AS VARCHAR(25)) AS location  
  FROM #Instance 
 
PRINT '' 
PRINT 'return instance information' 
SELECT CAST(name AS VARCHAR(25)) AS name,  
       CAST(character_value AS VARCHAR(50)) AS value  
  FROM #msver 
 WHERE name in ('productname','productversion','platform','filedescription') 
 
PRINT '' 
PRINT 'return registry values' 
SELECT CAST(value AS VARCHAR(25)) AS value,  
       CAST(data AS VARCHAR(100)) AS data  
  FROM #AuditData 
 ORDER BY value 
 
PRINT '' 
PRINT 'server-wide collation' 
SELECT SERVERPROPERTY( 'Collation' ) AS Server_Default_Collation; 
 
PRINT '' 
PRINT 'check for system database files and sizes' 
 
DECLARE databases_cursor CURSOR FOR  
      SELECT name  
      FROM sysdatabases 
      WHERE name IN ('master','model','msdb','tempdb') 
      ORDER BY name 
 
OPEN databases_cursor 
FETCH NEXT FROM databases_cursor INTO @Database 
 
WHILE @@FETCH_STATUS = 0 
BEGIN 
       
      PRINT '   - ' + @Database 
      SET @sql = 'SELECT fileid, ' 
      SET @sql = @sql + 'CAST(name AS VARCHAR(25)) as name, ' 
      SET @sql = @sql + 'CAST(filename AS VARCHAR(75)) as filename, ' 
      SET @sql = @sql + '(size*8)/1024 as [size-mb], ' 
      SET @sql = @sql + 'maxsize as [max-8kb pages], growth ' 
      SET @sql = @sql + 'FROM ' + @Database + '..sysfiles ' 
      SET @sql = @sql + 'ORDER BY groupid DESC, name ASC ' 
 
      EXEC (@sql) 
 
      FETCH NEXT FROM databases_cursor INTO @Database 
    
END 
 
CLOSE databases_cursor 
DEALLOCATE databases_cursor 
 
PRINT '' 
PRINT 'check for user database files and sizes' 
 
DECLARE databases_cursor CURSOR FOR  
      SELECT name  
      FROM sysdatabases 
      WHERE name NOT IN ('master','model','msdb','questsoftware','litespeedlocal','tempdb') 
      ORDER BY name 
 
OPEN databases_cursor 
FETCH NEXT FROM databases_cursor INTO @Database 
 
IF @@FETCH_STATUS <> 0  
      PRINT '         <<No USER Databases>>' 
 
WHILE @@FETCH_STATUS = 0 
BEGIN 
       
      PRINT '   - ' + @Database 
      SET @sql = 'SELECT fileid, ' 
      SET @sql = @sql + 'CAST(name AS VARCHAR(25)) as name, ' 
      SET @sql = @sql + 'CAST(filename AS VARCHAR(75)) as filename, ' 
      SET @sql = @sql + '(size*8)/1024 as [size-mb], ' 
      SET @sql = @sql + 'maxsize as [max-8kb pages], growth ' 
      SET @sql = @sql + 'FROM ' + @Database + '..sysfiles ' 
      SET @sql = @sql + 'ORDER BY groupid DESC, name ASC ' 
 
      EXEC (@sql) 
 
      FETCH NEXT FROM databases_cursor INTO @Database 
    
END 
 
CLOSE databases_cursor 
DEALLOCATE databases_cursor 
 
--------------------- 
PRINT '' 
PRINT 'check to see if xp_cmdshell ,SQL Mail or Database Mail under Surface Area Configuration for Features' 
exec sp_configure 'show advanced options',1 
reconfigure with override 
 
create table #xp_cmd 
( 
name varchar(50), 
minvalue int, 
maxvalue int, 
config_value int, 
run_value int, 
) 
 
insert into #xp_cmd 
exec sp_configure 
 
select name,config_value from #xp_cmd where name in('xp_cmdshell','SQL Mail XPs','Database Mail XPs') 
 
exec sp_configure 'show advanced options',0 
reconfigure with override 
 
drop table #xp_cmd 
 
------------------ 
 
PRINT '' 
PRINT 'check to see if global groups were added' 
SELECT CAST(loginname AS VARCHAR(35)) AS loginname,  
       hasaccess,  
       isntname,  
       isntgroup,  
       sysadmin  
  FROM syslogins  
 WHERE name LIKE '%ds_s_amg_sqldba_l%' 
    OR name LIKE '%ds_wimmssqladmin_oa%' 
    OR name LIKE '%ds_wimmssqldba_ap%' 
    OR name LIKE '%ms sql admin%' 
    OR name LIKE '%mssqldba%' 
    OR sysadmin = 1 
    ORDER BY isntname, isntgroup, loginname 
     
PRINT '' 
PRINT 'check to see if builtin\administrators was removed' 
SELECT CAST(loginname AS VARCHAR(35)) AS loginname,  
       hasaccess,  
       isntname,  
       isntgroup,  
       sysadmin  
  FROM syslogins  
 WHERE name LIKE '%administrators%' 
 
PRINT '' 
PRINT 'check to see if NT AUTHORITY\SYSTEM was removed' 
SELECT CAST(loginname AS VARCHAR(35)) AS loginname,  
       hasaccess,  
       isntname,  
       isntgroup,  
       sysadmin  
  FROM syslogins  
 WHERE name LIKE '%SYSTEM%' 
 
PRINT '' 
PRINT 'check to see if dtsadmin and jobadmin roles were added (sql2000)' 
SELECT CAST(name AS VARCHAR(35)) AS name,  
       issqlrole  
  FROM msdb..sysusers  
 WHERE name LIKE 'dtsadminrole' 
    OR name LIKE 'jobadminrole' 
 
PRINT '' 
PRINT 'verify memory and CPU settings' 
SELECT CAST(description AS VARCHAR(50)) AS description,  
       CAST(value AS VARCHAR(50)) AS value 
  FROM sys.configurations 
 WHERE name IN ('awe enabled','max server memory (MB)','min server memory (MB)','priority boost') 
 ORDER BY name 
 
PRINT '' 
PRINT 'verify CPU affinity' 
 
SELECT @CPUCount = internal_value  
  FROM #msver  
 WHERE NAME = 'processorcount' 
 
SELECT @AffinityMask = CAST(value as int)  
  FROM sys.configurations  
 WHERE name = 'affinity mask' 
 
SET @CPUID = 0 
SET @InstCPUCount = 0 
SET @CPUList = '' 
 
IF @AffinityMask = 0 
      BEGIN 
            SET @InstCPUCount = @CPUCount 
            SET @CPUList = 'No affinity set - all CPUs available to instance' 
      END 
ELSE 
      BEGIN 
            WHILE(@CPUID <= @CPUCount - 1) 
                  BEGIN 
                        IF(@AffinityMask & POWER(2, @CPUID)) > 0 
                              BEGIN 
                                    SET @CPUList = @CPUList + 'CPU' + CAST(@CPUID AS VARCHAR(2)) + ' ' 
                                    SET @InstCPUCount = @InstCPUCount + 1 
                              END 
                        SET @CPUID = @CPUID + 1 
                  END 
      END 
 
PRINT 'Total CPU Count            = ' + cast (@CPUCount as varchar(2)) 
PRINT 'Instance CPU Count         = ' + cast (@InstCPUCount as varchar(2)) 
PRINT 'CPUs Assigned to Instance  = ' + @CPUList 
 
 
 
PRINT '' 
PRINT 'verify operators setup' 
SELECT id,  
       CAST(name AS VARCHAR(25)) AS name,  
       enabled,  
       CAST(email_address AS VARCHAR(100)) AS email_address,  
       CAST(pager_address AS VARCHAR(100)) AS pager_address  
  FROM msdb..sysoperators 
 
PRINT '' 
PRINT 'verify maintenance plans are scheduled and active' 
SELECT CAST(j.name AS VARCHAR(50)) AS name,  
       j.date_created,  
       j.date_modified,  
       j.enabled,  
       j.notify_level_email,  
       CAST(o1.name AS VARCHAR(25)) AS email_operator,  
--       CAST(o1.email_address AS VARCHAR(50)) AS email_address,  
       j.notify_level_page,   
       CAST(o2.name AS VARCHAR(25)) AS pager_operator 
--       CAST(o2.pager_address AS VARCHAR(50)) AS pager_address 
  FROM msdb.dbo.sysjobs_view j 
  LEFT JOIN msdb..sysoperators o1  
    ON j.notify_email_operator_id = o1.id 
  LEFT JOIN msdb..sysoperators o2  
    ON j.notify_page_operator_id = o2.id 
 ORDER BY j.name 
 
PRINT '' 
PRINT 'verify alerts were setup' 
SELECT CAST(a.name AS VARCHAR(50)) AS name,  
       CAST(a.event_source AS VARCHAR(20)) AS event_source,  
       a.event_category_id,  
       a.event_id,  
       a.message_id,  
       a.severity,  
       a.enabled,  
       CAST(o1.name AS VARCHAR(25)) AS email_operator,  
--       CAST(o1.email_address AS VARCHAR(100)) AS email_addr,  
       CAST(o2.name AS VARCHAR(25)) AS pager_operator,  
--       CAST(o2.pager_address AS VARCHAR(100)) AS pager_addr, 
       CAST(database_name AS VARCHAR(25)) AS database_name 
  FROM msdb..sysalerts a 
  LEFT JOIN msdb..sysnotifications n1 on a.id = n1.alert_id and n1.notification_method=1 
  LEFT JOIN msdb..sysnotifications n2 on a.id = n2.alert_id and n2.notification_method=2 
  LEFT JOIN msdb..sysoperators o1 on o1.id = n1.operator_id 
  LEFT JOIN msdb..sysoperators o2 on o2.id = n2.operator_id 
 
PRINT '' 
PRINT 'verify database mail was setup - list settings' 
SELECT CAST(name AS VARCHAR(25)) AS account_name,  
       CAST(description AS VARCHAR(25)) AS description 
  FROM msdb.dbo.sysmail_profile 
 ORDER BY name 
 
SELECT CAST(a.name AS VARCHAR(25)) AS account_name,  
       CAST(a.description AS VARCHAR(25)) AS description, 
       CAST(a.email_address AS VARCHAR(50)) AS email_address, 
       CAST(a.display_name AS VARCHAR(25)) AS display_name, 
       CAST(a.replyto_address AS VARCHAR(25)) AS replyto_address, 
       CAST(s.servertype AS VARCHAR(10)) AS servertype, 
       CAST(s.servername AS VARCHAR(25)) AS servername, 
       s.port, 
       CAST(s.username AS VARCHAR(20)) AS username, 
       s.use_default_credentials, 
       s.enable_ssl 
  FROM msdb.dbo.sysmail_account a 
  JOIN msdb.dbo.sysmail_server s ON a.account_id = s.account_id 
 
--clean up 
DROP TABLE #Instance 
DROP TABLE #AuditData 
DROP TABLE #msver 
DROP TABLE #WinverSP 
 
 
--================================= Verify IIS Services on server ================================ 
PRINT '' 
PRINT 'Verify IIS Services on server' 
declare @cdt int 
create table #net_data 
(descriptions varchar(100)) 
 
insert into #net_data exec master..xp_cmdshell 'net start' 
select @cdt=count(*) from #net_data where descriptions like '%IIS%' 
if @cdt > 0   
print 'IIS Services intsalled on the server ' 
else  
print 'NO IIS Services intsalled on the server ' 
 
drop table #net_data 
 
--================================= Verify Service account for Services for SQL Server ================================ 
PRINT '' 
PRINT 'Verify the processid for sql instance' 
 
create table #net_data1 
(descriptions varchar(200)) 
 
 
insert into #net_data1 exec master..xp_cmdshell 'sc qc MSSQLSERVER' 
insert into #net_data1 exec master..xp_cmdshell 'sc qc SQLSERVERAGENT' 
insert into #net_data1 exec master..xp_cmdshell 'sc qc msftesql' 
insert into #net_data1 exec master..xp_cmdshell 'sc qc sqlbrowser' 
select * from #net_data1 where descriptions like '%service_start_name%' 
drop table #net_data1 
 
 
--================================= Verify Linked servers ================================ 
PRINT '' 
PRINT 'Verify the Linked Server Details' 
 
SELECT ss.server_id  
          ,ss.name  
          ,'Server ' = Case ss.Server_id  
                            when 0 then 'Current Server'  
                            else 'Remote Server'  
                            end  
          ,ss.product  
          ,ss.provider  
          ,ss.catalog  
          ,'Local Login ' = case sl.uses_self_credential  
                            when 1 then 'Uses Self Credentials'  
                            else ssp.name  
                            end  
           ,'Remote Login Name' = sl.remote_name  
           ,'RPC Out Enabled'    = case ss.is_rpc_out_enabled  
                                   when 1 then 'True'  
                                   else 'False'  
                                   end  
           ,'Data Access Enabled' = case ss.is_data_access_enabled  
                                    when 1 then 'True'  
                                    else 'False'  
                                    end  
           ,ss.modify_date  
      FROM sys.Servers ss  
 LEFT JOIN sys.linked_logins sl  
        ON ss.server_id = sl.server_id  
 LEFT JOIN sys.server_principals ssp  
        ON ssp.principal_id = sl.local_principal_id 