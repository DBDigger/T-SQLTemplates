/*
When the stat parser hangs on 43 and we resume from the next file, we end up with missed stats in ASI_StatsRaw. To help keep downstream impact to a minimum, please use the attached script to generate a restatement script. The generated script should be run after the parser starts to process the next file.

You will need to set the from/to variables at the beginning of the script to include the hour before the failed file and the hour of the failed file. So if the parser hangs on the file for 2018020613, you will need to set the [from variable] = 2018020612 and the [to variable] = 2018020613. Do not change the minutes for action_dt variables, just the hour part. 

It will output the statements needed to delete the partial data currently in the stat table and copy the stats for the period specified from StatsStgArea_02. The output will contain 1 row per table being processed. It is ok to run all the statements together and should take about 20 mins for restatement to complete.

*/
declare @part_yyyymmddhh_from varchar(20), @part_yyyymmddhh_to varchar(20)
declare @action_dt_from varchar(25),@action_dt_to varchar(25)

set @part_yyyymmddhh_from='2018020512'
set @part_yyyymmddhh_to='2018020514'
set @action_dt_from = '2018-02-05 12:00:00.000'
set @action_dt_to = '2018-02-05 14:59:59.997'

if(object_id('tempdb.dbo.#tmp') is not null) drop table #tmp;
create table #tmp(
       id int identity(1,1)
       ,OLD_DatabaseNM varchar(128)
       ,OLD_SchemaNM varchar(128)
       ,OLD_TableNM varchar(128)
       ,NEW_DatabaseNM varchar(128)
       ,NEW_SchemaNM varchar(128)
       ,NEW_TableNM varchar(128)
       ,OLD_IsPartitioned char(1)
);

insert into #tmp(
       OLD_DatabaseNM 
       ,OLD_SchemaNM 
       ,OLD_TableNM 
       ,NEW_DatabaseNM  
       ,NEW_SchemaNM  
       ,NEW_TableNM  
       ,OLD_IsPartitioned  
)

select 
        SRC_DatabaseNM 
       ,SRC_SchemaNM 
       ,SRC_TableNM 
       ,DST_DatabaseNM  
       ,DST_SchemaNM  
       ,b.DST_TableNM  
       ,b.SRC_IsPartitioned  
       --select *
from ASI_StatsRaw.sys.objects a
inner join ADM_Support.dbo.META_LOAD_ASI_StatsRaw_02 b on a.name = b.DST_TableNM
where b.DST_TableNM  not in ('STAT_MONY01', 'STAT_APRR14')
order by 1 


declare @tables table(
  Table_ID int identity(1,1),
  Database_NM varchar(50),
  Schema_NM varchar(50),
  Table_NM varchar(50)
);

declare @columns table(
  Column_id int identity(1,1)
  ,Table_ID int
  ,ColumnList varchar(max)
);

insert into @tables (
  Database_NM
  ,Schema_NM
  ,Table_NM
)
select
  'ASI_StatsRaw' as Database_NM
  ,'dbo' as Schema_NM
  ,t.name as Table_NM
from ASI_StatsRaw.sys.tables t
  inner join ADM_Support.dbo.META_LOAD_ASI_StatsRaw_02 b on t.name = b.DST_TableNM
where t.name not in ('STAT_MONY01', 'STAT_APRR14')

insert into @tables (
  Database_NM
  ,Schema_NM
  ,Table_NM
)
select
  'StatsStgArea_02' as Database_NM
  ,'dbo' as Schema_NM
  ,t.name as Table_NM
from StatsStgArea_02.sys.tables t
  inner join ADM_Support.dbo.META_LOAD_ASI_StatsRaw_02 b on t.name = b.DST_TableNM
where t.name not in ('STAT_MONY01', 'STAT_APRR14')

insert into @columns (Table_ID, ColumnList)
select 
  t.Table_ID
  ,stuff((
        select
          ','+'['+pc.name+']'+char(10)
        from ASI_StatsRaw.sys.tables pt
          inner join ASI_StatsRaw.sys.columns pc
            on pc.object_id = pt.object_id
          left outer join (select
                        t.name table_nm, c.name column_nm, c.column_id
                      from StatsStgArea_02.sys.tables t
                        inner join StatsStgArea_02.sys.columns c
                          on c.object_id = t.object_id) x
            on x.table_nm = pt.name and (x.column_nm = pc.name)
        where t.Table_NM = pt.name 
              and pc.name <> 'STAT_ID'
              and (x.column_nm is not null or pc.name in ('XML_ID', 'SourceServer_NM', 'APPL_CD', 'Source_CreateDate'))
        order by pc.column_id
        for xml path('')),1,1,'') as columnList
