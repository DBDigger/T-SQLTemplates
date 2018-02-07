-- Get object level permissions in a DB
SELECT Us.name AS username,us.type_desc as UserType, schema_name(obj.schema_id)+'.'+Obj.name AS objectName, 
dp.permission_name AS permission  ,  dp.state_desc as PermissionStatus
FROM sys.database_permissions dp 
JOIN sys.database_principals Us  ON dp.grantee_principal_id = Us.principal_id  
JOIN sys.objects Obj ON dp.major_id = Obj.object_id 
--where us.type_desc <> 'DATABASE_ROLE'
order by Us.name 