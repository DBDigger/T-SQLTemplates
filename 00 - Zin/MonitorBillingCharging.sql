------------------------------------------------------------------------------------------------------------------------------------

-- Get date up to charging is done
select MAX(chargedon) as UpToDate,MAX(ACCOUNTINGID_FK) as LastID from ACCOUNTING_Radius_CHARGING_Ii with (nolock) where ISCHARGED = 1


-- Radius Counters
select  * from TABLECOUNTERS with (nolock)

-- Min ID on radius 8471974331
-- Counter Value on Porthos 8743876770



select min(rlid ) from RADIUSLOGS with (nolock) where created < '2015-11-11' 


-- Get partitions of radiuslogs on 172.17.1.201
SELECT p.partition_number AS [p#], p.rows, rv.value	
FROM sys.partitions p with (nolock)
INNER JOIN sys.indexes i with (nolock) ON p.object_id = i.object_id
	AND p.index_id = i.index_id
INNER JOIN sys.objects o  with (nolock) ON p.object_id = o.object_id
INNER JOIN sys.partition_schemes ps with (nolock) ON ps.data_space_id = i.data_space_id
INNER JOIN sys.partition_functions f with (nolock) ON f.function_id = ps.function_id
LEFT OUTER JOIN sys.partition_range_values rv with (nolock) ON f.function_id = rv.function_id
	AND p.partition_number = rv.boundary_id
WHERE i.index_id < 2
	AND o.object_id = OBJECT_ID('radiuslogs')
order by p#
--------------------------------------------------------------------------------------------------------------

select 
(select created from accounting_radius_charging with (nolock) where accountingid_fk in (select max(accountingid_fk) from accounting_radius_charging with (nolock) where ischarged = 1 )) AS ChargingOn,
(select created from accounting_radius_charging_I with (nolock) where accountingid_fk in (select max(accountingid_fk) from accounting_radius_charging_I with (nolock) where ischarged = 1 )) AS ChargingOnI,
(select created from accounting_radius_charging_II with (nolock) where accountingid_fk in (select max(accountingid_fk) from accounting_radius_charging_II with (nolock) where ischarged = 1 )) AS ChargingOnII,
(select created from accounting_radius_charging_III with (nolock) where accountingid_fk in (select max(accountingid_fk) from accounting_radius_charging_III with (nolock) where ischarged = 1 )) AS ChargingOnIII,
(select created from accounting_radius_charging_IV with (nolock) where accountingid_fk in (select max(accountingid_fk) from accounting_radius_charging_IV with (nolock) where ischarged = 1 )) AS ChargingOnIV,
(select created from accounting_radius_charging_V with (nolock) where accountingid_fk in (select max(accountingid_fk) from accounting_radius_charging_V with (nolock) where ischarged = 1 )) AS ChargingOnV,
(select created from accounting_radius_charging_VI with (nolock) where accountingid_fk in (select max(accountingid_fk) from accounting_radius_charging_VI with (nolock) where ischarged = 1 )) AS ChargingOnVI
go


select 
(select created from accounting_radius with (nolock) where accountingid in (select max(accountingid_fk) from accounting_radius_charging with (nolock) where ischarged = 1 )) AS ARCharging,
(select created from accounting_radius with (nolock) where accountingid in (select max(accountingid_fk) from accounting_radius_charging_I with (nolock) where ischarged = 1 )) AS ARCharging_I,
(select created from accounting_radius with (nolock) where accountingid in (select max(accountingid_fk) from accounting_radius_charging_II with (nolock) where ischarged = 1 )) AS ARCharging_II,
(select created from accounting_radius with (nolock) where accountingid in (select max(accountingid_fk) from accounting_radius_charging_III with (nolock) where ischarged = 1 )) AS ARCharging_III,
(select created from accounting_radius with (nolock) where accountingid in (select max(accountingid_fk) from accounting_radius_charging_IV with (nolock) where ischarged = 1 )) AS ARCharging_IV,
(select created from accounting_radius with (nolock) where accountingid in (select max(accountingid_fk) from accounting_radius_charging_V with (nolock) where ischarged = 1 )) AS ARCharging_V,
(select created from accounting_radius with (nolock) where accountingid in (select max(accountingid_fk) from accounting_radius_charging_VI with (nolock) where ischarged = 1 )) AS ARCharging_VI
GO
-- 

select 
(select count(*) from ACCOUNTING_RADIUS_CHARGING  with (nolock) where ischarged = 0) as IsChargedZeroCount,
(select count(*) from ACCOUNTING_RADIUS_CHARGING_I  with (nolock) where ischarged = 0) as IsChargedZeroCount_I, 
(select count(*) from ACCOUNTING_RADIUS_CHARGING_II  with (nolock) where ischarged = 0) as IsChargedZeroCount_II, 
(select count(*) from ACCOUNTING_RADIUS_CHARGING_Iii with (nolock) where ischarged = 0) as IsChargedZeroCount_III,
(select count(*) from ACCOUNTING_RADIUS_CHARGING_iv  with (nolock) where ischarged = 0) as IsChargedZeroCount_IV,
(select count(*) from ACCOUNTING_RADIUS_CHARGING_v  with (nolock) where ischarged = 0) as IsChargedZeroCount_V,
(select count(*) from ACCOUNTING_RADIUS_CHARGING_vI  with (nolock) where ischarged = 0) as IsChargedZeroCount_VI
GO
-- 4850287	7574333	285	3998086	302	168755305	1082114
-- 4077116	7157600	237	3522819	0	169751876	1081347
-- 3623789	6887101	1	3270030	0	169645490	1081347


select 
(select count(*) from ACCOUNTING_RADIUS_CHARGING  with (nolock) where ischarged = 1) as IsChargedOneCount,
(select count(*) from ACCOUNTING_RADIUS_CHARGING_I  with (nolock) where ischarged = 1) as IsChargedOneCount_I, 
(select count(*) from ACCOUNTING_RADIUS_CHARGING_II  with (nolock) where ischarged = 1) as IsChargedOneCount_II, 
(select count(*) from ACCOUNTING_RADIUS_CHARGING_Iii with (nolock) where ischarged = 1) as IsChargedOneCount_III,
(select count(*) from ACCOUNTING_RADIUS_CHARGING_iv  with (nolock) where ischarged = 1) as IsChargedOneCount_IV,
(select count(*) from ACCOUNTING_RADIUS_CHARGING_v  with (nolock) where ischarged = 1) as IsChargedOneCount_V,
(select count(*) from ACCOUNTING_RADIUS_CHARGING_vI  with (nolock) where ischarged = 1) as IsChargedZeroCount_VI
GO

-- 32425203	51709388	14357040	61795819	7838545	31851594	16493184
-- 32711923	51919388	14388632	61995769	7877167	31851594	16514020
-- 32826527	52039388	14392076	62075749	7882444	31951594	16519427
-- 33361278	52459388	14410664	62435659	7904323	32651594	16542189

[RPT_RadiusHeartBeatSynchronization]
--17935491	4727	3511332		22695684	5184	
--17324692	1727	30254		19845216	2045
--17008615	174		11543		18589956	1264		
[RPT_RadiusHeartBeatBilling]



----------------------------------------------------------------------------------------------------------------
select top   10 * from ACCOUNTING_OPERATORS

select top  10 * from ACCOUNTING_OPERATORS_CHARGING

select top 10 * from ORGFTPSUBSCRIPTIONS


select top 10 * from usagefiles

select distinct OPERATORID, OPERATORNAME  from usagefiles u inner join OPERATORS o on u.OPERATORID_FK  = o.OPERATORID


select top 100 * from USAGEFILES where OPERATORID_FK = 36 order by CREATED desc

select COUNT(*) from C2C_GPRS_DR where UsageFileID_FK  = 1694619
select top 10 * from TMUK order by 1 desc
select * from sys.objects where name like '%TM%' and type  = 'U'  order by name