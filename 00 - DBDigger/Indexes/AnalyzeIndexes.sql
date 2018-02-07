-- get index usage
SELECT  '[' + Sch.name + '].[' + Tab.[name] + ']' AS TableName, 
        Ind.type_desc, 
        Ind.[name] AS IndexName, 
        usg_stats.user_seeks AS UserSeek, 
        usg_stats.user_scans AS UserScans, 
        usg_stats.user_lookups AS UserLookups, 
        usg_stats.user_updates AS UserUpdates                   
FROM    sys.[indexes] AS Ind 
        INNER JOIN sys.[tables] AS Tab ON Tab.[object_id] = Ind.[object_id] 
        INNER JOIN sys.[schemas] AS Sch ON Sch.[schema_id] = Tab.[schema_id] 
        LEFT OUTER JOIN sys.dm_db_index_usage_stats AS usg_stats ON  Ind.index_id = usg_stats.index_id 
                                    AND Ind.[OBJECT_ID] = usg_stats.[OBJECT_ID]  and usg_stats.database_id = DB_ID() 
WHERE  Ind.type_desc <> 'HEAP' 
AND Tab.name  = 'CNTPRODITEMS' -- uncomment to get single table indexes detail 
ORDER BY TableName


-- Possible Bad NC Indexes (writes > reads)
SELECT  OBJECT_NAME(s.[object_id]) AS [Table Name] ,
        i.name AS [Index Name] ,
        i.index_id ,
        user_updates AS [Total Writes] ,
        user_seeks + user_scans + user_lookups AS [Total Reads] ,
        user_updates - ( user_seeks + user_scans + user_lookups )
            AS [Difference]
FROM    sys.dm_db_index_usage_stats AS s WITH ( NOLOCK )
        INNER JOIN sys.indexes AS i WITH ( NOLOCK )
            ON s.[object_id] = i.[object_id]
            AND i.index_id = s.index_id
WHERE   OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1
        AND s.database_id = DB_ID()
        AND user_updates > ( user_seeks + user_scans + user_lookups )
        AND i.index_id > 1
ORDER BY [Difference] DESC ,
        [Total Writes] DESC ,
        [Total Reads] ASC ;

-- List unused indexes
SELECT  OBJECT_NAME(i.[object_id]) AS [Table Name] ,
        i.name
FROM    sys.indexes AS i
        INNER JOIN sys.objects AS o ON i.[object_id] = o.[object_id]
WHERE   i.index_id NOT IN ( SELECT  s.index_id
                            FROM    sys.dm_db_index_usage_stats AS s
                            WHERE   s.[object_id] = i.[object_id]
                                    AND i.index_id = s.index_id
                                    AND database_id = DB_ID() )
        AND o.[type] = 'U'
ORDER BY OBJECT_NAME(i.[object_id]) ASC ;


---------------------------------------- Get index Size ---------------------------------------------
SELECT OBJECT_NAME(B.OBJECT_ID) AS TABLENAME, a.NAME AS IndexName, partition_number, s.row_count AS RowsInIndex, CASE is_disabled
		WHEN 1
			THEN 'Yes'
		WHEN 0
			THEN 'No'
		END AS IsDisabled, 
CASE is_hypothetical
		WHEN 1
			THEN 'Yes'
		WHEN 0
			THEN 'No'
		END AS IsHypothetical, 
USER_SEEKS, USER_SCANS, USER_LOOKUPS, USER_UPDATES,a.type_desc AS IndexType
FROM SYS.DM_DB_INDEX_USAGE_STATS B
INNER JOIN SYS.OBJECTS C ON B.OBJECT_ID = C.OBJECT_ID
INNER JOIN SYS.INDEXES A ON A.OBJECT_ID = B.OBJECT_ID AND A.INDEX_ID = B.INDEX_ID
INNER JOIN sys.dm_db_partition_stats s ON b.OBJECT_ID = s.OBJECT_ID AND b.INDEX_ID = s.INDEX_ID
WHERE DATABASE_ID = DB_ID(DB_NAME()) 
AND C.TYPE <> 'S' 
AND a.type_desc <> 'HEAP'
order by OBJECT_NAME(B.OBJECT_ID) , a.NAME 

