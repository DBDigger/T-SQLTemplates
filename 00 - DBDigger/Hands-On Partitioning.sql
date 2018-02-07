--******************
--Copyright 2013, Brent Ozar PLF, LLC DBA Brent Ozar Unlimited.
--******************
--******************
--1. CREATE OUR DEMO DATABASE
--Blow it away if it already exists
--******************
IF DB_ID('PartitionThis') IS NOT NULL 
    BEGIN
        USE master; 
        ALTER DATABASE [PartitionThis] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        DROP DATABASE [PartitionThis];
    END 
GO

CREATE DATABASE [PartitionThis]
GO

ALTER DATABASE [PartitionThis]
MODIFY FILE ( NAME = N'PartitionThis', SIZE = 256MB , MAXSIZE = 10GB , FILEGROWTH = 512MB );
ALTER DATABASE [PartitionThis]	
MODIFY FILE ( NAME = N'PartitionThis_log', SIZE = 128MB , FILEGROWTH = 128MB );
GO

USE PartitionThis;
GO

--*******************************
--2 CREATE HELPER OBJECT
--*******************************
CREATE SCHEMA [ph] AUTHORIZATION dbo;
GO
--Create a view to see partition information by filegroup
CREATE VIEW ph.FileGroupDetail
AS
    SELECT  pf.name AS pf_name ,
            ps.name AS partition_scheme_name ,
            p.partition_number ,
            ds.name AS partition_filegroup ,
            OBJECT_NAME(si.object_id) AS object_name ,
            rv.value AS range_value ,
            SUM(CASE WHEN si.index_id IN ( 1, 0 ) THEN p.rows
                     ELSE 0
                END) AS num_rows
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
GO



--******************
--3. CREATE OUR HERO, THE PARTITION FUNCTION
--This one is RIGHT bound
--******************

--Create the partition function: myPF
--RIGHT means that the boundary points are the LOWER end of the range
CREATE PARTITION FUNCTION myPF (INT)
AS RANGE RIGHT FOR VALUES
(2, 3);
GO

--Here's how we see the partition function
SELECT  name ,
        type_desc ,
        fanout ,
        boundary_value_on_right ,
        create_date
FROM    sys.partition_functions
WHERE   name = 'myPF';
GO

--******************
--4. Add filegroups and files
--******************
ALTER DATABASE PartitionThis ADD FILEGROUP FG1
GO
ALTER DATABASE PartitionThis ADD FILEGROUP FG2
GO
ALTER DATABASE PartitionThis ADD FILEGROUP FG3
GO

--Add files to the filegroups
--This is being done dynamically so it will work on different instances, but it makes some big assumptions!
DECLARE @path NVARCHAR(256) ,
    @i TINYINT= 1 ,
    @sql NVARCHAR(4000);
SELECT TOP 1
        @path = LEFT(physical_name, LEN(physical_name) - 4)
FROM    sys.database_files
WHERE   name = 'PartitionThis'

WHILE @i <= 3 
    BEGIN
        SET @sql = N'ALTER DATABASE PartitionThis ADD FILE (name=File' + CAST(@i AS NCHAR(1)) + ', 
		 filename=''' + @path + N'File' + CAST(@i AS NCHAR(1)) + '.ndf' + ''',
		 size=128MB, filegrowth=256MB) TO FILEGROUP FG' + CAST(@i AS NCHAR(1))
	--show the command we're running
        RAISERROR (@sql,0,0)
	
	--run it
        EXEC sp_executesql @sql;
        SET @i += 1;
    END
GO

--******************
--5. Create the partition scheme: MyPS 
--******************
CREATE PARTITION SCHEME MyPS 
AS PARTITION MyPF
TO (FG1, FG2, FG3);
GO

--******************
--6. Create a table with a clustered index on the partition scheme
--Add some rows
--******************
CREATE TABLE dbo.MyPartitionedTable
    (
      i INT NOT NULL ,
      j VARCHAR(10) DEFAULT ( 'BOO!' )
    )
ON  MyPS(i);
GO

CREATE CLUSTERED INDEX cx_MyPartitionedTable_i ON dbo.MyPartitionedTable(i);
GO


