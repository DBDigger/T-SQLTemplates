/*--------------------------------------------------------------------------------- 
The sample scripts are not supported under any Microsoft standard support program or service 
and are intented as a supplement to online documentation.The sample scripts are provided AS IS without warranty 
of any kind either expressed or implied. Microsoft further disclaims all implied warranties including, 
without limitation, any implied warranties of merchantability or of fitness for a particular purpose.
#--------------------------------------------------------------------------------- */
 
 /*
 Rebuild index statement is printed at partition level if
  a. RGQualityMeasure is not met for @PercentageRGQualityPassed Rowgroups 
    -- this is an arbitrary number, what we are saying is that if the average is above this number, don't bother rebuilding as we consider this number to be good quality rowgroups
 b. Second constraint is the Deleted rows, currently the default that is set am setting is 10% of the partition itself. If the partition is very large or small consider adjusting this
 c. In SQL 2014, post index rebuild,the dmv doesn't show why the RG is trimmed to < 1 million in this case in SQL 2014. 
   - If the Dictionary is full ( 16MB) then no use in rebuilding this rowgroup as even after rebuild it may get trimmed
   - If dictionary is full only rebuild if deleted rows falls above the threshold
  */

 if object_id('tempdb..#temp') IS NOT NULL
 drop table #temp
 go
 
 Declare @DeletedRowsPercent Decimal(5,2)
 -- Debug = 1 if you need all rowgroup information regardless
 Declare @Debug int =0
 -- Percent of deleted rows for the partition
 Set @DeletedRowsPercent = 10   
 -- RGQuality means we are saying anything over 500K compressed is good row group quality, anything less need to re-evaluate.
 Declare @RGQuality int = 500000 
 -- means 50% of rowgroups are < @RGQUality from the rows/rowgroup perspective 
 Declare @PercentageRGQualityPassed smallint = 20  
 ;WITH CSAnalysis
 ( object_id,TableName,index_id,partition_number,CountRGs,TotalRows,
  AvgRowsPerRG,CountRGLessThanQualityMeasure,RGQualityMeasure,PercentageRGLessThanQualityMeasure
  ,DeletedRowsPercent,NumRowgroupsWithDeletedRows)
 AS
 (SELECT object_id,object_name(object_id) as TableName, index_id,
  rg.partition_number,count(*) as CountRGs, sum(total_rows) as TotalRows, Avg(total_rows) as AvgRowsPerRG,
  SUM(CASE WHEN rg.Total_Rows <@RGQuality THEN 1 ELSE 0 END) as CountRGLessThanQualityMeasure, @RGQuality as RGQualityMeasure,
  cast((SUM(CASE WHEN rg.Total_Rows <@RGQuality THEN 1.0 ELSE 0 END)/count(*) *100)  as Decimal(5,2))  as PercentageRGLessThanQualityMeasure,
  Sum(rg.deleted_rows * 1.0)/sum(rg.total_rows *1.0) *100 as 'DeletedRowsPercent',
  sum (case when rg.deleted_rows >0 then 1 else 0 end ) as 'NumRowgroupsWithDeletedRows'
  FROM  sys.column_store_row_groups rg  
  where rg.state = 3 
  group by rg.object_id, rg.partition_number,index_id
),
CSDictionaries  --(maxdictionarysize int,maxdictentrycount int,[object_id] int, partition_number int)
 AS
 (   select max(dict.on_disk_size) as maxdictionarysize, max(dict.entry_count) as maxdictionaryentrycount
  ,max(partition_number) as maxpartition_number,part.object_id, part.partition_number
  from sys.column_store_dictionaries dict
  join sys.partitions part on dict.hobt_id = part.hobt_id
  group by part.object_id, part.partition_number
) 
 select a.*,b.maxdictionarysize,b.maxdictionaryentrycount,maxpartition_number 
 into #temp from CSAnalysis a
 inner join CSDictionaries b
 on a.object_id = b.object_id and a.partition_number = b.partition_number

 
-- Maxdop Hint optionally added to ensure we don't spread small amount of rows accross many threads
-- IF we do that, we may end up with smaller rowgroups anyways.
 declare @maxdophint smallint, @effectivedop smallint  
 -- True if running from the same context that will run the rebuild index.
 select @effectivedop=effective_max_dop from sys.dm_resource_governor_workload_groups
 where group_id in (select group_id from sys.dm_exec_requests where session_id = @@spid)
 
 -- Get the Alter Index Statements.
  select 'Alter INDEX ' + QuoteName(IndexName) + ' ON ' + QuoteName(TableName) + '  REBUILD ' +
 Case 
 when maxpartition_number = 1 THEN ' '
 else  ' PARTITION = ' + cast(partition_number as varchar(10)) 
 End
  + ' WITH (MAXDOP ='  + cast((Case  WHEN (TotalRows*1.0/1048576) < 1.0 THEN 1 WHEN (TotalRows*1.0/1048576) < @effectivedop THEN  FLOOR(TotalRows*1.0/1048576) ELSE 0 END) as varchar(10)) + ')'
 as Command
 from #temp a
 inner join
 ( select object_id,index_id,Name as IndexName from sys.indexes
    where type in ( 5,6) -- non clustered columnstore and clustered columnstore
 ) as b
on b.object_id = a.object_id and a.index_id = b.index_id
where ( DeletedRowsPercent >= @DeletedRowsPercent)
-- Rowgroup Quality trigger, percentage less than rowgroup quality as long as dictionary is not full
 OR ( ( ( AvgRowsPerRG < @RGQuality and TotalRows > @RGQuality) AND PercentageRGLessThanQualityMeasure>= @PercentageRGQualityPassed)
  AND maxdictionarysize < ( 16*1000*1000)) -- DictionaryNotFull, lower threshold than 16MB.
 order by TableName,a.index_id,a.partition_number

-- Debug print if needed
if @Debug=1
  Select getdate() as DiagnosticsRunTime,* from #temp
  order by TableName,index_id,partition_number
else
  Select getdate() as DiagnosticsRunTime,* from #temp
  -- Deleted rows trigger
  where ( DeletedRowsPercent >= @DeletedRowsPercent)
  -- Rowgroup Quality trigger, percentage less than rowgroup quality as long as dictionary is not full
  OR ( ( ( AvgRowsPerRG < @RGQuality and TotalRows > @RGQuality) AND PercentageRGLessThanQualityMeasure>= @PercentageRGQualityPassed)
  AND maxdictionarysize < ( 16*1000*1000)) -- DictionaryNotFull, lower threshold than 16MB.
  order by TableName,index_id,partition_number
-- Add logic to actually run those statements
