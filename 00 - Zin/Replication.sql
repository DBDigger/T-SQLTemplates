-- Get log reader latency
sp_replcounters

-- Get log reader log

SELECT top 100 time, CAST(comments AS XML) AS comments, runstatus, duration, 
xact_seqno, delivered_transactions, delivered_commands, average_commands, 
delivery_time, delivery_rate, delivery_latency / ( 1000 * 60 ) AS delivery_latency_Min 
FROM distribution.dbo.mslogreader_history WITH (nolock)  
ORDER BY time DESC 

-- https://www.mssqltips.com/sqlservertip/3598/troubleshooting-transactional-replication-latency-issues-in-sql-server/
-- Jobs to diable before billing replication reinitialization
/*
Aspider_Import 
C2C_Import 
Charging1
Charging2
Charging4
Charging5
Import Softbank CDRs
NetworkServicesBilling_DefaultInstance 
NetworkServicesBilling_Instance1 
NetworkServicesBilling_Instance2 
NetworkServicesBilling_Instance3 
NetworkServicesBilling_Instance4 
NetworkServicesBilling_Instance5 
NetworkServicesBilling_OperatorCDRInstance
OneTimeServicesBilling 
OnlineInvoicegeneration-Disregard
PermanentServicesBilling 
RADIUSAccountingInsert 
RADIUSAccountingInsert_Failed 
Rogers_Import
TMAustriaImport 
TMUSImport 
WatchdogMonitor

*/

-- Drop replication setups
-- To drop a push subscription to all articles for a transactional publication, run at Publisher:
EXEC sp_dropsubscription @publication = N'zin',@article = N'all',@subscriber = N'all',@destination_db = N'all'
	
	
-- drop local subscription by running on subscriber DB
sp_subscription_cleanup @publisher = 'zin'	,@publisher_db = 'wmp_ss'	,@publication = 'Zin'


--To drop a transactional publication, run the following script at Publisher
sp_droppublication  @publication=  'Zin' , @ignore_distributor =  ignore_distributor 
GO

USE master
GO
EXEC sp_replicationdboption @dbname = N'wmpoperatorusage_ss',@optname = N'subscribe',@value = N'false'
GO	
EXEC sp_replicationdboption  @dbname = 'wmp_ss', @optname = N'publish', @value = N'false';
GO

--------------------------------------------------------------------------------------
-- Get list of publications
select * from Distribution.dbo.MSpublications



select  top 100 * from distribution.dbo.MSrepl_errors
 where error_type_id is not null
order by time desc


select * from MSReplication_monitordata


select * from MSSnapshot_agents 

select * from MSSnapshot_history


-- Check pendencies
RPT_RadiusHeartBeatBilling
RPT_RadiusHeartBeatSynchronization
select * from EXCEPTIONLOG order by LOGID desc

exec sp_repldone @xactid = NULL, @xact_seqno = NULL, @numtrans = 0, @time = 0, @reset = 1


sp_replflush

sp_posttracertoken -- posts a tracer token into a replication flow
sp_helptracertokens -- returns a list of all active posted tracer tokens
sp_helptracertokenhistory -- returns latency information given a tracer token ID and publication as parameters
sp_deletetracertokenhistory -- deletes a tracer token given a tracer token ID and publication as parameters 

--This procedure can be used in emergency situations to allow truncation of the transaction log when transactions pending replication are present.


select * from MSsubscriptions

-- update MSsubscriptions set status = 2

select * from msdb..MSdistpublishers

select * from distribution..MSpublisher_databases

select * from distribution..MSpublications

select * from distribution..MSarticles

select * from distribution..MSsubscriptions

select * from MSlogreader_history order by time desc

-- Run on publisher distibution db distribution agents that are actively distributing transactions (in progress)
SELECT      da.name, da.publisher_db, da.subscription_type,
            dh.runstatus, dh.delivery_rate, dh.start_time, dh.duration
