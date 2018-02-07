-- Get list of users
select name, type_desc from sys.database_principals where type_desc in ('SQL_USER','DATABASE_ROLE')
order by type_desc, name

--Get the list of all Login Accounts in a SQL Server

SELECT name AS Login_Name, type_desc AS Account_Type
FROM sys.server_principals 
WHERE TYPE IN ('U', 'S', 'G')
and name not like '%##%'
ORDER BY name, type_desc

--Get the list of all SQL Login Accounts only

SELECT name
FROM sys.server_principals 
WHERE TYPE = 'S'
and name not like '%##%'

--Get the list of all Windows Login Accounts only

SELECT name
FROM sys.server_principals 
WHERE TYPE = 'U'

--Get the list of all Windows Group Login Accounts only

SELECT name
FROM sys.server_principals 
WHERE TYPE = 'G'
