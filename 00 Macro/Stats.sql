-- Get column stats update date
SELECT  OBJECT_NAME(st.object_id) AS TableName,st.name AS STATName, STATS_DATE(st.object_id , st.stats_id) AS [LastUpdated]
FROM    sys.tables AS tbl INNER JOIN sys.stats st ON st.object_id = tbl.object_id
AND st.name NOT IN (SELECT name FROM sys.indexes WHERE object_id = st.object_id)
ORDER BY [LastUpdated]


-- Get index stats update date
SELECT  OBJECT_NAME(o.object_id) AS TableName, o.name AS IndexName,  STATS_DATE(i.object_id, i.index_id) AS StatUpdateDate
FROM sys.objects o
JOIN sys.indexes i ON  o.object_id = i.object_id
ORDER BY  StatUpdateDate
GO

-- drop all column stats
DECLARE @Sql        NVARCHAR(MAX)       SET @Sql       = ''
DECLARE @TableName  sysname             SET @TableName = ''
DECLARE @StatsName  sysname             SET @StatsName = ''

DECLARE cur CURSOR LOCAL FOR
SELECT OBJECT_NAME(s.object_id)   AS 'TableName'
     , s.name                     AS 'StatsName'
  FROM sys.stats     s 
  JOIN sys.tables    t
    ON s.object_id = t.object_id
 WHERE s.object_id > 100
   AND s.name NOT IN 
         (SELECT name FROM sys.indexes WHERE object_id = s.object_id)

OPEN cur
FETCH NEXT FROM cur INTO @TableName, @StatsName

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Sql = 'DROP STATISTICS ' + QUOTENAME(@TableName) + '.' + QUOTENAME(@StatsName)
    PRINT @Sql
    --EXEC sp_executesql @Sql
    FETCH NEXT FROM cur INTO @TableName, @StatsName
END

CLOSE cur 
DEALLOCATE cur 

-- check auto stats update status
SELECT name FROM [sys].[databases] WHERE  [is_auto_create_stats_on] = 0

-- set autostats update ON
ALTER DATABASE [AdventureWorks2012] SET AUTO_UPDATE_STATISTICS ON






-- Drop all index and user stats
CREATE PROCEDURE [dbo].[DropIndexes] 
  @SchemaName NVARCHAR(255) = NULL, @TableName NVARCHAR(255) = NULL AS
BEGIN
SET NOCOUNT ON

CREATE TABLE #commands (ID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, Command NVARCHAR(2000));
DECLARE @CurrentCommand NVARCHAR(2000);

--INSERT INTO #commands (Command)
--SELECT 'DROP INDEX [' + i.name + '] ON [' + s.name + '].[' + t.name + ']'
--FROM sys.tables t
--INNER JOIN sys.indexes i ON t.object_id = i.object_id
--INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
--WHERE i.type = 2
--AND s.name = COALESCE(@SchemaName, s.name)
--AND t.name = COALESCE(@TableName, t.name);

INSERT INTO #commands (Command)
SELECT 'DROP STATISTICS ' + SCHEMA_NAME([t].[schema_id]) + '.'  + OBJECT_NAME([s].[object_id]) + '.' + s.[name]
FROM sys.[stats] AS [s]
JOIN sys.[tables] AS [t]
ON s.[object_id] = t.[object_id]
WHERE [s].[name] LIKE '[_]WA[_]Sys[_]%'
AND OBJECT_NAME([s].[object_id]) NOT LIKE 'sys%'

DECLARE result_cursor CURSOR FOR
SELECT Command FROM #commands

OPEN result_cursor
FETCH NEXT FROM result_cursor into @CurrentCommand
WHILE @@FETCH_STATUS = 0
BEGIN 

	EXEC(@CurrentCommand);

FETCH NEXT FROM result_cursor into @CurrentCommand
END
--end loop

--clean up
CLOSE result_cursor
DEALLOCATE result_cursor
END
GO



------------------- Update incremental stats of last two partitions
DECLARE @RESAMPLE BIT = 1
DECLARE @PERCENT_SAMPLE INT = 100 -- IF @RESAMPLE = 0 SET @PERCENT_SAMPLE
DECLARE @PROCESS_LAST_X_NONEMPTY_PARTITIONS INT = 2

IF (OBJECT_ID ('tempdb..#TEMP_LAST2PARTITIONS') IS NOT NULL)
DROP TABLE #TEMP_LAST2PARTITIONS
;WITH AUX_LAST2PARTITIONS AS
(
SELECT
T.object_id
,TableName = T.Name
,I.index_id
,IX_Name = COALESCE(I.Name,'[HEAP]')
,P.partition_number
,P.rows
,i.data_space_id
,ROW_NUMBER = ROW_NUMBER() OVER ( PARTITION BY T.object_id, I.index_id ORDER BY P.partition_number DESC)
FROM sys.tables T
INNER JOIN sys.indexes I
ON T.object_id = I.object_id
INNER JOIN sys.data_spaces DS
ON I.data_space_id = DS.data_space_id
INNER JOIN sys.partitions P
ON I.object_id = P.object_id
AND I.index_id = P.index_id
WHERE DS.type = 'PS' -- PARTITION_SCHEME — PARTITION TABLE
AND P.rows > 0 -- filter empty partitions
)
SELECT
* INTO #TEMP_LAST2PARTITIONS
FROM AUX_LAST2PARTITIONS
WHERE [ROW_NUMBER] <= @PROCESS_LAST_X_NONEMPTY_PARTITIONS

CREATE CLUSTERED INDEX #IX_TEMP_LAST2PARTITIONS ON #TEMP_LAST2PARTITIONS (object_id, index_id, partition_number)

;WITH AUX AS
(
SELECT
AUX.object_id
,AUX.TableName
,AUX.index_id
,AUX.IX_Name
,StatsName = S.name
,AUX.partition_number
,AUX.rows
,PARTITION_VALUE = ISNULL(CAST(left_prv.value AS VARCHAR(MAX))+ CASE WHEN pf.boundary_value_on_right = 0 THEN ' > '
ELSE ' >= '
END , '-INF > ')
+ 'X' + ISNULL(CASE WHEN pf.boundary_value_on_right = 0 THEN ' >= '
ELSE ' > '
END + CAST(right_prv.value AS NVARCHAR(MAX)), ' > INF')
FROM #TEMP_LAST2PARTITIONS AUX
INNER JOIN sys.stats S
ON aux.object_id = S.object_id
LEFT JOIN sys.partition_schemes ps
ON aux.data_space_id = ps.data_space_id
LEFT JOIN sys.partition_functions pf
ON ps.function_id = pf.function_id
LEFT JOIN sys.partition_range_values left_prv
ON left_prv.function_id = ps.function_id
AND left_prv.boundary_id + 1 = aux.partition_number
LEFT JOIN sys.partition_range_values right_prv
ON right_prv.function_id = ps.function_id
AND right_prv.boundary_id = aux.partition_number
WHERE S.is_incremental = 1
)
SELECT SQL_COMMAND = 'UPDATE STATISTICS ' + QUOTENAME(TableName) + ' (' + QUOTENAME(StatsName) + ') WITH RESAMPLE ON PARTITIONS (' + CONVERT(VARCHAR(20), partition_number)
+ ')' + CHAR(10)
,INFO = ' — PARTITIONED TABLES INCREMENTAL LAST (' + CONVERT(VARCHAR, @PROCESS_LAST_X_NONEMPTY_PARTITIONS) + ') PARTITIONS ON (' + PARTITION_VALUE + ')'
FROM AUX
ORDER BY TableName, IX_Name, StatsName, partition_number desc