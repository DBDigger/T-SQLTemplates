--sp_whoisactive

SELECT s.database_name
	,cast(s.backup_size / 1000000000 AS int)  AS [bkSize (GB)]
	,DATEDIFF(HOUR, s.backup_start_date, s.backup_finish_date) as [TimeTaken(Hours)]
	,s.backup_start_date,backup_finish_date
	,CASE s.[type]
		WHEN 'D'
			THEN 'Full'
		WHEN 'I'
			THEN 'Differential'
		WHEN 'L'
			THEN 'Transaction Log'
		END AS BackupType
	,first_lsn, last_lsn, last_lsn - first_lsn as LSNDiff
FROM msdb.dbo.backupset s
INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
WHERE s.database_name = 'wmpoperatorusage'
ORDER BY backup_start_date desc
	,backup_finish_date


	-- Get backup info from backup file
RESTORE HEADERONLY FROM DISK = '\\192.168.1.102\DBA Backups\CRMBackup\NYCHUBCRMDBCLU_M2MHUB_CRM_FULL_20150531_010128.bak'
GO

-- Get restore size
restore filelistonly from disk = '\\192.168.1.102\DBA Backups\From-NonMatrix\DB Backups from DI Production\AfterShrinkBackups\M2MHUB_CRM20150408_AfterShrink.bak'