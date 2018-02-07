select OBJECT_NAME(object_id) TableName, * from sys.dm_db_xtp_table_memory_stats where object_id > 0

-- Memory consumption by internal system structures
SELECT memory_consumer_desc  
     , allocated_bytes/1024 AS allocated_bytes_kb  
     , used_bytes/1024 AS used_bytes_kb  
     , allocation_count  
   FROM sys.dm_xtp_system_memory_consumers 

-- Memory consumption at run-time when accessing memory-optimized tables
SELECT memory_object_address  
     , pages_in_bytes  
     , bytes_used  
     , type 
   FROM sys.dm_os_memory_objects WHERE type LIKE '%xtp%'


-- this DMV accounts for all memory used by the hek_2 engine  
SELECT type  
     , name  
     , memory_node_id  
     , pages_kb/1024 AS pages_MB   
   FROM sys.dm_os_memory_clerks WHERE type LIKE '%xtp%'



select * from sys.memory_optimized_tables_internal_attributes

select * from sys.dm_xtp_transaction_stats

------------------------------------------------------------------------------------------------
-- Add FG anf file for memory optimized objects
ALTER DATABASE [TestDB] 
ADD FILEGROUP [TestDBSampleDB_mod_fg] CONTAINS MEMORY_OPTIMIZED_DATA; 
GO 
ALTER DATABASE [TestDB] 
ADD FILE (NAME='TestDB_mod_dir', FILENAME='C:\SQL2016\TestDB_mod_dir') 
	TO FILEGROUP [TestDBSampleDB_mod_fg];
GO

-- Verify memory optimized files
USE TestDB;
SELECT g.name, g.type_desc, f.physical_name 
 FROM sys.filegroups g JOIN sys.database_files f ON g.data_space_id = f.data_space_id 
 WHERE g.type = 'FX' AND f.type = 2
 GO


 -- Get tables size details
SET NOCOUNT ON
IF EXISTS (SELECT name FROM tempdb..sysobjects WHERE name = '#TableSize')
  DROP TABLE #TableSize

CREATE TABLE #TableSize (name varchar(50), rows int, reserved varchar(15), data varchar(15), index_size varchar(15), unsed varchar(15))
GO

DECLARE @tblname varchar(50)
DECLARE tblname CURSOR FOR
SELECT
  name
FROM sysobjects
WHERE name IN ('APPL_PreferenceItem', 'APPL_PreferenceItemMatrix', 'APPL_PreferenceItemMatrixCellValue', 'APPL_PreferenceItemValue', 'OFFR_Application')

OPEN tblname
FETCH NEXT FROM tblname INTO @tblname

WHILE @@FETCH_STATUS = 0

BEGIN
  INSERT INTO #TableSize
  EXEC sp_spaceused @tblname
  FETCH NEXT FROM tblname INTO @tblname
END

CLOSE tblname
DEALLOCATE tblname

GO

SELECT name Table_Name, rows Total_Rows, reserved Total_Table_Size, data Data_size, index_size Index_Size, unsed Unused_Space
FROM #TableSize

DROP TABLE #TableSize