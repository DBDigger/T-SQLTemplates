SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetJobIdFromProgramName] (
	@program_name nvarchar(128)
)
RETURNS uniqueidentifier
AS
BEGIN
DECLARE @start_of_job_id int
SET @start_of_job_id = CHARINDEX('(Job 0x', @program_name) + 7
RETURN CASE WHEN @start_of_job_id > 0 THEN CAST(
		SUBSTRING(@program_name, @start_of_job_id + 06, 2) + SUBSTRING(@program_name, @start_of_job_id + 04, 2) + 
		SUBSTRING(@program_name, @start_of_job_id + 02, 2) + SUBSTRING(@program_name, @start_of_job_id + 00, 2) + '-' +
		SUBSTRING(@program_name, @start_of_job_id + 10, 2) + SUBSTRING(@program_name, @start_of_job_id + 08, 2) + '-' +
		SUBSTRING(@program_name, @start_of_job_id + 14, 2) + SUBSTRING(@program_name, @start_of_job_id + 12, 2) + '-' +
		SUBSTRING(@program_name, @start_of_job_id + 16, 4) + '-' +
		SUBSTRING(@program_name, @start_of_job_id + 20,12) AS uniqueidentifier)
	ELSE NULL
	END
END --FUNCTION

-- SELECT *
FROM msdb.dbo.sysjobs
WHERE
job_id = dbo.GetJobIdFromProgramName ('SQLAgent - TSQL JobStep (Job 0x9565DD5048FEA8459350965872DCCBD2 : Step 1)')