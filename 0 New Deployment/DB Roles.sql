-- Update the RoleName with the name of your role
DECLARE @RoleName VARCHAR(75) = '[ROLE_General_Permissions'

DECLARE @RoleTable TABLE ([GrantedBy] VARCHAR (50) NOT NULL, [Permission] VARCHAR (50) NOT NULL, [State] VARCHAR (50) NOT NULL)
DECLARE @RoleScript VARCHAR(75)

INSERT INTO @RoleTable SELECT p2.[name], dbp.[permission_name], dbp.[state_desc] 
FROM [sys].[database_permissions] dbp LEFT JOIN [sys].[objects] so
    ON dbp.[major_id] = so.[object_id] LEFT JOIN [sys].[database_principals] p
    ON dbp.[grantee_principal_id] = p.[principal_id] LEFT JOIN [sys].[database_principals] p2
    ON dbp.[grantor_principal_id] = p2.[principal_id]
WHERE p.[name] = @RoleName

SELECT 'USE [' +  DB_NAME() + '] CREATE ROLE [' + @RoleName + ']' AS 'Create Role'
SELECT 'USE [' +  DB_NAME() + '] GRANT ' + [Permission] + ' ON SCHEMA::[' + [GrantedBy] + '] TO [' + @RoleName + ']' AS 'Add Permissions' 
FROM @RoleTable 


-----------------------------------------------------------------
CREATE ROLE [ROLE_General_Permissions]
GO

GRANT SELECT ON SCHEMA::[dbo] TO [ROLE_General_Permissions];
GRANT VIEW DEFINITION ON SCHEMA::[dbo] TO [ROLE_General_Permissions];
GO