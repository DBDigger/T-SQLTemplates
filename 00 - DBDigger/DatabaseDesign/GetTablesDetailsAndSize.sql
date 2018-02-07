
SELECT 
	s.Name AS SchemaName,
    t.NAME AS TableName,
        p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB
    
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.NAME NOT in ('dbo_CNTR_ContainerItem_CT','dbo_CNTR_ContainerItemData_CT') 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    TotalSpaceMB desc





-- Get table rows and read write stats
SELECT TableName = object_name(s.object_id),
       Reads = SUM(user_seeks + user_scans + user_lookups), Writes =  SUM(user_updates), SUM(ps.row_count) AS [RowCount]
FROM sys.indexes AS i 
INNER JOIN sys.dm_db_index_usage_stats AS s ON s.object_id = i.object_id AND i.index_id = s.index_id
INNER JOIN sys.dm_db_partition_stats AS ps ON i.[object_id] = ps.[object_id] AND i.index_id = ps.index_id
WHERE objectproperty(s.object_id,'IsUserTable') = 1
and  i.type_desc IN ( 'CLUSTERED', 'HEAP' )
        AND i.[object_id] > 100
        AND OBJECT_SCHEMA_NAME(ps.[object_id]) <> 'sys'
GROUP BY object_name(s.object_id)




ORDER BY [RowCount] DESC, Writes desc
-- Table and row count information   
SELECT  OBJECT_NAME(ps.[object_id]) AS [TableName] ,
        i.name AS [IndexName] ,
        SUM(ps.row_count) AS [RowCount]
FROM    sys.dm_db_partition_stats AS ps
        INNER JOIN sys.indexes AS i ON i.[object_id] = ps.[object_id]
                                       AND i.index_id = ps.index_id
WHERE   i.type_desc IN ( 'CLUSTERED', 'HEAP' )
        AND i.[object_id] > 100
        AND OBJECT_SCHEMA_NAME(ps.[object_id]) <> 'sys'
GROUP BY ps.[object_id] ,
        i.name
ORDER BY SUM(ps.row_count) DESC ;


-- List all database tables and there indexes with  
-- detailed information about row count and  
-- used + reserved data space.  
SELECT SCH.name AS SchemaName 
      ,OBJ.name AS ObjName 
      ,OBJ.type_desc AS ObjType 
      ,INDX.name AS IndexName 
      ,INDX.type_desc AS IndexType 
      ,PART.partition_number AS PartitionNumber 
      ,PART.rows AS PartitionRows 
      ,STAT.row_count AS StatRowCount 
      ,STAT.used_page_count * 8 AS UsedSizeKB 
      ,STAT.reserved_page_count * 8 AS RevervedSizeKB 
FROM sys.partitions AS PART 
     INNER JOIN sys.dm_db_partition_stats AS STAT 
         ON PART.partition_id = STAT.partition_id 
            AND PART.partition_number = STAT.partition_number 
     INNER JOIN sys.objects AS OBJ 
         ON STAT.object_id = OBJ.object_id 
     INNER JOIN sys.schemas AS SCH 
         ON OBJ.schema_id = SCH.schema_id 
     INNER JOIN sys.indexes AS INDX 
         ON STAT.object_id = INDX.object_id 
            AND STAT.index_id = INDX.index_id 
ORDER BY SCH.name 
        ,OBJ.name 
        ,INDX.name 
        ,PART.partition_number 
 
 --************************************************************************************************************
 --Get Table size and row count detail
 --************************************************************************************************************
        
        SELECT OBJECT_NAME(object_id) AS TableName
	,(reserved_page_count * 8) / 1024 AS Size_inMB
	,*
FROM sys.dm_db_partition_stats
ORDER BY (reserved_page_count * 8) / 1024 DESC

/*------------------------------------------------------------------
Get columns list of each table along with other properties
-------------------------------------------------------------------*/
SELECT o.NAME AS TableName, c.NAME AS ColumnName, t.NAME AS DataType, c.max_length, c.precision, c.scale, c.is_nullable, c.is_identity
FROM sys.columns c
INNER JOIN sys.objects o ON c.object_id = o.object_id
INNER JOIN systypes t ON c.system_type_id = t.xtype
WHERE o.is_ms_shipped = 0
ORDER BY o.NAME, c.is_identity DESC, c.is_nullable


/*------------------------------------------------------------------
Get Rows of each tables, Size of each table, Size of data, Size of Indexes on it,
File on which table resides.
-------------------------------------------------------------------*/
BEGIN try  
CREATE TABLE #TableSize 
(NAME VARCHAR(255), [rows] INT, reserved VARCHAR(25), data VARCHAR(25), index_size VARCHAR(25), unused VARCHAR(25))

EXEC sp_MSforeachtable @command1 = "insert into #TableSize EXEC sp_spaceused '?'"

SELECT t.NAME, rows, convert(numeric(18,3),convert(numeric(18,3),SUBSTRING(reserved, 0, LEN(reserved) - 2))/1024) AS [Reserved(MB)], 
convert(numeric(18,3),convert(numeric(18,3),SUBSTRING(data, 0, LEN(data) - 2))/1024) AS [Data(MB)], 
convert(numeric(18,3),convert(numeric(18,3),SUBSTRING(index_size, 0, LEN(index_size) - 2))/1024) AS [Index(MB)],  
convert(numeric(18,3),convert(numeric(18,3),SUBSTRING(unused, 0, LEN(unused) - 2))/1024) AS [Unused(MB)],
[df].[physical_name] AS [datafilename]
FROM [sys].[data_spaces] [ds]
INNER JOIN [sys].[database_files] [df] ON [ds].[data_space_id] = [df].[data_space_id]
INNER JOIN [sys].[indexes] [si] ON [si].[data_space_id] = [ds].[data_space_id]
AND [si].[index_id] < 2
INNER JOIN #TableSize t ON object_name([si].[object_id]) = t.NAME

DROP TABLE #TableSize


END try 
BEGIN catch 
SELECT -100 AS l1
,       ERROR_NUMBER() AS tablename
,       ERROR_SEVERITY() AS row_count
,       ERROR_STATE() AS reserved
,       ERROR_MESSAGE() AS data
,       1 AS index_size, 1 AS unused, 1 AS schemaname 
END catch