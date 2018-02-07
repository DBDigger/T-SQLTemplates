-- SP to get the SQL logs
xp_readerrorlog 2,1, 'SERVICE_RUNNING', NULL, '2014-04-25 18:00:00.000', '2014-04-25 23:00:00.000', 'desc'

-- Parameter details
/*
1 Value of error log file you want to read: 0 = current log, 1 = Archive #1, 2 = Archive #2, etc…
2 Log file type: 1 or NULL = sql server error log, 2 = SQL Agent log
3 Search string 1: String one you want to search for, eg:- you want to search for database
4 Search string 2: String two you want to search for to further refine the results; eg:- you want to filter and display only the error messages.
5 Search from start time : this parameter can be used to filter out the log and fetch log only starting at the start time;
6 Search to end time: this parameter is specified to read the error log upto end time
7 Sort order for results: N’asc’ = ascending, N’desc’ = descending
*/