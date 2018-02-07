DECLARE @RowsDeleted INTEGER
SET @RowsDeleted = 1
declare @loopcount smallint 
SET @loopcount = 1

WHILE (@RowsDeleted > 0)
    BEGIN
        -- delete 10,000 rows a time
        delete top (10000) from SIMCARDS
--output deleted.*  into RequestDetails1_BkUp_May292014
where  created < = '2014-05-01'
        SET @RowsDeleted = @@ROWCOUNT
        set @loopcount =  @loopcount + 1
        
        Print @loopcount
    END



	-- Transactional tables
	ApiSessions_Archive
APITRANSACTIONLOG
audit2011_1
EIMREQUESTDETAILS
EIMREQUESTPROCESSING
EIMREQUESTPROCESSINGDETAILS
EIMREQUESTS
EXCEPTIONLOG
NETWORKAUTHENTICATIONLOG
REQUESTCALLBACKRESPONSES
REQUESTDETAILS1
Requestdetails1_BkUp_July312014
REQUESTS1
SERVICE_ASYNC_RESPONSE_LOG_Archive
SERVICE_REQUEST_DETAILS
SERVICE_REQUEST_PROCESSING_DETAIL
ServiceAsyncResponseLog_Replicated
StockRequestDetail