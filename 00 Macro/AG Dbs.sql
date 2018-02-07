:connect ASI-SQLPCN1-06
select * from sys.dm_hadr_database_replica_states where synchronization_state_desc not in ('SYNCHRONIZED' ,'SYNCHRONIZING')
GO

select r.replica_server_name, r.endpoint_url,
rs.connected_state_desc, rs.last_connect_error_description, 
rs.last_connect_error_number, rs.last_connect_error_timestamp 
from sys.dm_hadr_availability_replica_states rs join sys.availability_replicas r
on rs.replica_id=r.replica_id
where rs.is_local=1
GO

    SELECT db_name(database_id) as DBName,
        session_id FROM sys.dm_exec_requests
        WHERE command = 'DB STARTUP'


select * from sys.dm_hadr_cluster
select * from sys.dm_hadr_cluster_members
select * from sys.dm_hadr_cluster_networks
select * from sys.availability_groups
select * from sys.availability_groups_cluster
select * from sys.dm_hadr_availability_group_states
select * from sys.availability_replicas
select * from sys.dm_hadr_availability_replica_cluster_nodes
select * from sys.dm_hadr_availability_replica_cluster_states
select * from sys.dm_hadr_availability_replica_states
select * from sys.dm_hadr_auto_page_repair
select * from sys.dm_hadr_database_replica_states
select * from sys.dm_hadr_database_replica_cluster_states
select * from sys.availability_group_listener_ip_addresses
select * from sys.availability_group_listeners
select * from sys.dm_tcp_listener_states

select object_name,counter_name,instance_name,cntr_value
from sys.dm_os_performance_counters
 where object_name like '%replica%'
 and counter_name = 'Log remaining for undo'     



SELECT
AG.name AS [AvailabilityGroupName],
ISNULL(agstates.primary_replica, '') AS [PrimaryReplicaServerName],
dbcs.database_name AS [DatabaseName]
FROM master.sys.availability_groups AS AG
LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states as agstates
   ON AG.group_id = agstates.group_id
INNER JOIN master.sys.availability_replicas AS AR
   ON AG.group_id = AR.group_id
INNER JOIN master.sys.dm_hadr_availability_replica_states AS arstates
   ON AR.replica_id = arstates.replica_id AND arstates.is_local = 1
INNER JOIN master.sys.dm_hadr_database_replica_cluster_states AS dbcs
   ON arstates.replica_id = dbcs.replica_id
   where dbcs.database_name in (
'ADM_Support', 'API_ExternalCompanyMapping', 'EmailExpress', 'EmailExpressL','InternalMarketing',
'MediaProcessing', 'OPR_Support', 'PROD_EIT', 'PROD_EIT_SN', 'PROD_Master', 'PROD_Master_RPRT',
'PROD_Master_WIP', 'Velocity_Conversion'
)

ORDER BY AG.name ASC, dbcs.database_name

