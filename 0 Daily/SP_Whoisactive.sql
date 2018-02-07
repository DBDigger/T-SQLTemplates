EXEC sp_WhoIsActive @get_task_info = 2;
EXEC sp_WhoIsActive @get_avg_time = 1 ;
EXEC sp_WhoIsActive @get_additional_info = 1;
EXEC sp_WhoIsActive @get_task_info = 2, @get_additional_info = 1;
EXEC sp_WhoIsActive @get_task_info = 2, @get_plans = 1;
EXEC sp_WhoIsActive @find_block_leaders = 1;
EXEC sp_WhoIsActive @delta_interval = 5;

-- http://sqlblog.com/blogs/adam_machanic/archive/tags/month+of+monitoring/default.aspx?p=2
-- All parameters
@filter_type VARCHAR(10) = 'session' -- -- session, program, database, login, host
@filter sysname = ''  
@not_filter sysname = '' 
@not_filter_type VARCHAR(10) = 'session' 
@show_own_spid BIT = 0 
@show_system_spids BIT = 0 
@show_sleeping_spids TINYINT = 1 
@get_full_inner_text BIT = 0 
@get_plans TINYINT = 0 
@get_outer_command BIT = 0 
@get_transaction_info BIT = 0 
@get_task_info TINYINT = 1 
@get_locks BIT = 0 
@get_avg_time BIT = 0 
@get_additional_info BIT = 0 
@find_block_leaders BIT = 0 
@delta_interval TINYINT = 0 
@output_column_list VARCHAR(8000) = '[dd%][session_id][sql_text][sql_command][login_name][wait_info][tasks][tran_log%][cpu%][temp%][block%][reads%][writes%][context%][physical%][query_plan][locks][%]' 
@sort_order VARCHAR(500) = '[start_time] ASC' 
@format_output TINYINT = 1 
@destination_table VARCHAR(4000) = '' 
@return_schema BIT = 0 
@schema VARCHAR(MAX) = NULL OUTPUT 
@help BIT = 0