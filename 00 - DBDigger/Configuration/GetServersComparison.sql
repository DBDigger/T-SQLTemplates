--EXEC CompareServerConfigurations @ServerNames = 'lhrlt-238,lhrlt-238\SSr2A'

DROP PROCEDURE CompareServerConfigurations 
GO 
CREATE PROCEDURE CompareServerConfigurations 
@ServerNames VARCHAR(1000)  
AS 
 
/* 
Parameters  
@ServerNames = The servers configurations to compared should be passed in the parameter as a comma seperated value as shown in the below usage. 
               This parameter cannot be blank.  
 
Usage : EXEC CompareServerConfigurations @Servernames ='Server1,Server2,Server3' 
 
 
*/ 
 
   SET NOCOUNT ON 
 
   IF LTRIM(RTRIM(@ServerNames)) = ''  
   BEGIN 
        RAISERROR('ServerNames cannot be empty',16,1) 
        RETURN 
   END 
 
    DECLARE @ServerTbl TABLE 
    ( 
     ServerName SYSNAME 
    ,LocalServer bit DEFAULT 0 
    ,Processed   bit DEFAULT 0 
    ) 
 
    DECLARE @SQL         VARCHAR(MAX) 
    DECLARE @BaseSQL     VARCHAR(MAX) 
    DECLARE @Server         SYSNAME 
    DECLARE @LocalServer BIT 
    DECLARE @PivotServer VARCHAR(4000) 
 
    SELECT @SQL = 'SELECT ''' + REPLACE (@ServerNames,',',''' UNION SELECT ''') + '''' 
 
    INSERT INTO @ServerTbl 
    (ServerName) 
    EXEC (@SQL) 
 
    UPDATE s 
       SET s.LocalServer = 1 
      FROM @ServerTbl s 
     WHERE S.ServerName = @@SERVERNAME 
     
 
    IF OBJECT_ID('tempdb.dbo.##ServerConfigTmp') IS NOT NULL 
        DROP TABLE ##ServerConfigTmp 
     
    CREATE TABLE ##ServerConfigTmp 
    ( 
     Rnk          VARCHAR(500) 
    ,ServerName      SYSNAME 
    ,ConfigName   VARCHAR(200) 
    ,Description  VARCHAR(500) 
    ,Minimum      VARCHAR(500) 
    ,Maximum      VARCHAR(500) 
    ,Value          VARCHAR(500) 
    ) 
 
     
    WHILE EXISTS(SELECT 1 FROM @ServerTbl WHERE Processed = 0) 
    BEGIN 
 
       SELECT TOP 1 @Server = ServerName,@LocalServer=LocalServer 
         FROM @ServerTbl 
        WHERE Processed = 0 
        ORDER BY LocalServer DESC 
 
        PRINT REPLICATE ('-',200) 
        PRINT 'Processing ' + @server 
        PRINT REPLICATE ('-',200) 
 
 
       SELECT @SQL = 'EXEC (''SELECT Rnk=''''8'''',Servername=''''' + @Server + ''''',Name,description,CONVERT(VARCHAR(500),minimum),CONVERT(VARCHAR(500),maximum),CONVERT(VARCHAR(500),value_in_use)  FROM master.SYS.configurations 
                    UNION 
                    SELECT ''''1'''',''''' + @Server + ''''',''''ServerName'''' ,''''Server Name'''' ,'''''''','''''''',CONVERT(VARCHAR(500),SERVERPROPERTY(''''ServerName'''')) 
                    UNION 
                    SELECT ''''2'''',''''' + @Server + ''''',''''InstanceName'''' , ''''Instance Name'''' ,'''''''','''''''',CONVERT(VARCHAR(500),SERVERPROPERTY(''''InstanceName'''')) 
                    UNION 
                    SELECT ''''3'''',''''' + @Server + ''''',''''ProductVersion'''' , ''''Product version'''' ,'''''''','''''''',CONVERT(VARCHAR(500),SERVERPROPERTY(''''productversion'''')) 
                    UNION 
                    SELECT ''''4'''',''''' + @Server + ''''',''''ProductLevel'''' , ''''Product Level'''' ,'''''''','''''''',CONVERT(VARCHAR(500),SERVERPROPERTY(''''productlevel'''')) 
                    UNION 
                    SELECT ''''5'''',''''' + @Server + ''''',''''Edition'''' , ''''Edition'''' ,'''''''','''''''',CONVERT(VARCHAR(500),SERVERPROPERTY(''''edition'''')) 
                    UNION 
                    SELECT ''''6'''',''''' + @Server + ''''',''''MachineName'''' , ''''Machine Name'''' ,'''''''','''''''',CONVERT(VARCHAR(500),SERVERPROPERTY(''''MachineName'''')) 
                    UNION 
                    SELECT ''''7'''',''''' + @Server + ''''',''''LicenseType'''' , ''''License Type'''' ,'''''''','''''''',CONVERT(VARCHAR(500),SERVERPROPERTY(''''LicenseType'''')) 
                      '') ' 
         
 
        DECLARE @OpenRowsetSQL VARCHAR(MAX) 
 
        SELECT @OpenRowsetSQL = 'SELECT a.* 
                                 FROM OPENROWSET(''SQLNCLI'', ''Server=' + @Server + ';Trusted_Connection=yes;'', 
                                ''' + replace(@SQL,'''','''''') + ''') AS a;' 
 
        INSERT INTO ##ServerConfigTmp 
        (Rnk,ServerName,ConfigName,Description,Minimum,Maximum,Value) 
        EXEC(@OpenRowsetSQL) 
 
         
        UPDATE @ServerTbl 
           SET Processed = 1 
         WHERE ServerName = @Server 
 
    END 
     
    SELECT @PivotServer = '' 
     
    SELECT @PivotServer = @PivotServer + QUOTENAME(ServerName) + ',' 
      FROM @ServerTbl 
     ORDER BY LocalServer DESC 
     
    SELECT @PivotServer = SUBSTRING(@PivotServer,1,LEN(@PivotServer)-1) 
 
    SELECT @SQL ='SELECT * 
                    FROM ( SELECT rnk,Servername,Configname,Description,Value 
                             FROM ##ServerConfigTmp) src 
                             PIVOT (MAX(Value) FOR Servername IN (' + @PivotServer + ')) AS pvt 
                            ORDER BY Rnk' 
 
 
      EXEC(@SQL) 
 
GO 
 
 
       
      