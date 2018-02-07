DECLARE @DisableStatement VARCHAR(150)
DECLARE @EnableStatement VARCHAR(150)
DECLARE @StopStatement VARCHAR(150)
DECLARE @JobEnable TABLE
(
  EnableStatement varchar(400)
) 

DECLARE JobStatusChangeCursor CURSOR
FOR
SELECT	'exec msdb.dbo.sp_update_job     @job_name = N''' + NAME + ''', @enabled = 0', 
		'exec msdb.dbo.sp_update_job     @job_name = N''' + NAME + ''', @enabled = 1',
		'exec msdb.dbo.sp_stop_job @job_name = '''+NAME+''''
FROM MSDB.dbo.sysjobs
WHERE enabled = 1
	AND category_id not between 1 and 20 

-- Open cursor
OPEN JobStatusChangeCursor

-- Fetch record from cursor
FETCH NEXT FROM JobStatusChangeCursor INTO @DisableStatement, @enableStatement, @StopStatement

-- Configure while loop in cursor
WHILE (@@FETCH_STATUS <> - 1)
BEGIN
	-- Execute Dynamical SQL
	EXECUTE (@disableStatement)
	EXECUTE (@StopStatement)

	
	insert into @JobEnable values (@EnableStatement)

	-- Fetch next recod
FETCH NEXT FROM JobStatusChangeCursor INTO @DisableStatement, @enableStatement, @StopStatement
END

-- Close and deallocate the cursor
CLOSE JobStatusChangeCursor

DEALLOCATE JobStatusChangeCursor

select * from @JobEnable
