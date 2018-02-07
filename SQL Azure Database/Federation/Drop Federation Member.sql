-- =======================================================================
-- Drop federation member template for a Windows Azure SQL Database
-- This script will run only in the context of the federation root database.
-- =======================================================================

USE FEDERATION ROOT WITH RESET
GO

ALTER FEDERATION <Federation_Name, sysname, > DROP AT (<Boundary_Side, LOW_OR_HIGH, HIGH> 
<Distribution_Name, sysname, > = <Boundary_Value, keytype, >)
GO
