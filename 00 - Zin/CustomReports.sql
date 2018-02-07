select top 10 * from reportexecutionlog where executionstatus like '%progress'
 

update reportexecutionlog set executionstatus = 'Removed', executionmessage = '', executiondate = getdate() where REPORTEXECUTIONID in (16016,  16017, 16029, 16030) 

ReportCustomListForGeneration_Usage


ReportCustomListForGeneration