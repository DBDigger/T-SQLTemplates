select * from [OPR_Support].[dbo].[LOOK_Database_DBSE] where DBSE_Name = 'test4'

SELECT MAX([DBSE_ID]) FROM [OPR_Support].[dbo].[LOOK_Database_DBSE]

INSERT INTO [OPR_Support].[dbo].[LOOK_Database_DBSE]
           ([DBSE_ID] ,[DBSE_Type_CD],[DBSE_Name] ,[DBSE_Desc]  ,[DBSE_Status]   ,[DBSE_Public]       )
     VALUES
           (378  ,'APP'  ,'test3' ,'Test database for AG configurations on BI'  ,'A'  ,'Y')
GO


--select max(ServerDBRelationship_ID) from [OPR_Support].[dbo].[OPER_ServerDBRelationship]

--select * from [OPR_Support].[dbo].LOOK_SERVER_SRVR where SRVR_SQLServer_Name like 'ASI-SQLPCN2-15'

insert into LOOK_SERVER_SRVR (SRVR_ID, SRVR_Type_CD, SRVR_Name, SRVR_Desc, SRVR_Status, SRVR_Public,  SRVR_SQLServer_Name)
values (217, 'PRD', 'ASI-SQLSI-10', 'Sandbox for Velocity External API', 'A', 'N', 'ASI-SQLSI-10')

insert into [OPR_Support].[dbo].[OPER_ServerDBRelationship]
(ServerDBRelationshipType_CD, SRVR_ID, DBSE_ID, [Status], ServerDBRelationship_ID) 
values ('BAKX', 249, 378, 'A', 1931 )
GO
