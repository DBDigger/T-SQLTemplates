-- Get drives shared in cluster
SELECT * FROM sys.dm_io_cluster_shared_drives;

-- Get nodes in a cluster
SELECT * FROM ::FN_VIRTUALSERVERNODES()

-- Get current node
select serverproperty('ComputerNamePhysicalNetBIOS')
