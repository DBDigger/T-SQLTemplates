SELECT 
    [sJOB].[name] AS [JobName]
    , [sJSTP].subsystem
    , [sJSTP].[step_id] AS [JobStartStepNo]
    , [sJSTP].[step_name] AS [JobStartStepName]
    
   
FROM
    [msdb].[dbo].[sysjobs] AS [sJOB]
    LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sJSTP]
        ON [sJOB].[job_id] = [sJSTP].[job_id]
        
   
ORDER BY 2



-- SELECT 
    [sJOB].[name] AS [JobName]
    , [sJSTP].[step_id] AS [JobStartStepNo]
    , [sJSTP].[step_name] AS [JobStartStepName]
    
   
FROM
    [msdb].[dbo].[sysjobs] AS [sJOB]
    LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sJSTP]
        ON [sJOB].[job_id] = [sJSTP].[job_id]
     
   
ORDER BY 1, 2