--Insert rows into each partition
INSERT  dbo.MyPartitionedTable
VALUES  ( 1, 'whee!' );
INSERT  dbo.MyPartitionedTable
VALUES  ( 2, 'whoo!' );
INSERT  dbo.MyPartitionedTable
VALUES  ( 2, 'whoo!' );
INSERT  dbo.MyPartitionedTable
VALUES  ( 3, 'wha?' );
INSERT  dbo.MyPartitionedTable
VALUES  ( 3, 'wha?' );
INSERT  dbo.MyPartitionedTable
VALUES  ( 3, 'wha?' );
GO

--We should see one row in FG1, two in FG2, and three in FG3
SELECT  *
FROM    ph.FileGroupDetail;
GO

--******************
--7. We want to switch out the data with IDs=0.
--This data is sitting in FG1
--******************
--Create the table to switch out to
CREATE TABLE dbo.MySwitchOutTable
    (
      i INT NOT NULL ,
      j VARCHAR(10)
    )
ON  FG1;
GO
CREATE CLUSTERED INDEX cx_MySwitchOutTable_i ON dbo.MySwitchOutTable(i);
GO

ALTER TABLE dbo.MyPartitionedTable SWITCH PARTITION 1 TO dbo.MySwitchOutTable;
GO

--We should see 0 rows in FG1 now.
--We still have two rows in FG2, and three in FG3
SELECT  *
FROM    ph.FileGroupDetail;
GO

--******************
--8. Now let's get that filegroup out of the Partition Function
--******************

--FG1 is empty and we want to get rid of it.
--We want to make it so the partition function doesn't know about it.
--To do that, we need to merge the boundary point
ALTER PARTITION FUNCTION myPF () MERGE RANGE (2);

--Check out what happened
SELECT  *
FROM    ph.FileGroupDetail;
GO

--Wait a second--- we're still using FG1!
--The rows that were on FG2 were dynamically moved onto FG1 and FG2 was removed
--That could be kind of a big deal if that was a lot of rows.





--------------------------------------
--OK, let's start over and do this right.
--------------------------------------


--******************
--Copyright 2013, Brent Ozar PLF, LLC DBA Brent Ozar Unlimited.
--******************
--******************
--1. CREATE OUR DEMO DATABASE
--Blow it away if it already exists
--******************
IF DB_ID('PartitionThis') IS NOT NULL 
    BEGIN
        USE master; 
        ALTER DATABASE [PartitionThis] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        DROP DATABASE [PartitionThis];
    END 
GO

CREATE DATABASE [PartitionThis]
GO

ALTER DATABASE [PartitionThis]
MODIFY FILE ( NAME = N'PartitionThis', SIZE = 256MB , MAXSIZE = 10GB , FILEGROWTH = 512MB );
ALTER DATABASE [PartitionThis]	
MODIFY FILE ( NAME = N'PartitionThis_log', SIZE = 128MB , FILEGROWTH = 128MB );
GO

USE PartitionThis;
GO

--*******************************
--2 CREATE HELPER OBJECT
--*******************************
CREATE SCHEMA [ph] AUTHORIZATION dbo;
GO

--Create a view to see partition information by filegroup
CREATE VIEW ph.FileGroupDetail
AS
    SELECT  pf.name AS pf_name ,
            ps.name AS partition_scheme_name ,
            p.partition_number ,
            ds.name AS partition_filegroup ,
            OBJECT_NAME(si.object_id) AS object_name ,
            rv.value AS range_value ,
            SUM(CASE WHEN si.index_id IN ( 1, 0 ) THEN p.rows
                     ELSE 0
                END) AS num_rows
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
GO

--******************
--3. CREATE OUR HERO, THE PARTITION FUNCTION
--This one is RIGHT bound
--******************

--This time we've added two more boundary points
--Create the partition function: myPF
--RIGHT means that the boundary points are the LOWER end of the range
CREATE PARTITION FUNCTION myPF (INT)
AS RANGE RIGHT FOR VALUES
(1, 2, 3, 4);
GO

--Here's how we see the partition function
SELECT  name ,
        type_desc ,
        fanout ,
        boundary_value_on_right ,
        create_date
FROM    sys.partition_functions
WHERE   name = 'myPF';
GO

