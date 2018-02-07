/*------------------------------------------------------------------
   If there are any databases in full recovery mode with no t-log backups,
   show the filesize of the according ldf.
------------------------------------------------------------------*/
SELECT 
      d.name AS [db_name]
  , f.name AS [ldf_name]
  , f.physical_name
  , f.size * 8 / 1024.00 AS [size_in_mb]
  , d.recovery_model_desc
FROM sys.master_files f
JOIN sys.databases d ON f.database_id = d.database_id
LEFT OUTER JOIN msdb.dbo.backupset b ON d.name = b.database_name AND b.type = 'L'
WHERE d.recovery_model IN (1, 2) AND b.type IS NULL AND d.database_id NOT IN (2, 3) AND f.type = 1 -- only show log files
ORDER BY f.size DESC


/*------------------------------------------------------------------
Get DBs with full recovery model but no TLog backups
-------------------------------------------------------------------*/
SELECT d.name, d.recovery_model_desc, case  when b.type is null then 'No' else 'Yes' end as IsTLogBackupTaken
FROM master.sys.databases d
LEFT OUTER JOIN msdb.dbo.backupset b ON d.name = b.database_name AND b.type = 'L'
WHERE d.recovery_model IN (1, 2) AND b.type IS NULL AND d.database_id NOT IN (2, 3)
  

/*------------------------------------------------------------------
Get backup paths
-------------------------------------------------------------------*/
SELECT TOP 100 physical_device_name,mirror FROM msdb.dbo.backupmediafamily ORDER BY media_set_id DESC


/*------------------------------------------------------------------
Get last backup date for each database
-------------------------------------------------------------------*/
SELECT d.name, MAX(b.backup_finish_date) AS last_backup_finish_date
FROM master.sys.databases d
LEFT OUTER JOIN msdb.dbo.backupset b ON d.name = b.database_name AND b.type = 'D'
WHERE d.database_id NOT IN (2, 3)  -- Bonus points if you know what that means
GROUP BY d.name
ORDER BY 2 DESC

/*------------------------------------------------------------------

-- Backup Status 
-------------------------------------------------------------------*/
SELECT DB.name AS DatabaseName 
      ,MAX(DB.recovery_model_desc) AS RecModel 
      ,MAX(BS.backup_start_date) AS LastBackup 
      ,MAX(CASE WHEN BS.type = 'D' 
                THEN BS.backup_start_date END) 
       AS LastFull 
      ,SUM(CASE WHEN BS.type = 'D' 
                THEN 1 END) 
       AS CountFull 
      ,MAX(CASE WHEN BS.type = 'L' 
                THEN BS.backup_start_date END) 
       AS LastLog 
      ,SUM(CASE WHEN BS.type = 'L' 
                THEN 1 END) 
       AS CountLog 
      ,MAX(CASE WHEN BS.type = 'I' 
                THEN BS.backup_start_date END) 
       AS LastDiff 
      ,SUM(CASE WHEN BS.type = 'I' 
                THEN 1 END) 
       AS CountDiff 
      ,MAX(CASE WHEN BS.type = 'F' 
                THEN BS.backup_start_date END) 
       AS LastFile 
      ,SUM(CASE WHEN BS.type = 'F' 
                THEN 1 END) 
       AS CountFile 
      ,MAX(CASE WHEN BS.type = 'G' 
                THEN BS.backup_start_date END) 
       AS LastFileDiff 
      ,SUM(CASE WHEN BS.type = 'G' 
                THEN 1 END) 
       AS CountFileDiff 
      ,MAX(CASE WHEN BS.type = 'P' 
                THEN BS.backup_start_date END) 
       AS LastPart 
      ,SUM(CASE WHEN BS.type = 'P' 
                THEN 1 END) 
       AS CountPart 
      ,MAX(CASE WHEN BS.type = 'Q' 
                THEN BS.backup_start_date END) 
       AS LastPartDiff 
      ,SUM(CASE WHEN BS.type = 'Q' 
                THEN 1 END) 
       AS CountPartDiff 
FROM sys.databases AS DB 
     LEFT JOIN 
     msdb.dbo.backupset AS BS 
         ON BS.database_name = DB.name 
WHERE ISNULL(BS.is_damaged, 0) = 0 -- exclude damaged backups          
GROUP BY DB.name 
ORDER BY DB.name;



SELECT  distinct
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
   msdb.dbo.backupset.database_name,  
   msdb.dbo.backupset.backup_start_date,  
   msdb.dbo.backupset.backup_finish_date,
   datediff(mi, msdb.dbo.backupset.backup_start_date, msdb.dbo.backupset.backup_finish_date) BackupTime,
   CASE msdb..backupset.type  
       WHEN 'D' THEN 'Database'  
       WHEN 'L' THEN 'Log'  
       WHEN 'I' THEN 'Differential'
   END AS backup_type,  
   (((msdb.dbo.backupset.backup_size)/1024)/1024)/1024 as BackupSizeinGB
FROM   msdb.dbo.backupmediafamily  
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE  (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 112) between '20140901' and '20140930')  
and database_name = 'wmpoperatorusage'
ORDER BY  
   msdb.dbo.backupset.database_name, 
   msdb.dbo.backupset.backup_finish_date
