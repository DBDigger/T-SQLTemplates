



-- Log status
select name, log_reuse_wait_desc from sys.databases


-- Read Logs
DBCC Log('DBDigger',1)
-- 2 for minimal info and 3 for detailed

-- Read TLog file
select [Current LSN], [Operation], [Transaction Name], [Transaction ID], [Transaction SID], [SPID], [Begin Time]
FROM   fn_dblog(null,null)

-- Get insert update and delete ops
SELECT*
FROM sys.fn_dblog(NULL,NULL)
WHERE Operation IN ('LOP_DELETE_ROWS', 'LOP_UPDATE_ROWS', 'LOP_INSERT_ROWS') 


-- Read TLog
SET NOCOUNT ON
DECLARE @LSN NVARCHAR(46)
DECLARE @LSN_HEX NVARCHAR(25)
DECLARE @trx_id NVARCHAR(28) = '0000:00004b1d'
DECLARE @tbl TABLE (id INT identity(1,1), i VARCHAR(10))
DECLARE @stmt VARCHAR(256)

SET @LSN = (SELECT TOP 1 [Current LSN] FROM fn_dblog(NULL, NULL) WHERE [Transaction ID] = @trx_id)

SET @stmt = 'SELECT CAST(0x' + SUBSTRING(@LSN, 1, 8) + ' AS INT)'
INSERT @tbl EXEC(@stmt)
SET @stmt = 'SELECT CAST(0x' + SUBSTRING(@LSN, 10, 8) + ' AS INT)'
INSERT @tbl EXEC(@stmt)
SET @stmt = 'SELECT CAST(0x' + SUBSTRING(@LSN, 19, 4) + ' AS INT)'
INSERT @tbl EXEC(@stmt)

SET @LSN_HEX =
 (SELECT i FROM @tbl WHERE id = 1) + ':' + (SELECT i FROM @tbl WHERE id = 2) + ':' + (SELECT i FROM @tbl WHERE id = 3)

SELECT [Current LSN], [Operation], [Context], [Transaction ID], [AllocUnitName], [Page ID], [Transaction Name],  [SPID],[Description] 
FROM fn_dblog(@LSN_HEX, NULL)