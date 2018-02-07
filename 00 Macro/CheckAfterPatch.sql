:Connect ASI-SQLDS-15
SELECT  @@servername, sqlserver_start_time 
 ,SERVERPROPERTY ('ProductVersion') ProductVersion,SERVERPROPERTY ('ResourceLastUpdateDateTime') ResourceLastUpdateDateTime
 ,SERVERPROPERTY ('ResourceVersion') ResourceVersion ,SERVERPROPERTY ('ServerName') ServerName
 ,SERVERPROPERTY ('Edition') Edition ,SERVERPROPERTY ('EngineEdition') EngineEdition
FROM sys.dm_os_sys_info
GO