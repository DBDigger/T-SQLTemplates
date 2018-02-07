/*

    Run this script on a subscriber of transactional or p2p replication

    

    The script accesses the publisher via a linked server to pull metadata of row counts for tables participating in the replication 

    (belonging to all publications for the database being queried) and performs a comparison against the tables at the subscription database. 

    The rows with a diff are returned and in addition the script prints the INSERT commands required to close the diff/gap of those rows that 

    exist at the publisher and do not exist at the subscriber

*/

 

 

USE ; --<-------- Edit database name here

 

/*

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SplitMeToString]') AND type in (N'TF'))

    DROP FUNCTION [dbo].[SplitMeToString];

GO

CREATE FUNCTION [dbo].[SplitMeToString]

(

     @sep VARCHAR(32)

    ,@s VARCHAR(MAX)

)

RETURNS @t TABLE (val VARCHAR(MAX))

AS 

BEGIN;

   DECLARE @xml XML

   SET @XML = N'<root><r>' + REPLACE(@s, @sep, '</r><r>') + '</r></root>'

   INSERT   INTO @t(val)

            SELECT   RTRIM(LTRIM(r.value('.', 'VARCHAR(max)'))) AS Item

            FROM     @xml.nodes('//root/r') AS RECORDS (r);

   RETURN;

END;

*/

 

 

SET NOCOUNT ON; SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

 

DECLARE @LinkedServer sysname, @database sysname, @command varchar(max), @dubug BIT, @diff int; /* Eliminate a diff smaller than this value */

SELECT @dubug = 0, @diff = 0

, @LinkedServer = N''    --<-------- Edit linked server name here

, @database = N''    --<-------- Edit the published database name here

 

 

IF OBJECT_id('tempdb..#sysarticles ') IS NOT NULL DROP TABLE #sysarticles;

IF OBJECT_id('tempdb..#subscriber ')    IS NOT NULL DROP TABLE #subscriber;

IF OBJECT_id('tempdb..#publisher ')        IS NOT NULL DROP TABLE #publisher;

IF OBJECT_id('tempdb..#indexes')            IS NOT NULL DROP TABLE #indexes;

IF OBJECT_id('tempdb..#data')                    IS NOT NULL DROP TABLE #data;

 

 

/* Get the replication articles from the publisher */

CREATE TABLE dbo.#sysarticles (article sysname, publication sysname, ident bit);

SELECT @command = '

INSERT dbo.#sysarticles (article, publication, ident)

SELECT 

     a.name    AS article

    ,p.name    AS publication

    ,OBJECTPROPERTY(objid, ''TableHasIdentity'') AS ident 

FROM [' + @LinkedServer + '].[' + @database + '].dbo.sysarticles a

INNER JOIN [' + @LinkedServer + '].[' + @database + '].dbo.syspublications p ON p.pubid = a.pubid;';

IF @dubug = 1 PRINT @command;

EXEC (@command);

 

-- Index information

SELECT 

     SCHEMA_NAME(o.SCHEMA_ID) AS [Schema]

    ,o.name AS [Table]

    ,i.name AS [Index]

    ,LEFT(list, ISNULL(splitter-1,LEN(list))) AS [Columns]

    ,a.ident

INTO #indexes

FROM sys.indexes i

INNER JOIN sys.objects o ON i.[object_id] = o.[object_id] 

INNER JOIN dbo.#sysarticles a ON a.article = o.name /* replication tables only */

INNER JOIN  sys.stats s ON i.[object_id] = s.[object_id] AND i.index_id = s.stats_id

CROSS APPLY (SELECT NULLIF(CHARINDEX('|',indexCols.list),0) splitter , list

                            FROM (SELECT CAST((SELECT CASE WHEN sc.is_included_column = 1 AND sc.ColPos = 1 THEN '|' ELSE '' END + CASE WHEN sc.ColPos  > 1 THEN ', ' ELSE '' END + name

                                                         FROM (SELECT 

                                                                             sc.is_included_column

                                                                            ,index_column_id

                                                                            ,name

                                                                            ,ROW_NUMBER() OVER (PARTITION BY sc.is_included_column ORDER BY sc.key_ordinal) ColPos

                                                                        FROM sys.index_columns  sc

                                                                        INNER JOIN sys.columns c ON sc.[object_id] = c.[object_id] AND sc.column_id = c.column_id

                                                                        WHERE sc.index_id = i.index_id AND sc.[object_id] = i.[object_id] ) sc

                                                    ORDER BY sc.is_included_column, ColPos

                                            FOR XML PATH (''), TYPE) AS VARCHAR(MAX)) list)indexCols ) indCol

