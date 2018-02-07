select 'ALTER DATABASE ['+name+'] SET COMPATIBILITY_LEVEL = 140;' from sys.databases where name NOT IN ('master','msdb','tempdb','model','distribution')
go

EXECUTE master.sys.sp_MSforeachdb 'USE [?]; EXEC DBCC CHECKDB WITH DATA_PURITY' ;
GO

EXECUTE master.sys.sp_MSforeachdb 'DBCC UPDATEUSAGE(?)' ;
GO


EXECUTE master.sys.sp_MSforeachdb 'USE [?]; EXEC sp_MSforeachtable @command1=''UPDATE STATISTICS ? ''' ;
GO

EXEC sp_updatestats;

select 'sp_refreshview  '''+name+''';' from sys.objects where type  = 'V' and is_ms_shipped = 0

--------------------------------------------------------------------------

---------------------------------------------------------------------
DECLARE @Database VARCHAR(255)  
DECLARE @Table VARCHAR(255)  
DECLARE @cmd NVARCHAR(500)  
DECLARE @fillfactor INT

SET @fillfactor = 80

DECLARE DatabaseCursor CURSOR FOR  
SELECT name FROM master.dbo.sysdatabases  
WHERE name NOT IN ('master','msdb','tempdb','model','distribution')  
ORDER BY 1  

OPEN DatabaseCursor  

FETCH NEXT FROM DatabaseCursor INTO @Database  
WHILE @@FETCH_STATUS = 0  
BEGIN  

   SET @cmd = 'DECLARE TableCursor CURSOR FOR SELECT ''['' + table_catalog + ''].['' + table_schema + ''].['' +
  table_name + '']'' as tableName FROM [' + @Database + '].INFORMATION_SCHEMA.TABLES
  WHERE table_type = ''BASE TABLE'' and table_schema+''.''+table_name   in (select schema_name(o.schema_id)+''.''+o.name from '+@Database+'.sys.indexes i inner join '+ @Database+'.sys.objects o on i.object_id = o.object_id where i.type > = 4)'  

   -- create table cursor  
   EXEC (@cmd)  
   OPEN TableCursor  

   FETCH NEXT FROM TableCursor INTO @Table  
   WHILE @@FETCH_STATUS = 0  
   BEGIN  

           SET @cmd = 'ALTER INDEX ALL ON ' + @Table + ' REBUILD partition = ALL WITH (DATA_COMPRESSION = COLUMNSTORE);'
           Print (@cmd)
       
	   --SET @cmd = 'ALTER INDEX ALL ON ' + @Table + ' REBUILD partition = ALL WITH (FILLFACTOR = ' + CONVERT(VARCHAR(3),@fillfactor) + ');'
    --       print (@cmd) 
      

       FETCH NEXT FROM TableCursor INTO @Table  
   END  

   CLOSE TableCursor  
   DEALLOCATE TableCursor  

   FETCH NEXT FROM DatabaseCursor INTO @Database  
END  
CLOSE DatabaseCursor  
DEALLOCATE DatabaseCursor 