FROM        dbo.MSdistribution_history dh WITH (NOLOCK)
INNER JOIN  dbo.msdistribution_agents da WITH (NOLOCK)
ON          dh.agent_id = da.id
WHERE       dh.runstatus = 3 -- 3 means 'in progress', table explanation here:
            -- http://msdn.microsoft.com/en-us/library/ms179878.aspx
AND         dh.start_time BETWEEN DATEADD(dd,-30,GETDATE()) AND GETDATE()
ORDER BY    dh.start_time DESC
     
 
 -- drop local subscription
 sp_subscription_cleanup  @publisher =  'zin'
        , @publisher_db =  'wmp_ss'
    , @publication =  'Zin'    
     

-- To drop a push subscription to all articles for a transactional publication, run at Publisher:
USE [PublicationDBname]
GO
EXEC sp_dropsubscription @publication = N'<Publication name>', @article = N'all', @subscriber = N'all', @destination_db = N'all'

-------------------------------------------------------------------------------------
--To drop a transactional publication, run the following script at Publisher
USE [PublicationDBname]
GO
EXEC sp_dropsubscription @publication = N'Customers1', @article = N'all', @subscriber = N'all', @destination_db = N'all'

USE master
GO
EXEC sp_replicationdboption @dbname = N'<Publication database name>', @optname = N'publish', @value = N'false'

--------------------------------------------------------------------------------------------------
-- To drop the subscriber designation from Publisher, run the following script at Publisher:
USE master
GO
EXEC sp_dropsubscriber @subscriber = N'<Subscriber server name>', @reserved = N'drop_subscriptions'

--To remove the distributor, run the following script at the distributor:
 -- Remove all replication settings from publisher
 sp_removedbreplication 'm2mhub_billing'
 go
 
 -- Check in distribution
 select * from Distribution.dbo.MSpublications
 
 
 -- Dropping the distribution databases
use master
exec sp_dropdistributiondb @database = N'distribution'
GO
SELECT spid FROM sys.sysprocesses WHERE dbid = db_id('distribution')
kill 168
/****** Uninstalling the server as a Distributor. Script Date: 6/12/2014 4:33:33 AM ******/
use master
exec sp_dropdistributor @no_checks = 1, @ignore_distributor = 1
GO


------------------------------------------------------------------------------------
sp_helppublication

-- Error: The snapshot could not be generated because the publisher is inactive.
--Run on distributor to update the publisher
sp_changedistpublisher 'lhrlt-238', 'active', 'true'
GO

-- Error:  The replication agent failed to create the directory 
-- verify the distribution path
------------------------------------------------------------------------------------
-- Run on publisher and get Snapshot agent info
sp_helppublication_snapshot @publication = 'Publication'
GO

-- Run on publisher and get logReader agent info
sp_helplogreader_agent 
GO

-- Run on publisher and get subscription info
sp_helpsubscription @publication = 'Publication' , @subscriber = 'Subscriber'
GO

-- Run to update the replication password after password of a login is changed
sp_changereplicationserverpasswords
GO
-------------------------------------------------------------------------------------
-- View and change the setting for immediate_sync, so that transaction may not be there until retention period
select immediate_sync,* from distribution.dbo.MSpublications

sp_changepublication @publication='repltest', @property='immediate_sync',@value='FALSE'

-- Run in the publication DB to get the PAL
sp_help_publication_access @publication = 'Publi_Customers1'

--Enable the DB for publication 
sp_replicationdboption


--------------------------------------------------------------------
-- Run on Publisher: Get article count in publications
WITH CTE_Summary
AS (
	SELECT p.NAME AS PublicationName
		,a.NAME AS ArticleName
	FROM sysarticles a
	INNER JOIN syspublications p ON p.pubid = a.pubid
	
	UNION
	
	SELECT p.NAME AS PublicationName
		,a.NAME AS ArticleName
	FROM dbo.sysschemaarticles a
	INNER JOIN syspublications p ON p.pubid = a.pubid
	)
