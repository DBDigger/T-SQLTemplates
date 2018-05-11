-- Get duplicates
SELECT a.[__$start_lsn] , a.[__$seqval], a.[__$operation]   
 FROM dbo_PROD_MedMediaCitation_CT a  
 join  
 (SELECT [__$start_lsn] , [__$seqval], [__$operation]  
 FROM dbo_PROD_MedMediaCitation_CT  
 GROUP BY [__$start_lsn] , [__$seqval], [__$operation]  
 HAVING count(*) >1) b   
 ON a.[__$start_lsn] = b.[__$start_lsn]  
 and a.[__$seqval] = b.[__$seqval]  
 and a.[__$operation] = b.[__$operation]  
 ORDER BY a.[__$start_lsn], a.[__$seqval], a.[__$operation]  
 GO  

  
--Delete duplicates
WITH CTE AS 
( 
SELECT ROW_NUMBER() OVER 
(PARTITION BY [__$start_lsn] , [__$seqval], [__$operation]
Order BY [__$start_lsn] DESC, [__$seqval] DESC, [__$operation] DESC ) 
AS RowNumber, 
[__$start_lsn] , [__$seqval], [__$operation]
FROM [dbo_PROD_Association_CT] tbl ) 
DELETE FROM CTE Where RowNumber > 1
GO 