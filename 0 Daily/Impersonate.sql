SELECT SUSER_NAME(), USER_NAME();
-- Set the execution context to login1. 
EXECUTE AS LOGIN = 'CustomReportingWMP';
--Verify the execution context is now login1.
EXEC dbo.ReportCustomArchiveListByCompanyId_Get 1


-- Now revert
REVERT;
SELECT SUSER_NAME(), USER_NAME();