--------------------------------------------------------------------------------- 
-- The sample scripts are not supported under any Microsoft standard support 
-- program or service. The sample scripts are provided AS IS without warranty  
-- of any kind. Microsoft further disclaims all implied warranties including,  
-- without limitation, any implied warranties of merchantability or of fitness for 
-- a particular purpose. The entire risk arising out of the use or performance of  
-- the sample scripts and documentation remains with you. In no event shall 
-- Microsoft, its authors, or anyone else involved in the creation, production, or 
-- delivery of the scripts be liable for any damages whatsoever (including, 
-- without limitation, damages for loss of business profits, business interruption, 
-- loss of business information, or other pecuniary loss) arising out of the use 
-- of or inability to use the sample scripts or documentation, even if Microsoft 
-- has been advised of the possibility of such damages 
--------------------------------------------------------------------------------- 

DECLARE @CurrentTime date
DECLARE @StartofWeek date
DECLARE @StartOfMonth date
DECLARE @StartOfYear date

SET @CurrentTime = CONVERT(varchar(12),GETDATE(),101)
SET @StartofWeek = CONVERT(varchar(12),DATEADD(dd, -6, GETDATE()),101)
SET @StartOfMonth = CONVERT(varchar(12),DATEADD(mm,-1,DATEADD(dd, 1, GETDATE())),101)
SET @StartOfYear = CONVERT(varchar(12),DATEADD(yy,-1,DATEADD(dd, 1, GETDATE())),101)

PRINT 'Today is: '
PRINT @CurrentTime
PRINT 'The start day of the latest week is: '
PRINT @StartofWeek
PRINT 'The start day of the latest month is: '
PRINT @StartOfMonth
PRINT 'The start day of the latest year is: '
PRINT @StartOfYear

SELECT Name,Exe.ReportID, 
SUM(CASE WHEN Exe.TimeStart BETWEEN @StartofWeek AND CONVERT(varchar(12),GETDATE(),101) THEN 1 ELSE 0 END) AS RecentWeek,
SUM(CASE WHEN Exe.TimeStart BETWEEN @StartOfMonth AND CONVERT(varchar(12),GETDATE(),101) THEN 1 ELSE 0 END) AS RecentMonth,
SUM(CASE WHEN Exe.TimeStart BETWEEN @StartOfYear AND CONVERT(varchar(12),GETDATE(),101) THEN 1 ELSE 0 END) AS RecentYear

FROM ExecutionLogStorage Exe WITH (NOLOCK) --If you changed the name of ExecutionLogStorage, please replace it with yours.
INNER JOIN Catalog Cata WITH (NOLOCK)   
ON Exe.ReportID = Cata.ItemID
GROUP BY Cata.Name,Exe.ReportID
ORDER BY Cata.Name