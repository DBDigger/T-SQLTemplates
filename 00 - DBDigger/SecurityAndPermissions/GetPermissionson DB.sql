EXECUTE AS USER = 'VerizonJava2';
SELECT * FROM fn_my_permissions(NULL, 'database') 
    ORDER BY subentity_name, permission_name ;  
REVERT;
GO

https://msdn.microsoft.com/en-us/library/ms176097.aspx

XECUTE AS USER = 'VerizonJava';
SELECT * FROM fn_my_permissions(NULL, 'SERVER'); 
REVERT;
GO