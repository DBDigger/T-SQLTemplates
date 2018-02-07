/****** Object:  LinkedServer [WYLN0-CLUDB01]    Script Date: 02/10/2016 10:45:13 ******/
EXEC master.dbo.sp_addlinkedserver   @server='WYLN0-CLUDB01',    @srvproduct='',  @provider='SQLNCLI',    @datasrc='PV1A-W-DB01'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WYLN0-CLUDB01',@useself=N'False',@locallogin=NULL,@rmtuser=N'wmp',@rmtpassword='########'

GO