select name, type_desc from sys.database_principals where type_desc in ('SQL_USER','DATABASE_ROLE')
order by type_desc, name