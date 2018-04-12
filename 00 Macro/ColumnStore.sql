-- Get tables with CCI
select schema_name(o.schema_id)+'.'+o.name, i.type_desc from sys.indexes i inner join sys.objects o on i.object_id = o.object_id where i.type > = 4 order by 1

-- Create CCI
CREATE CLUSTERED COLUMNSTORE INDEX CCI_FactOnlineSales2 ON dbo.FactOnlineSales2 WITH (MAXDOP = 1);

-- ReBuild CCI
ALTER INDEX IndexName ON schema.TableName
REBUILD PARTITION = number {ALL}
        [ WITH ([ DATA_COMPRESSION = { COLUMNSTORE | COLUMNSTORE_ARCHIVE } ]   [ , MAXDOP = number ]             ) ];

-- Re organize CCI
ALTER INDEX IndexName ON schema.TableName REORGANIZE [ PARTITION = [ PartitionNumber | ALL ] ];

-- Recreate the clustered columnstore index by droping the existing clustered index
CREATE CLUSTERED COLUMNSTORE INDEX CCI_FactOnlineSales2 ON dbo.FactOnlineSales2
WITH (DROP_EXISTING = ON, MAXDOP = 1);
GO

-- Get a view of metadata 
select * 	from sys.column_store_dictionaries;
select * 	from sys.column_store_segments;
select * 	from sys.column_store_row_groups; 

-- Current memory use of segments
SELECT  OBJECT_NAME(p.[object_id]) AS [Table],  i.[name] AS [Index Name], c.[name] AS [Column Name],
 p.[column_id], p.[row_group_id], p.[object_type_desc], p.[access_count], p.[memory_used_in_bytes], p.[object_load_time]
FROM  sys.dm_column_store_object_pool p
LEFT OUTER JOIN  sys.index_columns ic ON  ic.[index_column_id] = p.[column_id] 
 AND ic.[index_id] = p.[index_id] 
 AND ic.[object_id] = p.[object_id]
LEFT OUTER JOIN  sys.columns c ON  ic.[object_id] = c.[object_id] 
 AND ic.[column_id] = c.[column_id]
LEFT OUTER JOIN  sys.indexes i ON  i.[object_id] = p.[object_id] 
 AND i.[index_id] = p.[index_id]
ORDER BY  p.[memory_used_in_bytes] DESC;
GO



--  Row groups info in a DB
SELECT  OBJECT_NAME(rg.[object_id]) AS [Table],i.[name] AS [Index], rg.[row_group_id],
 rg.[delta_store_hobt_id], rg.[state_description], rg.[total_rows], rg.[deleted_rows], rg.[size_in_bytes]
FROM  sys.column_store_row_groups AS rg
LEFT OUTER JOIN  sys.indexes AS i ON rg.[object_id] = i.[object_id]
 AND rg.[index_id] =i.[index_id]
ORDER BY  [Table], [Index], rg.[row_group_id];
GO



-- Segments information for specific table
SELECT
	OBJECT_NAME(i.object_id) AS TableName ,i.name AS IndexName ,i.type_desc AS IndexType
   ,COALESCE(c.name, '* Internal *') AS ColumnName ,p.partition_number ,s.segment_id
   ,s.row_count ,s.on_disk_size ,s.min_data_id ,s.max_data_id
FROM sys.column_store_segments AS s
INNER JOIN sys.partitions AS p 	ON p.hobt_id = s.hobt_id
INNER JOIN sys.indexes AS i ON i.object_id = p.object_id
		AND i.index_id = p.index_id
LEFT JOIN sys.index_columns AS ic ON ic.object_id = i.object_id
		AND ic.index_id = i.index_id
		AND ic.index_column_id = s.column_id
LEFT JOIN sys.columns AS c ON c.object_id = ic.object_id
		AND c.column_id = ic.column_id
WHERE i.name IN (N'CCI_FactOnlineSales2')
ORDER BY TableName, IndexName,
s.column_id, p.partition_number, s.segment_id;


