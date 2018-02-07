-- Get read write and row count of each partitioned table
SELECT object_name(s.object_id) as objectName,
       SUM(user_seeks + user_scans + user_lookups) as Reads, SUM(user_updates) as Writes, SUM(ps.row_count) AS [RowsCount]
FROM sys.indexes AS i 
INNER JOIN sys.dm_db_index_usage_stats AS s ON s.object_id = i.object_id AND i.index_id = s.index_id
INNER JOIN sys.dm_db_partition_stats AS ps ON i.[object_id] = ps.[object_id] AND i.index_id = ps.index_id
WHERE object_name(s.object_id) in 
(SELECT t.name
FROM sys.TABLES t with (nolock)
    JOIN sys.indexes i  with (nolock) ON t.object_id = i.object_id
    JOIN sys.partition_schemes ps  with (nolock) ON i.data_space_id = ps.data_space_id
    JOIN sys.partition_functions pf  with (nolock) ON ps.function_id = pf.function_id)
    group by object_name(s.object_id)
--    WHERE objectproperty(s.object_id,'IsUserTable') = 1
--and OBJECTPROPERTY(s.object_id, N'SchemaId') = SCHEMA_ID(N'dbo')
--and  i.type_desc IN ( 'CLUSTERED', 'HEAP' )
--        AND i.[object_id] > 100
--        AND OBJECT_SCHEMA_NAME(ps.[object_id]) <> 'sys'


-- get data file space and locations
SELECT b.groupname AS 'File Group'
	,a.NAME as FileName
	,physical_name
,
	CONVERT(INT, a.Size / 128.000, 2)/1024 AS [Currently Allocated Space (MB)]
	,(CONVERT(INT, ROUND((a.Size - FILEPROPERTY(a.NAME, 'SpaceUsed')) / 128.000, 2)) * 100) / (CONVERT(INT, ROUND(a.Size / 128.000, 2))) AS PercentFree
FROM sys.database_files a(NOLOCK)
LEFT OUTER JOIN sysfilegroups b(NOLOCK) ON a.data_space_id = b.groupid
ORDER BY b.groupname 


-- Get tables, FG and rows
SELECT SCHEMA_NAME(o.schema_id) as schemaname, OBJECT_NAME(i.object_id) AS [object]
	,fg.NAME AS [filegroup]
	,sum(p.rows)	
FROM sys.partitions p  with (nolock) 
INNER JOIN sys.indexes i with (nolock) ON p.object_id = i.object_id
	AND p.index_id = i.index_id
INNER JOIN sys.objects o  with (nolock) ON p.object_id = o.object_id
INNER JOIN sys.partition_schemes ps with (nolock) ON ps.data_space_id = i.data_space_id
INNER JOIN sys.destination_data_spaces dds with (nolock) ON dds.partition_scheme_id = ps.data_space_id
	AND dds.destination_id = p.partition_number
INNER JOIN sys.filegroups fg with (nolock) ON dds.data_space_id = fg.data_space_id
WHERE i.index_id < 2
group by SCHEMA_NAME(o.schema_id) , OBJECT_NAME(i.object_id) ,fg.NAME
order by OBJECT_NAME(i.object_id)


-- Get details about each partition
SELECT  pf.name AS pf_name ,
        ps.name AS partition_scheme_name ,
        p.partition_number ,
        ds.name AS partition_filegroup ,
        pf.type_desc AS pf_type_desc ,
        pf.fanout AS pf_fanout ,
        pf.boundary_value_on_right ,
        OBJECT_NAME(si.object_id) AS object_name ,
        rv.value AS range_value ,
        SUM(CASE WHEN si.index_id IN ( 1, 0 ) THEN p.rows
                    ELSE 0
            END) AS num_rows ,
        SUM(dbps.reserved_page_count) * 8 / 1024. AS reserved_mb_all_indexes ,
        SUM(CASE ISNULL(si.index_id, 0)
                WHEN 0 THEN 0
                ELSE 1
            END) AS num_indexes
FROM    sys.destination_data_spaces AS dds
        JOIN sys.data_spaces AS ds ON dds.data_space_id = ds.data_space_id
        JOIN sys.partition_schemes AS ps ON dds.partition_scheme_id = ps.data_space_id
        JOIN sys.partition_functions AS pf ON ps.function_id = pf.function_id
        LEFT JOIN sys.partition_range_values AS rv ON pf.function_id = rv.function_id
                                                        AND dds.destination_id = CASE pf.boundary_value_on_right
                                                                                    WHEN 0 THEN rv.boundary_id
                                                                                    ELSE rv.boundary_id + 1
                                                                                END
        LEFT JOIN sys.indexes AS si ON dds.partition_scheme_id = si.data_space_id
        LEFT JOIN sys.partitions AS p ON si.object_id = p.object_id
                                            AND si.index_id = p.index_id
                                            AND dds.destination_id = p.partition_number
        LEFT JOIN sys.dm_db_partition_stats AS dbps ON p.object_id = dbps.object_id
                                                        AND p.partition_id = dbps.partition_id
GROUP BY ds.name ,
        p.partition_number ,
        pf.name ,
        pf.type_desc ,
        pf.fanout ,
        pf.boundary_value_on_right ,
        ps.name ,
        si.object_id ,
        rv.value;
