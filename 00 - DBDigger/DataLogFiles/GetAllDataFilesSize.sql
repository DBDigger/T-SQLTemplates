SELECT DB_NAME(database_id) AS DatabaseName,
cast(sum( size* 8.0 / 1024)/1024 as DECIMAL(18,3))  [Size(GB)]
FROM sys.master_files
GROUP BY database_id
ORDER BY database_id