/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 *  FROM [DBAServices].[dbo].[Maint_Indexes]

-- Set NULL for all Non partitioned tables
Update [DBAServices].[dbo].[Maint_Indexes] set processtime = NULL where partitionnumb is null

-- Get fragmentation for single table
select * FROM sys.dm_db_index_physical_stats(db_id(), object_id('invoiceitemdetails_4usagefile'), NULL, NULL , NULL)
GO


sp_helpindex SIMCARDS


SELECT * FROM [DBAServices].[dbo].[Maint_Indexes]


insert into [DBAServices].[dbo].[Maint_Indexes] values ('[IPADDRESSES]', '[Inx_IPAddresses_IP]', NULL, NULL, NULL)