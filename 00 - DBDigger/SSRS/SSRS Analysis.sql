--�-Last Time a Report was used (by execution start date/time
SELECT DISTINCT C.NAME
	,MAX(EL.TIMESTART)
FROM REPORTSERVER.DBO.EXECUTIONLOG(NOLOCK) EL
INNER JOIN REPORTSERVER.DBO.CATALOG (NOLOCK) C ON EL.REPORTID = C.ITEMID
--�WHERE USERNAME = ''
GROUP BY C.NAME
ORDER BY C.NAME


--******************************************************************************************************
/*��Report usage Stats by Date
��How many reports were viewed on a specific day
��For the where clause, it might be advisable to insert the name of the account that runs SSRS.
��The reason being, if you have a report that is run off of cache or has subscription, the counts will show here.
��So if you want to see reports that have been run by users only then filter out the account that runs the SSRS service.*/
SELECT CONVERT(VARCHAR(25), TIMESTART, 101)
	,COUNT(*)
FROM REPORTSERVER.DBO.EXECUTIONLOG(NOLOCK)
--WHERE USERNAME NOT IN
GROUP BY CONVERT(VARCHAR(25), TIMESTART, 101)
ORDER BY CONVERT(VARCHAR(25), TIMESTART, 101) DESC


--******************************************************************************************************
--Report usage Hourly Stats
--When the report server is used during the day
SELECT DATEPART(HOUR, TIMESTART) AS HOUR
	,COUNT(*)
FROM REPORTSERVER.DBO.EXECUTIONLOG(NOLOCK)
--WHERE USERNAME NOT IN
GROUP BY DATEPART(HOUR, TIMESTART)
ORDER BY DATEPART(HOUR, TIMESTART)


--******************************************************************************************************
--Detailed -- May take time to generate
SELECT EL.USERNAME
	,C.NAME
	,EL.TIMESTART
	,EL.TIMEEND
	,EL.PARAMETERS
	,EL.SOURCE
FROM REPORTSERVER.DBO.EXECUTIONLOG(NOLOCK) EL
INNER JOIN REPORTSERVER.DBO.CATALOG (NOLOCK) C ON EL.REPORTID = C.ITEMID
--WHERE EL.USERNAME NOT IN
ORDER BY TIMESTART DESC



--******************************************************************************************************
--Reports used by user
SELECT EL.USERNAME
	,C.NAME
	,COUNT(1)
FROM REPORTSERVER.DBO.EXECUTIONLOG(NOLOCK) EL
INNER JOIN REPORTSERVER.DBO.CATALOG (NOLOCK) C ON EL.REPORTID = C.ITEMID
GROUP BY EL.USERNAME
	,C.NAME
ORDER BY EL.USERNAME
	,C.NAME



--******************************************************************************************************
--Usage by Report
--Shows how many times a report has been executed in the past 90 days
SELECT C.NAME
	,COUNT(1)
FROM REPORTSERVER.DBO.EXECUTIONLOG(NOLOCK) EL
INNER JOIN REPORTSERVER.DBO.CATALOG (NOLOCK) C ON EL.REPORTID = C.ITEMID
--WHERE EL.USERNAME NOT IN
GROUP BY C.NAME
ORDER BY COUNT(1) DESC



--******************************************************************************************************
--Recent usages per user per report
SELECT EL.USERNAME
	,C.NAME
	,EL.TIMESTART
	,EL.TIMEEND
FROM REPORTSERVER.DBO.EXECUTIONLOG(NOLOCK) EL
INNER JOIN REPORTSERVER.DBO.CATALOG (NOLOCK) C ON EL.REPORTID = C.ITEMID
--WHERE USERNAME = �
ORDER BY TIMESTART DESC



--******************************************************************************************************
--Specific Reports
--Enter name of specific report that you would like information about
SELECT EL.USERNAME
	,C.NAME
	,EL.TIMESTART
	,EL.TIMEEND
FROM REPORTSERVER.DBO.EXECUTIONLOG(NOLOCK) EL
INNER JOIN REPORTSERVER.DBO.CATALOG (NOLOCK) C ON EL.REPORTID = C.ITEMID
WHERE PATH LIKE '%EFax_Queue_Status%'
ORDER BY TIMESTART DESC