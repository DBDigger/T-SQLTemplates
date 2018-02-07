USE [master]
GO

CREATE LOGIN [WinSrv_SFTP_CDRPSetup]
	WITH PASSWORD = N'sql123!@#' MUST_CHANGE
		,DEFAULT_DATABASE = [wmpoperatorusage_nsisUAT]
		,CHECK_EXPIRATION = ON
		,CHECK_POLICY = ON
GO

USE [wmpoperatorusage_nsisUAT]
GO

CREATE USER [WinSrv_SFTP_CDRPSetup]
FOR LOGIN [WinSrv_SFTP_CDRPSetup]
GO

USE [wmpoperatorusage_nsisUAT]
GO

EXEC sp_addrolemember N'db_datareader'
	,N'WinSrv_SFTP_CDRPSetup'
GO

USE [wmpoperatorusage_nsisUAT]
GO

EXEC sp_addrolemember N'db_datawriter'
	,N'WinSrv_SFTP_CDRPSetup'
GO

USE [wmpoperatorusage_nsisUAT]
GO

EXEC sp_addrolemember N'view_Def'
	,N'WinSrv_SFTP_CDRPSetup'
GO

USE [wmpoperatorusage_nsisUAT]
GO

GRANT EXECUTE
	TO WinSrv_SFTP_CDRPSetup
GO

ELECT state_desc, permission_name, 'ON', class_desc,
SCHEMA_NAME(major_id),
'TO', USER_NAME(grantee_principal_id)
FROM sys.database_permissions AS Perm
JOIN sys.database_principals AS Prin
ON Perm.major_ID = Prin.principal_id AND class_desc = 'SCHEMA'
WHERE major_id = SCHEMA_ID('zts')
AND grantee_principal_id = user_id('Amna.Elahi')

ALTER USER [Amna.Elahi] WITH DEFAULT_SCHEMA=[zts]
GO
GRANT SELECT ON SCHEMA::zts TO [Amna.Elahi]

GRANT insert ON SCHEMA::zts TO [Amna.Elahi]

GRANT update ON SCHEMA::zts TO [Amna.Elahi]

GRANT delete ON SCHEMA::zts TO [Amna.Elahi]
GRANT execute ON SCHEMA::zts TO [Amna.Elahi]
GRANT ALTER ON SCHEMA::zts TO [Amna.Elahi]
GRANT view definition ON SCHEMA::zts TO [Amna.Elahi]
GRANT create table TO [Amna.Elahi]
GRANT create procedure TO [Amna.Elahi]