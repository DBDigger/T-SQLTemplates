-- ===================================================
-- Create federated table template Windows Azure SQL Database 
-- ===================================================

IF OBJECT_ID('<schema_name, sysname, dbo>.<table_name, sysname, sample_table>', 'U') IS NOT NULL
  DROP TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
GO

CREATE TABLE <schema_name, sysname, dbo>.<table_name, sysname, sample_table>
(
       <columns_in_primary_key, , c1> <column1_datatype, , bigint> <column1_nullability,, NOT NULL>, 
       <column2_name, sysname, c2> <column2_datatype, , char(10)> <column2_nullability,, NULL>, 
       <column3_name, sysname, c3> <column3_datatype, , datetime> <column3_nullability,, NULL>, 
    CONSTRAINT <contraint_name, sysname, PK_sample_table> PRIMARY KEY (<columns_in_primary_key, , c1>)
) FEDERATED ON (<Distribution_Name, sysname, > = <column_Name, sysname, >)
GO
