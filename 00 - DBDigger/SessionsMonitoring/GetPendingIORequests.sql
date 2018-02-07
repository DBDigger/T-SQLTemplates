-- Pending IO Requests 
;WITH  
 pir AS 
    (SELECT PIR.scheduler_address 
           ,COUNT(*) AS PendIoRequests 
           ,SUM(PIR.io_pending_ms_ticks) AS PendWaitTime 
     FROM sys.dm_io_pending_io_requests AS PIR 
     GROUP BY PIR.scheduler_address 
     ) 
,req AS 
     (SELECT ER.task_address 
            ,COUNT(*) AS ReqCnt 
            ,COUNT(DISTINCT ER.database_id) AS ReqDbCnt 
            ,SUM(ER.wait_time) AS ReqWaitTime 
      FROM sys.dm_exec_requests AS ER 
      GROUP BY ER.task_address 
     ) 
SELECT OS.scheduler_id AS Scheduler 
      ,OS.cpu_id AS CpuId 
      ,CASE WHEN OS.scheduler_id < 1048576 
            THEN 'Query' 
            ELSE 'Internal' END AS Scheduler 
      ,OS.[status] AS OsStatus 
      ,OS.current_workers_count AS CurrWrk 
      ,OS.active_workers_count AS ActWrk 
      ,OS.pending_disk_io_count AS pDiskIo 
      ,OW.pending_io_count AS pIoCount 
      ,OW.pending_io_byte_count AS pIoBytes 
      ,OW.[state] AS WorkerState 
      ,req.ReqDbCnt 
      ,req.ReqCnt 
      ,req.ReqWaitTime 
      ,pir.PendIoRequests 
      ,pir.PendWaitTime 
FROM sys.dm_os_schedulers AS OS 
     INNER JOIN sys.dm_os_workers AS OW 
         ON OS.active_worker_address = OW.worker_address     
     -- Change it to INNER join to get only pending schedulers 
     LEFT JOIN pir 
         ON pir.scheduler_address = OS.scheduler_address 
     LEFT JOIN req 
         ON req.task_address = OW.task_address 
ORDER BY OS.scheduler_id;