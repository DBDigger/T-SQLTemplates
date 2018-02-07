-- Get currently running processes
USE MASTER 
GO 
SELECT SPID,ER.percent_complete, 
    CAST(((DATEDIFF(s,start_time,GetDate()))/3600) as varchar) + ' hour(s), ' 
        + CAST((DATEDIFF(s,start_time,GetDate())%3600)/60 as varchar) + 'min, ' 
        + CAST((DATEDIFF(s,start_time,GetDate())%60) as varchar) + ' sec' as running_time, 
    CAST((estimated_completion_time/3600000) as varchar) + ' hour(s), ' 
        + CAST((estimated_completion_time %3600000)/60000 as varchar) + 'min, ' 
        + CAST((estimated_completion_time %60000)/1000 as varchar) + ' sec' as est_time_to_go, 
    DATEADD(second,estimated_completion_time/1000, getdate()) as est_completion_time, 
/* End of Article Code */     
ER.command,ER.blocking_session_id, LASTWAITTYPE,  
DB_NAME(SP.DBID) AS DBNAME, 
SUBSTRING(est.text, (ER.statement_start_offset/2)+1,  
        ((CASE ER.statement_end_offset 
         WHEN -1 THEN DATALENGTH(est.text) 
         ELSE ER.statement_end_offset 
         END - ER.statement_start_offset)/2) + 1) AS QueryText, 
TEXT,CPU,HOSTNAME,LOGIN_TIME,LOGINAME, 
SP.status,PROGRAM_NAME,NT_DOMAIN, NT_USERNAME 
FROM SYSPROCESSES SP  
INNER JOIN sys.dm_exec_requests ER 
ON sp.spid = ER.session_id 
CROSS APPLY SYS.DM_EXEC_SQL_TEXT(er.sql_handle) EST 
ORDER BY CPU DESC 


--************************************************************************************************************
-- get database wise processes
--************************************************************************************************************
-- Databases Processes Overview 
;WITH pro AS 
   (SELECT PRO.dbid  
          ,COUNT(*) AS Processes 
          ,SUM(PRO.cpu) AS Cpu 
          ,SUM(PRO.physical_io) AS PhysicalIo 
          ,SUM(PRO.memusage) AS MemUsage 
          ,MAX(PRO.last_batch) AS LastBatch 
          ,SUM(PRO.open_tran) AS OpenTran 
          ,COUNT(DISTINCT PRO.sid) AS Users 
          ,COUNT(DISTINCT PRO.hostname) AS Host 
    FROM sys.sysprocesses AS PRO 
    GROUP BY PRO.dbid) 
SELECT DB.name AS DatabaseName 
      ,pro.* 
      ,DB.log_reuse_wait_desc AS LogReUse 
FROM sys.databases AS DB 
     LEFT JOIN pro 
         ON DB.database_id = pro.dbid 
ORDER BY DB.name; 

--************************************************************************************************************
-- get current IO and CPU workload
--************************************************************************************************************
-- Current IO and CPU Workload 
SET NOCOUNT ON; 
 
-- Clean up temp table, if still exists. 
IF NOT OBJECT_ID('tempdb..#processes') IS NULL 
    DROP TABLE #processes; 
GO 
 
-- Create snapshot of current processes in a temp table 
SELECT PRC.spid 
      ,PRC.login_time 
      ,PRC.ecid 
      ,PRC.[sid] 
      ,PRC.cpu 
      ,PRC.physical_io 
INTO #processes 
FROM sys.sysprocesses AS PRC 
WHERE PRC.spid <> @@SPID; -- Exclude own process 
GO 
 
-- Wait a few seconds before comparing snapshot 
-- with current processes 
WAITFOR DELAY '00:00:02';  -- 2 seconds 
GO 
 
-- Get total difference to calculate percentage values. 
DECLARE @cpuDiff int, @ioDiff int; 
SELECT @cpuDiff = SUM(ACT.cpu - SNP.cpu) 
      ,@ioDiff = SUM(ACT.physical_io - SNP.physical_io) 
FROM sys.sysprocesses AS ACT 
     INNER JOIN #processes AS SNP 
         ON ACT.spid = SNP.spid 
            AND ACT.[sid] = SNP.[sid] 
 WHERE ACT.spid <> @@SPID -- Exclude own process 
      AND SNP.ecid <= 1      
 
-- Join snapshot and current process to get delta values. 
SELECT ACT.cpu - SNP.cpu AS CpuDiff 
      ,ACT.physical_io - SNP.physical_io AS IoDiff 
      ,CASE WHEN @cpuDiff = 0.0 THEN 0.0 
            ELSE CONVERT(decimal(10, 2), 100.0 * (ACT.cpu - SNP.cpu) / @cpuDiff) 
            END AS [Cpu %] 
      ,CASE WHEN @ioDiff = 0 THEN 0.0 
            ELSE CONVERT(decimal(10, 2), 100.0 * (ACT.physical_io - SNP.physical_io) / @ioDiff) 
            END AS [IO %] 
      ,ACT.spid AS Spid 
      ,ACT.waitresource AS WaitResource 
      ,DB.name AS DataBaseName 
      ,ACT.hostname AS HostName 
      ,ACT.[program_name] AS ProgramName 
      ,ACT.loginame AS LoginName 
      ,ACT.cmd AS Command 
      ,EST.[text] AS SQLStatement 
FROM sys.sysprocesses AS ACT 
     INNER JOIN #processes AS SNP 
         ON ACT.spid = SNP.spid 
            AND ACT.[sid] = SNP.[sid] 
            AND ACT.login_time = SNP.login_time 
     LEFT JOIN sys.databases AS DB 
         ON ACT.dbid = DB.database_id 
     CROSS APPLY sys.dm_exec_sql_text(ACT.sql_handle) AS EST 
WHERE ACT.spid <> @@SPID -- Exclude own process 
      AND SNP.ecid <= 1 
      AND ((ACT.cpu - SNP.cpu) > 0 
           OR 
           (ACT.physical_io - SNP.physical_io) > 0 
          ) 
ORDER BY ACT.cpu - SNP.cpu 
       + ACT.physical_io - SNP.physical_io DESC; 
GO 
 
-- Clean up temp table 
DROP TABLE #processes; 
GO 