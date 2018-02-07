:connect ASI-SQLPCN1-11
exec msdb..sysmail_update_account_sp  @account_id = 1
    , @mailserver_name =  'relayauth.asicentral.com'    
    , @mailserver_type =  'SMTP'  
    , @port = 587,   
    , @username = 'usrsmtpauth_DBA'   
    , @password = 'pvJ^8nKayOoG'  
    , @use_default_credentials =0  
    , @enable_ssl = 1
GO

Select ':Connect ' + @@servername + ' exec msdb..sysmail_update_account_sp  @account_id = ' + cast(account_id as varchar(10)) + '
    , @mailserver_name =  ''relayauth.asicentral.com''    
    , @mailserver_type =  ''SMTP''  
    , @port = 587,   
    , @username = ''usrsmtpauth_DBA''   
    , @password = ''pvJ^8nKayOoG''  
    , @use_default_credentials =0  
    , @enable_ssl = 1'   
--select * 
from msdb..[sysmail_server]
--where servername not like '%relay%'