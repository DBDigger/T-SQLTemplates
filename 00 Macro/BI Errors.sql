select *
from BI_Data_Factory.dbo.BI_Data_Staging_Process_History
where Process_Date_Time >= dateadd(dd, -3, getdate())
order by 1 desc