-------------------------------------------------- Index Usage  ---------------------------------------------
SELECT   OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME], 
         I.[NAME] AS [INDEX NAME], 
         USER_SEEKS,USER_SCANS,USER_LOOKUPS,     USER_UPDATES ,
          last_user_scan,last_user_update
          
    
FROM     SYS.DM_DB_INDEX_USAGE_STATS AS S 
         INNER JOIN SYS.INDEXES AS I 
           ON I.[OBJECT_ID] = S.[OBJECT_ID] 
              AND I.INDEX_ID = S.INDEX_ID 
WHERE    OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1  
order by OBJECT_NAME(S.[OBJECT_ID]) ,          I.[NAME] 
       

--------------------------------------- Indexes never utilized  ---------------------------------------------
SELECT
	OBJECT_NAME(i.[object_id]) AS [Table Name] 
,	ISNULL(i.name,'') As [Index Name]
,	i.type_desc
,	i.is_primary_key
,	i.is_unique
,	i.is_unique_constraint
,	t.rows
,	o.create_date
,	o.modify_date
,	ISNULL(SUBSTRING((SELECT distinct
		', '+ 
		ISNULL(so.name,'')
	FROM syscomments sc 
	INNER JOIN sysobjects so ON sc.id = so.id 
	WHERE charindex(OBJECT_NAME(i.[object_id]), text) > 0 FOR XML PATH('')),2,2000),'') as dependency
FROM    sys.indexes AS i
        JOIN sys.objects AS o ON i.[object_id] = o.[object_id]
        join sys.sysindexes t on t.id = i.[object_id] and i.index_id= t.indid
        
        LEFT JOIN sys.key_constraints U ON U.name = i.name
WHERE   i.index_id NOT IN ( SELECT  ddius.index_id
                            FROM    sys.dm_db_index_usage_stats AS ddius
                            WHERE   ddius.[object_id] = i.[object_id]
                                    AND i.index_id = ddius.index_id
                                    AND database_id = DB_ID() )
        AND o.[type] = 'U'
ORDER BY OBJECT_NAME(i.[object_id]) ASC ;



------------------------------------- Indexes maintained but not utilized  ---------------------------------------------
SELECT  '[' + DB_NAME() + '].[' + su.[name] + '].[' + o.[name] + ']'
            AS [statement] ,
        i.[name] AS [index_name] ,
        ddius.[user_seeks] + ddius.[user_scans] + ddius.[user_lookups]
            AS [user_reads] ,
        ddius.[user_updates] AS [user_writes] ,
        SUM(SP.rows) AS [total_rows]
FROM    sys.dm_db_index_usage_stats ddius
        INNER JOIN sys.indexes i ON ddius.[object_id] = i.[object_id]
                                     AND i.[index_id] = ddius.[index_id]
        INNER JOIN sys.partitions SP ON ddius.[object_id] = SP.[object_id]
                                        AND SP.[index_id] = ddius.[index_id]
        INNER JOIN sys.objects o ON ddius.[object_id] = o.[object_id]
        INNER JOIN sys.sysusers su ON o.[schema_id] = su.[UID]
WHERE   ddius.[database_id] = DB_ID() -- current database only
        AND OBJECTPROPERTY(ddius.[object_id], 'IsUserTable') = 1
        AND ddius.[index_id] > 0
GROUP BY su.[name] ,
        o.[name] ,
        i.[name] ,
        ddius.[user_seeks] + ddius.[user_scans] + ddius.[user_lookups] ,
        ddius.[user_updates]
