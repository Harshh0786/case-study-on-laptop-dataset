-- 1.create backup

SELECT * FROM atomm.laptopdata;

create table laptops_backup like atomm.laptopdata;

insert into atomm.laptops_backup
select * from atomm.laptopdata;

-- 2.check number of rows

select count(*) from atomm.laptops_backup;

-- 3.check memory consumption for reference

select DATA_LENGTH from information_schema.tables
where table_schema = 'atomm'
and table_name = 'laptops_backup';

-- 4.Drop non importaant cols

select * from atomm.laptops_backup;
ALTER TABLE atomm.laptops_backup DROP COLUMN `Unnamed: 0`; -- backticks(`)
select * from atomm.laptops_backup;

-- 5.Drop null values

ALTER TABLE atomm.laptops_backup
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;

-- Delete from atomm.laptops_backup
-- where id in (select id from atomm.laptops_backup
-- where Company is null and TypeName is null and Inches is null
-- and Cpu is null and Ram is null and Memory is null and Gpu is null
-- and OpSys is null and Weight is null and Price is null)

CREATE TEMPORARY TABLE TempDeleteTable AS
SELECT id
FROM atomm.laptops_backup
WHERE Company IS NULL
  AND TypeName IS NULL
  AND Inches IS NULL
  AND Cpu IS NULL
  AND Ram IS NULL
  AND Memory IS NULL
  AND Gpu IS NULL
  AND OpSys IS NULL
  AND Weight IS NULL
  AND Price IS NULL;
  
DELETE FROM atomm.laptops_backup
WHERE id IN (SELECT id FROM TempDeleteTable);

DROP TEMPORARY TABLE TempDeleteTable;

-- 6.check is there any duplicate rows in dataset if available then drop that rows

select Company,TypeName,Inches,ScreenResolution,Cpu,Ram,Memory,Gpu,OpSys,Weight,Price,count(*) 
from atomm.laptops_backup
group by Company,TypeName,Inches,ScreenResolution,Cpu,Ram,Memory,Gpu,OpSys,Weight,Price
having count(*) > 1;

delete from atomm.laptops_backup 
where id not in (select min(id) 
from atomm.laptops_backup
group by Company,TypeName,Inches,ScreenResolution,Cpu,Ram,Memory,Gpu,OpSys,Weight,Price
having count(*) > 1);

-- checking column data values

select distinct Company from atomm.laptops_backup;
select distinct TypeName from atomm.laptops_backup;

-- here inches datatype is text so let's convert it into decimal

alter table atomm.laptops_backup
modify column Inches decimal(10,1);

-- in ram coloumn lets remove gb word and convert it into integer

select * from atomm.laptops_backup;

UPDATE atomm.laptops_backup 
SET Ram = REPLACE(Ram, 'GB', '');

alter table atomm.laptops_backup
modify column Ram INTEGER;

-- In weight column lets remove kg word and convert it into decimal

UPDATE atomm.laptops_backup 
SET Weight = REPLACE(Weight, 'kg', '');

-- there is one value in weight which is 0.0002 so its an anomaly lets remove this row

delete from atomm.laptops_backup
where id = 257;

UPDATE atomm.laptops_backup 
SET Weight = round(Weight,2);

alter table atomm.laptops_backup
modify column Weight decimal(10,2);

-- here price column type is integer it occupy more memory in rom so lets reduce it

update atomm.laptops_backup
set Price = round(Price);

select * from atomm.laptops_backup;

alter table atomm.laptops_backup
modify column Price Integer;

-- lets work on OpSys column

select distinct OpSys from atomm.laptops_backup;

-- mac
-- windows
-- linux
-- no os
-- android chrome (others)

select OpSys,
case
	when OpSys like '%mac%' then 'macos'
    when OpSys like 'windows%' then 'windows'
    when OpSys like '%linux%' then 'linux'
    when OpSys = 'No OS' then 'N/A'
    else 'other'
end as 'os_brand'
from atomm.laptops_backup;

update atomm.laptops_backup
set OpSys = case
				when OpSys like '%mac%' then 'macos'
				when OpSys like 'windows%' then 'windows'
				when OpSys like '%linux%' then 'linux'
				when OpSys = 'No OS' then 'N/A'
				else 'other'
			end;
            
select * from atomm.laptops_backup;

-- lets work on gpu column 
-- so from this column we can create two extra columns which is gpu brand and gpu name

alter table atomm.laptops_backup
add column gpu_brand varchar(255) after Gpu,
add column gpu_name varchar(255) after gpu_brand;

SELECT * FROM atomm.laptops_backup;

-- for gpu_name column

select substring_index(Gpu,' ',1) from atomm.laptops_backup;

update atomm.laptops_backup
set gpu_brand = substring_index(Gpu,' ',1);

-- for gpu_brand column

select replace(Gpu,gpu_brand,'') from atomm.laptops_backup;

update atomm.laptops_backup
set gpu_name = replace(Gpu,gpu_brand,'');

-- lets drop gpu column

alter table atomm.laptops_backup Drop column Gpu;

select * from atomm.laptops_backup;

-- from this cpu column we can crete 3 columns
-- 1.cpu brand
-- 2.cpu name
-- 3.speed of the cpu

alter table atomm.laptops_backup
add column cpu_brand varchar(255) after Cpu,
add column cpu_name varchar(255) after cpu_brand,
add column cpu_speed Decimal(10,1) after cpu_name;

-- for cpu_brand column

select substring_index(Cpu,' ',1) from atomm.laptops_backup;

update atomm.laptops_backup
set cpu_brand = substring_index(Cpu,' ',1);

-- for cpu speed

select substring_index(Cpu,' ',-1) from atomm.laptops_backup;

select cast(replace(substring_index(Cpu,' ',-1),'GHz','') as decimal(10,1)) from atomm.laptops_backup;

update atomm.laptops_backup
set cpu_speed = cast(replace(substring_index(Cpu,' ',-1),'GHz','') as decimal(10,1));

-- for cpu name

select cpu,
replace(replace(Cpu,cpu_brand,''),substring_index(replace(Cpu,cpu_brand,''),' ',-1),''),
replace(Cpu,cpu_brand,''),
substring_index(replace(Cpu,cpu_brand,''),' ',-1)
from atomm.laptops_backup;

update atomm.laptops_backup
set cpu_name = replace(replace(Cpu,cpu_brand,''),substring_index(replace(Cpu,cpu_brand,''),' ',-1),'');

-- lets drop the cpu column

alter table atomm.laptops_backup drop column Cpu;

-- lets work on screen resolution column

-- by using Screen Resolution column i have extracted 2 columns which resolution height and resolution width

-- resolution height and width

select ScreenResolution, substring_index(substring_index(ScreenResolution,' ',-1),'x',1) from atomm.laptops_backup;
select ScreenResolution, substring_index(substring_index(ScreenResolution,' ',-1),'x',-11) from atomm.laptops_backup;

alter table atomm.laptops_backup
add column resolution_height integer after ScreenResolution,
add column resolution_width INTEGER after resolution_height;

update atomm.laptops_backup
set resolution_height = substring_index(substring_index(ScreenResolution,' ',-1),'x',1);

update atomm.laptops_backup
set resolution_width = substring_index(substring_index(ScreenResolution,' ',-1),'x',-1);

ALTER TABLE atomm.laptops_backup RENAME COLUMN resolution_height TO resolution_width ,Rename Column resolution_width TO resolution_height;

alter table atomm.laptops_backup
add column touchscreen integer after resolution_width;

select ScreenResolution like '%touch%' from atomm.laptops_backup;

update atomm.laptops_backup
set touchscreen = ScreenResolution like '%touch%';

alter table atomm.laptops_backup drop column ScreenResolution;

-- lets rework on cpu_name 

select cpu_name,
substring_index(trim(cpu_name),' ',2)
from atomm.laptops_backup;

update atomm.laptops_backup
set cpu_name = substring_index(trim(cpu_name),' ',2);

-- lets work on memory column

select Memory from atomm.laptops_backup;

-- we can extract 3 columns from the memory column which is memory type,primary storage, secondary storage

alter table atomm.laptops_backup
add column memory_type varchar(255) after Memory,
add column primary_storage INTEGER after memory_type,
add column secondary_storage INTEGER after primary_storage;

-- applying condition to generate memory type column 


select Memory,
case
	when Memory like '%HDD%' AND Memory like '%SDD%'  then 'hybrid'
    when Memory like '%SSD%' THEN 'SDD'
    when Memory like '%HDD%' THEN 'HDD'
	when Memory like '%Flash Storage%' THEN 'Flash Storage'
    when Memory like '%Hybrid%' then 'hybrid'
    when Memory like '%Flash Storage%' and Memory like '%HDD%' Then 'hybrid'
    else null
END as 'memory_type'
from atomm.laptops_backup;

update atomm.laptops_backup
set memory_type = case
						when Memory like '%HDD%' AND Memory like '%SDD%'  then 'hybrid'
						when Memory like '%SSD%' THEN 'SDD'
						when Memory like '%HDD%' THEN 'HDD'
						when Memory like '%Flash Storage%' THEN 'Flash Storage'
						when Memory like '%Hybrid%' then 'hybrid'
						when Memory like '%Flash Storage%' and Memory like '%HDD%' Then 'hybrid'
						else null
					END;

-- extarcting primary storage and secondary storage from memory column 

select Memory,
REGEXP_SUBSTR(substring_index(Memory,'+',1),'[0-9]+'),
case when Memory like '%+%' then REGEXP_SUBSTR(substring_index(Memory,'+',-1),'[0-9]+') else 0 end
from atomm.laptops_backup;

UPDATE atomm.laptops_backup
set primary_storage = REGEXP_SUBSTR(substring_index(Memory,'+',1),'[0-9]+'),
secondary_storage = case when Memory like '%+%' then REGEXP_SUBSTR(substring_index(Memory,'+',-1),'[0-9]+') else 0 end;

-- in primary storage and secondary storage we can multiply the <=2 with 1024 just because of it is hdd we just convert it into mb

select primary_storage,
case when primary_storage <= 2 then primary_storage*1024 else primary_storage END,
secondary_storage,
case when secondary_storage <= 2 then secondary_storage*1024 else secondary_storage END
from atomm.laptops_backup;

update atomm.laptops_backup
set primary_storage = case when primary_storage <= 2 then primary_storage*1024 else primary_storage END,
secondary_storage = case when secondary_storage <= 2 then secondary_storage*1024 else secondary_storage END;

alter table atomm.laptops_backup drop column Memory;

-- lets remove gpu_name column because it is useless

alter table atomm.laptops_backup drop column gpu_name