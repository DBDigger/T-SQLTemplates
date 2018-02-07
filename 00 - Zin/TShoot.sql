-- Check for identity constraint status
SELECT b.NAME, a.NAME, a.is_disabled, a.is_not_for_replication, a.is_not_trusted
FROM sys.check_constraints a JOIN sys.objects b ON a.parent_object_id = b.object_id
ORDER BY a.is_disabled

-- Enable Disable
ALTER TABLE OTSVCSCHARGING NOCHECK CONSTRAINT repl_identity_range_tran_1914541954
ALTER TABLE OTSVCSCHARGING CHECK CONSTRAINT repl_identity_range_tran_1914541954