SELECT
  'declare @filesize int;' + 'set @filesize = ' + CAST(CONVERT(int, a.Size / 128.000, 2) 
  + 500 AS varchar(10)) + '; WHILE @filesize > ' + CAST(CONVERT(int, a.Size / 128.000, 2) 
  + 1024 AS varchar(10)) + ' BEGIN; DBCC SHRINKFILE (N''' + a.NAME + 
  ''' , @filesize);  WAITFOR DELAY ''00:00:07'';  SET @filesize = @filesize - 1000; END GO' AS ShrinkLoop,
  b.groupname AS 'File Group',
  a.NAME,
  physical_name,
  CONVERT(int, a.Size / 128.000, 2) AS [Currently Allocated Space (MB)],
  CONVERT(int, FILEPROPERTY(a.NAME, 'SpaceUsed') / 128.000, 2) AS [Space Used (MB)],
  CONVERT(int, (a.Size - FILEPROPERTY(a.NAME, 'SpaceUsed')) / 128.000, 2) AS [Available Space (MB)],
  (CONVERT(int, ROUND((a.Size - FILEPROPERTY(a.NAME, 'SpaceUsed')) / 128.000, 2)) * 100) / (CONVERT(int, ROUND(a.Size / 128.000, 2))) AS PercentFree
FROM sys.database_files a (NOLOCK)
LEFT OUTER JOIN sysfilegroups b (NOLOCK)
  ON a.data_space_id = b.groupid
--where (CONVERT(INT, ROUND((a.Size - FILEPROPERTY(a.NAME, 'SpaceUsed')) / 128.000, 2)) * 100) / (CONVERT(INT, ROUND(a.Size / 128.000, 2))) > 30
--where CONVERT(INT, (a.Size - FILEPROPERTY(a.NAME, 'SpaceUsed')) / 128.000, 2) > 10000
--where physical_name like 'F%'
ORDER BY [Available Space (MB)] DESC
GO




declare @filesize int

set @filesize = 68000

WHILE @filesize > 60000
BEGIN
 DBCC SHRINKFILE (N'Primary_Temp_V1' , @filesize)

 WAITFOR DELAY '00:01:00'
 
 SET @filesize = @filesize - 1000;
END

-------------------------------------------
declare @currentfilesize int = 80700
declare @shrinkedfilesize int = 3000
declare @shrinkbyamount int = 20000

WHILE ((@currentfilesize - @shrinkedfilesize) <> 0)
BEGIN

 IF (@currentfilesize -  @shrinkbyamount < @shrinkedfilesize)
 SET @currentfilesize = @shrinkedfilesize;
 ELSE
 SET @currentfilesize = @currentfilesize - @shrinkbyamount;

 print @currentfilesize
 DBCC SHRINKFILE (N'wmp' , @currentfilesize)
 WAITFOR DELAY '00:00:09'
END