SELECT PublicationName
	,COUNT(*)
FROM CTE_Summary
GROUP BY PublicationName
ORDER BY PublicationName

----------------------------------------------------------------
-- Run on Dist: Get list of publications and their articles
SELECT
     P.[publication]   AS [Publication Name]
    ,A.[publisher_db]  AS [Database Name]
    ,A.[article]       AS [Article Name]
    ,A.[source_owner]  AS [Schema]
    ,A.[source_object] AS [Table]
FROM
    [distribution].[dbo].[MSarticles] AS A
    INNER JOIN [distribution].[dbo].[MSpublications] AS P
        ON (A.[publication_id] = P.[publication_id])
ORDER BY
    P.[publication], A.[article];



-- Run on Publisher: Get list of publications and their articles
SELECT p.NAME
	,a.NAME
FROM sysarticles a
INNER JOIN syspublications p ON p.pubid = a.pubid

UNION

SELECT p.NAME
	,a.NAME
FROM dbo.sysschemaarticles a
INNER JOIN syspublications p ON p.pubid = a.pubid
ORDER BY p.NAME
	,a.NAME



-- Run on Distributor: Get immediate sync and allow anonymous settings
--  explain the reason for 0
select publication, immediate_sync,allow_anonymous 
from distribution.dbo.MSpublications

-- Run on Publisher: Get list of publications
Select name, description From SysPublications
order by name

-- OR 
EXEC sp_helpPublication


-- Run on Subscriber: Get object count summary
select TYPE ,count(*) from sys.objects 
where is_ms_shipped = 0
and name not like 'sp_MSupd%'
and name not like 'sp_MSins%'
and name not like 'sp_MSdel%'
and type in ('u','p','v','fn','tf')
group by TYPE
order by type 



-- Run on Subscriber: Get object list
select name, TYPE from sys.objects 
where is_ms_shipped = 0
and name not like 'sp_MSupd%'
and name not like 'sp_MSins%'
and name not like 'sp_MSdel%'
and type in ('u','p','v','fn','tf')
order by type , name

--------------------------------------------------------------------------------------------------------
-- Transactions per hour
Use Distribution
GO
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @StartTime datetime, @EndTime datetime;
SELECT  @StartTime = DATEADD(minute, -60, CURRENT_TIMESTAMP), @EndTime = CURRENT_TIMESTAMP;

SELECT
     p.publisher_db
    ,p.publication
    ,DATEPART(Hour, t.entry_time) AS [time]
    ,COUNT(*) AS cnt
FROM MSrepl_transactions t
INNER JOIN MSrepl_commands c ON t.xact_seqno = c.xact_seqno AND t.publisher_database_id = c.publisher_database_id
INNER JOIN MSpublisher_databases d ON d.id = t.publisher_database_id
INNER JOIN MSpublications p ON p.publisher_db = d.publisher_db
WHERE 1=1
--AND t.entry_time > DATEADD (Hour, -1, CURRENT_TIMESTAMP)
GROUP BY DATEPART(Hour, entry_time), p.publisher_db, p.publication
ORDER BY DATEPART(Hour, entry_time),p.publisher_db, p.publication;

-----------------------------------------------------------------
-- List the replication related jobs
SELECT name, description, enabled from MSDB..sysjobs
WHERE category_id>10 and category_id<20

------------------------------------------------------------------------------------------
Use <published database>
GO
-- Total records in the log
SELECT count(*) FROM ::fn_dblog(NULL, NULL)
GO

-- Records marked for REPLICATION
SElECT count(*) FROM ::fn_dblog(NULL, NULL) WHERE Description='REPLICATE'
GO

--------------------------------------------------------------------
-- General info about publisher, districutor, publications
EXEC distribution.dbo.sp_replmonitorhelppublisher

-------------------------------------------------------------------------------------
-- Get errors occurred 
select id, time,error_type_id, source_name, error_code, error_text 
 from distribution.dbo.msrepl_errors (nolock) 
 order by time desc

