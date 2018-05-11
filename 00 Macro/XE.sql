-- Extended Event for finding *long running query*
IF EXISTS (SELECT *	FROM sys.server_event_sessions WHERE name = 'LongRunningQueries')
	DROP EVENT SESSION [LongRunningQueries] ON SERVER
GO

-- Create Event
CREATE EVENT SESSION [LongRunningQueries] ON SERVER

-- Add event to capture event
ADD EVENT sqlserver.sql_statement_completed
(
-- Add action - event property
ACTION (sqlserver.database_name,sqlserver.sql_text, sqlserver.tsql_stack)
-- Criteria to capture statements
WHERE sqlserver.sql_statement_completed.duration > 200
-- WHERE sqlserver.database_name = 'DBNameHere'
)


-- Add target for capturing the data - XML File
ADD TARGET package0.event_file (SET filename = N'K:\MSSQL\LongRunningQueries.xel')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB
        ,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO


ALTER EVENT SESSION [LongRunningQueries] ON SERVER STATE = START;
GO


-- Create CTE and statement to group and display the results from file
WITH CTE_ExecutedSQLStatements
AS
(SELECT [XML Data]
		,[XML Data].value('(event/data[1])[1]','VARCHAR(100)') AS Database_ID
		,[XML Data].value('(event/data[2])[1]','INT') AS OBJECT_ID
		,[XML Data].value('(event/data[3])[1]','INT') AS object_type
	   ,[XML Data].value ('(/event[@name=''sql_statement_completed'']/@timestamp)[1]', 'DATETIME') AS [Time]
	   ,[XML Data].value ('(/event/data[@name=''duration'']/value)[1]', 'int') AS [Duration]
	   ,[XML Data].value ('(/event/data[@name=''cpu_time'']/value)[1]', 'int') AS [CPU]
	   ,[XML Data].value ('(/event/data[@name=''logical_reads'']/value)[1]', 'int') AS [logical_reads]
	   ,[XML Data].value ('(/event/data[@name=''physical_reads'']/value)[1]', 'int') AS [physical_reads]
	   ,[XML Data].value ('(/event/action[@name=''sql_text'']/value)[1]', 'varchar(max)') AS [SQL Statement]
	   ,[XML Data].value ('(/event/action[@name=''database_name'']/value)[1]', 'varchar(max)') AS [database_name]
	FROM (SELECT object_name AS [Event]	   ,CONVERT(XML, event_data) AS [XML Data]
		FROM sys.fn_xe_file_target_read_file
		('K:MSSQL\LongRunningQueries*.xel', NULL, NULL, NULL)) AS v)

SELECT [SQL Statement] AS [SQL Statement]
	, [database_name]
   ,SUM(Duration) AS [Total Duration]
   ,SUM(CPU) AS [Total CPU]
   ,SUM(Logical_Reads) AS [Total Logical Reads]
   ,SUM(Physical_Reads) AS [Total Physical Reads]
FROM CTE_ExecutedSQLStatements
GROUP BY [SQL Statement], [database_name]
ORDER BY [Total Duration] DESC
GO


-- Stop the event
ALTER EVENT SESSION [LongRunningQueries] ON SERVER STATE = STOP
GO

-- Clean up. Drop the event
DROP EVENT SESSION [LongRunningQueries] ON SERVER
GO