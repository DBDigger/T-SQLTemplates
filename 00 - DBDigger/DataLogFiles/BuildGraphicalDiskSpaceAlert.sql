CREATE proc [dbo].[USP_Send_DiskSpace]  
( 
    @To  varchar(200) ,    
    @CRITICAL    int     = 10    -- if the freespace(%) is less than @alertvalue, it will send message 
) 
as 
Begin 
DECLARE     @HOSTNAME     VARCHAR(20),  
                @HEAD        VARCHAR(100), 
                @BGCOLOR    VARCHAR(50), 
                @REC        VARCHAR(50), 
                @PRIORITY    VARCHAR(10), 
                @FREE VARCHAR(20), 
                @TOTAL VARCHAR(20), 
                @FREE_PER VARCHAR(20), 
                @CHART VARCHAR(2000), 
                @HTML VARCHAR(MAX), 
                @HTMLTEMP VARCHAR(MAX), 
                @TITLE VARCHAR(100), 
                @DRIVE VARCHAR(100), 
                @SQL VARCHAR(MAX) 
 
CREATE TABLE #MOUNTVOL (COL1 VARCHAR(500)) 
 
INSERT INTO #MOUNTVOL 
EXEC XP_CMDSHELL 'MOUNTVOL' 
 
DELETE #MOUNTVOL WHERE COL1 NOT LIKE '%:%' 
DELETE #MOUNTVOL WHERE COL1 LIKE '%VOLUME%' 
DELETE #MOUNTVOL WHERE COL1 IS NULL 
DELETE #MOUNTVOL WHERE COL1 NOT LIKE '%:%' 
DELETE #MOUNTVOL WHERE COL1 LIKE '%MOUNTVOL%' 
DELETE #MOUNTVOL WHERE COL1 LIKE '%RECYCLE%' 
 
SELECT LTRIM(RTRIM(COL1)) FROM #MOUNTVOL 
 
CREATE TABLE #DRIVES 
    ( 
        DRIVE VARCHAR(500), 
        INFO VARCHAR(80) 
    ) 
 
