-- Get Size of all data and log files  
 SELECT DB_NAME(database_id) AS DatabaseName, type_desc, name, physical_name,  
 cast( (size* 8.0 / 1024)/1024 as DECIMAL(18,3)) [Size(GB)]  
 FROM sys.master_files  
  WHERE physical_name like 'F:%'  
 ORDER BY 5 desc 

-- get data file space and locations
SELECT b.groupname AS 'File Group'
	,a.NAME
	,physical_name
	,CONVERT(INT, a.Size / 128.000, 2) AS [Currently Allocated Space (MB)]
	,CONVERT(INT, FILEPROPERTY(a.NAME, 'SpaceUsed') / 128.000, 2) AS [Space Used (MB)]
	,CONVERT(INT, a.max_Size / 128.000, 2) [Maximum Space (MB)]
	,CASE 
		WHEN a.IS_PERCENT_GROWTH = 0
			THEN CONVERT(VARCHAR, CONVERT(DECIMAL(15, 2), ROUND(a.growth / 128.000, 2))) + ' MB'
		ELSE CONVERT(VARCHAR, a.growth) + ' PERCENT'
		END [Growth]
	,CONVERT(INT, (a.Size - FILEPROPERTY(a.NAME, 'SpaceUsed')) / 128.000, 2) AS [Available Space (MB)]
	,(CONVERT(INT, ROUND((a.Size - FILEPROPERTY(a.NAME, 'SpaceUsed')) / 128.000, 2)) * 100) / (CONVERT(INT, ROUND(a.Size / 128.000, 2))) AS PercentFree
FROM sys.database_files a(NOLOCK)
LEFT OUTER JOIN sysfilegroups b(NOLOCK) ON a.data_space_id = b.groupid
ORDER BY PercentFree




DBCC SHRINKFILE (N'ITS_DB_ss_log' , 200)
GO



-- Get files detail on a drive
DECLARE @command VARCHAR(5000)   
DECLARE @DBInfo TABLE   
( ServerName VARCHAR(100),   
DatabaseName VARCHAR(100),
logicalfName varchar(100),   
PhysicalFileName NVARCHAR(520),   
FileSizeMB DECIMAL(10,2),   
SpaceUsedMB DECIMAL(10,2),   
FreeSpaceMB DECIMAL(10,2), 
FreeSpacePct varchar(8) 
) 

SELECT @command = 'Use [' + '?' + '] SELECT   
@@servername as ServerName,   
' + '''' + '?' + '''' + ' AS DatabaseName  ,name , filename 
    , convert(decimal(12,2),round(a.size/128.000,2)) as FileSizeMB 
    , convert(decimal(12,2),round(fileproperty(a.name,'+''''+'SpaceUsed'+''''+')/128.000,2)) as SpaceUsedMB 
    , convert(decimal(12,2),round((a.size-fileproperty(a.name,'+''''+'SpaceUsed'+''''+'))/128.000,2)) as FreeSpaceMB, 
    CAST(100 * (CAST (((a.size/128.0 -CAST(FILEPROPERTY(a.name,' + '''' + 'SpaceUsed' + '''' + ' ) AS int)/128.0)/(a.size/128.0)) AS decimal(4,2))) AS varchar(8)) + ' + '''' + '%' + '''' + ' AS FreeSpacePct 
from dbo.sysfiles a
where a.filename like ''F:%''' 

INSERT INTO @DBInfo 
EXEC sp_MSForEachDB @command   

SELECT * from @DBInfo order by 7 desc


-- Get shrink commands for a DB
DECLARE @MB_to_Leave int
SELECT @MB_to_Leave = 1000
SELECT DB_NAME() AS DbName,
       name AS FileName,
       physical_name,
       SIZE/128 AS CurrentSizeMB,
            CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128 AS UsedSpaceMB,
            SIZE/128 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128 AS FreeSpaceMB,
                 (1.0-(CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0)/(SIZE/128))*100 AS [% FreeSpace],
                 'DBCC SHRINKFILE (N''' + name + ''' , ' + cast(CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128 + @MB_to_Leave AS varchar(100))+ ') 
 go' AS ShrinkCommand
FROM sys.database_files
WHERE physical_name LIKE 'F:%'
ORDER BY 6 DESC