--  contains one row for each Distribution Agent running at the local Distributor
SELECT id, name, publisher_db, publication, creation_date FROM MSdistribution_agents

-- contains history rows for the Distribution Agents associated with the local Distributor.
SELECT agent_id,runstatus, start_time, duration, comments, delivered_transactions, delivered_commands, delivery_latency, total_delivered_commands, error_id FROM MSdistribution_history

-- view exposes additional information on the status commands in the distribution database
SELECT * FROM MSDistribution_Status
------------------------------------------------------------------------------------------------------
-- Executed at distributor. Returns replicated commands stored in the distribution database
sp_browsereplcmds


-- Executed at distributor. Returns current status information for one or more publications at a Publisher.
sp_replmonitorhelppublication @publisher = 'CO390DOLAP1'


-- Executed at distributor. Returns status information for subscriptions 
sp_replmonitorhelpsubscription @publisher = 'CO390DOLAP1', @publication_type = 0


-- Executed at distributor. Returns pending command count and estimated time
sp_replmonitorsubscriptionpendingcmds @publisher = 'CO390DOLAP1', @publisher_db = 'USS_Customer_DM_01', @publication = 'Publi_Multi1', @subscriber = 'CO390DOLAP1\Rpt1', @subscriber_db = 'USS_Customer_DM_01', @subscription_type = 1

------------------------------------------------------------------------------------
-- Transactions Not Replicated
With MaxXact (SubscriberServer, Publisher_db, XactSeqNo)
As (Select S.name, DA.publisher_db, max(H.xact_seqno)
    From distribution.dbo.MSdistribution_history H with(nolock)
    Inner Join distribution.dbo.MSdistribution_agents DA with(nolock) On DA.id = H.agent_id
    Inner Join master.sys.servers S with(nolock) On S.server_id = DA.subscriber_id
    Group By S.name, DA.publisher_db)
Select MX.SubscriberServer, MX.Publisher_db, COUNT(*) As TransactionsNotReplicated
From distribution.dbo.msrepl_transactions T with(nolock)
Right Join MaxXact MX On MX.XactSeqNo < T.xact_seqno And MX.Publisher_db = db_name(T.publisher_database_id)
Group By MX.SubscriberServer, MX.Publisher_db

-- Commnads not replicated
With MaxXact (ServerName, PublisherDBID, XactSeqNo)
As (Select S.name, DA.publisher_database_id, max(H.xact_seqno)
    From distribution.dbo.MSdistribution_history H with(nolock)
    Inner Join distribution.dbo.MSdistribution_agents DA with(nolock) On DA.id = H.agent_id
    Inner Join master.sys.servers S with(nolock) On S.server_id = DA.subscriber_id
    Group By S.name, DA.publisher_database_id)
Select MX.ServerName, MX.PublisherDBID, COUNT(*) As CommandsNotReplicated
From distribution.dbo.MSrepl_commands C with(nolock)
Right Join MaxXact MX On MX.XactSeqNo < C.xact_seqno And MX.PublisherDBID = C.publisher_database_id
Group By MX.ServerName, MX.PublisherDBID;


