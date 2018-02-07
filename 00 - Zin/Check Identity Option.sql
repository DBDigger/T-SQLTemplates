------ query for check identity insert three values for the tables
use wmp
go
select b.name, a.name,a.is_disabled,a.is_not_for_replication,a.is_not_trusted 
from sys.check_constraints a
join sys.objects b on a.parent_object_id = b.object_id
order by a.is_disabled
