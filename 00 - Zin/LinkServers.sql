-- Get link server list
SELECT a.server_id,a.name, product, data_source, remote_name
FROM sys.Servers a
LEFT OUTER JOIN sys.linked_logins b ON b.server_id = a.server_id
LEFT OUTER JOIN sys.server_principals c ON c.principal_id = b.local_principal_id


--Set option for all link servers
select 'EXEC master.dbo.sp_serveroption @server=N'''+name+''', @optname=N''remote proc transaction promotion'', @optvalue=N''false'';'  from sys.servers 
where server_id <> 0
and is_remote_proc_transaction_promotion_enabled  = 1