---------------------------------------------------------------------
SELECT 
(CASE  
    WHEN mdh.runstatus =  '1' THEN 'Start - '+cast(mdh.runstatus as varchar)
    WHEN mdh.runstatus =  '2' THEN 'Succeed - '+cast(mdh.runstatus as varchar)
    WHEN mdh.runstatus =  '3' THEN 'InProgress - '+cast(mdh.runstatus as varchar)
    WHEN mdh.runstatus =  '4' THEN 'Idle - '+cast(mdh.runstatus as varchar)
    WHEN mdh.runstatus =  '5' THEN 'Retry - '+cast(mdh.runstatus as varchar)
    WHEN mdh.runstatus =  '6' THEN 'Fail - '+cast(mdh.runstatus as varchar)
    ELSE CAST(mdh.runstatus AS VARCHAR)
END) [Run Status], 
--mda.subscriber_db [Subscriber DB], 
mda.publication [PUB Name],
right(left(mda.name,LEN(mda.name)-(len(mda.id)+1)), LEN(left(mda.name,LEN(mda.name)-(len(mda.id)+1)))-(10+len(mda.publisher_db)+(case when mda.publisher_db='ALL' then 1 else LEN(mda.publication)+2 end))) [SUBSCRIBER],
CONVERT(VARCHAR(25),mdh.[time]) [LastSynchronized],
und.UndelivCmdsInDistDB [UndistCom], 
mdh.comments [Comments], 
--'select * from distribution.dbo.msrepl_errors (nolock) where id = ' + CAST(mdh.error_id AS VARCHAR(8)) [Query More Info],
--mdh.xact_seqno [SEQ_NO],
(CASE  
    WHEN mda.subscription_type =  '0' THEN 'Push' 
    WHEN mda.subscription_type =  '1' THEN 'Pull' 
    WHEN mda.subscription_type =  '2' THEN 'Anonymous' 
    ELSE CAST(mda.subscription_type AS VARCHAR)
END) [SUB Type]

--mda.publisher_db+' - '+CAST(mda.publisher_database_id as varchar) [Publisher DB],
--mda.name [Pub - DB - Publication - SUB - AgentID]
FROM distribution.dbo.MSdistribution_agents mda 
LEFT JOIN distribution.dbo.MSdistribution_history mdh ON mdh.agent_id = mda.id 
JOIN 
    (SELECT s.agent_id, MaxAgentValue.[time], SUM(CASE WHEN xact_seqno > MaxAgentValue.maxseq THEN 1 ELSE 0 END) AS UndelivCmdsInDistDB 
    FROM distribution.dbo.MSrepl_commands t (NOLOCK)  
    JOIN distribution.dbo.MSsubscriptions AS s (NOLOCK) ON (t.article_id = s.article_id AND t.publisher_database_id=s.publisher_database_id ) 
    JOIN 
        (SELECT hist.agent_id, MAX(hist.[time]) AS [time], h.maxseq  
        FROM distribution.dbo.MSdistribution_history hist (NOLOCK) 
        JOIN (SELECT agent_id,ISNULL(MAX(xact_seqno),0x0) AS maxseq 
        FROM distribution.dbo.MSdistribution_history (NOLOCK)  
        GROUP BY agent_id) AS h  
        ON (hist.agent_id=h.agent_id AND h.maxseq=hist.xact_seqno) 
        GROUP BY hist.agent_id, h.maxseq 
        ) AS MaxAgentValue 
    ON MaxAgentValue.agent_id = s.agent_id 
    GROUP BY s.agent_id, MaxAgentValue.[time] 
    ) und 
ON mda.id = und.agent_id AND und.[time] = mdh.[time] 
where mda.subscriber_db<>'virtual' -- created when your publication has the immediate_sync property set to true. This property dictates whether snapshot is available all the time for new subscriptions to be initialized. This affects the cleanup behavior of transactional replication. If this property is set to true, the transactions will be retained for max retention period instead of it getting cleaned up as soon as all the subscriptions got the change.
--and mdh.runstatus='6' --Fail
--and mdh.runstatus<>'2' --Succeed
order by mdh.[time]












--Log Reader Agent: transaction log file scan and failure to construct a replicated command 

--Updates the record that identifies the last distributed transaction of the server
exec sp_repldone @xactid = NULL, @xact_seqno = NULL, @numtrans = 0, @time = 0, @reset = 1
GO
-- Flushes the article cache
sp_replflush
GO

sp_replrestart
GO

SP_RemoveDBReplication
GO 

USE master
EXEC sp_removedbreplication @dbname='M2MHub_Billing'
GO
sp_dropsubscription @subscriber='NYCHUBBILDBCLU'
GO
sp_droppublication 'M2MHUB_CRMMain'
GO

