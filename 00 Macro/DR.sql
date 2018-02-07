-- 1. Backup on source DBs
select 'backup database '+ name +'
to disk  = ''\\asinetwork.local\Backups\SQL Backups 3\PRD\' + @@servername + '\' + name + '.bak''
with init, stats = 5
go'
from sys.databases
where database_id<5


-- 2. Restore 
restore  database model_1
from disk = '\\asinetwork.local\Backups\SQL Backups 3\PRD\DR-SQLPCN1-06\model.bak'
with 
move 'modeldev' to 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\New\model.mdf',
move 'modellog' to 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\New\modellog.ldf',
stats = 10
go

restore database master_1
from disk = '\\asinetwork.local\Backups\SQL Backups 3\PRD\DR-SQLPCN1-06\master.bak'
with 
move 'master' to 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\New\master.mdf',
move 'mastlog' to 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\New\mastlog.ldf',
stats = 10
go

restore  database msdb_1
from disk = '\\asinetwork.local\Backups\SQL Backups 3\PRD\DR-SQLPCN1-06\msdb.bak'
with 
move 'MSDBData'to 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\New\MSDBData.mdf',
move 'MSDBLog' to 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\New\MSDBLog.ldf',
stats = 10
go

-- 2. Drop existing availability group after system DBs restore
DROP AVAILABILITY GROUP [asi-sqlpcdg1-06]

-- 3. Drop existing Db folders
select 'drop database ['+name+'];' from sys.databases 

-- 4. change Instance name
select @@servername

-- 5. Drop instance name
exec sp_dropserver 'DR-SQLPCN1-06', 'droplogins'

-- 6. Rename instance name
sp_addserver  'DR-SQLPCN2-06', 'local'

-- 7. Remove required DBs from log backup plan on source server 

-- 8. Backup databases on source server

-- 9. Restore DBs on DR with no recovery

-- 10. Add DBs in logshipping

-- 11. Copy SSIS files and modify the config files

-- 12

