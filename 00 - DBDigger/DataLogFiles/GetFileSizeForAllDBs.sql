SELECT DbName 
      ,DbState 
      ,DbRecovery 
      ,[ROWS MB], [LOG MB], [FILESTREAM], [FULLTEXT] 
FROM ( 
        SELECT DB.name AS DbName 
              ,DB.state_desc AS DbState 
              ,DB.recovery_model_desc AS DBRecovery 
              ,MF.type_desc AS FileType 
              ,CONVERT(int, ROUND(MF.size * 0.0078125, 0)) AS SizeMB 
        FROM sys.databases AS DB 
             INNER JOIN sys.master_files AS MF 
                 ON DB.database_id = MF.database_id 
        WHERE HAS_DBACCESS(DB.name) = 1 
     ) AS DBS 
PIVOT (SUM(SizeMB) 
       FOR FileType IN ([ROWS MB], [LOG MB], [FILESTREAM], [FULLTEXT])  
      ) AS PVT 
ORDER BY DbName

/*------------------------------------------------------------------
Get each database file growth,read and write operations count on each db file,
IO count and IO wait time on each file.
-------------------------------------------------------------------*/
SELECT     
    d.name AS [Database],
    convert(varchar, getdate(), 107) as ForDate,
    f.physical_name AS [File], 
    convert(numeric(18,3),fs.size_on_disk_bytes / 1024 / 1024) AS [File Size (MB)],
    (convert(numeric(18,3),fs.num_of_bytes_read / 1024.0 / 1024.0)) [Total MB Read], 
    (convert(numeric(18,3),fs.num_of_bytes_written / 1024.0 / 1024.0)) AS [Total MB Written], 
    (convert(numeric(18,3),fs.num_of_reads + fs.num_of_writes)) AS [Total I/O Count], 
    fs.io_stall AS [Total I/O Wait Time (ms)]
FROM sys.dm_io_virtual_file_stats(default, default) AS fs
INNER JOIN sys.master_files f ON fs.database_id = f.database_id AND fs.file_id = f.file_id
INNER JOIN sys.databases d ON d.database_id = fs.database_id
order by d.name, fs.size_on_disk_bytes desc


/*------------------------------------------------------------------
Get each database drive and size
-------------------------------------------------------------------*/
SELECT     
    d.name AS [Database],
    substring(f.physical_name,1,2) AS [File], 
    convert(numeric(18,3),fs.size_on_disk_bytes / 1024 / 1024) AS [File Size (MB)]
    
FROM sys.dm_io_virtual_file_stats(default, default) AS fs
INNER JOIN sys.master_files f ON fs.database_id = f.database_id AND fs.file_id = f.file_id
INNER JOIN sys.databases d ON d.database_id = fs.database_id
where d.database_id > 4
order by f.physical_name,d.name, fs.size_on_disk_bytes desc



--- Get size of all DBs
SELECT DB_NAME(database_id), name, type_desc, physical_name, size, max_size, growth, is_percent_growth
FROM sys.master_files
order by database_id, name