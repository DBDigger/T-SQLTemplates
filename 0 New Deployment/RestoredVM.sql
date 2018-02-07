-- Drop distribution

EXEC sp_dropdistributor @no_checks = 1, @ignore_distributor = 1
GO

-- Check server name
select @@SERVERNAME
go

-- Drop old name
sp_dropserver 'MATRIX2\MATRIX2SQL2'
go

-- Add new name
sp_addserver 'TMOCR7\MATRIX2SQL2', LOCAL
go