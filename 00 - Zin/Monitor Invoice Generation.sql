select getdate() as Time, COUNT(1)
from CHARGINGSESSIONS cs with (nolock)
where cs.SESSIONSTATUS = 'C'
and cs.AFFECTEDROWS >0


SELECT  COUNT (*) AS InvoicesInBillingSession
FROM invoices_ip
WHERE billingsessionid_fk = 2175

-- Get current session
SELECT *  FROM [wmpoperatorusage].[dbo].[BillingSessionsToClose]

-- Get remaining records in current session
select getdate(), count(*) from INVOICEITEMDETAILS_IPP with (nolock) where billingsessionid_fk = 2117


-- Records ready for processing
select distinct billingsessionid_fk from invoices_ip with (nolock) where datefrom = '2014-06-03 00:00:00.000'

-- Records processed in prev dates
select distinct billingsessionid_fk from invoices with (nolock) where datefrom = '2014-06-02 00:00:00.000'

select COUNT(*) from CHARGINGSESSIONS where SERVICETYPE = 'net' and AFFECTEDROWS >0 and SESSIONSTATUS = 'C'



select count(*) from INVOICes_ip as InvoicesCount with (nolock) where BILLINGSESSIONID_FK in (SELECT BillingsessionID  FROM [BillingSessionsToClose] with (nolock));
select count(*) from INVOICEITEMS_IP as InvoiceItemsCount with (nolock) where BILLINGSESSIONID_FK in (SELECT BillingsessionID  FROM [BillingSessionsToClose] with (nolock));
select count(*) from INVOICEITEMDETAILS_IP as InvoiceItemDetailsCount with (nolock) where BILLINGSESSIONID_FK in (SELECT BillingsessionID  FROM [BillingSessionsToClose] with (nolock));


select * from INVOICEDOCUMENTS where BILLINGSESSIONID_FK = 2140

select top 10 * from CHARGINGSESSIONS 

SELECT *  FROM [wmpoperatorusage].[dbo].[BillingSessionsToClose]