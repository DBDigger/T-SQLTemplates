USE DBAServices;
EXECUTE dbo.DatabaseIntegrityCheck
@Databases = 'wmp'
--, @CheckCommands = 'CHECKDB'
--, @CheckCommands = 'CHECKALLOC'
--, @CheckCommands = 'CHECKCATALOG'
 , @CheckCommands = 'CHECKFILEGROUP'
 , @FileGroups = 'wmp.PRIMARY'
 --, @PhysicalOnly = 'Y'
 , @ExtendedLogicalChecks = 'Y'
 --, @NoIndex = 'Y'
 --, @CheckCommands = 'CHECKTABLE'
 --, @Objects = 'ALL_OBJECTS, -AdventureWorks.Production.Product'
GO

USE DBAServices;
EXECUTE dbo.DatabaseIntegrityCheck
@Databases = 'SYSTEM_DATABASES',
@CheckCommands = 'CHECKDB'
GO

-- Rectify the storage if error occurs in DBCC
DBCC UPDATEUSAGE (M2MHub_Billing) WITH COUNT_ROWS; 
GO

-- Get file groups info 
SELECT db_name() as DBName, b.groupname AS 'File Group' ,a.NAME, physical_name
	,CONVERT(INT, a.Size / 128.000, 2) AS [Currently Allocated Space (MB)]
	,CONVERT(INT, FILEPROPERTY(a.NAME, 'SpaceUsed') / 128.000, 2) AS [Space Used (MB)]
FROM sys.database_files a(NOLOCK)
LEFT OUTER JOIN sysfilegroups b(NOLOCK) ON a.data_space_id = b.groupid
ORDER BY [File Group], [Space Used (MB)] desc