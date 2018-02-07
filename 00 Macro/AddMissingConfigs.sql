select * from [OPR_Support].[dbo].[LOOK_Database_DBSE] where DBSE_Name = 'EIT_ProductChange_Master'

INSERT INTO [OPR_Support].[dbo].[LOOK_Database_DBSE]
           ([DBSE_ID] ,[DBSE_Type_CD],[DBSE_Name] ,[DBSE_Desc]  ,[DBSE_Status]   ,[DBSE_Public]       )
     VALUES
           (328  ,'APP'  ,'DM_MemberDemogr_ML' ,'Memberdemogr backup used during nightly update - Michael'  ,'A'  ,'Y')
GO

--select max(ServerDBRelationship_ID) from [OPER_ServerDBRelationship]

--select * from LOOK_SERVER_SRVR where SRVR_SQLServer_Name like 'ASI-SQLUCN2-10'

insert into LOOK_SERVER_SRVR (SRVR_ID, SRVR_Type_CD, SRVR_Name, SRVR_Desc, SRVR_Status, SRVR_Public,  SRVR_SQLServer_Name)
values (217, 'PRD', 'ASI-SQLSI-10', 'Sandbox for Velocity External API', 'A', 'N', 'ASI-SQLSI-10')

insert into [OPR_Support].[dbo].[OPER_ServerDBRelationship]
(ServerDBRelationshipType_CD, SRVR_ID, DBSE_ID, [Status], ServerDBRelationship_ID) 
values ('BAKX', 132, 73, 'A', 1099 )
GO