HAVING  ddius.[user_seeks] + ddius.[user_scans] + ddius.[user_lookups] = 0
ORDER BY ddius.[user_updates] DESC ,
        su.[name] ,
        o.[name] ,
        i.[name ]
        
        
-----------------------------------Potentialy inefficent indexes  ---------------------------------------------
SELECT  OBJECT_NAME(ddius.[object_id]) AS [Table Name] ,
        i.name AS [Index Name] ,
        i.index_id ,
        user_updates AS [Total Writes] ,
        user_seeks + user_scans + user_lookups AS [Total Reads] ,
        user_updates - ( user_seeks + user_scans + user_lookups )
            AS [Difference]
FROM    sys.dm_db_index_usage_stats AS ddius WITH ( NOLOCK )
        INNER JOIN sys.indexes AS i WITH ( NOLOCK )
            ON ddius.[object_id] = i.[object_id]
            AND i.index_id = ddius.index_id
WHERE   OBJECTPROPERTY(ddius.[object_id], 'IsUserTable') = 1
        AND ddius.database_id = DB_ID()
        AND user_updates > ( user_seeks + user_scans + user_lookups )
        AND i.index_id > 1
ORDER BY [Difference] DESC ,
        [Total Writes] DESC ,
        [Total Reads] ASC ;
        
        
------------------------------------------ Detailed index info  ---------------------------------------------
SELECT  '[' + DB_NAME() + '].[' + su.[name] + '].[' + o.[name] + ']'
                                                       AS [statement] ,
        i.[name] AS [index_name] ,
        ddius.[user_seeks] + ddius.[user_scans] + ddius.[user_lookups]
            AS [user_reads] ,
        ddius.[user_updates] AS [user_writes] ,
        ddios.[leaf_insert_count] ,
        ddios.[leaf_delete_count] ,
        ddios.[leaf_update_count] ,
        ddios.[nonleaf_insert_count] ,
        ddios.[nonleaf_delete_count] ,
        ddios.[nonleaf_update_count]
FROM    sys.dm_db_index_usage_stats ddius
        INNER JOIN sys.indexes i ON ddius.[object_id] = i.[object_id]
                                     AND i.[index_id] = ddius.[index_id]
        INNER JOIN sys.partitions SP ON ddius.[object_id] = SP.[object_id]
                                        AND SP.[index_id] = ddius.[index_id]
        INNER JOIN sys.objects o ON ddius.[object_id] = o.[object_id]
        INNER JOIN sys.sysusers su ON o.[schema_id] = su.[UID]
        INNER JOIN sys.[dm_db_index_operational_stats](DB_ID(), NULL, NULL,
                                                       NULL)
                  AS ddios
                      ON ddius.[index_id] = ddios.[index_id]
                         AND ddius.[object_id] = ddios.[object_id]
                         AND SP.[partition_number] = ddios.[partition_number]
                         AND ddius.[database_id] = ddios.[database_id]
WHERE OBJECTPROPERTY(ddius.[object_id], 'IsUserTable') = 1
      AND ddius.[index_id] > 0
      AND ddius.[user_seeks] + ddius.[user_scans] + ddius.[user_lookups] = 0
ORDER BY ddius.[user_updates] DESC ,
        su.[name] ,
        o.[name] ,
        i.[name ]
        
        
        
------------------------------------------------------- Missing Indexs  ---------------------------------------------
SELECT  user_seeks * avg_total_user_cost * ( avg_user_impact * 0.01 ) AS [index_advantage] ,
        dbmigs.last_user_seek ,
        dbmid.[statement] AS [Database.Schema.Table] ,
        dbmid.equality_columns ,
        dbmid.inequality_columns ,
        dbmid.included_columns ,
        dbmigs.unique_compiles ,
        dbmigs.user_seeks ,
        dbmigs.avg_total_user_cost ,
        dbmigs.avg_user_impact