-- Dictionaries information for specific table
SELECT
	OBJECT_NAME(i.object_id) AS TableName ,i.name AS IndexName ,i.type_desc AS IndexType ,COALESCE(c.name, '* Internal *') AS ColumnName
   ,p.partition_number ,s.segment_id ,s.encoding_type ,dG.type AS GlDictType ,dG.entry_count AS GlDictEntryCount
   ,dG.on_disk_size AS GlDictOnDiskSize ,dL.type AS LcDictType ,dL.entry_count AS LcDictEntryCount ,dL.on_disk_size AS LcDictOnDiskSize
FROM sys.column_store_segments AS s
INNER JOIN sys.partitions AS p 	ON p.hobt_id = s.hobt_id
INNER JOIN sys.indexes AS i ON i.object_id = p.object_id
		AND i.index_id = p.index_id
LEFT JOIN sys.index_columns AS ic ON ic.object_id = i.object_id
		AND ic.index_id = i.index_id
		AND ic.index_column_id = s.column_id
LEFT JOIN sys.columns AS c 	ON c.object_id = ic.object_id
		AND c.column_id = ic.column_id
LEFT JOIN sys.column_store_dictionaries AS dG         -- Global dictionary 
	ON dG.hobt_id = s.hobt_id
		AND dG.column_id = s.column_id
		AND dG.dictionary_id = s.primary_dictionary_id
LEFT JOIN sys.column_store_dictionaries AS dL         -- Local dictionary
	ON dL.hobt_id = s.hobt_id
		AND dL.column_id = s.column_id
		AND dL.dictionary_id = s.secondary_dictionary_id
WHERE i.name IN (N'CCI_FactOnlineSales2')
AND s.encoding_type IN (2, 3)
ORDER BY TableName, IndexName,
s.column_id, p.partition_number, s.segment_id;

-- Rowgroups information
SELECT OBJECT_NAME(rg.object_id) AS TableName ,i.name AS IndexName   ,i.type_desc AS IndexType
   ,rg.partition_number ,rg.row_group_id ,rg.total_rows  ,rg.size_in_bytes
FROM sys.column_store_row_groups AS rg
INNER JOIN sys.indexes AS i ON i.object_id = rg.object_id
		AND i.index_id = rg.index_id
WHERE i.name IN (N'CCI_FactOnlineSales2')
ORDER BY TableName, IndexName,
rg.partition_number, rg.row_group_id;


-- Returns tables suggested for using Clustered Columnstore for the Datawarehouse environments
SELECT OBJECT_SCHEMA_NAME(t.object_id) AS 'Schema' ,OBJECT_NAME(t.object_id) AS 'Table' ,SUM(p.rows) AS 'Row Count'
   ,(SELECT COUNT(*) FROM sys.columns AS col WHERE t.object_id = col.object_id) AS 'Cols Count'
   ,(SELECT SUM(col.max_length) FROM sys.columns AS col
		JOIN sys.types AS tp ON col.system_type_id = tp.system_type_id
		WHERE t.object_id = col.object_id) 	AS 'Cols Max Length'
   ,(SELECT COUNT(*) FROM sys.columns AS col
		JOIN sys.types AS tp ON col.system_type_id = tp.system_type_id
		WHERE t.object_id = col.object_id
		AND (UPPER(tp.name) IN ('TEXT', 'NTEXT', 'TIMESTAMP', 'HIERARCHYID', 'SQL_VARIANT', 'XML', 'GEOGRAPHY', 'GEOMETRY')
		OR (UPPER(tp.name) IN ('VARCHAR', 'NVARCHAR')
		AND (col.max_length = 8000
		OR col.max_length = -1)) )) 	AS 'Unsupported Columns'
   ,(SELECT COUNT(*) FROM sys.objects WHERE type = 'PK' AND parent_object_id = t.object_id) AS 'Primary Key'
   ,(SELECT COUNT(*) FROM sys.objects WHERE type = 'F' AND parent_object_id = t.object_id) AS 'Foreign Keys'
   ,(SELECT COUNT(*) FROM sys.objects WHERE type IN ('UQ', 'D', 'C') AND parent_object_id = t.object_id) AS 'Constraints'
   ,(SELECT COUNT(*) FROM sys.objects WHERE type IN ('TA', 'TR') AND parent_object_id = t.object_id) AS 'Triggers'
   ,t.is_tracked_by_cdc AS 'CDC' ,t.is_memory_optimized AS 'Hekaton' ,t.is_replicated AS 'Replication'
   ,COALESCE(t.filestream_data_space_id, 0, 1) AS 'FileStream' ,t.is_filetable AS 'FileTable'
