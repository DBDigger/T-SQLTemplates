
declare @filesize int

set @filesize = 68000

WHILE @filesize > 60000
BEGIN
 DBCC SHRINKFILE (N'Primary_Temp_V1' , @filesize)

 WAITFOR DELAY '00:01:00'
 
 SET @filesize = @filesize - 1000;
END

-------------------------------------------
declare @currentfilesize int = 80700
declare @shrinkedfilesize int = 3000
declare @shrinkbyamount int = 20000

WHILE ((@currentfilesize - @shrinkedfilesize) <> 0)
BEGIN

 IF (@currentfilesize -  @shrinkbyamount < @shrinkedfilesize)
 SET @currentfilesize = @shrinkedfilesize;
 ELSE
 SET @currentfilesize = @currentfilesize - @shrinkbyamount;

 print @currentfilesize
 DBCC SHRINKFILE (N'wmp' , @currentfilesize)
 WAITFOR DELAY '00:00:09'
END