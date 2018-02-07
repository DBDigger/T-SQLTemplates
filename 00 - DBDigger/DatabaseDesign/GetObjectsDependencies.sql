-- Transact-SQL Statement to list all objects and their dependencies (SQL Server 2008). 
SELECT SCH.name + '.' + OBJ.name AS ObjectName 
      ,OBJ.type_desc AS ObjectType 
      ,COL.name AS ColumnName 
      ,DEP.referenced_database_name AS ReferencedDatabase 
      ,REFSCH.name + '.' + REFOBJ.name AS ReferencedObjectName 
      ,REFOBJ.type_desc AS ReferencedObjectType 
      ,REFCOL.name AS ReferencedColumnName       
      ,DEP.referencing_class_desc AS ReferenceClass 
      ,DEP.is_schema_bound_reference AS IsSchemaBound 
FROM sys.sql_expression_dependencies AS DEP 
     INNER JOIN 
     sys.objects AS OBJ 
         ON DEP.referencing_id = OBJ.object_id 
     INNER JOIN 
     sys.schemas AS SCH 
         ON OBJ.schema_id = SCH.schema_id 
     LEFT JOIN sys.columns AS COL 
         ON DEP.referencing_id = COL.object_id 
            AND DEP.referencing_minor_id = COL.column_id 
     INNER JOIN sys.objects AS REFOBJ 
         ON DEP.referenced_id = REFOBJ.object_id 
     INNER JOIN sys.schemas AS REFSCH 
         ON REFOBJ.schema_id = REFSCH.schema_id 
     LEFT JOIN sys.columns AS REFCOL 
         ON DEP.referenced_class IN (0, 1) 
            AND DEP.referenced_minor_id = REFCOL.column_id 
            AND DEP.referenced_id = REFCOL.object_id 
ORDER BY ObjectName 
        ,ReferencedObjectName 
        ,REFCOL.column_id 