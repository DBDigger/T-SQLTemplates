SELECT	SERVERPROPERTY('ServerName') AS [SQLServer],
	--@@microsoftversion/0x01000000 AS [MajorVersion],
	SERVERPROPERTY('ProductVersion') AS [VersionBuild],
	SERVERPROPERTY('ProductLevel') AS [Product],
	SERVERPROPERTY ('Edition') AS [Edition],
	SERVERPROPERTY('IsIntegratedSecurityOnly') AS [IsWindowsAuthOnly],
	SERVERPROPERTY('IsClustered') AS [IsClustered],
	[cpu_count] AS [CPUs],
	[physical_memory_in_bytes]/1048576 AS [RAM (MB)]
FROM	[sys].[dm_os_sys_info]


-- server installation date
--use dbo.syslogins to make this compatible with SQL Server 2000
USE [master]
GO
SELECT	[createdate] AS 'SQL Install Date'
FROM	[sys].[syslogins]
WHERE	[sid] = 0x010100000000000512000000 --NT AUTHORITY\SYSTEM
GO