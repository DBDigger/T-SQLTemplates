-- Adding new article without generating a complete snapshot

--1)      Make sure that your publication has IMMEDIATE_SYNC and ALLOW_ANONYMOUS properties set to FALSE or 0.

Use wmp
GO
select name, immediate_sync , allow_anonymous from syspublications;

--If either of them is TRUE then modify that to FALSE by using the following command

EXEC sp_changepublication @publication = 'TestPublication', @property = N'allow_anonymous', @value='False';
EXEC sp_changepublication @publication = 'TestPublication', @property = N'immediate_sync', @value='false';


--2)      Now add the article to the publication
EXEC sp_addarticle @publication = 'PorthosMain', @article ='WHITELABELDOCUMENTS', @source_object='WHITELABELDOCUMENTS', @force_invalidate_snapshot=1;
EXEC sp_addarticle @publication = 'PorthosMain', @article ='WHITELABELDOCUMENTDETAILS', @source_object='WHITELABELDOCUMENTDETAILS', @force_invalidate_snapshot=1;

/* If you do not use the @force_invalidate_snapshot option then you will receive the following error
Msg 20607, Level 16, State 1, Procedure sp_MSreinit_article, Line 99
Cannot make the change because a snapshot is already generated. Set
@force_invalidate_snapshot to 1 to force the change and invalidate the existing snapshot. */


--3)Verify if you are using CONCURRENT or NATIVE method for synchronization by running the following command.
Use wmp
GO
select name,sync_method from syspublications;

--If the value is 3 or 4 then it is CONCURRENT and if it is 0 then it is NATIVE. For more information check http://msdn.microsoft.com/en-us/library/ms189805.aspx
 --4) Then add the subscription for this new article using the following command

EXEC sp_addsubscription @publication = 'PorthosMain', @article = 'WHITELABELDOCUMENTS',  @subscriber ='pv1a-w-db03\cludb02', @destination_db = 'wmpoperatorusage', @reserved='Internal';
EXEC sp_addsubscription @publication = 'PorthosMain', @article = 'WHITELABELDOCUMENTDETAILS',  @subscriber ='pv1a-w-db03\cludb02', @destination_db = 'wmpoperatorusage', @reserved='Internal';


--If you are using the NATIVE  method for synchronization then the parameter @reserved=’Internal’ is optional but there is no harm in using it anyways. But if it is CONCURRENT then you have to use that parameter. Else the next time you run the snapshot agent it is going to generate a snapshot for all the articles. At the end start the SNAPSHOT AGENT job from the job activity monitor and Verify that the snapshot was generated for only one article.