FROM sys.tables t
INNER JOIN sys.partitions AS p ON t.object_id = p.object_id
WHERE p.data_compression IN (0, 1, 2) -- None, Row, Page
AND p.index_id IN (0, 1)
AND (SELECT COUNT(*) FROM sys.indexes ind WHERE t.object_id = ind.object_id AND ind.type IN (5, 6)) = 0
GROUP BY t.object_id ,t.is_tracked_by_cdc ,t.is_memory_optimized ,t.is_filetable ,t.is_replicated ,t.filestream_data_space_id
HAVING SUM(p.rows) > 1000000
ORDER BY SUM(p.rows) DESC


-- GET dictionary size for each table
select object_name(object_id), dictionary_id , count(*) as 'Number of Dictionaries' , sum(entry_count) as 'Entry Count'
	, min(on_disk_size) as 'Min Size', max(on_disk_size) as 'Max Size', avg(on_disk_size) as 'Avg Size'
	from sys.column_store_dictionaries dict
		join sys.partitions part 	on dict.hobt_id = part.hobt_id
	group by object_id, dictionary_id 
	order by object_name(object_id), dictionary_id 


-- What's being locked
SELECT dm_tran_locks.request_session_id   ,dm_tran_locks.resource_database_id  ,DB_NAME(dm_tran_locks.resource_database_id) AS dbname
   ,CASE
		WHEN resource_type = 'object' THEN OBJECT_NAME(dm_tran_locks.resource_associated_entity_id)
		ELSE OBJECT_NAME(partitions.object_id)
	END AS ObjectName
   ,partitions.index_id ,indexes.name AS index_name ,dm_tran_locks.resource_type ,dm_tran_locks.resource_description
   ,dm_tran_locks.resource_associated_entity_id ,dm_tran_locks.request_mode ,dm_tran_locks.request_status
FROM sys.dm_tran_locks
LEFT JOIN sys.partitions ON partitions.hobt_id = dm_tran_locks.resource_associated_entity_id
JOIN sys.indexes ON indexes.object_id = partitions.object_id
		AND indexes.index_id = partitions.index_id
WHERE resource_associated_entity_id > 0
AND resource_database_id = DB_ID()
ORDER BY request_session_id, resource_associated_entity_id 


-- Rowgroups information
SELECT rg.total_rows ,CAST(100.0 * (total_rows) / 1048576 AS DECIMAL(6, 3)) AS PercentFull
   ,CAST(100 - 100.0 * (total_rows - ISNULL(deleted_rows, 0)) / IIF(total_rows = 0, 1, total_rows) AS DECIMAL(6, 3)) AS PercentDeleted
   ,i.object_id ,OBJECT_NAME(i.object_id) AS TableName  ,i.name AS IndexName  ,i.index_id  ,i.type_desc   ,rg.*
FROM sys.indexes AS i
INNER JOIN sys.column_store_row_groups AS rg ON i.object_id = rg.object_id
		AND i.index_id = rg.index_id
WHERE OBJECT_NAME(i.object_id) = 'MaxDataTable'
--and state = 0
ORDER BY OBJECT_NAME(i.object_id), i.name, row_group_id;