FROM    sys.dm_db_missing_index_group_stats AS dbmigs WITH ( NOLOCK )
        INNER JOIN sys.dm_db_missing_index_groups AS dbmig WITH ( NOLOCK )
                    ON dbmigs.group_handle = dbmig.index_group_handle
        INNER JOIN sys.dm_db_missing_index_details AS dbmid WITH ( NOLOCK )
                    ON dbmig.index_handle = dbmid.index_handle
WHERE   dbmid.[database_id] = DB_ID()
ORDER BY index_advantage DESC ;

       
-- Get index usage and type of usage------------------------------------------------------
SELECT DB_NAME(DATABASE_ID) AS DATABASENAME, OBJECT_NAME(B.OBJECT_ID) AS TABLENAME, a.NAME AS IndexName, a.type_desc AS IndexType, s.row_count AS RowsInIndex, CASE is_disabled
		WHEN 1
			THEN 'Yes'
		WHEN 0
			THEN 'No'
		END AS IsDisabled, 
CASE is_hypothetical
		WHEN 1
			THEN 'Yes'
		WHEN 0
			THEN 'No'
		END AS IsHypothetical, 
USER_SEEKS, USER_SCANS, USER_LOOKUPS, USER_UPDATES
FROM SYS.DM_DB_INDEX_USAGE_STATS B
INNER JOIN SYS.OBJECTS C ON B.OBJECT_ID = C.OBJECT_ID
INNER JOIN SYS.INDEXES A ON A.OBJECT_ID = B.OBJECT_ID AND A.INDEX_ID = B.INDEX_ID
INNER JOIN sys.dm_db_partition_stats s ON b.OBJECT_ID = s.OBJECT_ID AND b.INDEX_ID = s.INDEX_ID
WHERE DATABASE_ID = DB_ID(DB_NAME()) 
AND C.TYPE <> 'S' 
AND a.type_desc <> 'HEAP'
       
       

-- Get volatile info of unused indexes------------------------------------------------------------
SELECT   DB_NAME() AS DATABASENAME,
         OBJECT_NAME(B.OBJECT_ID) AS TABLENAME,
         B.NAME AS INDEXNAME,
         B.INDEX_ID
FROM     SYS.OBJECTS A
         INNER JOIN SYS.INDEXES B
           ON A.OBJECT_ID = B.OBJECT_ID
WHERE    NOT EXISTS (SELECT *
                     FROM   SYS.DM_DB_INDEX_USAGE_STATS C
                     WHERE  B.OBJECT_ID = C.OBJECT_ID
                            AND B.INDEX_ID = C.INDEX_ID)
         AND A.TYPE <> 'S'
ORDER BY 1, 2, 3 


-- Get only indexes that have been used since the last time the stats were reset----------------------
SELECT   TABLENAME, INDEXNAME, INDEX_ID, [1] AS COL1, [2] AS COL2, [3] AS COL3,
         [4] AS COL4, [5] AS COL5, [6] AS COL6, [7] AS COL7
FROM     (SELECT A.NAME AS TABLENAME,
                 A.OBJECT_ID,
                 B.NAME AS INDEXNAME,
                 B.INDEX_ID,
                 D.NAME AS COLUMNNAME,
                 C.KEY_ORDINAL
          FROM   SYS.OBJECTS A
                 INNER JOIN SYS.INDEXES B
                   ON A.OBJECT_ID = B.OBJECT_ID
                 INNER JOIN SYS.INDEX_COLUMNS C
                   ON B.OBJECT_ID = C.OBJECT_ID
                      AND B.INDEX_ID = C.INDEX_ID
                 INNER JOIN SYS.COLUMNS D
                   ON C.OBJECT_ID = D.OBJECT_ID
                      AND C.COLUMN_ID = D.COLUMN_ID
          WHERE  A.TYPE <> 'S') P
         PIVOT
         (MIN(COLUMNNAME)
          FOR KEY_ORDINAL IN ( [1],[2],[3],[4],[5],[6],[7] ) ) AS PVT
