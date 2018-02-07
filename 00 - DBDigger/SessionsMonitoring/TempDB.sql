SELECT  SUM(unallocated_extent_page_count) AS [free pages] ,
        ( SUM(unallocated_extent_page_count) * 1.0 / 128 ) AS [free space in MB]
FROM    sys.dm_db_file_space_usage ;


-- Quick TempDB Summary
SELECT SUM(user_object_reserved_page_count) * 8.192 AS [UserObjectsKB] ,
      SUM(internal_object_reserved_page_count) * 8.192 AS [InternalObjectsKB] ,
      SUM(version_store_reserved_page_count) * 8.192 AS [VersonStoreKB] ,
      SUM(unallocated_extent_page_count) * 8.192 AS [FreeSpaceKB]
FROM    sys.dm_db_file_space_usage ;