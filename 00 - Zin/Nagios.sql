-- Failed jobs
SELECT   
Job.instance_id         ,SysJobs.job_id        ,SysJobs.name as 'JOB_NAME'        ,SysJobSteps.step_name as 'STEP_NAME'
        ,Job.run_status        ,Job.sql_message_id        ,Job.sql_severity        ,Job.message        ,Job.exec_date
        ,Job.run_duration        ,Job.server        ,SysJobSteps.output_file_name 
    FROM    (SELECT Instance.instance_id         ,DBSysJobHistory.job_id        ,DBSysJobHistory.step_id
        ,DBSysJobHistory.sql_message_id        ,DBSysJobHistory.sql_severity        ,DBSysJobHistory.message
        ,(CASE DBSysJobHistory.run_status            WHEN 0 THEN 'Failed'             WHEN 1 THEN 'Succeeded'
            WHEN 2 THEN 'Retry'            WHEN 3 THEN 'Canceled'
            WHEN 4 THEN 'In progress'        END) as run_status
        ,((SUBSTRING(CAST(DBSysJobHistory.run_date AS VARCHAR(8)), 5, 2) + '/'
        + SUBSTRING(CAST(DBSysJobHistory.run_date AS VARCHAR(8)), 7, 2) + '/'
        + SUBSTRING(CAST(DBSysJobHistory.run_date AS VARCHAR(8)), 1, 4) + ' '
        + SUBSTRING((REPLICATE('0',6-LEN(CAST(DBSysJobHistory.run_time AS varchar)))
        + CAST(DBSysJobHistory.run_time AS VARCHAR)), 1, 2) + ':'
        + SUBSTRING((REPLICATE('0',6-LEN(CAST(DBSysJobHistory.run_time AS VARCHAR)))
        + CAST(DBSysJobHistory.run_time AS VARCHAR)), 3, 2) + ':'
        + SUBSTRING((REPLICATE('0',6-LEN(CAST(DBSysJobHistory.run_time as varchar)))
        + CAST(DBSysJobHistory.run_time AS VARCHAR)), 5, 2))) AS 'exec_date'
        ,DBSysJobHistory.run_duration
        ,DBSysJobHistory.retries_attempted
        ,DBSysJobHistory.server
        FROM msdb.dbo.sysjobhistory DBSysJobHistory
        JOIN (SELECT DBSysJobHistory.job_id
            ,DBSysJobHistory.step_id
            ,MAX(DBSysJobHistory.instance_id) as instance_id
            FROM msdb.dbo.sysjobhistory DBSysJobHistory
            GROUP BY DBSysJobHistory.job_id
            ,DBSysJobHistory.step_id
            ) AS Instance ON DBSysJobHistory.instance_id = Instance.instance_id
        WHERE DBSysJobHistory.run_status <> 1
        ) AS Job
    JOIN msdb.dbo.sysjobs SysJobs
       ON (Job.job_id = SysJobs.job_id)
    JOIN msdb.dbo.sysjobsteps SysJobSteps
       ON (Job.job_id = SysJobSteps.job_id AND Job.step_id = SysJobSteps.step_id)
       where sysjobs.enabled  = 1
    GO

-- Failed authentication
select count(*) as FailedActivations
from simcards s with(NolocK)
join cntproditems cpi with(Nolock) on cpi.simcardid_fk=s.simcardid
join ORGANIZATION o with(Nolock) on o.ORGID=cpi.COMPANYID
join CONTRACTPRODUCTS cp with(Nolock) on cp.contractproductid=cpi.contractproductid_Fk
join priceplansummary p with(nolock) on p.productpriceplanid_Fk=cp.productpriceplanid_fk
join SIMSTATUSES_LANG sl with(Nolock) on sl.SIMSTATUSID_FK=s.SIMSTATUSID_FK
where s.simstatusid_Fk in (4,9)
and sl.LANGUAGEID_FK=1
and s.operatorid_Fk=11
and datediff(hour,cpi.activationdate,getutcdate())< = 24 
and o.PARENTORGID_FK<>5015
and not exists (select 1 from ipaddresses i with(Nolock) where i.NETWORKCONNECTIONID_FK=cpi.productitemid_FK)

--HourSinceLastRecord_ChargingIII
select datediff(hour, max(created),getUTCdate()) as HourSinceLastRecord_ChargingIII from wmpoperatorusage..ACCOUNTING_RADIUS_CHARGING_III