-- Get log shipping jobs disable command
select ' EXEC msdb..sp_update_job @job_name =''' +name +  ''', @enabled =0;'
 from msdb..sysjobs
 where name like '%lsr%'
 order by name

 -- Manually execute jobs
 select 'EXEC msdb..sp_start_job @job_name =''' + name + ''''  from msdb..sysjobs
where name like 'cdc%capture%'


 -- Add replica to AG
 :Connect ASI-SQLPCDG1-10
ALTER AVAILABILITY GROUP [asi-sqlpcdg1-10]
ADD REPLICA ON N'dr-sqlpcn2-10' WITH (ENDPOINT_URL = N'TCP://dr-sqlpcn2-10.asinetwork.local:5022', 
FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, SESSION_TIMEOUT = 10, 
PRIMARY_ROLE(ALLOW_CONNECTIONS = ALL), SECONDARY_ROLE(ALLOW_CONNECTIONS = NO));
GO

:Connect ASI-SQLPCDG2-10
ALTER AVAILABILITY GROUP [asi-sqlpcdg2-10]
ADD REPLICA ON N'dr-sqlpcn2-10' WITH (ENDPOINT_URL = N'TCP://dr-sqlpcn2-10.asinetwork.local:5022', 
FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, SESSION_TIMEOUT = 10, 
PRIMARY_ROLE(ALLOW_CONNECTIONS = ALL), SECONDARY_ROLE(ALLOW_CONNECTIONS = NO));
GO


-- Join AG
ALTER AVAILABILITY GROUP group_name JOIN 


-- Add DBs to AG
select 'ALTER DATABASE [' + name + '] SET HADR AVAILABILITY GROUP = [asi-sqlpcdg1-10];'
 from sys.databases
where state =1


-- Remove replicas from AG
:connect asi-sqlpcdg1-11
 ALTER AVAILABILITY GROUP [asi-sqlpcdg1-11] REMOVE REPLICA ON N'DR-SQLPCN1-11';
GO

:connect asi-sqlpcdg2-11
 ALTER AVAILABILITY GROUP [asi-sqlpcdg2-11] REMOVE REPLICA ON N'DR-SQLPCN1-11';
GO

-- Remove DB from replica
ALTER AVAILABILITY GROUP [agname] REMOVE DATABASE [databasename]

-- AG dashboard
-- Run on primary
SELECT 
	ar.replica_server_name, 	adc.database_name, 	ag.name AS ag_name, 	drs.is_local, 	drs.is_primary_replica, 	drs.synchronization_state_desc, 	drs.is_commit_participant, 	drs.synchronization_health_desc, 	drs.recovery_lsn, 	drs.truncation_lsn, 	drs.last_sent_lsn, 	drs.last_sent_time, 
	drs.last_received_lsn, 	drs.last_received_time, 	drs.last_hardened_lsn, 	drs.last_hardened_time, 	drs.last_redone_lsn, 	drs.last_redone_time, 
	drs.log_send_queue_size, 	drs.log_send_rate, 	drs.redo_queue_size, 	drs.redo_rate, 	drs.filestream_send_rate, 	drs.end_of_log_lsn, 
	drs.last_commit_lsn, 	drs.last_commit_time
FROM sys.dm_hadr_database_replica_states AS drs
INNER JOIN sys.availability_databases_cluster AS adc 	ON drs.group_id = adc.group_id AND 	drs.group_database_id = adc.group_database_id
INNER JOIN sys.availability_groups AS ag 	ON ag.group_id = drs.group_id INNER JOIN sys.availability_replicas AS ar ON drs.group_id = ar.group_id AND 
	drs.replica_id = ar.replica_id
ORDER BY 	ag.name, 	ar.replica_server_name, 	adc.database_name;



-- Log shipping info 
select * from [dbo].[log_shipping_monitor_primary]
GO
select * from [dbo].[log_shipping_primary_databases]
GO
select * from [dbo].[log_shipping_primary_secondaries]
GO


select * from msdb.dbo.[log_shipping_monitor_secondary]
GO
select * from msdb.dbo.[log_shipping_secondary]
GO
select * from msdb.dbo.log_shipping_secondary_databases
GO


-- Get LSN
use msdb
go

select  s.backup_set_id, 
        s.first_lsn,
        s.last_lsn,
        s.database_name,
        s.backup_start_date,
        s.backup_finish_date,
        s.type,
        f.physical_device_name
from    backupset s join backupmediafamily f
        on s.media_set_id = f.media_set_id
where   s.backup_finish_date > '08/22/2017' -- or any recent date to limit result set
        and s.database_name = 'ASI_security'
		--and last_lsn = 419918000000696100001
order by s.backup_start_date  desc


-- Restore logs
RESTORE LOG Prod_Master FROM  DISK = N'\\asinetwork.local\Backups\SQL Backups 2\PRD\asi-sqlpcn1-10\RECOVERY\LogBackup\PROD_Master_backup_2017_08_22_210003_3373259.trn' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 10
GO


-- List AG Replica Details 
select n.group_name,n.replica_server_name,n.node_name,rs.role_desc 
from sys.dm_hadr_availability_replica_cluster_nodes n 
join sys.dm_hadr_availability_replica_cluster_states cs 
on n.replica_server_name = cs.replica_server_name 
join sys.dm_hadr_availability_replica_states rs  
on rs.replica_id = cs.replica_id 
 
-- AG Status 
DECLARE @HADRName    varchar(25) 
SET @HADRName = @@SERVERNAME 
select n.group_name,n.replica_server_name,n.node_name,rs.role_desc, 
db_name(drs.database_id) as 'DBName',drs.synchronization_state_desc,drs.synchronization_health_desc 
from sys.dm_hadr_availability_replica_cluster_nodes n 
join sys.dm_hadr_availability_replica_cluster_states cs 
on n.replica_server_name = cs.replica_server_name 
join sys.dm_hadr_availability_replica_states rs  
on rs.replica_id = cs.replica_id 
join sys.dm_hadr_database_replica_states drs 
on rs.replica_id=drs.replica_id 
where n.replica_server_name <> @HADRName