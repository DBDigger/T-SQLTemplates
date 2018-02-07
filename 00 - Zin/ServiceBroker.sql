-- Get queue names and SPs
select name, state, is_activation_enabled 
from sys.dm_broker_queue_monitors qm inner join sys.service_queues sq 
on qm.queue_id = sq.object_id


-- Invalid queue items
select count(*) as InvalidQueueItems 
from broker.LocalReqReceiveQueue_All with(nolock) 
where message_body is not null 
and CAST(message_body AS nvarchar)='0|0|0|1'


-- Requests without simcard ID
select count(*) as [Requests without SIMCARD ID] 
from wmp..REQUESTDETAILS1 r with (nolock) 
where r.SIMID_FK is null and r.REQUESTSTATUSIDINTERNAL_FK = 1 
and r.XMLPACKET is not null 
and r.CREATED >='2014-06-05 00:00:00.000'

-- Get queue count
select COUNT(1)/2 
from wmp.[broker].[LocalReqSendQueue_TMO] with (nolock)

http://www.sqlteam.com/article/how-to-troubleshoot-service-broker-problems

-- A row for each stored procedure activated by Service Broker. It can be joined to dm_exec_sessions.session_id via the spid column. 
select * from sys.dm_broker_activated_tasks

-- returns a row for each Service Broker network connection
select * from sys.dm_broker_connections 

-- returns a row for each Service Broker message that an instance of SQL Server is in the process of forwarding.
select * from sys.dm_broker_forwarded_messages

-- returns a row for each queue monitor in the instance. A queue monitor manages activation for a queue.
select * from sys.dm_broker_queue_monitors


--Every sent message sits in it until the target sends back a acknowledgement. If an acknowledgement returns successfully then the message will disappear from the view. If not the transmission_status column will hold the error information. 
select * from sys.transmission_queue

select queue_id, name, state from sys.dm_broker_queue_monitors qm inner join sys.service_queues sq on qm.queue_id = sq.object_id
select top 10 * from problemrequest order by created desc



ALTER QUEUE broker.LocalReqReceiveQueue_All WITH STATUS = OFF ;
ALTER QUEUE broker.LocalReqReceiveQueue_All WITH STATUS = ON ;


select CAST(message_body AS nvarchar),* from broker.LocalReqReceiveQueue_All where message_body is not null


sp_recompile NetworkJobs_RemoveSims_II
sp_recompile NetworkJobs_AddSims_II

sp_recompile NetworkJobs_AddSims;
sp_recompile NetworkJobs_RemoveSims;

-- Receive queue
RECEIVE TOP(1)   CAST(message_body AS nvarchar)
  FROM broker.CombineReqSIMIDReceiveQueue
  
  
select * from sys.objects where name = 'NetworkJobs_RemoveSims_II'



SELECT conversation_handle, is_initiator, s.name as 'local service',
far_service, sc.name 'contract', state_desc
FROM sys.conversation_endpoints ce
LEFT JOIN sys.services s
ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts sc
ON ce.service_contract_id = sc.service_contract_id;


SELECT SP.SPID,[TEXT] as SQLcode FROM SYS.SYSPROCESSES SP
CROSS APPLY SYS.DM_EXEC_SQL_TEXT(SP.[SQL_HANDLE])AS DEST WHERE OPEN_TRAN=1

SELECT [conversation_handle] FROM sys.conversation_endpoints


DBCC OPENTRAN

SELECT 
er.session_id
,er.open_transaction_count
FROM sys.dm_exec_requests er
where er.open_transaction_count > 0


select * from sys.service_queues

select * from sys.dm_broker_queue_monitors 

select * from sys.dm_broker_activated_tasks

select * from  sys.transmission_queue


select Q.name as queuename, i.name as internalname
from sys.service_queues as Q
	join sys.internal_tables as I
		on q.object_id = i.parent_object_id

http://www.mssqltips.com/sqlservertip/1197/service-broker-troubleshooting/
http://technet.microsoft.com/en-us/library/ms166069%28v=sql.105%29.aspx


select top 1000 * from requests1 where requestid = 7948965


select top 10 * from requestdetails1  where requestdetailid = 14612049



sp_recompile 'networkjobs_addsims'

 select CAST(message_body AS nvarchar(max)) from broker.localreqreceivequeue_roammobilityall

  select COUNT(*)/2 from broker.localreqreceivequeue_roammobilityall


RECEIVE TOP(1)
		 conversation_handle,
		service_name,
		 service_contract_name,
		message_type_name,
		 CAST(message_body AS nvarchar(max))
	FROM broker.localreqreceivequeue_roammobilityall


	select top 100 * from exceptionlog order by 1 desc






-------------------------------------------------------------------------------------------------------------------------------------
  
 
DECLARE  
 @vRequestId bigint,  
 @vRequestDetailId bigint,  
 @vRequestTypeId smallint,  
 @vIsSyncRequired smallint,  
 @vConversation_handle uniqueidentifier,  
 @vCombinedQueueData nvarchar(500),  
 @vReqStatusInternalId smallint,  
 @veLogMessage nvarchar(max),  
 @vResult int,  
 @veUserMessage nvarchar(1024),  
 @veLogId bigint,  
 @vProcessNotificationId bigint,  
 @vMessage nvarchar(max)  
