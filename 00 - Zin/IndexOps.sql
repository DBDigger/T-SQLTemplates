-- Create index 
CREATE NONCLUSTERED INDEX [NCINX_SRDetails_SRID_FK] ON [dbo].[StockRequestDetail] 
(
	[StockRequestID_FK] ASC
)
INCLUDE ( [RequestStatusID_FK],
[NetworkID],
[MEID_Dec],
[SIMCardID_FK]) WITH (STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO



-- Disable an index 
ALTER INDEX IX_IndexName ON Schema.TableName DISABLE 

-- Drop an index 
DROP INDEX IndexName ON Schema.TableName 

-- Enable an index 
ALTER INDEX IX_IndexName ON Schema.TableName REBUILD 

-- online rebuild 
ALTER INDEX [INX_RTUBC_NETWORKCONNECTION_USAGEDATE] ON [dbo].[REALTIMEUSAGEBYCOMPANY]  REBUILD WITH (ONLINE=ON, sort_in_tempdb = on)

-- Get fragmentation of all tables
SELECT   'ALTER INDEX [' +dbindexes.[name]+'] ON [' + dbschemas.[name]+'].['+dbtables.name + '] REBUILD  ;', dbschemas.[name] as 'Schema',
dbtables.[name] as 'Table',
dbindexes.[name] as 'Index',
indexstats.avg_fragmentation_in_percent,
indexstats.page_count
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
AND indexstats.index_id = dbindexes.index_id
WHERE indexstats.database_id = DB_ID()
ORDER BY indexstats.avg_fragmentation_in_percent desc

-- Get fragmentation of all tables
SELECT DB_NAME(DB_ID()) AS DatabaseName,
       schemas.[name] AS SchemaName,
       objects.[name] AS ObjectName,
       indexes.[name] AS IndexName,
       objects.type_desc AS ObjectType,
       indexes.type_desc AS IndexType,
       dm_db_index_physical_stats.partition_number AS PartitionNumber,
       dm_db_index_physical_stats.page_count AS [PageCount],
       dm_db_index_physical_stats.avg_fragmentation_in_percent AS AvgFragmentationInPercent
FROM sys.dm_db_index_physical_stats (@DatabaseID, NULL, NULL, NULL, 'LIMITED') dm_db_index_physical_stats
INNER JOIN sys.indexes indexes ON dm_db_index_physical_stats.[object_id] = indexes.[object_id] AND dm_db_index_physical_stats.index_id = indexes.index_id
INNER JOIN sys.objects objects ON indexes.[object_id] = objects.[object_id]
INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id]
WHERE objects.[type] IN('U','V')
AND objects.is_ms_shipped = 0
AND indexes.[type] IN(1,2,3,4)
AND indexes.is_disabled = 0
AND indexes.is_hypothetical = 0
AND dm_db_index_physical_stats.alloc_unit_type_desc = 'IN_ROW_DATA'
AND dm_db_index_physical_stats.index_level = 0
AND dm_db_index_physical_stats.page_count >= 1000

-- Get fragmentation for single table
 SELECT IPS.Index_type_desc, 
      IPS.avg_fragmentation_in_percent, 
      IPS.avg_fragment_size_in_pages, 
      IPS.avg_page_space_used_in_percent, 
      IPS.record_count, 
      IPS.ghost_record_count,
      IPS.fragment_count, 
      IPS.avg_fragment_size_in_pages
   FROM sys.dm_db_index_physical_stats(db_id(), object_id('invoiceitemdetails_4usagefile'), NULL, NULL , NULL) AS IPS;
GO

-- Get fragmentation of all


-- Generate table with number of rows
SELECT so.[name] AS [table name]
	,CASE 
		WHEN si.indid BETWEEN 1
				AND 254
			THEN si.[name]
		ELSE NULL
		END AS [Index Name]
	,si.indid
FROM sysindexes si
INNER JOIN sysobjects so ON si.id = so.id
WHERE si.indid < 2
	AND so.type = 'U' -- Only User Tables
	AND so.[name] != 'dtproperties'
