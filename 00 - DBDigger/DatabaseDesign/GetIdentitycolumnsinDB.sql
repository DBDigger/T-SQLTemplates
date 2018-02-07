elect  TABLE_NAME, COLUMN_NAME
      from INFORMATION_SCHEMA.COLUMNS
       where TABLE_SCHEMA = 'dbo'
       and COLUMNPROPERTY(object_id(TABLE_NAME), COLUMN_NAME, 'IsIdentity') = 1