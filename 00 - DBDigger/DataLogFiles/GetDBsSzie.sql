-- Get Size of all databases
SELECT DB_NAME(database_id) AS DatabaseName, 
cast(sum( size* 8.0 / 1024)/1024 as DECIMAL(18,3))  [Size(GB)]
FROM sys.master_files
GROUP BY database_id
ORDER BY database_id


-- Get Size of all database in data and log category
SELECT DB_NAME(database_id) AS DatabaseName, type_desc,  
cast(sum( size* 8.0 / 1024)/1024 as DECIMAL(18,3))  [Size(GB)]
FROM sys.master_files
GROUP BY database_id, type_desc
ORDER BY database_id, type_desc DESC


-- Get Size of all data and log files
SELECT DB_NAME(database_id) AS DatabaseName, type_desc,  name, physical_name,
cast( (size* 8.0 / 1024)/1024 as DECIMAL(18,3))  [Size(GB)]
FROM sys.master_files
-- WHERE DB_NAME(database_id) = 'DBToFiletr'
ORDER BY database_id, type_desc DESC, name