ORDER BY so.[name]

-- Generate table with number of rows
SELECT QUOTENAME(SCHEMA_NAME(sOBJ.schema_id)) + '.' + QUOTENAME(sOBJ.NAME) AS [TableName]
	,SUM(sdmvPTNS.row_count) AS [RowCount]
FROM sys.objects AS sOBJ WITH (NOLOCK)
INNER JOIN sys.dm_db_partition_stats AS sdmvPTNS WITH (NOLOCK) ON sOBJ.object_id = sdmvPTNS.object_id
WHERE sOBJ.type = 'U'
	AND sOBJ.is_ms_shipped = 0x0
	AND sdmvPTNS.index_id < 2
	AND sOBJ.NAME NOT LIKE 'Account%'
	AND sOBJ.NAME NOT LIKE '%invoice%'
GROUP BY sOBJ.schema_id
	,sOBJ.NAME
ORDER BY [TableName]


-- Get Stat update date
SELECT name AS index_name,
STATS_DATE(OBJECT_ID, index_id) AS StatsUpdated
FROM sys.indexes with (nolock)
WHERE OBJECT_ID = OBJECT_ID('INVOICEITEMDETAILS')
GO


-- Update stats
UPDATE STATISTICS TableName -- can also mention IndexName here
WITH FULLSCAN
GO

-- Make USPs to use new stats
EXEC sp_recompile TableName

-- Get indexes list for non partitioned tables
SELECT OBJECT_NAME(IPS.OBJECT_ID) AS [TableName], avg_fragmentation_in_percent, SI.name [IndexName], 
schema_name(ST.schema_id) AS [SchemaName], 0 AS IsProcessed , t.name
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL , NULL) IPS
JOIN sys.tables ST WITH (nolock) ON IPS.OBJECT_ID = ST.OBJECT_ID
JOIN sys.indexes SI WITH (nolock) ON IPS.OBJECT_ID = SI.OBJECT_ID AND IPS.index_id = SI.index_id
left outer join sys.TABLES t on st.name = t.name
WHERE ST.is_ms_shipped = 0 AND SI.name IS NOT NULL
AND avg_fragmentation_in_percent >= 30
and t.name is not null
ORDER BY avg_fragmentation_in_percent DESC

-- Listing 1. Query to determine table filegroup by index

SELECT OBJECT_SCHEMA_NAME(t.object_id) AS schema_name
,t.name AS table_name
,i.index_id
,i.name AS index_name
,ds.name AS filegroup_name
FROM sys.tables t with (nolock)
INNER JOIN sys.indexes i  with (nolock) ON t.object_id=i.object_id
INNER JOIN sys.filegroups ds  with (nolock) ON i.data_space_id=ds.data_space_id
INNER JOIN sys.partitions p  with (nolock) ON i.object_id=p.object_id AND i.index_id=p.index_id
ORDER BY t.name, i.index_id


-- Get stat sampling information
DBCC SHOW_STATISTICS (INVOICEITEMDETAILS_4UsageFile, INX_INVOICEITEMDETAILS_4UsageFile_ACCOUNTINGID) WITH STAT_HEADER




/*
Script  : Index Fragmentation Status (includes Partitioned Tables/Indexes)
*/
- Hide quoted text -
SELECT
             SCHEMA_NAME(o.schema_id) AS SchemaName               
            ,OBJECT_NAME(o.object_id) AS TableName
            ,i.name  AS IndexName
            ,i.type_desc AS IndexType
            ,CASE WHEN ISNULL(ps.function_id,1) = 1 THEN 'NO' ELSE 'YES' END AS Partitioned
            ,COALESCE(fg.name ,fgp.name) AS FileGroupName
            ,p.partition_number AS PartitionNumber
            ,p.rows AS PartitionRows
            ,dmv.Avg_Fragmentation_In_Percent
            ,dmv.Fragment_Count
            ,dmv.Avg_Fragment_Size_In_Pages
            ,dmv.Page_Count 
            ,prv_left.value  AS PartitionLowerBoundaryValue
            ,prv_right.value AS PartitionUpperBoundaryValue
            ,CASE WHEN pf.boundary_value_on_right = 1 THEN 'RIGHT' WHEN pf.boundary_value_on_right = 0 THEN 'LEFT' ELSE 'NONE' END AS PartitionRange
            ,pf.name        AS PartitionFunction
            ,ds.name AS PartitionScheme
