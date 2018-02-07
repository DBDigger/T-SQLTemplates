declare @fileListTable table
(
    LogicalName nvarchar(128), PhysicalName nvarchar(260), [Type] char(1), FileGroupName nvarchar(128),
    Size numeric(20,0), MaxSize numeric(20,0), FileID bigint, CreateLSN numeric(25,0),
    DropLSN numeric(25,0), UniqueID uniqueidentifier, ReadOnlyLSN numeric(25,0), ReadWriteLSN numeric(25,0),
    BackupSizeInBytes bigint, SourceBlockSize int, FileGroupID int, LogGroupGUID uniqueidentifier, DifferentialBaseLSN  numeric(25,0),
    DifferentialBaseGUID uniqueidentifier, IsReadOnl bit, IsPresent bit, TDEThumbprint varbinary(32)
)
insert into @fileListTable exec('restore filelistonly from disk = ''\\asinetwork.local\Backups\SQL Backups 2\UAT\asi-sqlucn1-01\RECOVERY\ForDMTransfer\ASI-SQLUCN1-01_DM_MemberDemogr_FULL_2016-12-02.BAK''')
select logicalname, physicalname from @fileListTable




declare @files table (ID int IDENTITY, FileName varchar(100))
insert into @files execute xp_cmdshell 'dir "\\asinetwork.local\Backups\SQL Backups 2\UAT\asi-sqlucn1-01\RECOVERY\ForDMTransfer" /b'
select * from @files