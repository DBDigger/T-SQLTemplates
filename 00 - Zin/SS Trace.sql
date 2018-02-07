-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
declare @DateTime datetime
declare @FileName NVARCHAR(400)

--Change File path accordingly

SELECT @FileName =  N'D:\Traces\LongRunningTrace' + REPLACE(LEFT(CONVERT(VARCHAR(50),GETDATE(),109),11),' ','')

--set @DateTime = '2012-04-24 11:10:00.000' --Close trace at
set @maxfilesize = 300 -- maximum file size in MBs

exec @rc = sp_trace_create @TraceID output, 0,@FileName, @maxfilesize, NULL 
if (@rc != 0) goto error

-- Set the events
declare @on bit
set @on = 1
EXEC sp_trace_setevent @TraceID, 10, 1,  @on --TextData
EXEC sp_trace_setevent @TraceID, 10, 2,  @on --BinaryData
EXEC sp_trace_setevent @TraceID, 10, 6,  @on --NTUserName
EXEC sp_trace_setevent @TraceID, 10, 9,  @on --ClientProcessID
EXEC sp_trace_setevent @TraceID, 10, 10, @on --ApplicationName
EXEC sp_trace_setevent @TraceID, 10, 11, @on --LoginName
EXEC sp_trace_setevent @TraceID, 10, 12, @on --SPID
EXEC sp_trace_setevent @TraceID, 10, 13, @on --Duration
EXEC sp_trace_setevent @TraceID, 10, 14, @on --StartTime
EXEC sp_trace_setevent @TraceID, 10, 15, @on --EndTime
EXEC sp_trace_setevent @TraceID, 10, 16, @on --Reads
EXEC sp_trace_setevent @TraceID, 10, 17, @on --Writes
EXEC sp_trace_setevent @TraceID, 10, 18, @on --CPU
EXEC sp_trace_setevent @TraceID, 10, 35, @on --DatabaseName

--https://msdn.microsoft.com/en-us/library/ms186265%28v=sql.105%29.aspx
--EXEC sp_trace_setevent @TraceID, 10,1,0 --TextData
--EXEC sp_trace_setevent @TraceID, 10,2,0 --BinaryData
--EXEC sp_trace_setevent @TraceID, 10,3,0 --DatabaseID
--EXEC sp_trace_setevent @TraceID, 10,4,0 --TransactionID
--EXEC sp_trace_setevent @TraceID, 10,5,0 --LineNumber
--EXEC sp_trace_setevent @TraceID, 10,6,0 --NTUserName
--EXEC sp_trace_setevent @TraceID, 10,7,0 --NTDomainName
--EXEC sp_trace_setevent @TraceID, 10,8,0 --HostName
--EXEC sp_trace_setevent @TraceID, 10,9,0 --ClientProcessID
--EXEC sp_trace_setevent @TraceID, 10,10,0 --ApplicationName
--EXEC sp_trace_setevent @TraceID, 10,11,0 --LoginName
--EXEC sp_trace_setevent @TraceID, 10,12,0 --SPID
--EXEC sp_trace_setevent @TraceID, 10,13,0 --Duration
--EXEC sp_trace_setevent @TraceID, 10,14,0 --StartTime
--EXEC sp_trace_setevent @TraceID, 10,15,0 --EndTime
--EXEC sp_trace_setevent @TraceID, 10,16,0 --Reads
--EXEC sp_trace_setevent @TraceID, 10,17,0 --Writes
--EXEC sp_trace_setevent @TraceID, 10,18,0 --CPU
--EXEC sp_trace_setevent @TraceID, 10,19,0 --Permissions
--EXEC sp_trace_setevent @TraceID, 10,20,0 --Severity
--EXEC sp_trace_setevent @TraceID, 10,21,0 --EventSubClass
--EXEC sp_trace_setevent @TraceID, 10,22,0 --ObjectID
--EXEC sp_trace_setevent @TraceID, 10,23,0 --Success
--EXEC sp_trace_setevent @TraceID, 10,24,0 --IndexID
--EXEC sp_trace_setevent @TraceID, 10,25,0 --IntegerData
--EXEC sp_trace_setevent @TraceID, 10,26,0 --ServerName
--EXEC sp_trace_setevent @TraceID, 10,27,0 --EventClass
--EXEC sp_trace_setevent @TraceID, 10,28,0 --ObjectType
--EXEC sp_trace_setevent @TraceID, 10,29,0 --NestLevel
--EXEC sp_trace_setevent @TraceID, 10,30,0 --State
--EXEC sp_trace_setevent @TraceID, 10,31,0 --Error
--EXEC sp_trace_setevent @TraceID, 10,32,0 --Mode
--EXEC sp_trace_setevent @TraceID, 10,33,0 --Handle
--EXEC sp_trace_setevent @TraceID, 10,34,0 --ObjectName
--EXEC sp_trace_setevent @TraceID, 10,35,0 --DatabaseName
--EXEC sp_trace_setevent @TraceID, 10,36,0 --FileName
--EXEC sp_trace_setevent @TraceID, 10,37,0 --OwnerName
--EXEC sp_trace_setevent @TraceID, 10,38,0 --RoleName
--EXEC sp_trace_setevent @TraceID, 10,39,0 --TargetUserName
--EXEC sp_trace_setevent @TraceID, 10,40,0 --DBUserName
--EXEC sp_trace_setevent @TraceID, 10,41,0 --LoginSid
--EXEC sp_trace_setevent @TraceID, 10,42,0 --TargetLoginName
--EXEC sp_trace_setevent @TraceID, 10,43,0 --TargetLoginSid
--EXEC sp_trace_setevent @TraceID, 10,44,0 --ColumnPermissions
--EXEC sp_trace_setevent @TraceID, 10,45,0 --LinkedServerName
--EXEC sp_trace_setevent @TraceID, 10,46,0 --ProviderName
--EXEC sp_trace_setevent @TraceID, 10,47,0 --MethodName
--EXEC sp_trace_setevent @TraceID, 10,48,0 --RowCounts
--EXEC sp_trace_setevent @TraceID, 10,49,0 --RequestID
--EXEC sp_trace_setevent @TraceID, 10,50,0 --XactSequence
--EXEC sp_trace_setevent @TraceID, 10,51,0 --EventSequence
--EXEC sp_trace_setevent @TraceID, 10,52,0 --BigintData1
--EXEC sp_trace_setevent @TraceID, 10,53,0 --BigintData2
--EXEC sp_trace_setevent @TraceID, 10,54,0 --GUID
--EXEC sp_trace_setevent @TraceID, 10,55,0 --IntegerData2
--EXEC sp_trace_setevent @TraceID, 10,56,0 --ObjectID2
--EXEC sp_trace_setevent @TraceID, 10,57,0 --Type
--EXEC sp_trace_setevent @TraceID, 10,58,0 --OwnerID
--EXEC sp_trace_setevent @TraceID, 10,59,0 --ParentName
--EXEC sp_trace_setevent @TraceID, 10,60,0 --IsSystem
--EXEC sp_trace_setevent @TraceID, 10,61,0 --Offset
--EXEC sp_trace_setevent @TraceID, 10,62,0 --SourceDatabaseID
--EXEC sp_trace_setevent @TraceID, 10,63,0 --SqlHandle
--EXEC sp_trace_setevent @TraceID, 10,64,0 --SessionLoginName

-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

set @bigintfilter = 3000000 ---Three Seconds (Change it accordingly)
exec sp_trace_setfilter @TraceID, 13, 0, 4, @bigintfilter

-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go
