/*------------------------------------------------------------------
Get Total size of disk,Free disk space.
It also enables and disables the use of CMD
-------------------------------------------------------------------*/
if ((SELECT  value FROM    sys.configurations where name = 'Ole Automation Procedures')= 0)
begin
EXEC sp_configure 'show advanced options', 1
RECONFIGURE
EXEC sp_configure 'Ole Automation Procedures', 1
RECONFIGURE
end

IF NOT EXISTS (SELECT name FROM tempdb..sysobjects WHERE name = '##_DriveSpace')
CREATE TABLE ##_DriveSpace (DriveLetter CHAR(1) NOT NULL, FreeSpace VARCHAR(10) NOT NULL)

IF NOT EXISTS (SELECT name FROM tempdb..sysobjects WHERE name = '##_DriveInfo')
CREATE TABLE ##_DriveInfo (DriveLetter CHAR(1), TotalSpace BIGINT, FreeSpace BIGINT)


DECLARE 
@Result INT, @objFSO INT, @Drv INT, @cDrive VARCHAR(13), 
@Size VARCHAR(50), @Free VARCHAR(50)

INSERT INTO ##_DriveSpace EXEC master.dbo.xp_fixeddrives


-- Iterate through drive letters.
DECLARE curDriveLetters CURSOR FOR SELECT driveletter FROM ##_DriveSpace

DECLARE @DriveLetter char(1) OPEN curDriveLetters

FETCH NEXT FROM curDriveLetters INTO @DriveLetter

WHILE (@@fetch_status <> - 1)
BEGIN
	IF (@@fetch_status <> - 2)
	BEGIN
		SET @cDrive = 'GetDrive("' + @DriveLetter + '")'

		EXEC @Result = sp_OACreate 'Scripting.FileSystemObject', @objFSO OUTPUT

		IF @Result = 0
			EXEC @Result = sp_OAMethod @objFSO, @cDrive, @Drv OUTPUT

		IF @Result = 0
			EXEC @Result = sp_OAGetProperty @Drv, 'TotalSize', @Size OUTPUT

		IF @Result = 0
			EXEC @Result = sp_OAGetProperty @Drv, 'FreeSpace', @Free OUTPUT

		IF @Result <> 0
			EXEC sp_OADestroy @Drv

		EXEC sp_OADestroy @objFSO

		SET @Size = (CONVERT(BIGINT, @Size) / 1048576)
		SET @Free = (CONVERT(BIGINT, @Free) / 1048576)

		INSERT INTO ##_DriveInfo
		VALUES (@DriveLetter, @Size, @Free)
	END

	FETCH NEXT
	FROM curDriveLetters
	INTO @DriveLetter
END

CLOSE curDriveLetters

DEALLOCATE curDriveLetters

PRINT 'Drive information for server ' + @@SERVERNAME + '.'
PRINT ''

-- Produce report.
SELECT DriveLetter,   TotalSpace/1024 AS [TotalSpace GB],FreeSpace/1024 AS [FreeSpace GB], (TotalSpace - FreeSpace)/1024 AS [UsedSpace GB], 
convert(int,((CONVERT(NUMERIC(9, 0), FreeSpace) / CONVERT(NUMERIC(9, 0), TotalSpace)) * 100)) AS [Percentage Free]
FROM ##_DriveInfo
ORDER BY [DriveLetter] ASC
GO

DROP TABLE ##_DriveSpace

DROP TABLE ##_DriveInfo


if ((SELECT  value FROM    sys.configurations where name = 'Ole Automation Procedures')= 1)
begin
EXEC sp_configure 'show advanced options', 1
RECONFIGURE
EXEC sp_configure 'Ole Automation Procedures', 0
RECONFIGURE
end
