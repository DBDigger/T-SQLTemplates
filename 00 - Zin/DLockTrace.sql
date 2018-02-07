/****************************************************/
/* Created by: SQL Server 2008 Profiler             */
/* Date: 10/01/2014  07:40:39 AM         */
/****************************************************/

/* Verify the current trace status
select * from sys.traces

EXEC sp_trace_setstatus @traceid = 2, @status = 0; -- Provide @traceID to Stop/Pause the Trace
EXEC sp_trace_setstatus @traceid = 2, @status = 1; -- Provide @traceID to Starts the Trace
EXEC sp_trace_setstatus @traceid = 2, @status = 2; -- Provide @traceID to Close the trace

-- Get traces that are Enabled
DBCC TRACESTATUS


-- Set trace on for deadlock details
DBCC TRACEON (1204, -1)
GO

-- Set trace on for XML plan
DBCC TRACEON (1222, -1)
GO

*/
-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
set @maxfilesize = 500 

-- Please replace the text InsertFileNameHere, with an appropriate
-- filename prefixed by a path, e.g., c:\MyFolder\MyTrace. The .trc extension
-- will be appended to the filename automatically. If you are writing from
-- remote server to local drive, please use UNC path and make sure server has
-- write access to your network share

exec @rc = sp_trace_create @TraceID output, 0, N'D:\DeadLocks\SharedBillingDLocksDec222015', @maxfilesize, NULL 
if (@rc != 0) goto error

-- Client side File and Table cannot be scripted

-- Set the events
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 148, 11, @on
exec sp_trace_setevent @TraceID, 148, 12, @on
exec sp_trace_setevent @TraceID, 148, 14, @on
exec sp_trace_setevent @TraceID, 148, 1, @on
--exec sp_trace_setevent @TraceID, 25, 15, @on
--exec sp_trace_setevent @TraceID, 25, 32, @on
--exec sp_trace_setevent @TraceID, 25, 1, @on
--exec sp_trace_setevent @TraceID, 25, 9, @on
--exec sp_trace_setevent @TraceID, 25, 57, @on
--exec sp_trace_setevent @TraceID, 25, 2, @on
--exec sp_trace_setevent @TraceID, 25, 10, @on
--exec sp_trace_setevent @TraceID, 25, 11, @on
--exec sp_trace_setevent @TraceID, 25, 35, @on
--exec sp_trace_setevent @TraceID, 25, 12, @on
--exec sp_trace_setevent @TraceID, 25, 13, @on
--exec sp_trace_setevent @TraceID, 25, 6, @on
--exec sp_trace_setevent @TraceID, 25, 14, @on
--exec sp_trace_setevent @TraceID, 25, 22, @on


-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

exec sp_trace_setfilter @TraceID, 10, 0, 7, N'SQL Server Profiler - aeb9d5ff-d013-433c-b8e7-4f385dc4660d'
-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go