-- Different dictionaries
SELECT OBJECT_NAME(i.object_id) AS TableName ,COUNT(csd.column_id) AS DictionariesCount ,CAST(SUM(csd.on_disk_size) / (1024.0 * 1024.0) AS DECIMAL(9, 2)) AS on_disk_size_MB
FROM sys.indexes AS i
JOIN sys.partitions AS p ON i.object_id = p.object_id
JOIN sys.column_store_dictionaries AS csd 	ON csd.hobt_id = p.hobt_id
WHERE i.object_id != OBJECT_ID('FactOnlineSales')
AND i.type_desc = 'CLUSTERED COLUMNSTORE'
GROUP BY OBJECT_NAME(i.object_id);


-- Rowgroups by status
select state, state_description, count(*) as 'RowGroup Count'
from sys.column_store_row_groups
where object_id = object_id('BiGDataTest')
group by state, state_description
order by state;


-- Segments for a column
select segment_id, row_count, base_id, min_data_id, max_data_id
	from sys.column_store_segments
	where column_id = 1;


-- check the count of Row Groups for each of our test tables:
SELECT object_name(i.object_id) as TableName, count(*) as RowGroupsCount
	FROM sys.indexes AS i
	INNEr JOIN sys.column_store_row_groups AS rg with(nolock) ON i.object_id = rg.object_id
	AND i.index_id = rg.index_id 
	WHERE object_name(i.object_id) in ( 'FactOnlineSales','FactOnlineSales_SmallGroups')
	group by object_name(i.object_id)
	ORDER BY object_name(i.object_id);


-- Clustered Columnstore Indexes Analysis
SELECT i.name, p.object_id, p.index_id, i.type_desc   	,sum(p.rows)/count(seg.segment_id) as 'rows'
	,sum(seg.on_disk_size) as 'size in Bytes' 	,cast( sum(seg.on_disk_size) / 1024. / 1024. / 1024 as decimal(8,3)) as 'size in GB'
	,count(distinct seg.segment_id) as 'Segments'	,count(distinct p.partition_id) as 'Partitions'
	FROM sys.column_store_segments AS seg 
		INNER JOIN sys.partitions AS p 		ON seg.hobt_id = p.hobt_id 
		INNER JOIN sys.indexes AS i ON p.object_id = i.object_id
	WHERE i.type in (5, 6)
	GROUP BY i.name, p.object_id, p.index_id, i.type_desc;


	-- Detailed information about Dictionaries
select 	OBJECT_NAME(t.object_id) as 'Table Name',	sum(dict.on_disk_size)/1024./1024 as DictionarySizeMB
	from sys.column_store_dictionaries dict
	inner join sys.partitions as p 		ON dict.partition_id = p.partition_id
	inner join sys.tables t		ON t.object_id = p.object_id
	inner join sys.indexes i		ON i.object_id = t.object_id
	where i.type in (5,6) -- Clustered & Nonclustered Columnstore
	group by t.object_id


-- Dictionaries count & type per each of the column
SELECT 	t.name AS 'Table Name'   ,dict.column_id   ,col.name   ,tp.name
   ,CASE dict.dictionary_id
		WHEN 0 THEN 'Global Dictionary'
		ELSE 'Local Dictionary'
	END AS 'Dictionary Type'
   ,COUNT(dict.type) AS 'Count'   ,SUM(dict.on_disk_size) AS 'Size in Bytes'
   ,CAST(SUM(dict.on_disk_size) / 1024.0 / 1024 AS DECIMAL(16, 3)) AS 'Size in MBytes'
FROM sys.column_store_dictionaries dict
INNER JOIN sys.partitions AS p	ON dict.partition_id = p.partition_id
INNER JOIN sys.tables t	ON t.object_id = p.object_id
INNER JOIN sys.all_columns col	ON col.column_id = dict.column_id
		AND col.object_id = t.object_id
