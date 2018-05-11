
/*
ASI-SQL-43
ASI-SQLUS-43
ASI-SQL-44 
ASI-SQL-44\STG 
ASI-SQLPCN1-10
ASI-SQLPCN2-10
ASI-SQLDS-10
ASI-SQLUCN1-10 
ASI-SQLUCN2-10 
ASI-SQLSS-10
ASI-SQLPCN1-11
ASI-SQLSS-11 
ASI-SQLUCN1-11
ASI-SQLDS-11 
ASI-SQLDs-15
ASI-SQLSS-15
ASI-SQLUCN1-15
ASI-SQLUCN2-15
ASI-SQLPCN1-15
ASI-SQLPCN2-15 
ASI-SQLPCN2-07


*/



SET NOCOUNT ON
GO

Print 'Report for partitioning status on '+@@servername
-- Create tempDB to hold DB names with partitioned tables
IF OBJECT_ID(N'tempdb.dbo.#DBs') IS NOT NULL
	DROP TABLE #DBs

CREATE TABLE #DBs (DBName VARCHAR(50))

-- Insert DB names with partitioned tables
INSERT INTO #DBs (DBName)
EXEC sp_msforeachdb 
'use ?; if exists (select top 1 * from ?.[sys].[partitions] where partition_number >1) select db_name()'
GO

-- Declare variables
DECLARE @DB_Name VARCHAR(50)
DECLARE @Command NVARCHAR(1000)
-- Declare cursor for checking DBs one by one
DECLARE database_cursor CURSOR
FOR

SELECT DBname
FROM #DBs

OPEN database_cursor

FETCH NEXT
FROM database_cursor
INTO @DB_Name

WHILE @@FETCH_STATUS = 0
BEGIN
	-- Prepare sql for last partition check
	SELECT @Command = 'use ' + @DB_Name + ';
	 if (SELECT convert(bigint, max(r.value) ) 
	 FROM [sys].[partition_range_values] r inner join [sys].[partition_functions] f
  on r.function_id = f.function_id) 
  < (select CONVERT([bigint],replace
  (replace(CONVERT([varchar](13),DATEADD(DAY, 1,(DATEADD(MONTH,1 , EOMONTH(getdate())))),(121)),''-'',''''),'' '','''')+''00''))
  Print ''Partitioning issue in DB ' + @DB_Name + ''';' + 'else print ''Partitioning Ok in DB ' + @DB_Name + ''' ;'

	--print @Command;
	EXEC sp_executesql @Command;

	FETCH NEXT
	FROM database_cursor
	INTO @DB_Name
END

CLOSE database_cursor

DEALLOCATE database_cursor