from @tables t
where t.Database_NM = 'ASI_StatsRaw'
group by t.Table_ID, t.Table_NM

insert into @columns (Table_ID, ColumnList)
select 
  t.Table_ID
  ,stuff((
        select --pt.name,
          ','+case when x.column_nm = 'XML_ID' then 'cast(-1 as bigint) as XML_ID' 
                   when x.column_nm = 'SourceServer_NM' then '''ASI-SQL-43'' as SourceServer_NM' 
                   when x.column_nm = 'APPL_CD' then '''CTKA'' as APPL_CD'
                   when x.column_nm = 'Source_CreateDate' then 'getdate() as Source_CreateDate'
                   else '['+x.column_nm+']' 
              end+char(10)
        from (select
                        t.name table_nm, c.name column_nm, c.column_id
                      from ASI_StatsRaw.sys.tables t
                        inner join ASI_StatsRaw.sys.columns c
                          on c.object_id = t.object_id) x
          inner join StatsStgArea_02.sys.tables pt
            on x.table_nm = pt.name
          left outer join StatsStgArea_02.sys.columns pc
            on pc.object_id = pt.object_id and pc.name = x.column_nm
        where t.Table_NM = pt.name 
              and x.column_nm <> 'STAT_ID'
              and (pc.name is not null or x.column_nm in ('XML_ID', 'SourceServer_NM', 'APPL_CD', 'Source_CreateDate'))
        order by x.column_id
        for xml path('')),1,1,'') as columnList
from @tables t
where t.Database_NM = 'StatsStgArea_02'
group by t.Table_ID, t.Table_NM


select
  'begin try'+char(10)+'print ''starting tran for '+a.Table_NM+'...'''+char(10)+
  'begin transaction'+char(10)+c.del + char(10) + a.ins + b.sel+
  'print ''commit tran for '+a.Table_NM+'...'''+char(10)+
  'commit transaction'+char(10)+'end try'+char(10)+
  'begin catch'+char(10)+
  'print ''rolling back tran for '+a.Table_NM+'...'''+char(10)+
  'rollback transaction'+char(10)+'end catch'+char(10)+'go'+char(10)
from
(select
  t.table_nm,
'insert into ASI_StatsRaw.dbo.'+t.Table_NM+'(
'+c.ColumnList+')'+char(10) as ins
from @tables t
  inner join @columns c
    on t.Table_ID = c.Table_ID
where t.Database_NM = 'ASI_StatsRaw') a
inner join
(select
  t.table_nm,
'select
  '+c.ColumnList+'from StatsStgArea_02.dbo.'+t.Table_NM+' a with (nolock)'+char(10)+
'where a.part_yyyymmddhh between '+  @part_yyyymmddhh_from +' and '+ @part_yyyymmddhh_to +char(10) as sel
from @tables t
  inner join @columns c
    on t.Table_ID = c.Table_ID
where t.Database_NM = 'StatsStgArea_02') b
on a.Table_NM = b.Table_NM
inner join (select OLD_TableNM as Table_NM,
'delete a '+ char(10)+
--'select count(*)'+char(10)+
'from ASI_StatsRaw.'+OLD_SchemaNM+'.'+OLD_TableNM + ' a'+char(10) + 
 case isnull(OLD_IsPartitioned,'N') 
       --when 'Y' then 'where a.part_yyyymmddhh between 2018013014 and 2018013017;'
       --when 'N' then 'where a.action_dt between '+''''+'2018-01-30 14:00:00'+''''+' and '+''''+'2018-01-30 17:59:59.997'+''';'
          when 'Y' then 'where a.part_yyyymmddhh between '+ @part_yyyymmddhh_from +' and '+@part_yyyymmddhh_to+'' 
       when 'N' then 'where a.action_dt between '+''''+@action_dt_from+''''+' and '+''''+@action_dt_to+''';'
end as del
from #tmp) c
on c.Table_NM = b.Table_NM
order by c.Table_NM
--select 
----'delete a '+ char(10)+
--'select count(*)'+char(10)+
--'from StatsStgArea_02.'+OLD_SchemaNM+'.'+OLD_TableNM + ' a'+char(10) + 
-- 'where a.part_yyyymmddhh between 2018013014 and 2018013017'

--from #tmp



--You can run this before and after for both stats raw and _02 to verify counts per hour. Just make sure you have the correct day & hours.

select PART_YYYYMMDDHH
       ,count(*) cnt
from asi_statsraw_02.dbo.stat_acad11 
where PART_YYYYMMDDHH between 2018020700 and 2018020723 
group by PART_YYYYMMDDHH
order by PART_YYYYMMDDHH
