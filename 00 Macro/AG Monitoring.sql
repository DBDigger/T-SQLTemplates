-- https://msdn.microsoft.com/en-us/library/dn135338(v=sql.110).aspx
https://www.sqlshack.com/measuring-availability-group-synchronization-lag/
------------------------------------------------------------------------------------------------------------
-- Get log generation rate on primary replica for a DB
Declare @DB varchar(150) = 'WESP'
declare @logbytesflush bigint = 0

select @logbytesflush = cntr_value
from sys.dm_os_performance_counters
 where object_name like '%SQLServer:Databases%'
 and counter_name = 'Log Bytes Flushed/sec'  
 and instance_name = @DB
 order by cntr_value 

WAITFOR DELAY '00:00:01'

select @logbytesflush = cntr_value - @logbytesflush
from sys.dm_os_performance_counters
 where object_name like '%SQLServer:Databases%'
 and counter_name = 'Log Bytes Flushed/sec'  
 and instance_name = @DB
 order by cntr_value 

 select @logbytesflush AS BytesPerSecondfor
 GO

------------------------------------------------------------------------------------------------------------
 -- Get log capture queue for an instance
 declare @instance varchar(150) = 'asi-sqlpcdg1-07:dr-sqlpcn2-07'
declare @logbytesflush bigint = 0

select @logbytesflush = cntr_value
from sys.dm_os_performance_counters
  where object_name like '%SQLServer:Availability Replica%'
  and counter_name = 'Bytes Sent to Replica/sec'
  and instance_name = @instance  

 order by cntr_value 

WAITFOR DELAY '00:00:01'

select @logbytesflush = cntr_value - @logbytesflush
from sys.dm_os_performance_counters
  where object_name like '%SQLServer:Availability Replica%'
  and counter_name = 'Bytes Sent to Replica/sec'
  and instance_name = @instance   

 select @logbytesflush AS BytesInCaptureQueuePerSec
 GO


 -----------------------------------------------------------------------------------------------------------
  -- Get log bytes send on wire
 declare @instance varchar(150) = 'asi-sqlpcdg1-07:dr-sqlpcn2-07'
declare @logbytesflush bigint = 0

select @logbytesflush = cntr_value
from sys.dm_os_performance_counters
  where object_name like '%SQLServer:Availability Replica%'
  and counter_name = 'Bytes Sent to Transport/sec'
  and instance_name = @instance  

 order by cntr_value 

WAITFOR DELAY '00:00:01'

select @logbytesflush = cntr_value - @logbytesflush
from sys.dm_os_performance_counters
  where object_name like '%SQLServer:Availability Replica%'
  and counter_name = 'Bytes Sent to Transport/sec'
  and instance_name = @instance   

 select @logbytesflush AS BytesSendOnWirePerSec
 GO