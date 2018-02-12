--ALTER PARTITION FUNCTION fn_myPartitionRange() MERGE RANGE (2017090100)


-- Note number of rows in source table
select schema_name(o.schema_id)+'.'+o.name as TablesWithColumnstoreIndex , sum(si.rowcnt) as NoOfRows
from sys.objects o 
inner join sysindexes si on o.object_id = si.id
inner join sys.indexes i on o.object_id = i.object_id
and i.type = 5
group by schema_name(o.schema_id)+'.'+o.name
order by NoOfRows desc 




-- Generate create TMP tables commands
select 'SELECT * INTO   '+schema_name(o.schema_id)+'.TMP_'+object_name(o.object_id) + ' FROM  ' + schema_name(o.schema_id)+'.'+object_name(o.object_id)+' WHERE 1 = 0;' --DISABLE REBUILD
from sys.indexes i inner join sys.objects o on i.object_id = o.object_id 
where i.type  > = 4
 --and object_name(o.object_id)  like 'TMP%'
order by 1


-- Create CC Indexes
select 'CREATE CLUSTERED COLUMNSTORE INDEX  TMP_'+ i.name+ ' ON '+ schema_name(o.schema_id)+'.TMP_'+object_name(o.object_id)+' WITH (DROP_EXISTING = OFF, DATA_COMPRESSION = COLUMNSTORE) ON ASI2017_M9_PARTITIONS;'
from sys.indexes i inner join sys.objects o on i.object_id = o.object_id 
where i.type  > = 4
and object_name(o.object_id) not like 'TMP%'
order by 1
GO


---- DROP CC indexes
--select 'DROP INDEX  TMP_'+ i.name+ ' ON '+ schema_name(o.schema_id)+'.TMP_'+object_name(o.object_id)+';'
--from sys.indexes i inner join sys.objects o on i.object_id = o.object_id 
--where i.type  > = 4
--and object_name(o.object_id) not like 'TMP%'
--order by 1
--GO


-- Generate constraints for TMP tables
select 'ALTER TABLE  '+schema_name(o.schema_id)+'.'+object_name(o.object_id) + ' WITH CHECK ADD CONSTRAINT '+  'CNSTRNT_'+object_name(o.object_id)+ ' CHECK (PART_YYYYMMDDHH >= 2017080100 );'
from sys.indexes i inner join sys.objects o on i.object_id = o.object_id 
where i.type  > = 4
 and object_name(o.object_id)  like 'TMP%'
order by 1


-- Partition switch commands
select 'ALTER TABLE '+  schema_name(o.schema_id)+'.'+object_name(o.object_id)+' SWITCH PARTITION 117 to '+schema_name(o.schema_id)+'.TMP_'+object_name(o.object_id)+ ';'
from sys.indexes i inner join sys.objects o on i.object_id = o.object_id 
where i.type  > = 4
 and object_name(o.object_id) not like 'TMP%'
order by 1
GO

Alter partition scheme psBI_Data_StagingPartitionsByMonth NEXT USED ASI2017_M10_PARTITIONS;  
ALTER PARTITION FUNCTION fn_myPartitionRange() SPLIT RANGE (2017090100);

-- Generate constraints modification
select 'ALTER TABLE  '+schema_name(o.schema_id)+'.'+object_name(o.object_id) + ' WITH CHECK ADD CONSTRAINT '+  'CNSTRNT11_'+object_name(o.object_id)+ ' CHECK ( PART_YYYYMMDDHH < 2017090100  );'
from sys.indexes i inner join sys.objects o on i.object_id = o.object_id 
where i.type  > = 4
 and object_name(o.object_id)  like 'TMP%'
order by 1


-- Switch back
select 'ALTER TABLE '+  schema_name(o.schema_id)+'.TMP_'+object_name(o.object_id)+' SWITCH to '+schema_name(o.schema_id)+'.'+object_name(o.object_id)+ ' Partition  117;'
from sys.indexes i inner join sys.objects o on i.object_id = o.object_id 
where i.type  > = 4
 and object_name(o.object_id) not like 'TMP%'
order by 1
GO


-- Verify no of row in TMP tables and DROP
SELECT	'DROP Table  '+  schema_name(o.schema_id)+'.'+object_name(o.object_id)+' ;',
	i.rows AS [RowCount]
FROM	sys.objects o
JOIN	sysindexes i	ON o.object_id = i.id
WHERE	schema_name(o.schema_id)+'.'+object_name(o.object_id) in (
select  schema_name(schema_id)+'.'+object_name(object_id)
from sys.objects where type =  'U' and name like 'TMP%')
order by 2 desc


