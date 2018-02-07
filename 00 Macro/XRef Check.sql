---ASI-SQLPCN1-14
----to check if there is cros ref status 

--1. See which Xref already added to HUB to be processed
use memberdemogr_hub 
go
exec dbo.spXREF_GetNewXRefInfo
      @ResultType = 'COLUMN'

exec dbo.spXREF_GetNewXRefInfo
      @ResultType = 'COMPANY'
-----------------

declare @CrossRefsType_CD char(4)
		,@Expired_DT_Override datetime = null 
		,@Comment varchar(200) = null 
		,@XRefID int 
		,@OLD_Company_ID int
		,@New_Company_ID int
		,@OLD_MasterCustomer_ID varchar(10)
		,@NEW_MasterCustomer_ID varchar(10)

------------
	
----
set @XRefID =1882	
set @OLD_MasterCustomer_ID = 35210
set @NEW_MasterCustomer_ID = 69240



--HUB
SELECT 'MemberDemogr_HUB.[dbo].[CUST_Company]'
select *
  FROM MemberDemogr_HUB.[dbo].[CUST_Company]
  where ASINum_MasterCustomer_ID in (@OLD_MasterCustomer_ID, @NEW_MasterCustomer_ID)
-----------------------------
									

SELECT @OLD_Company_ID = Company_ID  FROM MemberDemogr_HUB.[dbo].[CUST_Company] where ASINum_MasterCustomer_ID = @OLD_MasterCustomer_ID
SELECT @New_Company_ID = Company_ID  FROM MemberDemogr_HUB.[dbo].[CUST_Company] where ASINum_MasterCustomer_ID = @NEW_MasterCustomer_ID


--2. Check the companies requested in the XRef email request in the Personify source
select 'old companies. MemberDemogr_LOAD.dbo.LOAD_CompanyBranch'
select *
from 
	MemberDemogr_LOAD.dbo.LOAD_CompanyBranch
where 
	Company_ID = @OLD_Company_ID
-------------------
select 'new companies.MemberDemogr_LOAD.dbo.LOAD_CompanyBranch'
select *
from 
	MemberDemogr_LOAD.dbo.LOAD_CompanyBranch
where 
	Company_ID = @New_Company_ID
-------------
select 'MemberDemogr_HUB.dbo.CUST_Crossrefs'
select *
from 
	MemberDemogr_HUB.dbo.CUST_Crossrefs
where 
	Crossrefs_ID = @XRefID
	and OLD_Company_ID = @OLD_Company_ID
	and NEW_Company_ID = @New_Company_ID

-----------------------------------



select 'MemberDemogr_HUB.dbo.CUST_TEMPCrossrefsAlias'
select *
from 
	MemberDemogr_HUB.dbo.CUST_TEMPCrossrefsAlias
where 
	TEMPCrossrefsAlias_ID = @XRefID
	and OLD_Company_ID = @OLD_Company_ID
	and NEW_Company_ID = @New_Company_ID

-----------------------------------

