DECLARE @NTLogin nvarchar(128); SET @NTLogin = 'WYLESSNET\Administrator'
DECLARE @UserList TABLE (
	[Account Name] nvarchar(128),
	[Type] nvarchar(128),
	[Privilege] nvarchar(128),
	[Mapped Login Name] nvarchar(128),
	[Permission Path] nvarchar(128) )
INSERT INTO @UserList EXEC xp_logininfo @NTLogin, 'all' --insert group information
IF EXISTS (SELECT NULL FROM @UserList WHERE [Type] = 'group') --only if it's a group
INSERT INTO @UserList EXEC xp_logininfo @NTLogin, 'members' --insert member information
SELECT * FROM @UserList


 exec xp_logininfo 'WYLESSNET\Administrator', 'members' 
 exec xp_logininfo 'WYLESSNET\Administrator', 'all'