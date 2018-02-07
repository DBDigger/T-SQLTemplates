/****************************************************/
/* Created by: SQL Server 2014 Profiler          */
/* Date: 05/09/2014  11:11:14 AM         */
/****************************************************/


-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
set @maxfilesize = 100 

-- Please replace the text InsertFileNameHere, with an appropriate
-- filename prefixed by a path, e.g., c:\MyFolder\MyTrace. The .trc extension
-- will be appended to the filename automatically. If you are writing from
-- remote server to local drive, please use UNC path and make sure server has
-- write access to your network share

exec sp_trace_create @TraceID output, 0, N'D:\Traces\Sept09', @maxfilesize, NULL 

-- Client side File and Table cannot be scripted

-- Set the events
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 10, 16, @on
exec sp_trace_setevent @TraceID, 10, 1,  @on
exec sp_trace_setevent @TraceID, 10, 17, @on
exec sp_trace_setevent @TraceID, 10, 18, @on
exec sp_trace_setevent @TraceID, 10, 12, @on
exec sp_trace_setevent @TraceID, 10, 13, @on
exec sp_trace_setevent @TraceID, 10, 14, @on
exec sp_trace_setevent @TraceID, 12, 16, @on
exec sp_trace_setevent @TraceID, 12, 1,  @on
exec sp_trace_setevent @TraceID, 12, 17, @on
exec sp_trace_setevent @TraceID, 12, 14, @on
exec sp_trace_setevent @TraceID, 12, 18, @on
exec sp_trace_setevent @TraceID, 12, 12, @on
exec sp_trace_setevent @TraceID, 12, 13, @on


-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

set @bigintfilter = 20000000
exec sp_trace_setfilter @TraceID, 13, 0, 4, @bigintfilter

set @bigintfilter = NULL
exec sp_trace_setfilter @TraceID, 13, 0, 1, @bigintfilter

-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go



----------------------------------
-- Create result Table
CREATE TABLE TraceResults_Sept07 (  TextData VARCHAR(max), Duration INT, Reads INT, Writes INT, CPU INT, StartTime DATETIME, ProcedureName VARCHAR(100))
GO

-- populate trace result table
INSERT INTO TraceResults_Sept07 (TextData, Duration, Reads, Writes, CPU, StartTime) 
SELECT TextData, Duration/1000, Reads, Writes, CPU, StartTime
FROM fn_trace_gettable('D:\Traces\LongRunningTraceSep72015.trc',1)

-- get procedure name
UPDATE TraceResults_Sept07 SET ProcedureName = LEFT( RIGHT(TextData, LEN(TextData) - CHARINDEX(' ',TextData, CHARINDEX('Exec',TextData))),
      CHARINDEX(' ', RIGHT(TextData, LEN(TextData) - CHARINDEX(' ',TextData, CHARINDEX('Exec',TextData))) + ' ') )
where TextData like '%exec%'

-- Get data
select procedurename, (Sum(duration)/1000)/1000 TimeImpact, sum(reads) ReadImpact, sum(cpu) CPUImpact, count(*) as Occurance
from TraceResults_Sept07
group by procedurename
order by TimeImpact desc