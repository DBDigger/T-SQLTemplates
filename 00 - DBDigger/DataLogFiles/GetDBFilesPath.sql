/*------------------------------------------------------------------
      Data files - where are they?  Are any on the C drive?  We want to avoid that
      because if they grow, they can fill up the OS drive, and that can lead to a
      very nasty crash.  Let's look at where the databases live. 
      In the results, also check the number of data and log files for all databases.
------------------------------------------------------------------*/
select DB_NAME(database_id) as DBName , name FileName, type_desc, physical_name,state_desc from sys.master_files order by DBName, filename, physical_name