WHERE    EXISTS (SELECT OBJECT_ID,
                        INDEX_ID
                 FROM   SYS.DM_DB_INDEX_USAGE_STATS B
                 WHERE  DATABASE_ID = DB_ID(DB_NAME())
                        AND PVT.OBJECT_ID = B.OBJECT_ID
                        AND PVT.INDEX_ID = B.INDEX_ID)
ORDER BY TABLENAME, INDEXNAME;


-- Leaf DML -------------------------------------------------------------------
SELECT OBJECT_NAME(A.[OBJECT_ID]) AS [OBJECT NAME], 
       I.[NAME] AS [INDEX NAME], 
       A.LEAF_INSERT_COUNT, 
       A.LEAF_UPDATE_COUNT, 
       A.LEAF_DELETE_COUNT 
FROM   SYS.DM_DB_INDEX_OPERATIONAL_STATS (NULL,NULL,NULL,NULL ) A 
       INNER JOIN SYS.INDEXES AS I 
         ON I.[OBJECT_ID] = A.[OBJECT_ID] 
            AND I.INDEX_ID = A.INDEX_ID 
WHERE  OBJECTPROPERTY(A.[OBJECT_ID],'IsUserTable') = 1

-- Index Access ----------------------------------------------------------------------------
SELECT   OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME], 
         I.[NAME] AS [INDEX NAME], 
         USER_SEEKS, 
         USER_SCANS, 
         USER_LOOKUPS, 
         USER_UPDATES 
FROM     SYS.DM_DB_INDEX_USAGE_STATS AS S 
         INNER JOIN SYS.INDEXES AS I 
           ON I.[OBJECT_ID] = S.[OBJECT_ID] 
              AND I.INDEX_ID = S.INDEX_ID 
WHERE    OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1 


-- Get unused indexes ------------------------------------------------------
SELECT DB_NAME(DATABASE_ID) AS DATABASENAME, OBJECT_NAME(B.OBJECT_ID) AS TABLENAME, a.NAME AS IndexName, a.type_desc AS IndexType, s.row_count AS RowsInIndex, CASE is_disabled
		WHEN 1
			THEN 'Yes'
		WHEN 0
			THEN 'No'
		END AS IsDisabled, 
CASE is_hypothetical
		WHEN 1
			THEN 'Yes'
		WHEN 0
			THEN 'No'
		END AS IsHypothetical, 
USER_SEEKS, USER_SCANS, USER_LOOKUPS, USER_UPDATES
FROM SYS.DM_DB_INDEX_USAGE_STATS B
INNER JOIN SYS.OBJECTS C ON B.OBJECT_ID = C.OBJECT_ID
INNER JOIN SYS.INDEXES A ON A.OBJECT_ID = B.OBJECT_ID AND A.INDEX_ID = B.INDEX_ID
INNER JOIN sys.dm_db_partition_stats s ON b.OBJECT_ID = s.OBJECT_ID AND b.INDEX_ID = s.INDEX_ID
WHERE DATABASE_ID = DB_ID(DB_NAME()) 
AND C.TYPE <> 'S' 
AND a.type_desc <> 'HEAP'
       AND USER_SEEKS = 0
       AND USER_SCANS = 0
       AND USER_LOOKUPS = 0
       AND USER_UPDATES = 0
ORDER BY OBJECT_NAME(B.OBJECT_ID), a.NAME
       
 

--------------------- Tables without clustered indexes
SELECT o.NAME, i.type_desc, o.type_desc, o.create_date
FROM sys.indexes i
INNER JOIN sys.objects o ON i.object_id = o.object_id
WHERE o.type_desc = 'USER_TABLE'
	AND i.type_desc = 'HEAP'
ORDER BY o.NAME
GO


------------------------------- SP_helpindex3
http://www.mssqltips.com/tipimages/1003_sp_helpindex3.txt