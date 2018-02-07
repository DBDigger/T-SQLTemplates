-- Map orphaned users
EXEC	[dbo].[spFixOrphanUsers] 		@DatabaseNM = N'dm_memberdemogr'


-- Generate user permissions
declare @DBName varchar(50) = NULL
declare @UserName Varchar(100) = 'Remote_Call'


DECLARE @DB_USers TABLE
(DBName sysname, UserName sysname, LoginType sysname, AssociatedRole varchar(max),create_date datetime,modify_date datetime)
 
INSERT @DB_USers
EXEC sp_MSforeachdb
 
'
use [?]
SELECT ''?'' AS DB_Name,
case prin.name when ''dbo'' then prin.name + '' (''+ (select SUSER_SNAME(owner_sid) from master.sys.databases where name =''?'') + '')'' else prin.name end AS UserName,
prin.type_desc AS LoginType,
isnull(USER_NAME(mem.role_principal_id),'''') AS AssociatedRole ,prin.create_date,prin.modify_date
FROM sys.database_principals prin
INNER JOIN sys.server_principals AS SP
ON prin.sid = SP.sid
LEFT OUTER JOIN sys.database_role_members mem ON prin.principal_id=mem.member_principal_id
WHERE prin.sid IS NOT NULL and prin.sid NOT IN (0x00) and
prin.is_fixed_role <> 1 AND SP.is_disabled =0 and  prin.name NOT LIKE ''##%''' 
 
SELECT
 
dbname,username ,logintype ,
 
STUFF(
 
(
 
SELECT ',' + CONVERT(VARCHAR(500),associatedrole)
 
FROM @DB_USers user2
 
WHERE 
user1.DBName=user2.DBName AND user1.UserName=user2.UserName
 
FOR XML PATH('')
 
)
 
,1,1,'') AS Permissions_user
 
FROM @DB_USers user1

WHERE dbname = CASE WHEN @DBName IS null then  dbname ELSE @DBName END
and  UserName = CASE WHEN @UserName IS null then UserName else @UserName END
 
GROUP BY
 
dbname,username ,logintype ,create_date ,modify_date
 
ORDER BY DBName,username



