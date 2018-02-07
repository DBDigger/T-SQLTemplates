/*------------------------------------------------------------------
List untrusted foreign keys
-------------------------------------------------------------------*/
SELECT QUOTENAME(SCH.NAME) + N'.' + QUOTENAME(TBL.NAME) + N'.' + QUOTENAME(FK.NAME)
FROM sys.foreign_keys AS FK
INNER JOIN sys.objects AS TBL ON FK.parent_object_id = TBL.object_id
INNER JOIN sys.schemas AS SCH ON FK.schema_id = SCH.schema_id
WHERE FK.is_not_trusted = 1

/*------------------------------------------------------------------
Repair untrusted foreign keys
-------------------------------------------------------------------*/
SELECT N'BEGIN TRY ALTER TABLE ' + QUOTENAME(SCH.NAME) + N'.' + QUOTENAME(TBL.NAME) + N' WITH CHECK CHECK CONSTRAINT ' + QUOTENAME(FK.NAME) + N'; END TRY ' + CHAR(13) + CHAR(10) + N'BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;' AS AlterCommand
FROM sys.foreign_keys AS FK
INNER JOIN sys.objects AS TBL ON FK.parent_object_id = TBL.object_id
INNER JOIN sys.schemas AS SCH ON FK.schema_id = SCH.schema_id
WHERE FK.is_not_trusted = 1
ORDER BY SCH.NAME
	,TBL.NAME
	,FK.NAME;