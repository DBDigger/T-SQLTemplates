USE [msdb]
GO
SELECT j.job_id, s.srvname,  j.name, js.step_id, js.command, j.enabled
FROM dbo.sysjobs j JOIN dbo.sysjobsteps js  ON js.job_id = j.job_id
JOIN master.dbo.sysservers s  ON s.srvid = j.originating_server_id
WHERE js.command LIKE N'%bilal%'


SELECT   name,  TYPE_desc
FROM sys.sql_modules m WITH (NOLOCK)
INNER JOIN sys.objects o WITH (NOLOCK)   ON m.object_id = o.object_id
WHERE definition LIKE '%bilal.ahmed%'

SELECT object_name(object_id), definition
FROM sys.sql_modules with (nolock)
WHERE DEFINITION LIKE '%seed%'


--will return any procs that use the same (this one takes a bit to run so maybe compile the list, server by server) :
exec sp_msforeachdb 
'select ''?'', p.name
from ?.sys.procedures p with (nolock)
  inner join ?.sys.sql_modules m with (nolock)
    on m.object_id = p.object_id
where m.definition like ''%@asinetwork.local%'''
