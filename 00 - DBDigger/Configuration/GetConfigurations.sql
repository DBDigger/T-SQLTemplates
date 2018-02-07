/*------------------------------------------------------------------
      Check for TDE
------------------------------------------------------------------*/
SELECT d.name, k.* 
  FROM sys.dm_database_encryption_keys k
  INNER JOIN sys.databases d ON k.database_id = d.database_id
  ORDER BY d.name
  

/*------------------------------------------------------------------
      Are any of the databases using features that are Enterprise Edition only?
      If a database is using something like partitioning, compression, or
      Transparent Data Encryption, then I won't be able to restore it onto a
      Standard Edition server.
------------------------------------------------------------------*/
EXEC dbo.sp_MSforeachdb 'SELECT ''[?]'' AS DatabaseName, * FROM [?].sys.dm_db_persisted_sku_features'



/*------------------------------------------------------------------
      Check for startup stored procedures.  These live in the master database, and
      they run automatically when SQL Server starts up.  
 ------------------------------------------------------------------*/
USE master
GO
SELECT *
FROM master.INFORMATION_SCHEMA.ROUTINES
WHERE OBJECTPROPERTY(OBJECT_ID(ROUTINE_NAME),'ExecIsStartup') = 1 



/*------------------------------------------------------------------
      Server version and edition
 ------------------------------------------------------------------*/
SELECT
      SERVERPROPERTY ('ComputerNamePhysicalNetBIOS') AS netbios_name
      ,@@SERVERNAME AS server_name
      ,REPLACE (CONVERT (NVARCHAR (128), SERVERPROPERTY ('Edition')),' Edition','') AS edition
      ,SERVERPROPERTY ('ProductVersion') AS version
      ,SERVERPROPERTY ('ProductLevel') AS [level]
      
      


/*------------------------------------------------------------------
      I don't like any surprises in the system databases.  Let's check the list of
      objects in master and model.  I don't want to see any rows returned from
      these four queries - if there are objects in the system databases, I want to
      ask why, and get them removed if possible.
------------------------------------------------------------------*/
 SELECT * FROM master.sys.tables WHERE name NOT IN ('spt_fallback_db', 'spt_fallback_dev', 'spt_fallback_usg', 'spt_monitor', 'spt_values', 'MSreplication_options')
SELECT * FROM master.sys.procedures WHERE name NOT IN ('sp_MSrepl_startup', 'sp_MScleanupmergepublisher')
SELECT * FROM model.sys.tables
SELECT * FROM model.sys.procedures




/* ------------------------------------------------------------------
      SQL Server 2008 & above only - is auditing enabled?  If so, it might be
      writing to an audit path that will fill up, or the server might be set to
      stop if the file path isn't available.  Let's see if there's any audits.
------------------------------------------------------------------*/
SELECT * FROM sys.dm_server_audit_status
/*
      Server settings can be made outside of sp_configure too.  The easiest way
      to check out the service settings are to go into Start, Programs,
      Microsoft SQL Server, Configuration Tools, SQL Server Configuration Manager.
      Go there now, and drill into SQL Server Services, then right-click on each
      service and hit Properties.  The advanced properties for the SQL Server
      service itself can hide some startup parameters.
 
      
      Next, check Instant File Initialization.  Take a note of the service account
      SQL Server is using, and then run secpol.msc.  Go into Local Policy, User
      Rights Assignment, Perform Volume Maintenance Tasks.  Double-click on that
      and add the SQL Server service account.  This lets SQL Server grow data
      files instantly.  For more info:
      http://www.sqlskills.com/blogs/kimberly/post/Instant-Initialization-What-Why-and-How.aspx
 
 
      There's a few more server-level things I like to check, but I use the SSMS
      GUI.  Go into Server Objects, and check out what's under Endpoints, Linked
      Servers, Resource Governor, and Triggers.  If any of these objects exist, you
      want to research to find out what they're being used for.
*/
SELECT * FROM sys.endpoints WHERE type <> 2
SELECT * FROM sys.resource_governor_configuration
SELECT * FROM sys.server_triggers
SELECT * FROM sys.servers