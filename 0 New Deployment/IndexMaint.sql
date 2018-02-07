-- create table in DBAServices
create table IndexFragmentation (id int identity (1,1),DB varchar(50), tablename varchar(150), indexname varchar(300),avgfrag tinyint, reportTime datetime, processTime datetime, logStmt varchar(400))

-- Generate Fragmentation
DECLARE @tablename VARCHAR(40)


DECLARE GetFragmentation CURSOR FOR

-- Generate table with number of rows
SELECT sOBJ.NAME AS [TableName]
FROM sys.objects AS sOBJ WITH (NOLOCK)
INNER JOIN sys.dm_db_partition_stats AS sdmvPTNS WITH (NOLOCK) ON sOBJ.object_id = sdmvPTNS.object_id
WHERE sOBJ.type = 'U'
	AND sOBJ.is_ms_shipped = 0x0
	AND sdmvPTNS.index_id < 2
	
	and (SCHEMA_NAME(sOBJ.schema_id)) = 'dbo'
GROUP BY sOBJ.schema_id
	,sOBJ.NAME
having SUM(sdmvPTNS.row_count) between 2000 and  1000000

OPEN GetFragmentation

FETCH NEXT FROM GetFragmentation INTO @tablename

WHILE (@@FETCH_STATUS <> -1)
BEGIN
insert into DBAServices..IndexFragmentation 
SELECT DB_NAME(), 
B.name AS TableName
, C.name AS IndexName
, A.avg_fragmentation_in_percent, GETDATE(), null,null
FROM sys.dm_db_index_physical_stats(db_id(), OBJECT_ID(@tablename), NULL, NULL , 'Limited') A
INNER JOIN sys.objects B
ON A.object_id = B.object_id
INNER JOIN sys.indexes C
ON B.object_id = C.object_id AND A.index_id = C.index_id
WHERE C.index_id > 0
and A.avg_fragmentation_in_percent >20

FETCH NEXT FROM GetFragmentation INTO @tablename

END
GO
CLOSE GetFragmentation

DEALLOCATE GetFragmentation





-- Defragment
DECLARE @RebuildStmt VARCHAR(400)
declare @ser int

DECLARE RebuilIndexes CURSOR FOR
SELECT 'ALTER INDEX ['+indexname+'] ON ['+tablename+'] REBUILD WITH (ONLINE=ON, sort_in_tempdb = on)', id
FROM dbaservices..IndexFragmentation

OPEN RebuilIndexes

FETCH NEXT FROM RebuilIndexes INTO @RebuildStmt, @ser
WHILE (@@FETCH_STATUS <> -1)
BEGIN
BEGIN TRY
	EXEC (@RebuildStmt)
	update dbaservices..IndexFragmentation set processtime = GETDATE () where id = @ser 
END TRY
BEGIN CATCH
	update dbaservices..IndexFragmentation set processtime = GETDATE (), logStmt =  ERROR_MESSAGE()  where id = @ser

END CATCH

FETCH NEXT FROM RebuilIndexes INTO @RebuildStmt
END
GO
CLOSE RebuilIndexes

DEALLOCATE RebuilIndexes