set nocount on
 
declare @index table
(
      object_id int,
      objectName sysname,
      index_id int,
      indexName sysname,
      fill_factor tinyint,
      allow_row_locks bit,
      allow_page_locks bit,
      is_padded bit,
      indexText varchar(max),
      indexTextEnd varchar(max)
)
 
declare @indexColumn table
(
      object_id int,
      index_id int,
      column_id int,
      index_column_id int,
      max_index_column_id int,
      is_descending_key bit,
      is_included_column bit,
      columnName varchar(255),
      indexText varchar(max) null
)
 
insert into @index
select
      i.object_id,
      object_name(i.object_id),
      i.index_id,
      i.name,
      fill_factor,
      allow_row_locks,
      allow_page_locks,
      is_padded,
      'CREATE NONCLUSTERED INDEX [' + i.name + '] ON [dbo].[' + object_name(i.object_id) + '] ' + char(13),
      'WITH (PAD_INDEX = ' +
            CASE WHEN is_padded = 1 THEN ' ON ' ELSE ' OFF ' END +
            ', STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ' +
            CASE WHEN allow_row_locks = 1 THEN ' ON ' ELSE ' OFF ' END +
            ', ALLOW_PAGE_LOCKS = ' +
            CASE WHEN allow_page_locks = 1 THEN ' ON ' ELSE ' OFF ' END +
            CASE WHEN fill_factor > 0 THEN ', FILLFACTOR = ' + convert(varchar(3), fill_factor) ELSE '' END +
            ')' + CHAR(13)
from sys.indexes i
where i.type = 2 and i.is_unique_constraint = 0
and objectproperty(i.object_id , 'IsUserTable') = 1
order by object_name(i.object_id), i.name
 
insert into @indexColumn
select
      i.object_id,
      i.index_id,
      ic.column_id,
      ic.index_column_id,
      max(ic.index_column_id) over (partition by      i.object_id, i.index_id, is_included_column),
      is_descending_key,
      is_included_column,
      '[' + c.name + ']',
      null
from @index i
join sys.index_columns ic
on i.object_id = ic.object_id
and i.index_id = ic.index_id
join sys.columns c
on ic.object_id = c.object_id
and ic.column_id = c.column_id
order by i.object_id, i.index_id, ic.index_column_id
 
 
 
declare @fields varchar(max)
declare @object_id int, @index_id int
 
select @fields = null, @object_id = -1, @index_id = -1
 
update @indexColumn
set @fields = indexText =
      case when object_id = isnull(@object_id, object_id) and index_id = isnull(@index_id, index_id)
            then isnull(@fields + ', ', ' ') + columnName + case when is_descending_key = 0 then ' ASC' else ' DESC' end
            else columnName + case when is_descending_key = 0 then ' ASC' else ' DESC' end
            end,
      @object_id = case when object_id <> @object_id
            then object_id else @object_id end,
      @index_id = case when index_id <> @index_id
            then index_id else @index_id end
from @indexColumn
where is_included_column = 0
 
select @fields = null, @object_id = -1, @index_id = -1
 
update @indexColumn
set @fields = indexText =
      case when object_id = isnull(@object_id, object_id) and index_id = isnull(@index_id, index_id)
            then isnull(@fields + ', ', ' ') + columnName
            else columnName
            end,
      @object_id = case when object_id <> @object_id
            then object_id else @object_id end,
      @index_id = case when index_id <> @index_id
            then index_id else @index_id end
from @indexColumn
where is_included_column = 1
 
update @index
set indexText = i.indexText + '( ' + char(13) + char(9) + ic.indexText + char(13) + ') '
from @index i join @indexColumn ic
on i.object_id = ic.object_id
and i.index_id = ic.index_id
and ic.index_column_id = ic.max_index_column_id
and ic.is_included_column = 0
 
update @index
set indexText = i.indexText + 'INCLUDE ( ' + char(13) + char(9) + ic.indexText + char(13) + ') '
from @index i join @indexColumn ic
on i.object_id = ic.object_id
and i.index_id = ic.index_id
and ic.index_column_id = ic.max_index_column_id
and ic.is_included_column = 1
 
update @index
set indexText = indexText + indexTextEnd
from @index
 
select indexText
--, objectName, indexName 
from @index 
-------------------------------------------------------------------------------------------------

USE AdventureWorks2012   
GO   
     
SELECT ' CREATE ' + 
    CASE WHEN I.is_unique = 1 THEN ' UNIQUE ' ELSE '' END  +  
    I.type_desc COLLATE DATABASE_DEFAULT +' INDEX ' +   
    I.name  + ' ON '  +  
    Schema_name(T.Schema_id)+'.'+T.name + ' ( ' + 
    KeyColumns + ' )  ' + 
    ISNULL(' INCLUDE ('+IncludedColumns+' ) ','') + 
    ISNULL(' WHERE  '+I.Filter_definition,'') + ' WITH ( ' + 
    CASE WHEN I.is_padded = 1 THEN ' PAD_INDEX = ON ' ELSE ' PAD_INDEX = OFF ' END + ','  + 
    'FILLFACTOR = '+CONVERT(CHAR(5),CASE WHEN I.Fill_factor = 0 THEN 100 ELSE I.Fill_factor END) + ','  + 
    -- default value 
    'SORT_IN_TEMPDB = OFF '  + ','  + 
    CASE WHEN I.ignore_dup_key = 1 THEN ' IGNORE_DUP_KEY = ON ' ELSE ' IGNORE_DUP_KEY = OFF ' END + ','  + 
    CASE WHEN ST.no_recompute = 0 THEN ' STATISTICS_NORECOMPUTE = OFF ' ELSE ' STATISTICS_NORECOMPUTE = ON ' END + ','  + 
    -- default value  
    ' DROP_EXISTING = ON '  + ','  + 
    -- default value  
    ' ONLINE = OFF '  + ','  + 
   CASE WHEN I.allow_row_locks = 1 THEN ' ALLOW_ROW_LOCKS = ON ' ELSE ' ALLOW_ROW_LOCKS = OFF ' END + ','  + 
   CASE WHEN I.allow_page_locks = 1 THEN ' ALLOW_PAGE_LOCKS = ON ' ELSE ' ALLOW_PAGE_LOCKS = OFF ' END  + ' ) ON [' + 
   DS.name + ' ] '  [CreateIndexScript] 
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
 JOIN sys.filegroups FG ON I.data_space_id=FG.data_space_id   
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
WHERE I.is_primary_key = 0 AND I.is_unique_constraint = 0 
--AND I.Object_id = object_id('Person.Address') --Comment for all tables 
--AND I.name = 'IX_Address_PostalCode' --comment for all indexes 
 