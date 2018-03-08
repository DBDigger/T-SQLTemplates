--Get the current database files Logical Name and Physical Location
USE master;
SELECT name as LogicalFileName ,'ALTER DATABASE ['+DB_NAME(database_id)+'] MODIFY FILE  ( NAME = '+name+' , FILENAME = '''+physical_name+''');' AS Stmt, physical_name AS FileLocation
, state_desc AS Status 
FROM sys.master_files 
WHERE database_id = DB_ID('M2MHUB_Billing');

--Take the Database offline
ALTER DATABASE M2MHUB_Billing SET OFFLINE WITH ROLLBACK IMMEDIATE
GO

USE master;
SELECT 'move /Y "'+physical_name +'" "'+ replace(physical_name,'F:','N:')+'"',name as LogicalFileName ,'ALTER DATABASE ['+DB_NAME(database_id)+'] MODIFY FILE  ( NAME = '+name+' , FILENAME = '''+physical_name+''');' AS Stmt, physical_name AS FileLocation
, state_desc AS Status 
FROM sys.master_files 
WHERE database_id = DB_ID('BI_EDW')
and name in (

-- Modify the FILENAME to new location for every file moved. Only one file can be moved at a time using ALTER DATABASE.
USE master
GO
ALTER DATABASE [M2MHUB_Billing] MODIFY FILE  ( NAME = wmpoperatorusage_ss , FILENAME = 'D:\SQLServerDatabases\M2MHUB_Billing\M2MHUB_Billing.mdf');



--Set the database ONLINE
ALTER DATABASE M2MHUB_Billing SET ONLINE;

-- verify the database files Physical location
SELECT name AS FileName, physical_name AS CurrentFileLocation, state_desc AS Status 
FROM sys.master_files 
WHERE database_id = DB_ID('M2MHUB_Billing');

