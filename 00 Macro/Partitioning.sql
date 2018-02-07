-- select CONVERT([bigint],replace(replace(CONVERT([varchar](13),getdate(),(121)),'-',''),' ',''))
exec sp_msforeachdb 'use ?; if exists (select top 1 * from ?.[sys].[partitions] where partition_number >1) select db_name()'
GO

use WESP_arch_pt
GO
-- get list of partitioned tables
SELECT schema_name(t.schema_id)+'.'+t.name AS TableName, ps.name AS PartitionScheme,
    ps.data_space_id, pf.name AS PartitionFunction, pf.function_id
FROM sys.objects t with (nolock)
    JOIN sys.indexes i  with (nolock) ON t.object_id = i.object_id
    JOIN sys.partition_schemes ps  with (nolock) ON i.data_space_id = ps.data_space_id
    JOIN sys.partition_functions pf  with (nolock) ON ps.function_id = pf.function_id
order by tablename --INVOICEITEMDETAILS
GO

--Alter partition scheme INVOICEITEMSArchiveps NEXT USED Invoices;  ALTER PARTITION FUNCTION INVOICEITEMSArchivepf() SPLIT RANGE (1675);

--ALTER PARTITION FUNCTION USAGESVCSBILLINGSpf() MERGE RANGE (2393)

--ALTER TABLE USAGESVCSBILLINGS SWITCH PARTITION 1 TO USAGESVCSBILLINGS_archive PARTITION 1; 

	SELECT b.groupname AS 'File Group'
	,a.NAME
	,physical_name
FROM sys.database_files a(NOLOCK)
RIGHT OUTER JOIN sysfilegroups b(NOLOCK) ON a.data_space_id = b.groupid
ORDER BY 1 desc


exec ADM_Support..SP_partitioning_filecreation @db_name = 'BI_MDM', @partition_month = '2017-12-01', @file_path = 'F:\MSSQLDB\Data\'


ALTER DATABASE [BI_EDW] ADD FILEGROUP [ASI2017_M11_PARTITIONS]
GO
ALTER DATABASE [BI_EDW] ADD FILE ( NAME = N'BI_EDW_2017_M11_file1_PARTITIONS', FILENAME = N'F:\MSSQLDB\Data\BI_EDW_2017_M11_file1_PARTITIONS.ndf' , SIZE = 1048576KB , FILEGROWTH = 262144KB ) TO FILEGROUP [ASI2017_M11_PARTITIONS]
GO
ALTER DATABASE [BI_EDW] ADD FILE ( NAME = N'BI_EDW_2017_M11_file2_PARTITIONS', FILENAME = N'F:\MSSQLDB\Data\BI_EDW_2017_M11_file2_PARTITIONS.ndf' , SIZE = 1048576KB , FILEGROWTH = 262144KB ) TO FILEGROUP [ASI2017_M11_PARTITIONS]
GO
ALTER DATABASE [BI_EDW] ADD FILE ( NAME = N'BI_EDW_2017_M11_file3_PARTITIONS', FILENAME = N'F:\MSSQLDB\Data\BI_EDW_2017_M11_file3_PARTITIONS.ndf' , SIZE = 1048576KB , FILEGROWTH = 262144KB ) TO FILEGROUP [ASI2017_M11_PARTITIONS]
GO


select 'delete from '+ schema_name(o.schema_id)+'.'+o.name +' where [PART_YYYYMMDDHH] >=  2017090100;' from sys.indexes i inner join sys.objects o on i.object_id = o.object_id where i.type > = 4 order by 1


use ASI_StatsRaw
GO
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
	AND o.object_id in (SELECT top 1 object_id(schema_name(t.schema_id)+'.'+t.name )
FROM sys.objects t with (nolock)
    JOIN sys.indexes i  with (nolock) ON t.object_id = i.object_id
    JOIN sys.partition_schemes ps  with (nolock) ON i.data_space_id = ps.data_space_id
    JOIN sys.partition_functions pf  with (nolock) ON ps.function_id = pf.function_id)
	order by p# desc