FROM sys.partitions AS p WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
            ON i.object_id = p.object_id
            AND i.index_id = p.index_id
INNER JOIN sys.objects AS o WITH (NOLOCK)
            ON o.object_id = i.object_id
INNER JOIN sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, N'LIMITED') dmv
            ON dmv.OBJECT_ID = i.object_id
            AND dmv.index_id = i.index_id
            AND dmv.partition_number  = p.partition_number
LEFT JOIN sys.data_spaces AS ds WITH (NOLOCK)
      ON ds.data_space_id = i.data_space_id
LEFT JOIN sys.partition_schemes AS ps WITH (NOLOCK)
      ON ps.data_space_id = ds.data_space_id
LEFT JOIN sys.partition_functions AS pf WITH (NOLOCK)
      ON pf.function_id = ps.function_id
LEFT JOIN sys.destination_data_spaces AS dds WITH (NOLOCK)
      ON dds.partition_scheme_id = ps.data_space_id
      AND dds.destination_id = p.partition_number
LEFT JOIN sys.filegroups AS fg WITH (NOLOCK)
      ON fg.data_space_id = i.data_space_id
LEFT JOIN sys.filegroups AS fgp WITH (NOLOCK)
      ON fgp.data_space_id = dds.data_space_id
LEFT JOIN sys.partition_range_values AS prv_left WITH (NOLOCK)
      ON ps.function_id = prv_left.function_id
      AND prv_left.boundary_id = p.partition_number - 1
LEFT JOIN sys.partition_range_values AS prv_right WITH (NOLOCK)
      ON ps.function_id = prv_right.function_id
      AND prv_right.boundary_id = p.partition_number
WHERE
      OBJECTPROPERTY(p.object_id, 'ISMSShipped') = 0  
ORDER BY
            SchemaName
    ,TableName
    ,IndexName
    ,PartitionNumber




	-- Partition index rebuild
	select * from uvw_pi where object = 365244356 and rows > 0

select * from sys.objects where name = 'accounting_operators'

sp_helpindex  accounting_operators

-- Get fragmentation for single table
 SELECT IPS.Index_type_desc, 
      IPS.avg_fragmentation_in_percent, 
      IPS.avg_fragment_size_in_pages, 
      IPS.avg_page_space_used_in_percent, 
      IPS.record_count, 
      IPS.ghost_record_count,
      IPS.fragment_count, 
      IPS.avg_fragment_size_in_pages
   FROM sys.dm_db_index_physical_stats(db_id(), object_id('accounting_operators'), 1, 2 , NULL) AS IPS;
GO

ALTER INDEX Accounting_Operators_PK ON accounting_operators REBUILD Partition = 2
--------------------------------------------------------------------------------------------------
-- Get index analysis in a DB
EXEC sp_BlitzIndex @DatabaseName = 'wmp' 
GO

-- Get Index Analysis for a table 
EXEC dbo.sp_BlitzIndex @DatabaseName='wmp', @SchemaName='dbo', @TableName='REQUESTDETAILSWF';

sp_spaceused REQUESTDETAILSWF
GO


-- Get partition function details
SELECT PF.[name],RV.boundary_id	,RV.[value]
FROM sys.partition_functions PF
INNER JOIN sys.partition_range_values RV ON PF.function_id = RV.function_id
WHERE PF.NAME = 'REQUESTDETAILSWF'
GO

-- Run on Publisher: Get list of publications and their articles
SELECT p.NAME 	,a.NAME
FROM sysarticles a INNER JOIN syspublications p ON p.pubid = a.pubid
ORDER BY a.NAME