DECLARE CUR CURSOR FOR SELECT LTRIM(RTRIM(COL1)) FROM #MOUNTVOL 
OPEN CUR 
FETCH NEXT FROM CUR INTO @DRIVE 
WHILE @@FETCH_STATUS=0  
BEGIN 
       SET    @SQL = 'EXEC XP_CMDSHELL ''FSUTIL VOLUME DISKFREE ' + @DRIVE +'''' 
         
        INSERT    #DRIVES 
            ( 
                INFO 
            ) 
        EXEC    (@SQL) 
 
        UPDATE    #DRIVES 
        SET    DRIVE = @DRIVE 
        WHERE    DRIVE IS NULL 
          
FETCH NEXT FROM CUR INTO @DRIVE 
END          
CLOSE CUR          
DEALLOCATE CUR        
 
-- SHOW THE EXPECTED OUTPUT 
SELECT        DRIVE, 
        SUM(CASE WHEN INFO LIKE 'TOTAL # OF BYTES             : %' THEN CAST(REPLACE(SUBSTRING(INFO, 32, 48), CHAR(13), '') AS BIGINT) ELSE CAST(0 AS BIGINT) END) AS TOTALSIZE, 
        SUM(CASE WHEN INFO LIKE 'TOTAL # OF FREE BYTES        : %' THEN CAST(REPLACE(SUBSTRING(INFO, 32, 48), CHAR(13), '') AS BIGINT) ELSE CAST(0 AS BIGINT) END) AS FREESPACE 
INTO #DISKSPACE FROM        ( 
            SELECT    DRIVE, 
                INFO 
            FROM    #DRIVES 
            WHERE    INFO LIKE 'TOTAL # OF %' 
        ) AS D 
GROUP BY    DRIVE 
ORDER BY    DRIVE 
 
 
 
 
SET @TITLE = 'DISK SPACE REPROT : '+ @@SERVERNAME 
 
SET @HTML = '<HTML><TITLE>'+@TITLE+'</TITLE> 
<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=2> 
 <TR BGCOLOR=#0070C0 ALIGN=CENTER STYLE=''FONT-SIZE:8.0PT;FONT-FAMILY:"TAHOMA","SANS-SERIF";COLOR:WHITE''> 
  <TD WIDTH=40><B>DRIVE</B></TD> 
  <TD WIDTH=250><B>TOTAL</B></TD> 
  <TD WIDTH=150><B>FREE SPACE</B></TD> 
  <TD WIDTH=150><B>FREE PRECENTAGE</B></TD> 
</TR>' 
 
DECLARE    RECORDS CURSOR  
FOR SELECT CAST(DRIVE AS VARCHAR(100)) AS 'DRIVE', CAST(FREESPACE/1024/1024 AS VARCHAR(10)) AS 'FREE',CAST(TOTALSIZE/1024/1024 AS VARCHAR(10)) AS 'TOTAL',  
CONVERT(VARCHAR(2000),'<TABLE BORDER=0 ><TR><TD BORDER=0 BGCOLOR='+ CASE WHEN ((FREESPACE/1024/1024)/((TOTALSIZE/1024/1024)*1.0))*100.0 < @CRITICAL   
    THEN 'RED' 
WHEN ((FREESPACE/1024/1024)/((TOTALSIZE/1024/1024)*1.0))*100.0 > 70   
    THEN '66CC00' 
   ELSE   
    '0033FF' 
   END +'><IMG SRC=''/GIFS/S.GIF'' WIDTH='+CAST(CAST(((FREESPACE/1024/1024)/((TOTALSIZE/1024/1024)*1.0))*100.0*2 AS INT) AS CHAR(10) )+' HEIGHT=5></TD> 
     <TD><FONT SIZE=1>'+CAST(CAST(((FREESPACE/1024/1024)/((TOTALSIZE/1024/1024)*1.0))*100.0 AS INT) AS CHAR(10) )+'%</FONT></TD></TR></TABLE>') AS 'CHART'  
    FROM #DISKSPACE ORDER BY ((FREESPACE/1024/1024)/((TOTALSIZE/1024/1024)*1.0))*100.0 
 
OPEN RECORDS 
 
FETCH NEXT FROM RECORDS INTO @DRIVE , @FREE, @TOTAL, @CHART  
         
WHILE @@FETCH_STATUS = 0 
 
BEGIN 
 
    SET @HTMLTEMP =  
        '<TR BORDER=0 BGCOLOR="#E8E8E8" STYLE=''FONT-SIZE:8.0PT;FONT-FAMILY:"TAHOMA","SANS-SERIF";COLOR:#0F243E''> 
        <TD ALIGN = CENTER>'+@DRIVE+'</TD> 
        <TD ALIGN=CENTER>'+@TOTAL+'</TD> 
        <TD ALIGN=CENTER>'+@FREE+'</TD> 
        <TD  VALIGN=MIDDLE>'+@CHART+'</TD> 
        </TR>' 
         
        SET @HTML = @HTML +    @HTMLTEMP 
         
    FETCH NEXT FROM RECORDS INTO @DRIVE , @FREE, @TOTAL, @CHART  
 
END 
CLOSE RECORDS 
DEALLOCATE RECORDS 
 
 
SET @HTML = @HTML + '</TABLE><BR> 
<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B>THANKS,</B></SPAN></P> 
<P CLASS=MSONORMAL><SPAN STYLE=''FONT-SIZE:10.0PT;''COLOR:#1F497D''><B>DBA TEAM</B></SPAN></P> 
</HTML>' 
 
--PRINT  
    PRINT @HTML 
 
--save data 
if(object_id('DBA.dbo.diskdrive_stats') is null) 
Begin 
    create table DBA.dbo.diskdrive_stats (   
        Drive varchar(100) ,    
        FreeSpace float null,   
        TotalSize float null, 
        Free_per float, 
        date_time datetime)   
     
insert into DBA.dbo.diskdrive_stats (Drive,Freespace,TotalSize,Free_Per,date_time) 
    select Drive,convert(float,freespace),convert(float,totalsize), 
   convert(float,((FREESPACE/1024/1024)/((TOTALSIZE/1024/1024)*1.0))*100.0),getdate() from #DISKSPACE 
 
    --insert into DBA.dbo.diskdrive_stats (Drive,Freespace,TotalSize,Free_Per,date_time) 
    --select *,((FREESPACE/1024/1024)/((TOTALSIZE/1024/1024)*1.0))*100.0,getdate() from #DISKSPACE 
End 
    Else 
Begin 
    insert into DBA.dbo.diskdrive_stats (Drive,Freespace,TotalSize,Free_Per,date_time) 
    select Drive,convert(float,freespace),convert(float,totalsize), 
   convert(float,((FREESPACE/1024/1024)/((TOTALSIZE/1024/1024)*1.0))*100.0),getdate() from #DISKSPACE 
End     
 
 
--############################Send Mail############################# 
 
set @head = '<RED> Disk Space report from SQL Server : '+@@servername 
 
--SELECT * FROM #DISKSPACE 
 
IF EXISTS(SELECT * FROM #DISKSPACE WHERE CAST((FREESPACE/(TOTALSIZE*1.0))*100.0 AS INT) <= @CRITICAL) 
    BEGIN 
        SET @PRIORITY = 'HIGH' 
         
        print @head 
        exec msdb.dbo.sp_send_dbmail     
        @profile_name = 'SQLProfile',     
        @recipients = @To,    
        @subject = @head, 
        @importance =  @Priority,   
        @body = @HTML,     
        @body_format = 'HTML' 
 
    END     
    ELSE 
    BEGIN     
        print'' 
    END 
 
 
 
DROP TABLE #MOUNTVOL 
DROP TABLE #DRIVES 
DROP TABLE #DISKSPACE 
 
END