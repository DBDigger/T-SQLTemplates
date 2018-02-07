-- Get list of SQL logins
SELECT name AS Login_Name, type_desc AS Account_Type
FROM sys.server_principals 
WHERE type_desc = 'SQL_LOGIN'
and name not like '%##%'
and is_disabled  = 0
ORDER BY type_desc, name