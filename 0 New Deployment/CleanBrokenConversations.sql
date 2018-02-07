DECLARE @handle UNIQUEIDENTIFIER

DECLARE conv_cur CURSOR FAST_FORWARD FOR 
SELECT count(*) FROM SYS.CONVERSATION_ENDPOINTS
where state_desc = 'DISCONNECTED_INBOUND'

OPEN conv_cur;

FETCH NEXT FROM conv_cur INTO @handle;

WHILE @@fetch_status = 0

BEGIN

END CONVERSATION @handle WITH CLEANUP

FETCH NEXT FROM conv_cur INTO @handle;

END

CLOSE conv_cur;

DEALLOCATE conv_cur;

GO