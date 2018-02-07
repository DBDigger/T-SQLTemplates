-- Get Transactions per second


DECLARE @cntr_value bigint

SELECT @cntr_value=cntr_value
    FROM sys.dm_os_performance_counters
    WHERE counter_name = 'transactions/sec'
        AND object_name = 'SQLServer:Databases                                                                                                             '
        AND instance_name = 'wmp'

WAITFOR DELAY '00:00:01'

SELECT cntr_value - @cntr_value
    FROM sys.dm_os_performance_counters
    WHERE counter_name = 'transactions/sec'
        AND object_name = 'SQLServer:Databases'                                                                         
        AND instance_name = 'wmp'
