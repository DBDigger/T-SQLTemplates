select $partition.INVOICEITEMDETAILSPF(1919)
GO

ALTER TABLE [dbo].[INVOICEITEMDETAILS_4UsageFile] DROP CONSTRAINT CK__INVOICEIT_BSID
ALTER TABLE [dbo].[INVOICEITEMDETAILS_4UsageFile] add constraint CK__INVOICEIT_BSID CHECK  ( billingsessionid_fk < 1920 )
GO
-- make the switch
ALTER TABLE InvoiceItemDetails SWITCH PARTITION 145 TO InvoiceItemDetails_4UsageFile;
GO

-- select count(1) from InvoiceItemDetails_4UsageFile with (nolock)

--ALTER TABLE [dbo].[INVOICEITEMDETAILS_4UsageFile] DROP CONSTRAINT CK__INVOICEIT_BSID
ALTER TABLE [dbo].[INVOICEITEMDETAILS_4UsageFile] add constraint CK__INVOICEIT_BSID CHECK  ( billingsessionid_fk = 1919 )
GO
-- make the switch
ALTER TABLE InvoiceItemDetails_4UsageFile SWITCH TO InvoiceItemDetails PARTITION 145 ;
GO

-- select count(1) from InvoiceItemDetails_4UsageFile with (nolock)