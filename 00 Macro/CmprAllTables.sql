declare @WespPt varchar(150)
create table  #cmp  
   ( 
   tblname varchar(150),
   ArchColName varchar(150),
   ArchPtColName varchar(150),
    is_nullable char,
   Ptis_nullable char, 
   system_type_name sql_variant, 
   Ptsystem_type_name sql_variant, 
   is_identity_column bit,
Ptis_identity_column bit,

 
   ) 

DECLARE OAKLAND CURSOR FOR 
 SELECT name from sys.objects where type  = 'U'  
  
 OPEN OAKLAND  
 FETCH NEXT FROM OAKLAND INTO @WespPt
 WHILE (@@FETCH_STATUS <> -1)  
 BEGIN 
 
 
 insert into #cmp 
SELECT @Wesppt as tblname,WESP_Arch.name  as ArchColName, WESP_Arch_Pt.name as ArchPtColName,
WESP_Arch_Pt.is_nullable as WESP_Arch_Pt_is_nullable, 
WESP_Arch.is_nullable as WESP_Arch_is_nullable, 
WESP_Arch_Pt.system_type_name as WESP_Arch_Pt_Datatype, 
WESP_Arch.system_type_name as WESP_Arch_Datatype, 
WESP_Arch_Pt.is_identity_column as WESP_Arch_Pt_is_identity, 
WESP_Arch.is_identity_column as WESP_Arch_is_identity  
FROM sys.dm_exec_describe_first_result_set (N'SELECT * FROM WESP_Arch_Pt..'+@Wesppt+'', NULL, 0) WESP_Arch_Pt 
FULL OUTER JOIN  sys.dm_exec_describe_first_result_set (N'SELECT * FROM WESP_Arch..'+@WespPt+'', NULL, 0) WESP_Arch 
ON WESP_Arch_Pt.name = WESP_Arch.name 

  
 FETCH NEXT FROM OAKLAND INTO @WespPt
 END 
   
 GO  
 CLOSE OAKLAND  
 DEALLOCATE OAKLAND  

 select * from #cmp order by 1,2
 drop table #cmp