INNER JOIN sys.types tp	ON col.system_type_id = tp.system_type_id
		AND col.user_type_id = tp.user_type_id
WHERE t.[is_ms_shipped] = 0
AND col.name IN ('SalesAmount', 'ProductKey', 'CurrencyKey', 'PromotionKey')
GROUP BY t.name		,CASE dict.dictionary_id
			 WHEN 0 THEN 'Global Dictionary'
			 ELSE 'Local Dictionary'
		 END
		,col.name		,tp.name		,dict.column_id
ORDER BY dict.column_id, t.name;


-- Delete segments and fragmentation
SELECT object_name(p.object_id) as TableName,	p.partition_number as Partition,
		cast( Avg( (rg.deleted_rows * 1. / rg.total_rows) * 100 ) as Decimal(5,2)) as 'Total Fragmentation (Percentage)',
		sum (case rg.deleted_rows when rg.total_rows then 1 else 0 end ) as 'Deleted Segments Count',
		cast( (sum (case rg.deleted_rows when rg.total_rows then 1 else 0 end ) * 1. / count(*)) * 100 as Decimal(5,2)) as 'DeletedSegments (Percentage)'
	FROM sys.partitions AS p 
		INNER JOIN sys.column_store_row_groups rg ON p.object_id = rg.object_id 
	where rg.state = 3 -- Compressed (Ignoring: 0 - Hidden, 1 - Open, 2 - Closed, 4 - Tombstone) 
	group by p.object_id, p.partition_number
	order by object_name(p.object_id);


-- what kind of information is available for Deleted Bitmaps & Delta-Stores
select object_name(ip.object_id) as TableName,	sum(al.used_pages) * 8 as 'size (KB)'
	from  sys.system_internals_partitions ip
		inner join sys.allocation_units al on al.container_id = ip.partition_id
	where ip.is_columnstore = 0
		and ownertype = 2
    group by object_name(object_id);


-- Cache for CCI
select name, type, pages_kb, pages_in_use_kb, entries_count, entries_in_use_count
	from sys.dm_os_memory_cache_counters 
	where type = 'CACHESTORE_COLUMNSTOREOBJECTPOOL';


-- Memory clerks for CCI
select name, type, memory_node_id, pages_kb, page_size_in_bytes, virtual_memory_reserved_kb, virtual_memory_committed_kb,shared_memory_reserved_kb, shared_memory_committed_kb
	from sys.dm_os_memory_clerks 
	where type = 'CACHESTORE_COLUMNSTOREOBJECTPOOL';



-- Create test table with CCI
-- Table definition
CREATE TABLE dbo.CCTest (	id INT NOT NULL   ,name VARCHAR(50) NOT NULL   ,lastname VARCHAR(50) NOT NULL);
GO

-- Creating our Clustered Columnstore Index
CREATE CLUSTERED COLUMNSTORE INDEX CCL_CCTest ON dbo.CCTest;
GO

-- Insert 2.4 million rows
DECLARE @i AS INT;
DECLARE @max AS INT;
SELECT 	@max = ISNULL(MAX(id), 0) FROM dbo.CCTest;
SET @i = 1;

BEGIN TRAN
WHILE @i <= 2400000
BEGIN
INSERT INTO dbo.CCTest (id, name, lastname)
	VALUES (@max + @i, 'SomeName_', 'SomeLastName_');

SET @i = @i + 1;
END;
COMMIT;


-- Get operational statistics
SELECT OBJECT_NAME(os.[object_id]) AS [Table], i.[name] AS [Index], os.[row_group_id]
, os.[index_scan_count], os.[scan_count], os.[delete_buffer_scan_count], os.[row_group_lock_count]
, os.[row_group_lock_wait_count] , os.[row_group_lock_wait_in_ms]
FROM  sys.dm_db_column_store_row_group_operational_stats AS os
LEFT OUTER JOIN  sys.indexes AS i ON  i.[index_id] = os.[index_id]
 AND i.[object_id] = os.[object_id]