--******************
--4. Add filegroups and files
--Two more this time
--******************
ALTER DATABASE PartitionThis ADD FILEGROUP FG1
GO
ALTER DATABASE PartitionThis ADD FILEGROUP FG2
GO
ALTER DATABASE PartitionThis ADD FILEGROUP FG3
GO
ALTER DATABASE PartitionThis ADD FILEGROUP FG4
GO
ALTER DATABASE PartitionThis ADD FILEGROUP FG5
GO

--Add files to the filegroups
--This is being done dynamically so it will work on different instances, but it makes some big assumptions!
DECLARE @path NVARCHAR(256) ,
    @i TINYINT= 1 ,
    @sql NVARCHAR(4000);
SELECT TOP 1
        @path = LEFT(physical_name, LEN(physical_name) - 4)
FROM    sys.database_files
WHERE   name = 'PartitionThis'

WHILE @i <= 5 
    BEGIN
        SET @sql = N'ALTER DATABASE PartitionThis ADD FILE (name=File' + CAST(@i AS NCHAR(1)) + ', 
		 filename=''' + @path + N'File' + CAST(@i AS NCHAR(1)) + '.ndf' + ''',
		 size=128MB, filegrowth=256MB) TO FILEGROUP FG' + CAST(@i AS NCHAR(1))
	--show the command we're running
        RAISERROR (@sql,0,0)
	
	--run it
        EXEC sp_executesql @sql;
        SET @i += 1;
    END
GO

--******************
--5. Create the partition scheme: MyPS 
--We've got to map to two more filegroups this time
--******************
CREATE PARTITION SCHEME MyPS 
AS PARTITION MyPF
TO (FG1, FG2, FG3, FG4, FG5);


--******************
--6. Create a table with a clustered index on the partition scheme
--Add some rows
--******************
CREATE TABLE dbo.MyPartitionedTable
    (
      i INT NOT NULL ,
      j VARCHAR(10) DEFAULT ( 'BOO!' )
    )
ON  MyPS(i);
GO

CREATE CLUSTERED INDEX cx_MyPartitionedTable_i ON dbo.MyPartitionedTable(i);

--We're inserting the same amount of rows
--We've purposely created two filegroups which are empty
--Insert rows into three of the partitions
INSERT  dbo.MyPartitionedTable
VALUES  ( 1, 'whee!' );
INSERT  dbo.MyPartitionedTable
VALUES  ( 2, 'whoo!' );
INSERT  dbo.MyPartitionedTable
VALUES  ( 2, 'whoo!' );
INSERT  dbo.MyPartitionedTable
VALUES  ( 3, 'wha?' );
INSERT  dbo.MyPartitionedTable
VALUES  ( 3, 'wha?' );
INSERT  dbo.MyPartitionedTable
VALUES  ( 3, 'wha?' );
GO

--We should see one row in FG2, two in FG3, and three in FG4
--FG1 and FG5 should have 0 rows.
--This is our "Empty Filegroup Sandwich"
SELECT  *
FROM    ph.FileGroupDetail;
GO

--******************
--7. We want to switch out the data with IDs=0.
--This data is sitting in FG2, 
--So we must put the switch-out table on the same filegroup
--******************

CREATE TABLE dbo.MySwitchOutTable
    (
      i INT NOT NULL ,
      j VARCHAR(10)
    )
ON  FG2;
GO
CREATE CLUSTERED INDEX cx_MySwitchOutTable_i ON dbo.MySwitchOutTable(i);
GO

ALTER TABLE dbo.MyPartitionedTable SWITCH PARTITION 2 TO dbo.MySwitchOutTable;
GO

--We should see 0 rows in FG2 now.
--We still have two rows in FG3, and three in FG4.
--FG1 and FG5 still have 0 rows (they always have!)
SELECT  *
FROM    ph.FileGroupDetail;
GO

--******************
--8. Now let's get that filegroup out of the Partition Function
--******************

--FG2 is empty and we want to get rid of it.
--We want to make it so the partition function doesn't know about it.
--To do that, we need to merge the boundary point
ALTER PARTITION FUNCTION myPF () MERGE RANGE (1);

--Check out what happened
SELECT  *
FROM    ph.FileGroupDetail;
GO

--Sure enough, we got rid of FG2.
--Most importantly, there was no data movement in merging the boundary point
--We made sure of that by having no data on each side of it.
