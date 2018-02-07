-- The service queue "ExternalMailQueue" is currently disabled.
Use MSDB
Select count(*) from ExternalMailQueue  
GO

ALTER QUEUE ExternalMailQueue WITH STATUS = ON
set nocount on
declare @Conversation_handle uniqueidentifier;
declare @message_type nvarchar(256);
declare @counter bigint;
declare @counter2 bigint;

set @counter = (select count(*) from ExternalMailQueue)
set @counter2=0

while (@counter2<=@counter)
begin
receive @Conversation_handle = conversation_handle, @message_type = message_type_name from ExternalMailQueue
set @counter2 = @counter2 + 1
end