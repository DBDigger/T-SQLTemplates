CREATE NONCLUSTERED INDEX [INX_INVOICEITEMDETAILS_4UsageFile_INVOICEITEMDID_FK] ON [dbo].[INVOICEITEMDETAILS_4UsageFile] 
(
	[INVOICEITEMID_FK] ASC,
	[BILLINGSESSIONID_FK] ASC,
	invoiceitemdetailid asc
)
INCLUDE ( [ZONEID_FK],
[OCTETSIN],
[OCTETSOUT],
[TOTALDATA]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON invoices
GO