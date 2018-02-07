-- Tables in a Schema 
DECLARE @schema SYSNAME;
SET @schema = N'some_schema';

SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE s.name = @schema;





-- Tables without primary key
SELECT [table] = s.name + N'.' + t.name 
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE NOT EXISTS
  (
    SELECT 1 FROM sys.key_constraints AS k
      WHERE k.[type] = N'PK'
      AND k.parent_object_id = t.[object_id]
  );


  -- Tables without unique key constraints
  SELECT [table] = s.name + N'.' + t.name 
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE NOT EXISTS
  (
    SELECT 1 FROM sys.key_constraints AS k
      WHERE k.[type] = N'UQ'
      AND k,parent_object_id = t.[object_id]
  );


  -- Tables without a clustered index 
  SELECT [table] = s.name + N'.' + t.name 
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE NOT EXISTS
  (
    SELECT 1 FROM sys.indexes AS i
      WHERE i.[object_id] = t.[object_id]
      AND i.index_id = 1
  );



  --  heaps with Forwarded Record Count > % of the Table
  DECLARE @percentage DECIMAL(5,2), @min_row_count INT;
SELECT @percentage = 10, @min_row_count = 1000;

;WITH x([table], [fwd_%]) AS 
(
  SELECT s.name + N'.' + t.name, CONVERT(DECIMAL(5,2), 100 * CONVERT(DECIMAL(18,2), 
      SUM(ps.forwarded_record_count)) / NULLIF(SUM(ps.record_count),0))
    FROM sys.tables AS t
    INNER JOIN sys.schemas AS s
    ON t.[schema_id] = s.[schema_id]
    INNER JOIN sys.indexes AS i
    ON t.[object_id] = i.[object_id]
    CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), 
      t.[object_id], i.index_id, NULL, N'DETAILED') AS ps
    WHERE i.index_id = 0
    AND EXISTS
    (
      SELECT 1 FROM sys.partitions AS p
        WHERE p.[object_id] = t.[object_id]
        AND p.index_id = 0 -- heap
        GROUP BY p.[object_id]
        HAVING SUM(p.[rows]) >= @min_row_count
    )
    AND ps.record_count >= @min_row_count
    AND ps.forwarded_record_count IS NOT NULL
    GROUP BY s.name, t.name
)
SELECT [table], [fwd_%]
  FROM x
  WHERE [fwd_%] > @percentage
  ORDER BY [fwd_%] DESC;




  -- Tables without an Identity Column
SELECT [table] = s.name + N'.' + t.name 
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE NOT EXISTS
  (
    SELECT 1 FROM sys.identity_columns AS i
      WHERE i.[object_id] = t.[object_id]
  );



  -- Tables with at Least two Triggers
  DECLARE @min_count INT;
SET @min_count = 2;

SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.triggers AS tr
      WHERE tr.parent_id = t.[object_id]
      GROUP BY tr.parent_id
      HAVING COUNT(*) >= @min_count
  );


  -- Tables with disabled trigger
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS 
  (
    SELECT 1 FROM sys.triggers AS tr
      WHERE tr.parent_id = t.[object_id]
      AND tr.is_disabled = 1
  );


  -- Tables with instead of triggers
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS 
  (
    SELECT 1 FROM sys.triggers AS tr
      WHERE tr.parent_id = t.[object_id]
      AND tr.is_disabled = 1
  );



  -- Tables with more than  columns
  DECLARE @threshold INT;
SET @threshold = 20;

;WITH c([object_id], [column count]) AS
(
  SELECT [object_id], COUNT(*)
    FROM sys.columns
    GROUP BY [object_id]
    HAVING COUNT(*) > @threshold
)
SELECT [table] = s.name + N'.' + t.name,
    c.[column count]
  FROM c
  INNER JOIN sys.tables AS t
  ON c.[object_id] = t.[object_id]
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  ORDER BY c.[column count] DESC;



  -- Tables with atleast one column name matching to pattern
  DECLARE @pattern NVARCHAR(128);
SET @pattern = N'%pattern%';

SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.columns AS c
      WHERE c.[object_id] = t.[object_id]
      AND LOWER(c.name) LIKE LOWER(@pattern)
      -- LOWER() due to potential case sensitivity
  );



  -- Tables with at least one xml column
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.columns AS c
      WHERE c.[object_id] = t.[object_id]
      AND c.system_type_id = 241 -- 241 = xml
  );



  -- Tables with atleast one BLOB column
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.columns AS c
      WHERE c.[object_id] = t.[object_id]
      AND c.max_length = -1
      AND c.system_type_id IN 
      (
        165, -- varbinary
        167, -- varchar
        231  -- nvarchar
      )
  );




  -- Tables with atleast one text/ntext/image column
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.columns AS c
      WHERE c.[object_id] = t.[object_id]
      AND c.system_type_id IN 
      (
        34, -- image
        35, -- text
        99  -- ntext
      )
  );




  -- Tables with atleast one alias type column
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.columns AS c
      INNER JOIN sys.types AS typ
      ON c.system_type_id = typ.system_type_id
      AND c.user_type_id = typ.user_type_id
      WHERE c.[object_id] = t.[object_id]
      AND typ.is_user_defined = 1
      -- AND type.name = N'something'



-- Tables with FKeys referencing other tables
SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.foreign_keys AS fk
      WHERE fk.parent_object_id = t.[object_id]
  );



  -- Tables with Foreign Keys that Reference a Specific Table
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.foreign_keys AS fk
      INNER JOIN sys.tables AS pt -- "parent table"
      ON fk.referenced_object_id = pt.[object_id]
      INNER JOIN sys.schemas AS ps
      ON pt.[schema_id] = ps.[schema_id]
      WHERE fk.parent_object_id = t.[object_id]
      AND ps.name = N'schema_name'
      AND pt.name = N'table_name'
  );



  -- Tables Referenced by Foreign Keys
SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.foreign_keys AS fk
      WHERE fk.referenced_object_id = t.[object_id]
  );



  -- Tables with Foreign Keys that Cascade
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.foreign_keys AS fk
      WHERE fk.parent_object_id = t.[object_id]
      AND (fk.delete_referential_action = 1 
       OR  fk.update_referential_action = 1)
  )


  --tables Referenced by Foreign Keys that Cascade
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.foreign_keys AS fk
      WHERE fk.referenced_object_id = t.[object_id]
      AND fk.delete_referential_action 
        + fk.update_referential_action > 0
  );



  -- Tables with disabled FKeys
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.foreign_keys AS fk
      WHERE fk.parent_object_id = t.[object_id]
      AND fk.is_disabled = 1
  );


  -- Tables with Untrusted Foreign Keys
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.foreign_keys AS fk
      WHERE fk.parent_object_id = t.[object_id]
      AND fk.is_not_trusted = 1
  );


  -- Tables with Self-Referencing Foreign Keys
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.foreign_keys AS fk
      WHERE fk.parent_object_id = t.[object_id]
      AND fk.referenced_object_id = t.[object_id]
  );


  -- Tables with Disabled Indexes
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.indexes AS i
      WHERE i.[object_id] = t.[object_id]
      AND i.is_disabled = 1
  );



  -- Tables with Hypothetical Indexes
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.indexes AS i
      WHERE i.[object_id] = t.[object_id]
      AND i.is_hypothetical = 1
  );


  -- Tables with Filtered Indexes
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.indexes AS i
      WHERE i.[object_id] = t.[object_id]
      AND i.has_filter = 1
  );


  -- Tables with More Than Five Indexes
  DECLARE @threshold INT;
SET @threshold = 5;

SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.indexes AS i
      WHERE i.[object_id] = t.[object_id]
      GROUP BY i.[object_id]
      HAVING COUNT(*) > @threshold
  );


  -- Tables with More Than One Index with the Same Leading Key Column
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1
      FROM sys.indexes AS i
      INNER JOIN sys.index_columns AS ic1
      ON i.[object_id] = ic1.[object_id]
      AND i.index_id = ic1.index_id
      INNER JOIN sys.index_columns AS ic2
      ON i.[object_id] = ic2.[object_id]
      AND ic1.index_column_id = ic2.index_column_id
      AND ic1.column_id = ic2.column_id
      AND ic1.is_descending_key = ic2.is_descending_key
      AND ic1.index_id <> ic2.index_id
      WHERE i.[type] IN (0,1,2) -- heap, cix, ncix
      AND ic1.index_column_id = 1
      AND ic2.index_column_id = 1
      AND i.[object_id] = t.[object_id]
      GROUP BY i.[object_id]
      HAVING COUNT(*) > 1
  );


  -- Tables with Duplicate Indexes
  http://www.jasonstrate.com/2013/03/thats-actually-a-duplicate-index/

  -- Tables with a Default or Check Constraint
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.default_constraints AS d
      WHERE d.parent_object_id = t.[object_id]
    UNION ALL
    SELECT 1 FROM sys.check_constraints AS c
      WHERE c.parent_object_id = t.[object_id]
  );


  -- Tables with a Default or Check Constraint Pointed at a UDF
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.sql_expression_dependencies AS d
      INNER JOIN sys.default_constraints AS dc
      ON dc.[object_id] = d.referencing_id
      INNER JOIN sys.objects AS udfs
      ON d.referenced_id = udfs.[object_id]
      WHERE dc.parent_object_id = t.[object_id]
      AND udfs.[type] = 'FN'
    UNION ALL
    SELECT 1 FROM sys.sql_expression_dependencies AS d
      INNER JOIN sys.check_constraints AS c
      ON c.[object_id] = d.referencing_id
      INNER JOIN sys.objects AS udfs
      ON d.referenced_id = udfs.[object_id]
      WHERE c.parent_object_id = t.[object_id]
      AND udfs.[type] = 'FN'
	  -- http://sqlblog.com/blogs/tibor_karaszi/archive/2009/12/17/be-careful-with-constraints-calling-udfs.aspx
	  -- http://sqlblogcasts.com/blogs/tonyrogerson/archive/2008/02/07/using-a-udf-in-a-check-constraint-to-check-validity-of-history-windows-start-end-date-windows.aspx
	  -- http://sqlblog.com/blogs/alexander_kuznetsov/archive/2009/07/01/when-check-constraints-using-udfs-fail-for-multirow-updates.aspx
	  -- http://sqlblog.com/blogs/alexander_kuznetsov/archive/2009/06/25/scalar-udfs-wrapped-in-check-constraints-are-very-slow-and-may-fail-for-multirow-updates.aspx

  );



  -- Tables with at least One Untrusted Check Constraint
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.check_constraints AS c
      WHERE c.parent_object_id = t.[object_id]
        AND c.is_not_trusted = 1
  );


  -- Tables with at least One System-Named Constraint
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  WHERE EXISTS
  (
    SELECT 1 FROM sys.foreign_keys AS fk
      WHERE fk.parent_object_id = t.[object_id]
      AND fk.is_system_named = 1
    UNION ALL
    SELECT 1 FROM sys.key_constraints AS k
      WHERE k.parent_object_id = t.[object_id]
      AND k.is_system_named = 1
    UNION ALL
    SELECT 1 FROM sys.default_constraints AS d
      WHERE d.parent_object_id = t.[object_id]
      AND d.is_system_named = 1
    UNION ALL
    SELECT 1 FROM sys.check_constraints AS c
      WHERE c.parent_object_id = t.[object_id]
      AND c.is_system_named = 1
  );


  --  Tables with More (or Less) Than X Rows
  DECLARE @threshold INT;
SET @threshold = 100000;

SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.partitions AS p
      WHERE p.[object_id] = t.[object_id]
        AND p.index_id IN (0,1)
      GROUP BY p.[object_id]
      HAVING SUM(p.[rows]) > @threshold
  );


  

  -- 
  -- Tables Referenced Directly by at least one View
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.tables AS st
      INNER JOIN sys.schemas AS ss
      ON st.[schema_id] = ss.[schema_id]
      CROSS APPLY sys.dm_sql_referencing_entities
        (QUOTENAME(ss.name) + N'.' + QUOTENAME(st.name), 
         N'OBJECT') AS r
      INNER JOIN sys.views AS v
      ON v.[object_id] = r.referencing_id
      INNER JOIN sys.schemas AS vs
      ON v.[schema_id] = vs.[schema_id]
      WHERE st.[object_id] = t.[object_id]
  );

  -- Tables Referenced Directly by at least one Indexed View
  SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT * FROM sys.tables AS st
      INNER JOIN sys.schemas AS ss
      ON st.[schema_id] = ss.[schema_id]
      CROSS APPLY sys.dm_sql_referencing_entities
        (QUOTENAME(ss.name) + N'.' + QUOTENAME(st.name), 
         N'OBJECT') AS r
      INNER JOIN sys.views AS v
      ON v.[object_id] = r.referencing_id
      INNER JOIN sys.schemas AS vs
      ON v.[schema_id] = vs.[schema_id]
      INNER JOIN sys.indexes AS i
      ON v.[object_id] = i.[object_id]
      WHERE i.index_id = 1
      AND st.[object_id] = t.[object_id]
    );



	-- Tables Referenced Directly by at least one View that uses SELECT *
	SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.tables AS st
      INNER JOIN sys.schemas AS ss
      ON st.[schema_id] = ss.[schema_id]
      CROSS APPLY sys.dm_sql_referencing_entities
        (QUOTENAME(ss.name) + N'.' + QUOTENAME(st.name), 
         N'OBJECT') AS r1
      INNER JOIN sys.views AS v
      ON v.[object_id] = r1.referencing_id
      INNER JOIN sys.schemas AS vs
      ON v.[schema_id] = vs.[schema_id]
      CROSS APPLY sys.dm_sql_referenced_entities
        (QUOTENAME(vs.name) + N'.' + QUOTENAME(v.name), 
         N'OBJECT') AS r2
      WHERE r2.is_select_all = 1
      AND st.[object_id] = t.[object_id]
    );


	-- tables Referenced Directly by Schema-Bound Objects
	SELECT [table] = s.name + N'.' + t.name
  FROM sys.tables AS t
  INNER JOIN sys.schemas AS s
  ON t.[schema_id] = s.[schema_id]
  WHERE EXISTS
  (
    SELECT 1 FROM sys.tables AS st
      INNER JOIN sys.schemas AS ss
      ON st.[schema_id] = ss.[schema_id]
      CROSS APPLY sys.dm_sql_referencing_entities
        (QUOTENAME(ss.name) + N'.' + QUOTENAME(st.name), 
         N'OBJECT') AS r
      INNER JOIN sys.objects AS o
      ON o.[object_id] = r.referencing_id
      INNER JOIN sys.sql_modules AS m
      ON o.[object_id] = m.[object_id]
      WHERE m.is_schema_bound = 1
      AND st.[object_id] = t.[object_id]
  );


  -- Tables Referenced by local Synonyms
  DECLARE @sql NVARCHAR(MAX), @exec NVARCHAR(MAX);

SELECT @sql = N'', @exec = QUOTENAME(DB_NAME()) + N'.sys.sp_executesql';

SELECT @sql = @sql + N'
UNION ALL SELECT [database] = N''' + REPLACE(db.name, '''', '''''') 
  + ''', [synonym] = syn.name, points_to = syn.base_object_name' 
  + N' FROM ' + QUOTENAME(db.name) + N'.sys.synonyms AS syn
  WHERE PARSENAME(syn.base_object_name, 3) = DB_NAME()
  AND COALESCE(PARSENAME(syn.base_object_name, 4), @srv) = @srv
  AND EXISTS 
  (
    SELECT 1 FROM sys.tables AS t 
    INNER JOIN sys.schemas AS s
    ON t.[schema_id] = s.[schema_id]
    WHERE t.name = PARSENAME(syn.base_object_name, 1)
    AND s.name = PARSENAME(syn.base_object_name, 2)
  )'
FROM sys.databases AS db WHERE [state] = 0;

SET @sql = STUFF(@sql, 1, 11, N'');

EXEC @exec @sql, N'@srv SYSNAME', @srv = @@SERVERNAME;