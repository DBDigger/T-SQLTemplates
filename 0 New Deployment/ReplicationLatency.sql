DECLARE @xml NVARCHAR(MAX)
DECLARE @body NVARCHAR(MAX)
DECLARE @DateHTML NVARCHAR(400)
declare @TID_Billing_Main int
declare @TID_PorthosUpdateable int
declare @TID_WMPTMUSAsyncResponse int


EXEC wmp.sys.sp_posttracertoken @publication = 'PorthosMain'
EXEC wmp.sys.sp_posttracertoken @publication = 'PorthosUpdateable'
EXEC wmp.sys.sp_posttracertoken @publication = 'WMPTMUSAsyncResponse'
  
 waitfor delay '00:03:00'
 
 if exists 
 (
SELECT publication_id
FROM distribution..MStracer_tokens t
JOIN distribution..MStracer_history h
ON t.tracer_id = h.parent_tracer_id
where (t.distributor_commit is null or h.subscriber_commit is null)
and t.tracer_id in (@TID_Billing_Main,@TID_PorthosUpdateable, @TID_WMPTMUSAsyncResponse)
)

begin
SET @xml = CAST((
 SELECT publication_id AS 'td'
					,'' 
					,agent_id AS 'td'
					,''
					, t.publisher_commit AS 'td'
					,''
       ,isnull(convert(varchar(8),Datediff(s,t.publisher_commit,t.distributor_commit)),'Pending')  AS 'td'
					,''
       ,isnull(convert(varchar(8),Datediff(s,t.distributor_commit,h.subscriber_commit)),'Pending') AS 'td'

FROM distribution..MStracer_tokens t
JOIN distribution..MStracer_history h
ON t.tracer_id = h.parent_tracer_id
where t.tracer_id in (@TID_Billing_Main,@TID_PorthosUpdateable, @TID_WMPTMUSAsyncResponse)
order by t.publisher_commit desc FOR XML PATH('tr')
					,ELEMENTS
				) AS NVARCHAR(MAX))

SET @body = '<html><body> <br>
<table border = 1> 
<tr>
 <th>  PublicationID </th><th>  AgentID</th><th>  PublisherCommit </th> <th> TimeToDist(Sec) </th> <th> TimeToSub(Sec) </th>  </tr>'
 	SET @body = 'There seems latency on CRM (172.18.1.206). </br> Following is the status for latest trace.'+@body + @xml + '</table></body></html>'
				
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'DBA_mail',
    @recipients = 'atif.shahzad@zintechnologies.com; asim.aslam@zintechnologies.com',
	--@copy_recipients = 'usama.riaz@zintechnologies.com; mehran.raza@wyless.com',
    @body = @body,
	@body_format = 'HTML',
    @subject = 'Latency in replication on CRM (172.18.1.206)' 
   
end