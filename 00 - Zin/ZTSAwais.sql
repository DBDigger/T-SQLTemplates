USE [master]
GO
CREATE LOGIN [Awais.Ahmad] WITH PASSWORD=N'sql123!@#' MUST_CHANGE, DEFAULT_DATABASE=[master], CHECK_EXPIRATION=ON, CHECK_POLICY=ON
GO
EXEC master..sp_addsrvrolemember @loginame = N'Awais.Ahmad', @rolename = N'processadmin'
GO
USE [DBAServices]
GO
CREATE USER [Awais.Ahmad] FOR LOGIN [Awais.Ahmad]
GO
USE [master]
GO
CREATE USER [Awais.Ahmad] FOR LOGIN [Awais.Ahmad]
GO
USE master
GO
GRANT EXECUTE ON xp_sqlagent_enum_jobs TO [Awais.Ahmad];
GRANT EXECUTE ON xp_sqlagent_is_starting TO [Awais.Ahmad];
GRANT EXECUTE ON xp_sqlagent_notify TO [Awais.Ahmad];
GRANT ALTER ANY LOGIN TO [Awais.Ahmad];
GRANT ALTER TRACE TO [Awais.Ahmad];
GRANT VIEW SERVER STATE TO [Awais.Ahmad];
USE [msdb]
GO
CREATE USER [Awais.Ahmad] FOR LOGIN [Awais.Ahmad]
GO
USE [msdb]
GO
EXEC sp_addrolemember N'SQLAgentOperatorRole', N'Awais.Ahmad'
GO
