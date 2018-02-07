
use MemberDemogr_HUB
go

/** check records in CUST_TEMPCrossrefsAlias **/

/**
	select * from dbo.CUST_TEMPCrossrefsAlias
	where tempcrossrefsalias_id in (1846)
**/


declare @CrossRefsType_CD char(4)
		,@Expired_DT_Override datetime = null 
		,@Comment varchar(200) = null 
		,@XRefID int 
		,@OLD_Company_ID int
		,@New_Company_ID int
		,@$$CreateUserName varchar(128) 			-- last user changed the data 
        ,@$$CreateMachineName varchar(128) 		-- last machine changes-procedure were run from

  set @$$CreateUserName = suser_sname()
  set @$$CreateMachineName = host_name()

/** change with new info **/

   --set @XRefID =1877										
   --set @OLD_Company_ID =3760 --ASI (94770)
   --set @New_Company_ID =3090 --ASI (83770)
   set @XRefID =1882										
   set @OLD_Company_ID =303 --ASI (92768)
   set @New_Company_ID =2351 --ASI (93010)

   set @CrossRefsType_CD = 'MRGE' --'NMCG'

   
INSERT INTO dbo.CUST_Crossrefs
		(Crossrefs_ID
		,CrossRefsType_CD
		,OLD_Company_ID
		,OLD_CompanyBranch_ID
		,OLD_ASINum_MasterCustomer_ID
		,OLD_Company_NM
		,OLD_TimssCompany_nm
		,NEW_Company_ID
		,NEW_CompanyBranch_ID
		,NEW_ASINum_MasterCustomer_ID
		,NEW_Company_NM
		,Effective_DT
		,Expired_DT
		,Internal_Comment
		,CreateDate
		,UpdateDate
		,UpdateSource
		,oldstatusid
		,oldmemberstatuscd
		,oldmembertypecd
		,newstatusid
		,newmemberstatuscd
		,newmembertypecd
		)
	select t.TEMPCrossrefsAlias_ID
		,@CrossRefsType_CD as CrossRefsType_CD
		,case when @CrossRefsType_CD = 'NMCG' then t.NEW_Company_ID else @OLD_Company_ID end as OLD_Company_ID
		,case when @CrossRefsType_CD = 'NMCG' then t.NEW_Company_ID else @OLD_Company_ID end as OLD_CompanyBranch_ID
		,t.OLD_MasterCustomer_ID as OLD_ASINum_MasterCustomer_ID
		,t.OLD_Company_NM 
		,t.OLD_Company_NM as OLD_TimssCompany_nm
		,t.NEW_Company_ID
		,t.NEW_Company_ID as NEW_CompanyBranch_ID
		,t.NEW_MasterCustomer_ID as NEW_ASINum_MasterCustomer_ID
		,t.NEW_Company_NM
		,t.Effective_DT
		,case when @Expired_DT_Override is null then t.Expired_DT else @Expired_DT_Override end as Expired_DT
		,left(coalesce(nullif(t.Internal_Comment,'') + '|' + nullif(@Comment,''), nullif(@Comment,''), nullif(t.Internal_Comment,'')),200) as Internal_Comment
		,t.CreateDate
		,getdate() as UpdateDate
		,@$$CreateUserName + ' - ' + @$$CreateMachineName as UpdateSource
		,case co.MemberStatus_CD 
			when 'CREF' then 108 
			when 'DELS' then 103
			when 'TRMN' then 109
			else 999 
		--,case co.MemberStatus_CD 
		--when 'CREF' then 108 
		--when 'DELS' then 103
		--when 'TRMN' then 109
		--else 108 
		end as OLDStatusID
		,co.MemberStatus_CD as OLD_MemberStatus_CD
		--,'CREF' as OLD_MemberStatus_CD
		--,co.MemberType_CD as OLD_MemberType_CD
		,case  isnull(co.MemberType_CD,'UNKN')
			when 'UNKN' then cn.MemberType_CD
			else co.MemberType_CD
		 end as OLD_MemberType_CD
		,case cn.MemberStatus_CD 
			when 'ACTV' then 100 
			else 999
		--,case cn.MemberStatus_CD 
		--	when 'ACTV' then 100 
		--	else 100
		end as NEWStatusID
		,cn.MemberStatus_CD as NEW_MemberStatus_CD
		--,'ACTV' as NEW_MemberStatus_CD
		,cn.MemberType_CD as NEW_MemberType_CD
		--,'DIST' as NEW_MemberType_CD
	from dbo.CUST_TEMPCrossrefsAlias t 
		left join dbo.CUST_Company cn
		 on t.NEW_Company_ID = cn.Company_ID
		left join dbo.CUST_Company co
		 on t.OLD_Company_ID = co.Company_ID
		 left join dbo.CUST_Crossrefs cc on t.TEMPCrossrefsAlias_ID=cc.Crossrefs_ID
	where --cc.Crossrefs_ID is null and
	  t.TEMPCrossrefsAlias_ID = @XRefID
	 and t.OLD_Company_ID = @OLD_Company_ID
	 and t.NEW_Company_ID = @New_Company_ID
 