ORDER BY  [Table], [Index], os.[row_group_id];
GO

-- Get fragmentation stats
SELECT OBJECT_NAME(i.[object_id]) AS [Table],i.[name] AS [Index],  ps.[row_group_id], ps.[delta_store_hobt_id],
 ps.[state_desc], ps.[total_rows], ps.[deleted_rows], ps.[size_in_bytes], ps.[trim_reason_desc], ps.[transition_to_compressed_state_desc],
 ps.[has_vertipaq_optimization], ps.[generation], ps.[created_time], ps.[closed_time], 100 * ( ISNULL ( ps.[deleted_rows], 0 ) ) / total_rows AS 'Fragmentation'
FROM  sys.indexes AS i INNER JOIN  sys.dm_db_column_store_row_group_physical_stats AS ps ON  i.[object_id] = ps.[object_id] 
 AND i.index_id = ps.index_id  
ORDER BY  [Table], [Index], ps.[row_group_id];
GO


-- usage statistics and I/O-related activity (locks, latches) for each partition of a table or index in a database
SELECT  OBJECT_NAME(os.[object_id]) AS [Table], i.[name] AS [Index], i.[type_desc] AS [Index Type], ip.[internal_object_type_desc],
 os.[range_scan_count], os.[singleton_lookup_count], os.[page_lock_count], os.[page_io_latch_wait_count], os.[page_io_latch_wait_in_ms],
 os.[tree_page_io_latch_wait_count], os.[tree_page_io_latch_wait_in_ms]
 FROM  sys.dm_db_index_operational_stats (DB_ID(), NULL, NULL, NULL)   AS os
INNER JOIN sys.indexes AS i ON i.[index_id] = os.[index_id]
 AND i.[object_id] = os.[object_id]
LEFT OUTER JOIN  sys.internal_partitions AS ip ON  ip.[hobt_id] = os.[hobt_id]
 AND ip.[index_id] = os.[index_id]
 AND ip.[object_id] = os.[object_id]
 AND ip.[partition_number] = os.[partition_number]
WHERE  OBJECT_NAME(os.[object_id]) IN   ('FactInternetSales', 'FactProductInventory')
ORDER BY [Table], [Index], ip.[row_group_id];
GO

--  information on the size and fragmentation of indexes and heaps in a table, database
SELECT  i.[name] AS [Index], i.[type_desc] AS [Index Type], ip.[internal_object_type_desc],
 ip.[rows], ps.[avg_fragmentation_in_percent],ps.[columnstore_delete_buffer_state_desc]
FROM  sys.dm_db_index_physical_stats  (DB_ID(), NULL, NULL, NULL , 'LIMITED') AS ps
INNER JOIN sys.indexes AS i ON i.[index_id] = ps.[index_id]
 AND i.[object_id] = ps.[object_id]
LEFT OUTER JOIN  sys.internal_partitions AS ip ON   ip.[hobt_id] = ps.[hobt_id]
 AND ip.[index_id] = ps.[index_id]
 AND ip.[object_id] = ps.[object_id]
 AND ip.[partition_number] = ps.[partition_number]
WHERE  OBJECT_NAME(ps.[object_id]) IN    ('FactInternetSales', 'FactProductInventory')
ORDER BY OBJECT_NAME(ps.[object_id]), [Index];
GO

-- Track the merge activity and row group qualification using the Extended Events 

CREATE EVENT SESSION [TupleMover] ON SERVER 

ADD EVENT sqlserver.columnstore_no_rowgroup_qualified_for_merge,
ADD EVENT sqlserver.columnstore_rowgroup_compressed,
ADD EVENT sqlserver.columnstore_rowgroup_merge_complete,
ADD EVENT sqlserver.columnstore_rowgroup_merge_start
ADD TARGET package0.event_file(SET filename=N'XeMerge',max_file_size=(10))
GO
Alter EVENT SESSION [XeMerge] ON SERVER  State = START
 
