
--Get VLFs info
DBCC LOGINFO



--Get VLFs info
 dbcc loginfo ('wmpoperatorusage')
 declare @vlfs int = @@rowcount 
 select @vlfs as TotalVLFs
 
 -- shrink the logs to as small as possible then grow them back to the original size, ideally in a single growth.

 /*
 You now get 3 statuses shown, “In Use”, “Available”, and “Available Never Used”. The If you have lots of VLFs that are “Available Never Used” that may be an indication that your log file may be larger than you need. If you don’t have any that are “Available Never Used” the log may be smaller than you need.
 */
	
DECLARE @logInfoResults AS TABLE
(
 [RecoveryUnitId] BIGINT, -- only on SQL Server 2012 and newer
 [FileId] TINYINT,
 [FileSize] BIGINT,
 [StartOffset] BIGINT,
 [FSeqNo] INTEGER,
 [Status] TINYINT,
 [Parity] TINYINT,
 [CreateLSN] NUMERIC(38,0)
);
 
INSERT INTO @logInfoResults
EXEC sp_executesql N'DBCC LOGINFO WITH NO_INFOMSGS';
 
SELECT cast(FileSize / 1024.0 / 1024 AS DECIMAL(20,1)) as FileSizeInMB,
case when FSeqNo = 0 then 'Available - Never Used' else (Case when status = 2 then 'In Use' else 'Available' end) end as TextStatus,
[Status] ,
REPLICATE('x', FileSize / MIN(FileSize) over()) as [BarChart ________________________________________________________________________________________________]
FROM @logInfoResults ;