-- Get index analysis in a DB
EXEC sp_BlitzIndex @DatabaseName = 'wmp' 
GO

-- Get Index Analysis for a table 
EXEC dbo.sp_BlitzIndex @DatabaseName='wmp', @SchemaName='dbo', @TableName='NETWORKSEGMENTIPS';

sp_spaceused NETWORKSEGMENTIPS
GO


-- Get partition function details
SELECT PF.[name],RV.boundary_id	,RV.[value]
FROM sys.partition_functions PF
INNER JOIN sys.partition_range_values RV ON PF.function_id = RV.function_id
WHERE PF.NAME = 'NETWORKSEGMENTIPS'
GO

-- Run on Publisher: Get list of publications and their articles
SELECT p.NAME 	,a.NAME
FROM sysarticles a INNER JOIN syspublications p ON p.pubid = a.pubid
ORDER BY a.NAME

-- Search Index in code
SELECT object_name(object_id), definition
FROM sys.sql_modules with (nolock)
WHERE DEFINITION LIKE '%Inx_NetworkSegmentIPs_LongIP%'