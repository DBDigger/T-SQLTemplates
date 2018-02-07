use wmpoperatorusage
go
  
select cmp.COMPLETENAME AS CustomerName,
       C.CONTRACTNAME AS [Contract],
       bs.MRTODATE AS BillingPeriodEndDate,
       sc.IMEA AS NetworkID,
       sc.PHONE AS Connection,
       sl.SIMSTATUS AS SIMState,
	   (select op.OPERATORNAME from operators op where op.operatorid = p.operatorid_fk) as OperatorName,
       pp.PRICEPLANDESCRIPTION2 as PricePlan,
       MIN(ii.datefrom) AS UsageStartDate,
       (select symbol from CURRENCIES with (nolock) where currencycode =  i.currencycode_fk) as ChargeCurrency,
       SUM(ISNULL(ii.SERVICECHARGE,0)-ISNULL(ii.DISCOUNT,0)) /** cr.CONVERSIONRATE */ AS TotalCost,
       SUM(CASE WHEN (p.operatorid_fk = 11 and ii.SERVICEID_FK IN (4, 36) and ii.ZONEID_FK = 11 and s.InvoiceServiceCategory = 'DATA') or (p.operatorid_fk <> 11 and ii.SERVICEID_FK IN (4, 36) and s.InvoiceServiceCategory = 'DATA') THEN  ISNULL(ii.SERVICECHARGE,0)-ISNULL(ii.DISCOUNT,0) ELSE 0 END) /** cr.CONVERSIONRATE*/ AS DataUsageCost,
       SUM(CASE WHEN (p.operatorid_fk = 11 and ii.ZONEID_FK <> 11 and s.InvoiceServiceCategory = 'DATA') or (p.operatorid_fk <> 11 and ii.SERVICEID_FK NOT IN (4, 36) and s.InvoiceServiceCategory = 'DATA') THEN  ISNULL(ii.SERVICECHARGE,0)-ISNULL(ii.DISCOUNT,0) ELSE 0 END) /** cr.CONVERSIONRATE*/ AS RoamingDataUsageCost,
       SUM(CASE WHEN (s.InvoiceServiceCategory = 'SMS') THEN  ISNULL(ii.SERVICECHARGE,0)-ISNULL(ii.DISCOUNT,0) ELSE 0 END) /** cr.CONVERSIONRATE*/ AS SMSCost,
       SUM(CASE WHEN (s.InvoiceServiceCategory = 'VOICE') THEN  ISNULL(ii.SERVICECHARGE,0)-ISNULL(ii.DISCOUNT,0) ELSE 0 END) /** cr.CONVERSIONRATE*/ AS VoiceCost,       
       SUM(CASE WHEN (p.operatorid_fk = 11 and ii.SERVICEID_FK IN (4, 36) and ii.ZONEID_FK = 11 and s.InvoiceServiceCategory = 'DATA') or (p.operatorid_fk <> 11 and ii.SERVICEID_FK IN (4, 36) and s.InvoiceServiceCategory = 'DATA') THEN  ISNULL(ii.PRICEPLANROUNDEDDATA,0) ELSE 0 END)/(1024.00*1024.00) AS TotalUsageMb,
       SUM(CASE WHEN (p.operatorid_fk = 11 and ii.SERVICEID_FK IN (4, 36) and ii.ZONEID_FK = 11 and s.InvoiceServiceCategory = 'DATA') or (p.operatorid_fk <> 11 and ii.SERVICEID_FK IN (4, 36) and s.InvoiceServiceCategory = 'DATA') THEN  ISNULL(ii.PRICEPLANROUNDEDDATA,0)-ISNULL(ii.DISCOUNTED,0) ELSE 0 END)/(1024.00*1024.00) AS OverageMb,  
       SUM(CASE WHEN (p.operatorid_fk = 11 and ii.ZONEID_FK <> 11 and s.InvoiceServiceCategory = 'DATA') or (p.operatorid_fk <> 11 and ii.SERVICEID_FK NOT IN (4, 36) and s.InvoiceServiceCategory = 'DATA') THEN  ISNULL(ii.PRICEPLANROUNDEDDATA,0) ELSE 0 END)/(1024.00*1024.00) AS RoamingUsageMb,
       SUM(CASE WHEN (p.operatorid_fk = 11 and ii.ZONEID_FK <> 11 and s.InvoiceServiceCategory = 'DATA') or (p.operatorid_fk <> 11 and ii.SERVICEID_FK NOT IN (4, 36) and s.InvoiceServiceCategory = 'DATA') THEN  ISNULL(ii.PRICEPLANROUNDEDDATA,0)-ISNULL(ii.DISCOUNTED,0) ELSE 0 END)/(1024.00*1024.00) AS RoamingOverageMb,       
       SUM(CASE WHEN (s.InvoiceServiceCategory = 'SMS') THEN  II.QUANTITY ELSE 0 END) /** cr.CONVERSIONRATE*/ AS SMSCount,
       SUM(CASE WHEN (s.InvoiceServiceCategory = 'VOICE') THEN  II.PRICEPLANROUNDEDDURATION ELSE 0 END) /** cr.CONVERSIONRATE*/ AS SMSDuration,
       con.CONTACTNAME AS CustomerContactName,
       con.EMAIL AS CustomerEmail,
       ac.EMAIL as AccountManagerEmail,
       GETUTCDATE() ReportDate
      
