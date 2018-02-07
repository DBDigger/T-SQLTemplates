SELECT count(*)
  FROM [msdb].[dbo].[sysalerts]
  where enabled = 1
  and name in (
'1205 - Deadlock Detected',
'17890 - Large memory paged out',
'3619 - Log is out of space',
'5145 - File Autogrow',
'5182 - New log file',
'601 - Data Movement',
'708 - Low virtual address space',
'833 - IO Requests taking longer',
'CPUAlert',
'Error Number 823',
'Error Number 824',
'Error Number 825',
'LongRunning',
'Page RestorePending (829) detected',
'Severity 016',
'Severity 017',
'Severity 018',
'Severity 019',
'Severity 020',
'Severity 021',
'Severity 022',
'Severity 023',
'Severity 024'
  )