WHERE i.is_primary_key = 1; /* PK only */

--AND o.name = '' 

--AND a.ident = 0

 

 

/* subscriber */

SELECT

    (row_number() OVER(ORDER BY t3.name, t2.name))%2 AS l1

    ,DB_NAME() AS [database]

    ,t3.name AS [schema]

    ,t2.name AS [table]

    ,t1.rows AS row_count

    ,((t1.reserved + ISNULL(a4.reserved,0))* 8) / 1024 AS reserved_MB 

    ,(t1.data * 8) / 1024 AS data_MB

    ,((CASE WHEN (t1.used + ISNULL(a4.used,0)) > t1.data THEN (t1.used + ISNULL(a4.used,0)) - t1.data ELSE 0 END) * 8) /1024 AS index_size_MB

    ,((CASE WHEN (t1.reserved + ISNULL(a4.reserved,0)) > t1.used THEN (t1.reserved + ISNULL(a4.reserved,0)) - t1.used ELSE 0 END) * 8)/1024 AS unused_MB

    ,i.[index]

    ,i.columns

    ,i.ident

INTO dbo.#subscriber

FROM

 (SELECT 

     ps.object_id

    ,SUM (CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END) AS [rows]

    ,SUM (ps.reserved_page_count) AS reserved

    ,SUM (CASE WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count) ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count) END) AS data

    ,SUM (ps.used_page_count) AS used

  FROM sys.dm_db_partition_stats ps

  GROUP BY ps.object_id) AS t1

LEFT OUTER JOIN 

     (SELECT 

             it.parent_id

            ,SUM(ps.reserved_page_count) AS reserved

            ,SUM(ps.used_page_count) AS used

        FROM sys.dm_db_partition_stats ps

        INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id) WHERE it.internal_type IN (202,204)

        GROUP BY it.parent_id) AS a4 ON (a4.parent_id = t1.object_id

        )

INNER JOIN sys.all_objects t2  ON ( t1.object_id = t2.object_id) 

INNER JOIN sys.schemas t3 ON (t2.schema_id = t3.schema_id)

INNER JOIN dbo.#sysarticles a ON a.article = t2.name

LEFT JOIN #indexes i ON i.[Schema] = SCHEMA_NAME(t2.schema_id) AND i.[Table] = t2.name

WHERE t2.type <> 'S' and t2.type <> 'IT';

 

 

/* publisher */

CREATE TABLE dbo.#publisher (l1 int, [database] sysname, [schema] sysname, [table] sysname, row_count int, reserved_MB float, data_MB float, index_size_MB float, unused_MB float);

SELECT @command = '

INSERT dbo.#publisher (l1, [database], [schema], [table], row_count, reserved_MB, data_MB, index_size_MB, unused_MB)

SELECT

    (row_number() over(order by t3.name, t2.name))%2 as l1

    ,DB_NAME() AS [database]

    ,t3.name AS [schema]

    ,t2.name AS [table]

    ,t1.rows AS row_count

    ,((t1.reserved + ISNULL(a4.reserved,0))* 8) / 1024 AS reserved_MB 

    ,(t1.data * 8) / 1024 AS data_MB

    ,((CASE WHEN (t1.used + ISNULL(a4.used,0)) > t1.data THEN (t1.used + ISNULL(a4.used,0)) - t1.data ELSE 0 END) * 8) /1024 AS index_size_MB

    ,((CASE WHEN (t1.reserved + ISNULL(a4.reserved,0)) > t1.used THEN (t1.reserved + ISNULL(a4.reserved,0)) - t1.used ELSE 0 END) * 8)/1024 AS unused_MB