BEGIN    
   SET NOCOUNT ON;     
     
 BEGIN TRY;   
  RECEIVE TOP(1) @vCombinedQueueData =  CAST(message_body AS nvarchar)  
  FROM broker.LocalReqReceiveQueue_All;  
    
  --Separate the combined data so that we can have requestid, detailid, type & IsSyn.  
  DECLARE  
  @f smallint,  
  @s smallint,  
  @t smallint  
  
  SELECT @f = CHARINDEX ('|', @vCombinedQueueData, 1)  
  SELECT @vRequestId = SUBSTRING(@vCombinedQueueData, 1, @f-1)  
  SELECT @s = CHARINDEX ('|', @vCombinedQueueData, @f+1)  
  SELECT @vRequestDetailId = SUBSTRING(@vCombinedQueueData, @f+1, (@s-@f)-1)    
  SELECT @t = CHARINDEX ('|', @vCombinedQueueData, @s+1)     
  SELECT @vRequestTypeId = SUBSTRING(@vCombinedQueueData, @s+1, (@t-@s)-1)  
  SELECT @vIsSyncRequired = SUBSTRING(@vCombinedQueueData, @t+1, 5) 
  
   
  print @vRequestTypeId;
  print @vRequestId;
 BEGIN TRANSACTION;  
   
  ---Check if the request is already procedded or not-------------------   
  IF @vRequestDetailId <> 0  
  BEGIN  
   SELECT @vReqStatusInternalId = rd.REQUESTSTATUSIDINTERNAL_FK  
   FROM requestdetails1 rd WITH (NOLOCK)  
   WHERE rd.REQUESTDETAILID = @vRequestDetailId;  
  END  
  ELSE  
  BEGIN  
   SET @vReqStatusInternalId = 1;  
  END  
   
  IF @vReqStatusInternalId = 1 --- Not processed yet.  
  BEGIN  
   IF @vRequestTypeId = 0  
   BEGIN  
    SELECT @vRequestTypeId = R.REQUESTTYPEID_FK  
    FROM REQUESTS1 R WITH (NOLOCK)  
    WHERE R.REQUESTID =  @vRequestId  
   END  
         
   IF @vIsSyncRequired = 1  
   BEGIN  
    --EXECUTE dbo.EIMSynchronizeRequests_Porthos @vRequestId;  
    print 'USP EIMSynchronizeRequests_Porthos called'
   END    
      
   IF @vRequestTypeId IN (21, 4, 40)  
   BEGIN  
    --EXECUTE dbo.RequestsLocalProcessing_SIMInquiry_II @vRequestId; 
    print 'USP RequestsLocalProcessing_SIMInquiry_II called' 
   END  
   ELSE  
   BEGIN  
    /* Checking if Stock Request completed or not. If it is not completed then local processing procedure will not process   
     the SIMs which are not yet processed by Stock processing service. So we need to send it back to queue. (POR-664 and PAPI-288)*/  
    IF EXISTS (SELECT 1 FROM REQUESTDETAILS1 RD WITH(NOLOCK) WHERE RD.REQUESTID_FK=@vRequestId AND RD.SIMID_FK IS NULL AND @vRequestTypeId IN(24,2,8) AND RD.REQUESTSTATUSIDINTERNAL_FK=1)  
    BEGIN  
     --EXEC [dbo].[SendRequestToLocalQueue_All]  
     --     @pRequestId =@vRequestId,  
     --     @pRequestDetailId =@vRequestDetailId,  
     --     @pRequestType = @vRequestTypeId,  
     --     @pIsSyncRequired= @vIsSyncRequired;  
     Print 'USP SendRequestToLocalQueue_All Called'
    END  
    ELSE  
    BEGIN  
     --EXECUTE dbo.RequestsLocalProcessing_II @vRequestId, @vRequestTypeId;  
     print 'USP RequestsLocalProcessing_II called'
    END  
   END;  
  END         
  
 COMMIT TRANSACTION  
  END TRY  
  BEGIN CATCH  
  IF XACT_STATE() <> 0  
  BEGIN  
   ROLLBACK TRANSACTION;  
  END  
  SELECT @veLogMessage = 'Procedure Name = '+ERROR_PROCEDURE()+': Error Number = '+CONVERT(VARCHAR,ERROR_NUMBER())+': Error On Line = '+CONVERT(VARCHAR,ERROR_LINE())+': Message = '+ERROR_MESSAGE()  
    
  INSERT INTO ProblemRequest(RequestID,CombinedQueueData,ErrorMessage,ProcessingStatus,Created,CreatedBy)  
  values(@vRequestId,@vCombinedQueueData,@veLogMessage,1,GETUTCDATE(),1)  
    
  EXECUTE @vResult= dbo.ProcessNotifications_Insert @pCompanyId = 47,  
               @pParameterList  = NULL,  
               @pContractId  = NULL,  
               @pWFStateId  = NULL,  
               @pRequestId  = @vRequestId,  
               @pRequestDetailId  = NULL,  
               @pRequestTypeId  = NULL,  
               @pAttachmentName   = NULL,  
               @pAttachment  = NULL,  
               @pMessageCode ='wnLocalProcessingException',  
               @pEmail = 'technical.support@zintechnologies.com',  
               @pCrestedBy =2899,  
               @pLanguageId  = 1,  
               @pProcessNotificationId = @vProcessNotificationId OUTPUT,  
               @pMessage = @vMessage OUTPUT  
             
  EXECUTE @vResult = dbo.ExceptionLog_INSERT @pMessage  = @veLogMessage,  
               @pUserId_Fk   = 1,   
               @pOrgId       = 1,  
               @pUserMessage = @veUserMessage OUTPUT,  
               @pLOGID       = @veLogId OUTPUT  
  --RETURN ERROR_NUMBER();  
 END CATCH   
END  
  