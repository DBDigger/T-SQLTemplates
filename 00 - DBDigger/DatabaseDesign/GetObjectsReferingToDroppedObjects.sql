SELECT so.name  'ObjectName' 
      ,so.type  'Objecttype' 
      ,Ssqldep.referenced_entity_name 'Dropped Object Name' 
  FROM sys.sql_expression_dependencies Ssqldep 
  JOIN sys.objects so 
    ON so.object_id = Ssqldep.referencing_id 
 WHERE Ssqldep.referenced_id IS NULL  
   AND Ssqldep.referenced_server_name IS NULL 
   AND Ssqldep.referenced_database_name IS NULL 
   AND Ssqldep.referenced_schema_name IS NULL 
   AND so.name <> Ssqldep.referenced_entity_name 