FROM

 (SELECT 

     ps.object_id

    ,SUM (CASE WHEN (ps.index_id < 2) THEN row_count ELSE 0 END) AS [rows]

    ,SUM (ps.reserved_page_count) AS reserved

    ,SUM (CASE WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count) ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count) END) AS data

    ,SUM (ps.used_page_count) AS used

  FROM [' + @LinkedServer + '].[' + @database + '].sys.dm_db_partition_stats ps

  GROUP BY ps.object_id) AS t1

LEFT OUTER JOIN 

 (SELECT 

       it.parent_id

      ,SUM(ps.reserved_page_count) AS reserved

      ,SUM(ps.used_page_count) AS used

  FROM [' + @LinkedServer + '].[' + @database + '].sys.dm_db_partition_stats ps

  INNER JOIN [' + @LinkedServer + '].[' + @database + '].sys.internal_tables it ON (it.object_id = ps.object_id) WHERE it.internal_type IN (202,204)

  GROUP BY it.parent_id) AS a4 ON (a4.parent_id = t1.object_id)

INNER JOIN [' + @LinkedServer + '].[' + @database + '].sys.all_objects t2  ON ( t1.object_id = t2.object_id) 

INNER JOIN [' + @LinkedServer + '].[' + @database + '].sys.schemas t3 ON (t2.schema_id = t3.schema_id)

INNER JOIN [' + @LinkedServer + '].[' + @database + '].dbo.sysarticles a ON a.name = t2.name

WHERE t2.type <> ''S'' and t2.type <> ''IT'';';

IF @dubug = 1 PRINT @command;

EXEC (@command);

 

 

/* Prepare the final output */

SELECT 

     @@servername AS [server]

    ,p.[schema]

    ,p.[table]

    ,a.publication

    ,p.reserved_MB    

    ,p.row_count                                 AS publisher_row_count

    ,s.row_count                                 AS subscriber_row_count

    ,p.row_count - s.row_count    AS diff

    ,(SELECT SUM(p.row_count - s.row_count)    AS diff_total FROM #publisher p

                INNER JOIN #subscriber s ON s.[table] = p.[table] 

                INNER JOIN #sysarticles a ON a.article = s.[table]

                WHERE s.row_count <> p.row_count AND (p.row_count - s.row_count > @diff OR @diff IS NULL) ) AS diff_total

    ,s.[columns]

    ,s.[index]

    ,s.ident

INTO #data

FROM #publisher p

INNER JOIN #subscriber s ON s.[table] = p.[table] AND s.[schema] = p.[schema]

INNER JOIN #sysarticles a ON a.article = s.[table] 

WHERE s.row_count <> p.row_count

AND (p.row_count - s.row_count > @diff OR @diff IS NULL);

 

 

/* Return tables with diff */

SELECT  

         [server]

        ,[schema]

        ,[table]

        ,reserved_MB

        ,publisher_row_count

        ,subscriber_row_count

        ,diff

        ,diff_total 

FROM #data 

ORDER BY diff DESC;

 

 

/* Use a cursor over the table to construct the INSERT commands */

DECLARE cur CURSOR LOCAL READ_ONLY FAST_FORWARD FOR 

    SELECT [schema], [table], [index], [columns], [Ident] FROM #data ORDER BY [table];

OPEN cur;

DECLARE @schema sysname, @table sysname, @index sysname, @columns sysname, @cnt int, @where nvarchar(4000), @col_cnt int, @ident bit ;

DECLARE @colname nvarchar(4000);

DECLARE @cols table (name nvarchar(4000), col_order int);

DECLARE @min int, @max int, @columns_list varchar(max), @column sysname, @debug bit;

