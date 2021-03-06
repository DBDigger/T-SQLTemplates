USE [wmpoperatorusage]
GO
/****** Object:  Table [dbo].[INVOICEITEMDETAILS]    Script Date: 03/27/2014 10:56:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[INVOICEITEMDETAILS_4UsageFile](
	[INVOICEITEMDETAILID] [numeric](27, 0) IDENTITY(794584362,2) NOT NULL,
	[INVOICEITEMID_FK] [numeric](27, 0) NOT NULL,
	[BILLINGSESSIONID_FK] [bigint] NOT NULL,
	[BANID_FK] [bigint] NULL,
	[ACCOUNTINGID_FK] [numeric](27, 0) NULL,
	[SERVICEID_FK] [int] NULL,
	[ZONEID_FK] [smallint] NULL,
	[USAGEDATE] [datetime] NULL,
	[APNNAME] [nvarchar](256) NULL,
	[USERIPADDRESS] [varchar](30) NULL,
	[CALLINGNUMBER] [varchar](32) NULL,
	[CALLEDNUMBER] [nvarchar](256) NULL,
	[OCTETSIN] [bigint] NULL,
	[OCTETSOUT] [bigint] NULL,
	[PACKETSIN] [bigint] NULL,
	[PACKETSOUT] [bigint] NULL,
	[TOTALDATA] [bigint] NULL,
	[OPERATORROUNDEDDATA] [bigint] NULL,
	[PRICEPLANROUNDEDDATA] [bigint] NULL,
	[DURATION] [int] NULL,
	[OPERATORROUNDEDDURATION] [int] NULL,
	[PRICEPLANROUNDEDDURATION] [int] NULL,
	[DISCOUNTED] [bigint] NULL,
	[ORIGINALSERVICECHARGE] [numeric](19, 7) NULL,
	[SERVICECHARGE] [numeric](19, 7) NULL,
	[TAXRATE] [numeric](5, 2) NULL,
	[TAX] [numeric](18, 7) NULL,
	[DISCOUNT] [numeric](19, 7) NULL,
	[TOTALCHARGE] [numeric](19, 7) NULL,
	[CONVERSIONRATEID_FK] [bigint] NULL,
	[CSERVICECHARGE] [numeric](19, 7) NULL,
	[CTAX] [numeric](18, 7) NULL,
	[CDISCOUNT] [numeric](19, 7) NULL,
	[CTOTALCHARGE] [numeric](19, 7) NULL,
	[ORGID] [bigint] NULL,
	[CREATED] [datetime] NOT NULL,
	[CREATEDBY] [bigint] NULL,
	[MODIFIED] [datetime] NULL,
	[MODIFIEDBY] [bigint] NULL,
	[UNITPRICE] [numeric](18, 7) NULL,
	[CALLCLASS] [varchar](512) NULL,
	[SESSIONCOUNTRY] [varchar](512) NULL,
	[SESSIONOPERATOR] [varchar](512) NULL,
	[CALLORIGIN] [varchar](512) NULL,
	[CALLDESTINATION] [varchar](512) NULL,
	[FILENAME] [varchar](512) NULL,
	[SGSNIP] [varchar](20) NULL,
	[USAGECYCLESTARTDATE] [datetime] NULL,
	[USAGECYCLEENDDATE] [datetime] NULL,
	[Operator_Name] [nvarchar](128) NULL,
	[Country_Name] [nvarchar](128) NULL,
 CONSTRAINT [INVOICEITEMDETAILS_4UsageFile_PK] PRIMARY KEY NONCLUSTERED 
(
	[INVOICEITEMDETAILID] ASC,
	[BILLINGSESSIONID_FK] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)) 
ON invoices
GO
SET ANSI_PADDING OFF
GO
CREATE CLUSTERED INDEX [Inx_INVOICEITEMDETAILS_BILLINGSESSIONID_4UsageFile_FK] ON [dbo].[INVOICEITEMDETAILS_4UsageFile] 
(
	[BILLINGSESSIONID_FK] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON invoices
GO
CREATE NONCLUSTERED INDEX [INX_INVOICEITEMDETAILS_4UsageFile_ACCOUNTINGID] ON [dbo].[INVOICEITEMDETAILS_4UsageFile] 
(
	[ACCOUNTINGID_FK] ASC
)
INCLUDE ( [INVOICEITEMDETAILID]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON invoices
GO
CREATE NONCLUSTERED INDEX [INX_InvoiceitemDetails_4UsageFile_Billing] ON [dbo].[INVOICEITEMDETAILS_4UsageFile] 
(
	[INVOICEITEMID_FK] ASC,
	[BILLINGSESSIONID_FK] ASC
)
INCLUDE ( [PRICEPLANROUNDEDDATA],
[PRICEPLANROUNDEDDURATION],
[DISCOUNTED],
[SERVICECHARGE],
[TAX],
[DISCOUNT],
[TOTALCHARGE]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON invoices
GO
CREATE NONCLUSTERED INDEX [INX_INVOICEITEMDETAILS_4UsageFile_INVOICEITEMID_FK] ON [dbo].[INVOICEITEMDETAILS_4UsageFile] 
(
	[INVOICEITEMID_FK] ASC,
	[BILLINGSESSIONID_FK] ASC
)
INCLUDE ( [ZONEID_FK],
[OCTETSIN],
[OCTETSOUT],
[TOTALDATA]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON invoices
GO
CREATE NONCLUSTERED INDEX [INX_INVOICEITEMDETAILS_4UsageFile_SERVICEIDZONEID] ON [dbo].[INVOICEITEMDETAILS_4UsageFile] 
(
	[SERVICEID_FK] ASC
)
INCLUDE ( [INVOICEITEMID_FK],
[ZONEID_FK],
[SERVICECHARGE],
[DISCOUNT],
[TOTALCHARGE]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON invoices
GO
