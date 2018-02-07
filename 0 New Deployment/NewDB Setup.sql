

select name, suser_sname(owner_sid), compatibility_level, is_auto_shrink_on, collation_name, recovery_model_desc,page_verify_option_desc, is_auto_create_stats_on, is_auto_update_stats_on,  is_broker_enabled, is_trustworthy_on
from sys.databases
order by database_id

-- Set DB owner to sa
select suser_sname(owner_sid) , 'ALTER AUTHORIZATION ON DATABASE::'+name+'  TO sa;' from sys.databases where suser_sname(owner_sid) <> 'sa'

-- Set compatibility level
select 'ALTER DATABASE ['+name+'] SET COMPATIBILITY_LEVEL = 120;' from sys.databases where COMPATIBILITY_LEVEL <> 120

--Set recovery model
select 'ALTER DATABASE ['+name+'] SET RECOVERY SIMPLE WITH NO_WAIT;' from sys.databases where recovery_model_desc <> 'SIMPLE'

-- Set AutoCreateStats
select 'ALTER DATABASE ['+name+'] SET AUTO_CREATE_STATISTICS ON;' from sys.databases where is_auto_create_stats_on = 0

-- Set AutoUpdateStats
select 'ALTER DATABASE ['+name+'] SET AUTO_UPDATE_STATISTICS ON;' from sys.databases where is_auto_update_stats_on = 0



ALTER DATABASE CDC_DB SET PAGE_VERIFY CHECKSUM  WITH NO_WAIT;
GO

SELECT name, description FROM sys.fn_helpcollations() where name in ('Latin1_General_CI_AS','SQL_Latin1_General_CP1_CI_AS','Latin1_General_CI_AS_KS_WS')


-- Make sa owner of DB
ALTER AUTHORIZATION ON DATABASE::PorthosWyless_WatchDog_QA TO sa
GO

-- Enable SB
ALTER DATABASE PorthosWyless_WatchDog_QA SET NEW_BROKER WITH ROLLBACK IMMEDIATE
GO

--Enabling service broker
USE master
ALTER DATABASE PorthosWyless_WatchDog_QA SET ENABLE_BROKER
GO

-- Set Trustworthy ON
ALTER DATABASE PorthosWyless_WatchDog_QA SET TRUSTWORTHY ON
GO


-- Verify
select name,is_broker_enabled from sys.databases where is_broker_enabled = 1

-- If already enable message  but not shown
ALTER DATABASE PorthosTMO_billing_qa SET DISABLE_BROKER
ALTER DATABASE PorthosTMO_billing_qa SET NEW_BROKER

-- Clear SB data 
ALTER DATABASE [msdb] SET NEW_BROKER WITH ROLLBACK IMMEDIATE;

-- Enable CLR
EXEC SP_CONFIGURE 'show advanced options' , '1';
GO
RECONFIGURE;
GO
EXEC SP_CONFIGURE 'clr enabled' , '1'
GO
RECONFIGURE;
GO

-- Enable trustworthy
USE master
ALTER DATABASE PorthosTMO_billing_dev SET TRUSTWORTHY ON



 -- Remove all replication settings from publisher
 sp_removedbreplication 'PorthosTMO_CRM_qa'
 go
 
 -- Check in distribution
 select * from Distribution.dbo.MSpublications
 
 
 -- Dropping the distribution databases
use master
exec sp_dropdistributiondb @database = N'distribution'
GO

/****** Uninstalling the server as a Distributor. Script Date: 6/12/2014 4:33:33 AM ******/
use master
exec sp_dropdistributor @no_checks = 1, @ignore_distributor = 1
GO


 
 -- Else do this if there are issues

 USE MASTER
GO
ALTER DATABASE distribution SET OFFLINE
GO
DROP DATABASE distribution
GO


-- change collation
USE [master]
GO
ALTER DATABASE [WatchDog_ss] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO

Alter Database WatchDog_ss Collate SQL_Latin1_General_CP1_CI_AS
GO

ALTER DATABASE [WatchDog_ss] SET  MULTI_USER WITH ROLLBACK IMMEDIATE
GO

SELECT 'update '+table_schema+'.'+table_name+' set '+column_name+' =   replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace('+column_name+',''a'',''b''),''e'',''r''),''i'',''m''),''o'',''y''),''u'',''s''),''m'',''z''),''1'',''2''),''2'',''3''),''3'',''4''),''4'',''5''),''5'',''6''),''6'',''7''),''7'',''8''),''8'',''9''),''9'',''1'')'
,table_schema+'.'+table_name, column_name, data_type, character_maximum_length
FROM INFORMATION_SCHEMA.COLUMNS
where data_type in ('varchar','nvarchar')
and (column_name like '%name%'
or column_name like '%phone%'
or column_name like '%fax%'
or column_name like '%ban%'
or column_name like '%address%'
)
order by character_maximum_length