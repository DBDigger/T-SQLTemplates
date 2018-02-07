-- Drop server
EXEC sp_dropserver  'NYCHUBBILDBCLU'

-- ADD new server name
EXEC sp_addserver DRNYCHUBBILDCLU , 'local' 


select * from sys.servers
-- Query to check remote login
select 
srl.remote_name as RemoteLoginName, 
sss.srvname
from sys.remote_logins srl join sys.sysservers sss on srl.server_id = sss.srvid
-- Query to remove the remote login
--Default Instance
sp_dropremotelogin NYCHUBBILDBCLU
GO
--Named Instance
sp_dropremotelogin 'NYCHUBBILDBCLU'
GO
EXEC Sp_dropserver @@ServerName,'droplogins'
GO