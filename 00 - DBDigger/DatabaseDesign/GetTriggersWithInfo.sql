-- Trigger Overview 
SELECT SCH.name + '.' + PAR.name AS ParentName 
      ,TRG.name AS TriggerName 
      ,TRG.type_desc AS TriggerType 
      ,TEV.type_desc AS EventType 
      ,TRG.is_instead_of_trigger AS InsteadOf 
      ,TEV.is_first AS IsFirst 
      ,TEV.is_last AS IsLast 
      ,TRG.is_disabled AS IsDisabled 
      ,TRG.is_not_for_replication AS IsNotForRepl 
      ,ISNULL(AM.assembly_class + '.' + AM.assembly_method, '') 
       AS ClrClassMethod 
FROM sys.triggers AS TRG 
     INNER JOIN sys.trigger_events AS TEV 
         ON TRG.object_id = TEV.object_id 
     INNER JOIN sys.objects AS PAR 
         ON TRG.parent_id = PAR.object_id 
     INNER JOIN sys.schemas AS SCH 
         ON PAR.schema_id = SCH.schema_id 
     LEFT JOIN sys.assembly_modules AS AM 
         ON TRG.object_id = AM.object_id 
ORDER BY PAR.[name] 
        ,TEV.[type] 
        ,TEV.is_first DESC 
        ,TEV.is_last  ASC 
        ,TRG.name;