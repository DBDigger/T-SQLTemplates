-- Get partition details for a table
-- Provide table name in last line of script
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object]
	,p.partition_number AS [p#]
	,fg.NAME AS [filegroup]
	,p.rows
	,au.total_pages AS pages
	,CASE boundary_value_on_right
		WHEN 1
			THEN 'less than'
		ELSE 'less than or equal to'
		END AS comparison
	,rv.value
	,CONVERT(VARCHAR(6), CONVERT(INT, SUBSTRING(au.first_page, 6, 1) + SUBSTRING(au.first_page, 5, 1))) + ':' + CONVERT(VARCHAR(20), CONVERT(INT, SUBSTRING(au.first_page, 4, 1) + SUBSTRING(au.first_page, 3, 1) + SUBSTRING(au.first_page, 2, 1) + SUBSTRING(au.first_page, 1, 1))) AS first_page
FROM sys.partitions p with (nolock)
INNER JOIN sys.indexes i with (nolock) ON p.object_id = i.object_id
	AND p.index_id = i.index_id
INNER JOIN sys.objects o  with (nolock) ON p.object_id = o.object_id
INNER JOIN sys.system_internals_allocation_units au with (nolock) ON p.partition_id = au.container_id
INNER JOIN sys.partition_schemes ps with (nolock) ON ps.data_space_id = i.data_space_id
INNER JOIN sys.partition_functions f with (nolock) ON f.function_id = ps.function_id
INNER JOIN sys.destination_data_spaces dds with (nolock) ON dds.partition_scheme_id = ps.data_space_id
	AND dds.destination_id = p.partition_number
INNER JOIN sys.filegroups fg with (nolock) ON dds.data_space_id = fg.data_space_id
LEFT OUTER JOIN sys.partition_range_values rv with (nolock) ON f.function_id = rv.function_id
	AND p.partition_number = rv.boundary_id
WHERE i.index_id < 2
	AND o.object_id = OBJECT_ID('SalesArchival')
	order by p#


EXEC    [DBAServices].[dbo].[DBA_MergeFirstPartition] N'INVOICEITEMS_archive',  N'wmpoperatorusage'
GO


EXEC	[DBAServices].[dbo].[DBA_MergeLastPartition] 		@pTableName = N'INVOICEITEMS_archive',		@pDatabaseName = N'wmpoperatorusage'
GO 

EXEC	[DBAServices].[dbo].[DBA_GenerateNextPartition] N'INVOICEITEMS_archive',N'wmpoperatorusage'
GO 


Alter partition scheme INVOICEITEMSArchiveps NEXT USED Invoices;  ALTER PARTITION FUNCTION INVOICEITEMSArchivepf() SPLIT RANGE (1675);

ALTER PARTITION FUNCTION USAGESVCSBILLINGSpf() MERGE RANGE (2393)


ALTER TABLE USAGESVCSBILLINGS SWITCH PARTITION 1 TO USAGESVCSBILLINGS_archive PARTITION 1;  

-- Get partitioning archi details
SELECT  distinct OBJECT_NAME(si.object_id) AS object_name,pf.NAME AS pf_name	,ps.NAME AS partition_scheme_name		,ds.NAME AS partition_filegroup	
FROM sys.destination_data_spaces AS dds
JOIN sys.data_spaces AS ds ON dds.data_space_id = ds.data_space_id
JOIN sys.partition_schemes AS ps ON dds.partition_scheme_id = ps.data_space_id
JOIN sys.partition_functions AS pf ON ps.function_id = pf.function_id
inner JOIN sys.indexes AS si ON dds.partition_scheme_id = si.data_space_id



-- Add new partition at the end 
ALTER PARTITION SCHEME TMUSGSMPS NEXT USED [Primary]
GO

ALTER PARTITION FUNCTION TMUSGSMPF() SPLIT RANGE ('2014-03-31 00:00:00.000')
GO


-- Generate next partition by using USP
USE DBAServices;
EXEC	[dbo].[GenerateNextPartition]
		@pTableName = N'ROGERS_SMS_Archive',
		@pDatabaseName = N'wmpoperatorusage'
GO 100


-- Get partitioning info
SELECT 

      i.object_id,

      i.name AS IndexName,

      p.partition_number,

      fg.name AS FileGroupName,

      value,

      ps.name AS SchemaName,

      f.name FunctionName

FROM sys.partitions p

JOIN sys.indexes i

      ON (p.object_id = i.object_id

          AND p.index_id = i.index_id)

JOIN sys.partition_schemes ps

      ON (ps.data_space_id = i.data_space_id)

JOIN sys.partition_functions f

      ON (f.function_id = ps.function_id)

LEFT JOIN sys.partition_range_values rv   

      ON (f.function_id = rv.function_id

          AND p.partition_number = rv.boundary_id)

JOIN sys.destination_data_spaces dds

      ON (dds.partition_scheme_id = ps.data_space_id

          AND dds.destination_id = p.partition_number)

JOIN sys.filegroups fg

      ON (dds.data_space_id = fg.data_space_id)

WHERE i.index_id < 2

      AND i.object_id = Object_Id('<ObjectName>')



-- Get partitioning column for a table
SELECT CAST(ic.partition_ordinal AS INT) AS [ID]
	,c.NAME AS ColumnName
FROM sys.tables AS tbl
INNER JOIN sys.indexes AS idx ON idx.object_id = tbl.object_id
	AND idx.index_id < 2
INNER JOIN sys.index_columns ic ON (ic.partition_ordinal > 0)
	AND (
		ic.index_id = idx.index_id
		AND ic.object_id = CAST(tbl.object_id AS INT)
		)
INNER JOIN sys.columns c ON c.object_id = ic.object_id
	AND c.column_id = ic.column_id
WHERE (
		tbl.NAME = 'invoiceitemdetails'
		AND SCHEMA_NAME(tbl.schema_id) = 'dbo'
		)
ORDER BY [ID]

-- Get partitioning function and scheme for a table
SELECT ps.NAME PartitionScheme
	,pf.NAME PartitionFunction
FROM sys.indexes i
JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
JOIN sys.partition_functions pf ON pf.function_id = ps.function_id
WHERE i.object_id = object_id('INVOICEITEMDETAILS')


 -- Get details
 SELECT pf.NAME AS pf_name	,ps.NAME AS partition_scheme_name	,p.partition_number	,ds.NAME AS partition_filegroup
	,OBJECT_NAME(si.object_id) AS object_name	,rv.value AS range_value	,SUM(CASE 
			WHEN si.index_id IN (	1	,0)	THEN p.rows ELSE 0
			END) AS num_rows
FROM sys.destination_data_spaces AS dds
JOIN sys.data_spaces AS ds ON dds.data_space_id = ds.data_space_id
JOIN sys.partition_schemes AS ps ON dds.partition_scheme_id = ps.data_space_id
JOIN sys.partition_functions AS pf ON ps.function_id = pf.function_id
LEFT JOIN sys.partition_range_values AS rv ON pf.function_id = rv.function_id
	AND dds.destination_id = CASE pf.boundary_value_on_right
		WHEN 0
			THEN rv.boundary_id
		ELSE rv.boundary_id + 1
		END
LEFT JOIN sys.indexes AS si ON dds.partition_scheme_id = si.data_space_id
LEFT JOIN sys.partitions AS p ON si.object_id = p.object_id
	AND si.index_id = p.index_id
	AND dds.destination_id = p.partition_number
LEFT JOIN sys.dm_db_partition_stats AS dbps ON p.object_id = dbps.object_id
	AND p.partition_id = dbps.partition_id
GROUP BY ds.NAME	,p.partition_number	,pf.NAME	,pf.type_desc	,pf.fanout	,pf.boundary_value_on_right	,ps.NAME	,si.object_id	,rv.value;



-- Get partition function details
SELECT PF.[name],RV.boundary_id	,RV.[value]
FROM sys.partition_functions PF
INNER JOIN sys.partition_range_values RV ON PF.function_id = RV.function_id
WHERE PF.NAME = 'myRangePF1'
GO


-- get partition objects in a file
select * FROM DBAServices.dbo.DbaTablePartitions
WHERE FILEGROUP = 'USAGE'
GO

-- Get partition schemes in a file
select distinct FG.Name as FileGroupName
    ,ps.Name
 from sys.partition_schemes PS
 inner join sys.destination_data_spaces as DDS 
    on DDS.partition_scheme_id = PS.data_space_id
 inner join sys.filegroups as FG 
    on FG.data_space_id = DDS.data_space_ID 
 where fg.name = 'usage'
GO 

-- Get tables in a file 
 SELECT o.[name], o.[type], i.[name], i.[index_id], f.[name]
FROM sys.indexes i
INNER JOIN sys.filegroups f
ON i.data_space_id = f.data_space_id
INNER JOIN sys.all_objects o
ON i.[object_id] = o.[object_id]
WHERE i.data_space_id = f.data_space_id
AND o.type = 'U' -- User Created Tables
and f.name = 'usage'
GO

-- get list of partitioned tables
SELECT t.name AS TableName, ps.name AS PartitionScheme,
    ps.data_space_id, pf.name AS PartitionFunction, pf.function_id
FROM sys.TABLES t with (nolock)
    JOIN sys.indexes i  with (nolock) ON t.object_id = i.object_id
    JOIN sys.partition_schemes ps  with (nolock) ON i.data_space_id = ps.data_space_id
    JOIN sys.partition_functions pf  with (nolock) ON ps.function_id = pf.function_id
order by tablename --INVOICEITEMDETAILS


select $partition.INVOICEITEMDETAILSPF(1919)
GO



-- Listing 2. Query to determine table filegroup by index and partition

SELECT OBJECT_SCHEMA_NAME(t.object_id) AS schema_name
,t.name AS table_name
,i.index_id
,i.name AS index_name
,p.partition_number
,fg.name AS filegroup_name

FROM sys.tables t  with (nolock)
INNER JOIN sys.indexes i with (nolock) ON t.object_id = i.object_id
INNER JOIN sys.partitions p with (nolock) ON i.object_id=p.object_id AND i.index_id=p.index_id
LEFT OUTER JOIN sys.partition_schemes ps with (nolock) ON i.data_space_id=ps.data_space_id
LEFT OUTER JOIN sys.destination_data_spaces dds with (nolock) ON ps.data_space_id=dds.partition_scheme_id AND p.partition_number=dds.destination_id
INNER JOIN sys.filegroups fg with (nolock) ON COALESCE(dds.data_space_id, i.data_space_id)=fg.data_space_id


-- Get partitioning summary
--paritioned table and index details
SELECT OBJECT_NAME(p.object_id) AS ObjectName
	,i.NAME AS IndexName
	,p.index_id AS IndexID
	,ds.NAME AS PartitionScheme
	,p.partition_number AS PartitionNumber
	,fg.NAME AS FileGroupName
	,prv_left.value AS LowerBoundaryValue
	,prv_right.value AS UpperBoundaryValue
	,CASE pf.boundary_value_on_right
		WHEN 1
			THEN 'RIGHT'
		ELSE 'LEFT'
		END AS Range
	,p.rows AS Rows
FROM sys.partitions AS p
JOIN sys.indexes AS i ON i.object_id = p.object_id
	AND i.index_id = p.index_id
JOIN sys.data_spaces AS ds ON ds.data_space_id = i.data_space_id
JOIN sys.partition_schemes AS ps ON ps.data_space_id = ds.data_space_id
JOIN sys.partition_functions AS pf ON pf.function_id = ps.function_id
JOIN sys.destination_data_spaces AS dds2 ON dds2.partition_scheme_id = ps.data_space_id
	AND dds2.destination_id = p.partition_number
JOIN sys.filegroups AS fg ON fg.data_space_id = dds2.data_space_id
LEFT JOIN sys.partition_range_values AS prv_left ON ps.function_id = prv_left.function_id
	AND prv_left.boundary_id = p.partition_number - 1
LEFT JOIN sys.partition_range_values AS prv_right ON ps.function_id = prv_right.function_id
	AND prv_right.boundary_id = p.partition_number
WHERE OBJECTPROPERTY(p.object_id, 'ISMSShipped') = 0

UNION ALL

--non-partitioned table/indexes
SELECT OBJECT_NAME(p.object_id) AS ObjectName
	,i.NAME AS IndexName
	,p.index_id AS IndexID
	,NULL AS PartitionScheme
	,p.partition_number AS PartitionNumber
	,fg.NAME AS FileGroupName
	,NULL AS LowerBoundaryValue
	,NULL AS UpperBoundaryValue
	,NULL AS Boundary
	,p.rows AS Rows
FROM sys.partitions AS p
JOIN sys.indexes AS i ON i.object_id = p.object_id
	AND i.index_id = p.index_id
JOIN sys.data_spaces AS ds ON ds.data_space_id = i.data_space_id
JOIN sys.filegroups AS fg ON fg.data_space_id = i.data_space_id
WHERE OBJECTPROPERTY(p.object_id, 'ISMSShipped') = 0
ORDER BY ObjectName
	,IndexID
	,PartitionNumber;
	
	
	-- Get partitioned tables
SELECT t.name
FROM sys.TABLES t with (nolock)
    JOIN sys.indexes i  with (nolock) ON t.object_id = i.object_id
    JOIN sys.partition_schemes ps  with (nolock) ON i.data_space_id = ps.data_space_id
    JOIN sys.partition_functions pf  with (nolock) ON ps.function_id = pf.function_id
order by tablename --INVOICEITEMDETAILS


-- get non partitioned tables
select schema_name(schema_id)+'.'+name
from sys.objects where type = 'U' and is_ms_shipped = 0 and name not in 
(SELECT t.name
FROM sys.TABLES t with (nolock)
    JOIN sys.indexes i  with (nolock) ON t.object_id = i.object_id
    JOIN sys.partition_schemes ps  with (nolock) ON i.data_space_id = ps.data_space_id
    JOIN sys.partition_functions pf  with (nolock) ON ps.function_id = pf.function_id)







	---------------------------------------------------------------------------------------

SELECT DISTINCT
        N'RowsOfData' = p.[rows] ,
        N'SchemaName' = s.NAME ,
        N'TableName' = o.NAME ,
        N'PartitionFileGroup' = ds2.NAME ,
        N'FileName' = files.[FileName] ,
        N'Physical File Name' = files.physical_name ,
        N'PartitionNumber' = dds.destination_id ,
        N'BoundaryValue' = prv.value ,
        N'IndexName' = i.NAME ,
        N'IndexType' = i.type_desc ,
        N'PartitionScheme' = ps.NAME ,
        N'PartitionFunction' = pf.NAME ,
        N'DataSpaceName' = ds.NAME ,
        N'DataSpaceType' = ds.type_desc ,
        N'RightBoundary' = pf.boundary_value_on_right , -- 1 = TRUE (values are less than boundary)
                 -- 0 = FALSE (values are less than or equal to boundary)
        N'DatabaseName' = DB_NAME()
FROM    sys.objects AS o
        INNER JOIN sys.schemas AS s ON o.[schema_id] = s.[schema_id]
        INNER JOIN sys.partitions AS p ON o.[object_id] = p.[object_id]
        INNER JOIN sys.indexes AS i ON p.[object_id] = i.[object_id]
                                       AND p.index_id = i.index_id
        INNER JOIN sys.data_spaces AS ds ON i.data_space_id = ds.data_space_id
        LEFT OUTER JOIN sys.partition_schemes AS ps ON ds.data_space_id = ps.data_space_id
        LEFT OUTER JOIN sys.partition_functions AS pf ON ps.function_id = pf.function_id
        LEFT OUTER JOIN sys.partition_range_values AS prv ON pf.function_id = prv.function_id
                                                             AND p.partition_number = prv.boundary_id
        LEFT OUTER JOIN sys.destination_data_spaces AS dds ON ps.data_space_id = dds.partition_scheme_id
                                                              AND p.partition_number = dds.destination_id
        LEFT OUTER JOIN sys.data_spaces AS ds2 ON dds.data_space_id = ds2.data_space_id
        FULL OUTER JOIN ( SELECT    DB_NAME() AS dbname ,
                                    database_files.name AS [FileName] ,
                                    database_files.physical_name ,
                                    filegroups.name AS filegroupname
                          FROM      sys.database_files --use sys.master_files if the database is read only and you want to see the metadata that is the database
                                    JOIN sys.filegroups ON database_files.data_space_id = filegroups.data_space_id
                                    JOIN sys.dm_io_virtual_file_stats(DB_ID(),
                                                              DEFAULT) DIVFS ON database_files.file_id = DIVFS.file_id
                        ) AS files ON files.filegroupname = ds2.name
WHERE   s.name = N'dbo' -- schema name 
        
        AND i.[index_id] = 1
ORDER BY TableName ,
        PartitionNumber ,
        RowsofData ASC ,
        PartitionScheme ,
        DatabaseName;
----------------------------------------------------------------------------------------------
-- Get tables and space in a FG
SELECT DS.name AS DataSpaceName 
      
      , case  when ps.data_space_id  is null  then 'No' else 'Yes' end as IsPartitioned 
     
      ,SCH.name AS SchemaName 
            
      ,OBJ.name AS ObjectName 
     ,sum(AU.total_pages / 128) AS TotalSizeMB 

FROM sys.data_spaces AS DS with (nolock) 
     INNER JOIN sys.allocation_units AS AU with (nolock) 
         ON DS.data_space_id = AU.data_space_id 
     INNER JOIN sys.partitions AS PA  with (nolock)
         ON (AU.type IN (1, 3)  
             AND AU.container_id = PA.hobt_id) 
            OR 
            (AU.type = 2 
             AND AU.container_id = PA.partition_id) 
     INNER JOIN sys.objects AS OBJ  with (nolock)
         ON PA.object_id = OBJ.object_id 
     INNER JOIN sys.schemas AS SCH  with (nolock)
         ON OBJ.schema_id = SCH.schema_id 
     LEFT JOIN sys.indexes AS IDX  with (nolock)

         ON PA.object_id = IDX.object_id 
            AND PA.index_id = IDX.index_id
			 left JOIN sys.partition_schemes ps ON ps.data_space_id = idx.data_space_id 
          
           where AU.total_pages / 128 > 0
           group by DS.name ,SCH.name,OBJ.name, ps.data_space_id
           order by TotalSizeMB  desc