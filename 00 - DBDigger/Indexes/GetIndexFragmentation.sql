/*Created by Mayur H. Sanap - 2012 */
IF EXISTS (
		SELECT *
		FROM tempdb.sys.all_objects
		WHERE NAME LIKE '#bbc%'
		)
	DROP TABLE #bbc

CREATE TABLE #bbc (
	DatabaseName VARCHAR(100)
	,ObjectName VARCHAR(100)
	,Index_id INT
	,indexName VARCHAR(100)
	,avg_fragmentation_percent FLOAT
	,IndexType VARCHAR(100)
	)
GO

INSERT INTO #bbc (
	DatabaseName
	,ObjectName
	,Index_id
	,indexName
	,avg_fragmentation_percent
	,IndexType
	)
SELECT db_name() AS DatabaseName
	,OBJECT_NAME(a.object_id) AS ObjectName
	,a.index_id
	,b.NAME AS IndexName
	,avg_fragmentation_in_percent
	,index_type_desc
-- , record_count, avg_page_space_used_in_percent --(null in limited) 
FROM sys.dm_db_index_physical_stats(db_id(), NULL, NULL, NULL, NULL) AS a
JOIN sys.indexes AS b ON a.object_id = b.object_id
	AND a.index_id = b.index_id
WHERE b.index_id <> 0
	AND avg_fragmentation_in_percent <> 0

SELECT *
FROM #bbc

DROP TABLE #bbc