-- Top 3 CPU-sapping queries for which plans exist in the cache        
SELECT TOP 3
        total_worker_time ,
        execution_count ,
        total_worker_time / execution_count AS [Avg CPU Time] ,
        CASE WHEN deqs.statement_start_offset = 0
                  AND deqs.statement_end_offset = -1
             THEN '-- see objectText column--'
             ELSE '-- query --' + CHAR(13) + CHAR(10)
                  + SUBSTRING(execText.text, deqs.statement_start_offset / 2,
                              ( ( CASE WHEN deqs.statement_end_offset = -1
                                       THEN DATALENGTH(execText.text)
                                       ELSE deqs.statement_end_offset
                                  END ) - deqs.statement_start_offset ) / 2)
        END AS queryText
FROM    sys.dm_exec_query_stats deqs
        CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
ORDER BY deqs.total_worker_time DESC ;


-- Use Counts and # of plans for compiled plans
SELECT  objtype ,
        usecounts ,
        COUNT(*) AS [no_of_plans]
FROM    sys.dm_exec_cached_plans
WHERE   cacheobjtype = 'Compiled Plan'
GROUP BY objtype ,
        usecounts
ORDER BY objtype ,
        usecounts ;
        
        
        
-- Look at the number of items in different parts of the cache
SELECT  name ,
        [type] ,
        entries_count ,
        single_pages_kb ,
        single_pages_in_use_kb ,
        multi_pages_kb ,
        multi_pages_in_use_kb
FROM    sys.dm_os_memory_cache_counters
WHERE   [type] = 'CACHESTORE_SQLCP'
        OR [type] = 'CACHESTORE_OBJCP'
ORDER BY multi_pages_kb DESC ;



-- Get total buffer usage by database
SELECT  DB_NAME(database_id) AS [Database Name] ,
        COUNT(*) * 8 / 1024.0 AS [Cached Size (MB)]
FROM    sys.dm_os_buffer_descriptors
WHERE   database_id > 4 -- exclude system databases
        AND database_id <> 32767 -- exclude ResourceDB
GROUP BY DB_NAME(database_id)
ORDER BY [Cached Size (MB)] DESC ;

-- Breaks down buffers by object (table, index) in the buffer pool
SELECT  OBJECT_NAME(p.[object_id]) AS [ObjectName] ,
        p.index_id ,
        COUNT(*) / 128 AS [Buffer size(MB)] ,
        COUNT(*) AS [Buffer_count]
FROM    sys.allocation_units AS a
        INNER JOIN sys.dm_os_buffer_descriptors
                 AS b ON a.allocation_unit_id = b.allocation_unit_id
        INNER JOIN sys.partitions AS p ON a.container_id = p.hobt_id
WHERE   b.database_id = DB_ID()
        AND p.[object_id] > 100 
GROUP BY p.[object_id] ,
        p.index_id
ORDER BY buffer_count DESC ;