-- Get Servers in Sentry
SELECT [ServerName], [InstanceName], [IsWatched], [IsPerformanceMonitorDisabled], [IsPerformanceAnalysisEnabled]
 FROM [SQLSentry].[dbo].[vwSqlServer]

-- Get Alerts history
SELECT
ParentObjectName , ObjectName, ConditionTypeName, ActionTypeName, COUNT(*) AS RecCt, MIN(EventStartTime) AS FirstTime, MAX(EventStartTime) AS LastTime
FROM vwObjectConditionActionHistory
WHERE MessageCreationTimestamp > '2016-12-01 00:00:00'
AND ActionTypeName IN ('Send Email', 'Send Page')
GROUP BY ObjectName , ConditionTypeName , ParentObjectName , ActionTypeName
ORDER BY COUNT(*) DESC