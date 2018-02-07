--------------- Import data from .trc to folder
SELECT * INTO trace_467
FROM::fn_trace_gettable('D:\Log_467.trc', 1)
GO