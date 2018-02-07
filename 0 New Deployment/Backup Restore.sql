-- Get backup info from backup file
RESTORE HEADERONLY FROM DISK = '\\192.168.1.102\DBA Backups\CRMBackup\NYCHUBCRMDBCLU_M2MHUB_CRM_FULL_20150531_010128.bak'
GO

-- Get restore size
restore filelistonly from disk = '\\192.168.1.102\DBA Backups\From-NonMatrix\DB Backups from DI Production\AfterShrinkBackups\M2MHUB_CRM20150408_AfterShrink.bak'