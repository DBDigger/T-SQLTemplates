SELECT  
    CASE WHEN I.is_unique = 1 THEN ' UNIQUE ' ELSE '' END [Is_unique],   
    I.type_desc+' INDEX' IndexType,   
    I.name IndexName,   
    Schema_name(T.Schema_id)+'.'+T.name ObjectName,  
    KeyColumns,   
    IncludedColumns,   
    I.Filter_definition,   
    CASE WHEN I.is_padded = 1 THEN ' ON ' ELSE ' OFF ' END [PAD_INDEX],   
    I.Fill_factor,   
    ' OFF ' [SORT_IN_TEMPDB] , -- default value    
    CASE WHEN I.ignore_dup_key = 1 THEN ' ON ' ELSE ' OFF ' END [Ignore_dup_key],   
    CASE WHEN ST.no_recompute = 0 THEN ' OFF ' ELSE ' ON ' END [Stats_Recompute],   
    ' OFF ' [DROP_EXISTING] ,-- default value    
    ' OFF ' [ONLINE] , -- default value    
    CASE WHEN I.allow_row_locks = 1 THEN ' ON ' ELSE ' OFF ' END [Allow_row_locks],   
    CASE WHEN I.allow_page_locks = 1 THEN ' ON ' ELSE ' OFF ' END [Allow_page_locks] ,    
    CASE WHEN ST.auto_created = 0 THEN ' Not Automatically Created ' ELSE ' Automatically Created ' END [Statistics_Creation],   
    CASE WHEN I.is_primary_key = 1 THEN 'Yes' ELSE 'NO' END 'Part of PrimaryKey',   
    CASE WHEN I.is_unique_constraint = 1 THEN 'Yes' ELSE 'NO' END 'Part of UniqueKey',   
    CASE WHEN I.is_disabled = 1 THEN 'Disabled' ELSE 'Enabled' END IndexStatus,   
    CASE WHEN I.Is_hypothetical = 1 THEN 'Yes' ELSE 'NO' END Is_hypothetical,   
    CASE WHEN I.has_filter = 1 THEN 'Yes' ELSE 'NO' END 'Filtered Index',   
    DS.name [FilegroupName]   
FROM sys.indexes I   
 JOIN sys.tables T ON T.Object_id = I.Object_id    
 JOIN sys.sysindexes SI ON I.Object_id = SI.id AND I.index_id = SI.indid   
 JOIN (SELECT * FROM (  
    SELECT IC2.object_id , IC2.index_id ,  
        STUFF((SELECT ' , ' + C.name + CASE WHEN MAX(CONVERT(INT,IC1.is_descending_key)) = 1 THEN ' DESC ' ELSE ' ASC ' END 
    FROM sys.index_columns IC1  
    JOIN Sys.columns C   
       ON C.object_id = IC1.object_id   
       AND C.column_id = IC1.column_id   
       AND IC1.is_included_column = 0  
    WHERE IC1.object_id = IC2.object_id   
       AND IC1.index_id = IC2.index_id   
    GROUP BY IC1.object_id,C.name,index_id  
    ORDER BY MAX(IC1.key_ordinal)  
       FOR XML PATH('')), 1, 2, '') KeyColumns   
    FROM sys.index_columns IC2   
    --WHERE IC2.Object_id = object_id('Person.Address') --Comment for all tables  
    GROUP BY IC2.object_id ,IC2.index_id) tmp3 )tmp4   
  ON I.object_id = tmp4.object_id AND I.Index_id = tmp4.index_id  
 JOIN sys.stats ST ON ST.object_id = I.object_id AND ST.stats_id = I.index_id   
 JOIN sys.data_spaces DS ON I.data_space_id=DS.data_space_id   
 --JOIN sys.filegroups FG ON I.data_space_id=FG.data_space_id   
 LEFT JOIN (SELECT * FROM (   
    SELECT IC2.object_id , IC2.index_id ,   
        STUFF((SELECT ' , ' + C.name  
    FROM sys.index_columns IC1   
    JOIN Sys.columns C    
       ON C.object_id = IC1.object_id    
       AND C.column_id = IC1.column_id    
       AND IC1.is_included_column = 1   
    WHERE IC1.object_id = IC2.object_id    
       AND IC1.index_id = IC2.index_id    
    GROUP BY IC1.object_id,C.name,index_id   
       FOR XML PATH('')), 1, 2, '') IncludedColumns    
   FROM sys.index_columns IC2    
   --WHERE IC2.Object_id = object_id('Person.Address') --Comment for all tables   
   GROUP BY IC2.object_id ,IC2.index_id) tmp1   
   WHERE IncludedColumns IS NOT NULL ) tmp2    
ON tmp2.object_id = I.object_id AND tmp2.index_id = I.index_id   
--WHERE I.Object_id = object_id('Person.Address') --Comment for all tables 