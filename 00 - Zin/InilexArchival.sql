select max(created) from accounting_radius_charging_V with (nolock) where ischarged = 1
-- 2016-06-11 11:39:30.240

select $partition.accountingradiuschargingVPF('2016-06-11 11:39:30.240')
--15

ALTER TABLE accounting_radius_charging_V SWITCH PARTITION 13 TO accounting_radius_charging_Archive_V PARTITION 13; 
ALTER TABLE accounting_radius_charging_V SWITCH PARTITION 14 TO accounting_radius_charging_Archive_V PARTITION 14; 



select $partition.accountingradiusPF('2016-06-11 11:39:30.240') 
-- 10

ALTER TABLE accounting_radius SWITCH PARTITION 8 TO accounting_radius_Archive PARTITION 8; 
ALTER TABLE accounting_radius SWITCH PARTITION 9 TO accounting_radius_Archive PARTITION 9; 


-- Truncate table accounting_radius_charging_Archive_V ;
-- Truncate table accounting_radius_Archive ;

select max(accountingid_fk) from accounting_radius_charging_V where ischarged = 1
-- 19999696579
-- 19999790767