from INVOICES_IP i with (nolock)
join CONTRACTS C WITH (NOLOCK) ON C.CONTRACTID = I.CONTRACTID_FK
join BILLINGSESSIONS bs with (nolock) on bs.BILLINGSESSIONID = i.BILLINGSESSIONID_FK
join INVOICEITEMS_IP ii with (nolock) on ii.INVOICEID_FK = i.INVOICEID 
--join invoiceitemdetails_ip iid with(Nolock) on iid.invoiceitemid_fk=ii.invoiceitemid
JOIN PRODUCTS P with (nolock) on P.PRODUCTID = ii.PRODUCTID_FK
--join OPERATORS op with (nolock) on op.operatorid = p.operatorid_fk
join SERVICES s with (nolock) on s.SERVICEID = ii.SERVICEID_FK
							 and s.SERVICETYPE = 'NET'
join PRICEPLANSUMMARY pp with (nolock) on pp.PRODUCTPRICEPLANID_FK = ii.PRODUCTPRICEPLANID_FK
join CNTPRODITEMS cpi with (nolock) on cpi.CNTPRODITEMID = ii.CNTPRODITEMID_FK
								   and cpi.PRODUCTTYPEID_FK = ii.PRODUCTTYPEID_FK
join SIMCARDS sc with (nolock) on sc.SIMCARDID = cpi.SIMCARDID_FK
join SIMSTATUSES_LANG sl with (nolock) on sl.SIMSTATUSID_FK = sc.SIMSTATUSID_FK
									  and sl.LANGUAGEID_FK = 1
join ORGANIZATION cmp with (nolock) on cmp.ORGID = i.TOORGID
join SYSTEMUSERS su with (nolock) on su.USERID = cmp.ACCOUNTMANAGER
join CONTACTS ac with (nolock) on ac.CONTACTREFERENCEID_FK = su.CONTACTREFERENCEID_FK
							  and ac.PREFERREDMAILADDRESS = '1'
							  and ac.ISDELETED = '0'
join BAN b with (nolock) on b.BANID = i.BANID_FK
join CONTACTS con with (nolock) on con.CONTACTID = b.BILLINGADDRESSID_FK
left outer join CONVERSIONRATES cr with (nolock) on cr.FROMCURRENCYCODE_FK = i.CURRENCYCODE_FK
												and cr.TOCURRENCYCODE_FK = 2
												and ii.DATEFROM between cr.FROMDATE and ISNULL(cr.TODATE, GETUTCDATE())
--WHERE I.TOORGID = 1127
group by cmp.COMPLETENAME ,
        C.CONTRACTNAME,
		p.OPERATORID_FK,
       bs.MRTODATE ,
       sc.IMEA ,
       sc.PHONE ,
       sl.SIMSTATUS ,
       pp.PRICEPLANDESCRIPTION2, 
       con.CONTACTNAME,
       con.EMAIL,
       ac.EMAIL,
       cr.CONVERSIONRATE,
       i.currencycode_fk
HAVING 
SUM(ISNULL(ii.SERVICECHARGE,0)-ISNULL(ii.DISCOUNT,0)) * cr.CONVERSIONRATE >25  
order by TotalCost desc   