--SELECT @columns_list = '';

 

 

    FETCH NEXT FROM cur INTO @schema, @table, @index, @columns, @ident;

    WHILE (@@FETCH_STATUS <> -1)

    BEGIN;

    

    /* Handle cases where the primary keys is composit consisting of more than a single column */

    INSERT INTO @cols SELECT val, ROW_NUMBER() OVER(ORDER BY val) FROM [dbo].[SplitMeToString](',', @columns);

    SELECT @where = 'WHERE';

    SELECT @col_cnt = 0;

    

    WHILE (SELECT MAX(col_order) FROM @cols) > @col_cnt

    BEGIN;

        SELECT @col_cnt = @col_cnt + 1;

        SELECT @colname = name FROM @cols WHERE col_order = @col_cnt;

        SELECT @where = @where + ' s.' + QUOTENAME(@colname) + ' = p.' + QUOTENAME(@colname) + ' AND';

    END;

    

    /* remove the last AND of the WHERE string */

    SELECT @where = SUBSTRING(@where,0, LEN(@Where) - 3);

    

    

    /*

     Get the PK diff

    SELECT @command =     

    'SELECT @cnt = (SELECT COUNT(*)

     FROM [' + @LinkedServer + '].[' + @database + '].' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + ' p

      WHERE NOT EXISTS (SELECT * FROM ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) 

            + ' s ' + @where + '));'

    IF @debug = 1 PRINT @command;

    --Execute

  EXEC sp_executesql 

      @statement = @command, 

      @params         = N'@cnt int OUTPUT', 

      @cnt             = @cnt OUTPUT;

  */

  

 

    /* Tables with no identity column use a simple INSERT...SELECT command */

        IF (@ident = 0)

        BEGIN;

                SELECT @command =     

                'INSERT ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + CHAR(10) +

                'SELECT * FROM [' + @LinkedServer + '].[' + @database + '].' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + ' p

                    WHERE NOT EXISTS (SELECT * FROM ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) 

                        + ' s ' + @where + ');' + CHAR(10);

                        

                PRINT @command;

        END

        

        /* Tables with identity column construct an explicit column list */

        ELSE IF (@ident = 1)

        BEGIN;

                SELECT @max = MAX(ORDINAL_POSITION), @min = MIN(ORDINAL_POSITION)     

                FROM    INFORMATION_SCHEMA.COLUMNS 

                WHERE TABLE_NAME = @table AND TABLE_SCHEMA = @schema;

            

            

                /* Loop through the columns to build the column list */

                SELECT @column = '', @columns_list = '';

                WHILE (@min <= @max )

                    BEGIN;

                        SELECT     

                             @column = QUOTENAME(COLUMN_NAME) + ','

                        FROM     INFORMATION_SCHEMA.COLUMNS

                        WHERE ORDINAL_POSITION = @min AND TABLE_NAME = @table AND TABLE_SCHEMA = @schema; 

                        

                        SELECT @columns_list = @columns_list + @column, @min = @min + 1 ;

                    END;

                

                    /* Remove the last comma */

                    SELECT @columns_list = LEFT(@columns_list, LEN(@columns_list) - 1);

                    

                    SELECT @command = 

                    'SET IDENTITY_INSERT ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + ' ON;

                    INSERT ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table)+ ' (' + @columns_list + ')'  + CHAR(10) +

                    'SELECT ' + @columns_list + CHAR(10) +

                    ' FROM [' + @LinkedServer + '].[' + @database + '].' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + ' p

                        WHERE NOT EXISTS (SELECT * FROM ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) 

                            + ' s ' + @where + ');

                    SET IDENTITY_INSERT ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + ' OFF;' + CHAR(10);

                            

                    PRINT @command;

            END;

 

/*

    --Save the results to a table

    SELECT @command = 

    'INSERT dbo.#Data ([database], [schema], [table], [index], [columns], [cnt])

     SELECT '''

        + DB_NAME() + ''''

        + ',''' + @schema + ''''

        + ',''' + @table + ''''

        + ',''' + @index    + ''''

        + ',''' + @columns + ''''

        + ','        + CAST(@cnt AS sysname) + '';

    --PRINT @command;

    --EXEC (@command);

*/

 

    SELECT @command = '', @where = '';

    DELETE @cols;

 

 

    FETCH NEXT FROM cur INTO @schema, @table, @index, @columns, @ident;

    END;

CLOSE cur; DEALLOCATE cur;