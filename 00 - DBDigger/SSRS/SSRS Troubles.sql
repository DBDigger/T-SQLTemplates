-- Run on PRPT1 to get the long running reports
USE ReportServer
GO
SELECT RequestPath AS REPORT_NAME
	,DATEDIFF(MINUTE, StartDate, GETDATE()) DURATION_MINUTES
	,U.UserName AS USER_NAME
	,J.StartDate START_DATETIME
	,J.ComputerName COMPUTER_NAME
	,JobID
FROM ReportServer..RunningJobs J WITH (NOLOCK)
INNER JOIN ReportServer..Users U WITH (NOLOCK) ON U.UserID = J.UserId
ORDER BY DATEDIFF(MINUTE, StartDate, GETDATE()) DESC

--*******************************************************************************************************************
-- Get SSRS subscriptions status in a day
SELECT [ItemPath]
	,[RequestType]
	,[Format]
	,[ItemAction]
	,[TimeStart]
	,[Source]
	,[Status]
	,[ByteCount]
	,[RowCount]
FROM [ReportServer].[dbo].[ExecutionLog3]
WHERE RequestType = 'Subscription'
	AND TimeStart > = '2013-09-24 05:00:59.603'
ORDER BY itempath
	,TimeStart DESC


--****************************************************************************************************************
-- get job name for SSRS subscriptions 
SELECT b.NAME AS JobName
	--,e.NAME
	,e.path
	,d.description
	,a.SubscriptionID
	,laststatus
	,eventtype
	,LastRunTime
	,date_created
	,date_modified
FROM ReportServer.dbo.ReportSchedule a
JOIN msdb.dbo.sysjobs b ON a.ScheduleID = b.NAME
JOIN ReportServer.dbo.ReportSchedule c ON b.NAME = c.ScheduleID
JOIN ReportServer.dbo.Subscriptions d ON c.SubscriptionID = d.SubscriptionID
JOIN ReportServer.dbo.CATALOG e ON d.report_oid = e.itemid
WHERE e.NAME LIKE '%dashboard%'
	AND b.description = 'This job is owned by a report server process. Modifying this job could result in database incompatibilities. Use Report Manager or Management Studio to update this job.'


--****************************************************************************************************************
	---------------------------------------- Search for a keyword in report definitions
	/*
;WITH XMLNAMESPACES
(DEFAULT 'http://schemas.microsoft.com/sqlserver/reporting/2008/01/reportdefinition',
'http://schemas.microsoft.com/sqlserver/reporting/2008/01/reportdefinition' AS REP
)
SELECT  c.Path ,
        c.Name ,
        DataSetXML.value('@Name', 'varchar(MAX)') DataSourceName ,
        DataSetXML.value('REP:Query[1]/REP:CommandText[1]', 'varchar(MAX)') CommandText
FROM    ( SELECT    ItemID ,
                    CAST(CAST(Content AS VARBINARY(MAX)) AS XML) ReportXML
          FROM      [ReportServer].[dbo].[Catalog]
          WHERE     TYPE = 2
        ) ReportXML
        CROSS APPLY ReportXML.nodes('//REP:DataSet') DataSetXML ( DataSetXML )
        INNER JOIN [dbo].[Catalog] c ON ReportXML.ItemID = c.ItemID
-- Search by part of the query text
WHERE   ( DataSetXML.value('REP:Query[1]/REP:CommandText[1]', 'varchar(MAX)') ) LIKE '% Enter object name here %'
*/