-- ASI-SQLPCN1-10
 --Error inproc spLOAD_PublishBatch User Msg: There is batch currently being processed. Cannot process more then one batch at the time;

 declare @Batch_ID bigint;

select @Batch_ID = Batch_ID 
from PROD_Master.dbo.PBSH_Batch 
where ProcessStatus_CD = 'BP';

update PROD_Master.dbo.PBSH_Batch
set ProcessStatus_CD = 'SC'
where Batch_ID = @Batch_ID;


-- ASI-SQLPCN1-11
-- Error Description: "Cannot insert duplicate key row in object 'dbo.LOAD_Price_PRCE' with unique index 'I_IC_LOAD_Price_PRCE_10'. The duplicate key value is (104088693, 1).

SELECT  [FPRC_PMAS_Id],  [FPRC_SequenceId],count(*)
FROM [dbo].[ASID_PDCT_FinalPrice_FPRC]
group by [FPRC_PMAS_Id]
,[FPRC_SequenceId]
having count(*) > 1



;with Dups
AS
(
SELECT 
[FPRC_PMAS_Id],
[FPRC_SequenceId],
count(*) as DupCount
FROM 
[dbo].[ASID_PDCT_FinalPrice_FPRC]
group by 
[FPRC_PMAS_Id],
[FPRC_SequenceId]
having 
count(*) > 1 
)
SELECT 
a.[FPRC_PMAS_Id],
a.[FPRC_SequenceId],
a.*
FROM 
[dbo].[ASID_PDCT_FinalPrice_FPRC] a
inner join Dups d
on d.FPRC_PMAS_Id = a.FPRC_PMAS_Id and d.FPRC_SequenceId = a.FPRC_SequenceId
order by 1,2  
--Backup data
;with Dups
AS
(
SELECT 
[FPRC_PMAS_Id],
[FPRC_SequenceId],
count(*) as DupCount
FROM 
[dbo].[ASID_PDCT_FinalPrice_FPRC]
group by 
[FPRC_PMAS_Id],
[FPRC_SequenceId]
having 
count(*) > 1 
)
SELECT 
a.*
INTO ASIWork.dbo.ASID_PDCT_FinalPrice_FPRC_bkp_dup_recs_20180105
FROM 
[dbo].[ASID_PDCT_FinalPrice_FPRC] a
inner join Dups d
on d.FPRC_PMAS_Id = a.FPRC_PMAS_Id and d.FPRC_SequenceId = a.FPRC_SequenceId
order by 1,2 

select * from ASIWork.dbo.ASID_PDCT_FinalPrice_FPRC_bkp_dup_recs_20180105