EXEC sp_dropsubscription 
  @publication = 'M2MHUB_CRMSnapshot', 
  @article = N'all',
  @subscriber = 'NYCHUBBILDBCLU',
  @ignore_distributor = 1;

EXEC sp_serveroption 'TMH-USW2A-CRDB1', 'DATA ACCESS', TRUE
GO





-- Get replication config in distribution
USE Distribution 
GO 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
-- Get the publication name based on article 
SELECT DISTINCT  
srv.srvname publication_server  
, a.publisher_db 
, p.publication publication_name 
, a.article 
, a.destination_object 
, ss.srvname subscription_server 
, s.subscriber_db 
, da.name AS distribution_agent_job_name 
FROM MSArticles a  
JOIN MSpublications p ON a.publication_id = p.publication_id 
JOIN MSsubscriptions s ON p.publication_id = s.publication_id 
JOIN master..sysservers ss ON s.subscriber_id = ss.srvid 
JOIN master..sysservers srv ON srv.srvid = p.publisher_id 
JOIN MSdistribution_agents da ON da.publisher_id = p.publisher_id  
     AND da.subscriber_id = s.subscriber_id 
ORDER BY 1,2,3  




-- Get Publications
-- Run from Publisher Database  
-- Get information for all databases 
DECLARE @Detail CHAR(1) 
SET @Detail = 'Y' 
CREATE TABLE #tmp_replcationInfo ( 
PublisherDB VARCHAR(128),  
PublisherName VARCHAR(128), 
TableName VARCHAR(128), 
SubscriberServerName VARCHAR(128), 
) 
EXEC sp_msforeachdb  
'use ?; 
IF DATABASEPROPERTYEX ( db_name() , ''IsPublished'' ) = 1 
insert into #tmp_replcationInfo 
select  
db_name() PublisherDB 
, sp.name as PublisherName 
, sa.name as TableName 
, UPPER(srv.srvname) as SubscriberServerName 
from dbo.syspublications sp  
join dbo.sysarticles sa on sp.pubid = sa.pubid 
join dbo.syssubscriptions s on sa.artid = s.artid 
join master.dbo.sysservers srv on s.srvid = srv.srvid 
' 
IF @Detail = 'Y' 
   SELECT * FROM #tmp_replcationInfo 
ELSE 
SELECT DISTINCT  
PublisherDB 
,PublisherName 
,SubscriberServerName  
FROM #tmp_replcationInfo 
DROP TABLE #tmp_replcationInfo 




-- Get subscription info
-- Run from Subscriber Database 
SELECT distinct publisher, publisher_db, publication
FROM dbo.MSreplication_subscriptions
ORDER BY 1,2,3


-- Table Diff
"C:\Program Files\Microsoft SQL Server\100\COM\tablediff.exe" -sourceserver PV1A-W-DB01 -sourcedatabase wmp -sourcetable networkconnectionsonline -destinationserver PV1A-W-DB03\cludb02 -destinationdatabase wmpoperatorusage -destinationtable networkconnectionsonline -et Difference -f D:\DeadLocks\networkconnectionsonline.sql

-- information about distribution agents that are actively distributing transactions (in progress) and will provide useful information such as the delivery rate (txs/sec). 
SELECT      da.name, da.publisher_db, da.subscription_type,
            dh.runstatus, dh.delivery_rate, dh.start_time, dh.duration
FROM        dbo.MSdistribution_history dh WITH (NOLOCK)
INNER JOIN  dbo.msdistribution_agents da WITH (NOLOCK)
ON          dh.agent_id = da.id
WHERE       dh.runstatus = 3 -- 3 means 'in progress', table explanation here:
            -- http://msdn.microsoft.com/en-us/library/ms179878.aspx
AND         dh.start_time BETWEEN DATEADD(dd,-30,GETDATE()) AND GETDATE()
ORDER BY    dh.start_time DESC