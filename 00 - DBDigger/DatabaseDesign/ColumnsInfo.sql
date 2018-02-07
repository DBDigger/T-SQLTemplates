select *
from information_schema.columns
where data_type = 'xml'
order by column_name