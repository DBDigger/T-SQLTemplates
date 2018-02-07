select name, type_desc from sys.database_principals where type_desc in ('SQL_USER','DATABASE_ROLE')
order by type_desc, name



SELECT 'ALTER AUTHORIZATION ON SCHEMA::'+s.name+' TO dbo;'
FROM sys.schemas s
WHERE s.principal_id = USER_ID('usama.riaz');



ALTER AUTHORIZATION ON SCHEMA::[[dbo],[zts]] TO dbo;

drop user [usama.riaz];


EXEC sp_change_users_login 'Auto_Fix', 'TestUser2'
GO