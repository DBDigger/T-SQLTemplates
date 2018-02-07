-- Recovery model, log reuse wait description, log file size, 
-- log usage size and compatibility level for all databases on instance
SELECT  db.[name] AS [Database Name] ,
        db.recovery_model_desc AS [Recovery Model] ,
        db.log_reuse_wait_desc AS [Log Reuse Wait Description] ,
        ls.cntr_value AS [Log Size (KB)] ,
        lu.cntr_value AS [Log Used (KB)] ,
        CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)
                    AS DECIMAL(18,2)) * 100 AS [Log Used %] ,
        db.[compatibility_level] AS [DB Compatibility Level] ,
        db.page_verify_option_desc AS [Page Verify Option]
FROM    sys.databases AS db
        INNER JOIN sys.dm_os_performance_counters AS lu
                    ON db.name = lu.instance_name
        INNER JOIN sys.dm_os_performance_counters AS ls
                    ON db.name = ls.instance_name
WHERE   lu.counter_name LIKE 'Log File(s) Used Size (KB)%'
        AND ls.counter_name LIKE 'Log File(s) Size (KB)%' ;
        
        
-- Get population status for all FT catalogs in the current database
SELECT  c.name ,
        c.[status] ,
        c.status_description ,
        OBJECT_NAME(p.table_id) AS [table_name] ,
        p.population_type_description ,
        p.is_clustered_index_scan ,
        p.status_description ,
        p.completion_type_description ,
        p.queued_population_type_description ,
        p.start_time ,
        p.range_count
FROM    sys.dm_fts_active_catalogs AS c
        INNER JOIN sys.dm_fts_index_population AS p
                       ON c.database_id = p.database_id
                        AND c.catalog_id = p.catalog_id
WHERE   c.database_id = DB_ID()
ORDER BY c.name ;



-- Check auto page repair history (New in SQL 2008)
SELECT  DB_NAME(database_id) AS [database_name] ,
        database_id ,
        file_id ,
        page_id ,
        error_type ,
        page_status ,
        modification_time
FROM    sys.dm_db_mirroring_auto_page_repair ; 