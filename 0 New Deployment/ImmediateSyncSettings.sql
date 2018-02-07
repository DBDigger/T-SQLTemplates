select immediate_sync , allow_anonymous from syspublications 

select * from syspublications

 EXEC sp_changepublication @publication = 'PorthosTMO_CRM_QA_Snapshot', @property =
N'allow_anonymous', @value='False' 
Go
EXEC sp_changepublication @publication = 'PorthosTMO_CRM_QA_Snapshot', @property =
N'immediate_sync', @value='false'
Go