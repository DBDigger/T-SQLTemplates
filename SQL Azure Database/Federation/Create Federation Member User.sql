-- ===================================================
-- Create User as DBO template for Windows Azure SQL Database
-- ===================================================

CREATE USER <user_name, sysname, user_name>	
GO

-- Add user to the database owner role
EXEC sp_addrolemember N'db_owner', N'<user_name, sysname, user_name>'
GO
