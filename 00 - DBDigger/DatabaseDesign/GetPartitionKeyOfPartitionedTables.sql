CREATE PROC sp_GetPartitionKey(@TableName Sysname)  
AS  
SELECT   
    t.object_id  Object_ID,  
    t.name  TableName,  
    ic.column_id  PartitioningColumnID,   
    c.name  PartitioningColumnName   
FROM sys.tables t  
    INNER JOIN sys.indexes i   
        ON i.object_id = t.object_id   
    INNER JOIN sys.index_columns ic  
        ON ic.index_id = i.index_id   
            AND ic.object_id = t.object_id  
    INNER JOIN sys.columns c  
        ON c.object_id = ic.object_id   
            AND c.column_id = ic.column_id  
WHERE t.object_id  = object_id(@TableName)AND   
    ic.partition_ordinal = 1