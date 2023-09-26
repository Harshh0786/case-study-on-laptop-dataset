use atomm;

select * from laptops_backup;

-- head , tail and sample

-- head
select * from laptops_backup
order by `id` limit 5;

-- tail
select * from laptops_backup
order by `id` desc limit 5;

-- sample
select * from laptops_backup
order by rand() limit 5;

-- univariate analysis

-- 8 number summary [count,min,max,std,q1,q2,q3]
-- missing values

select count(Price),
Min(Price),
max(Price),
avg(Price),
std(Price),
percentile_cont(0.25) within group(order by Price) over() as 'Q1', 
percentile_cont(0.5) within group(order by Price) over() as 'Median', 
percentile_cont(0.75) within group(order by Price) over() as 'Q3', 
from laptops_backup
order by `id` limit 1;

-- missing values

select count(Price)
from laptops_backup
where Price is null;

-- outliers
-- for outliers we can use boxplot trick where we can use equation of minimum and maximum

select * from (select *,
percentile_cont(0.25) within group(order by Price) over() as 'Q1', 
percentile_cont(0.75) within group(order by Price) over() as 'Q3'
from laptops_backup) t
where t.Price < t.Q1 - (1.5*(t.Q3 - t.Q1)) or
t.price > t.Q3 + (1.5*(t.Q3 - t.Q1));

-- horizontal / vertical histogram

select t.buckets,repeat('*',count(*)/5) from (select Price,
case
	when Price Between 0 and 25000 then '0 - 25k'
    when Price Between 25001 and 50000 then '25k - 50k'
    when Price Between 50001 and 75000 then '50k - 75k'
	when Price Between 75001 and 100000 then '75k - 100k'
    else '> 100k'
end as 'buckets'
from laptops_backup) t
group by t.buckets;

-- for categorical cols

-- frequency count

select Company,count(*) from laptops_backup
group by Company;

-- side by side 8 number analysis same like first one 8 number summary in this one u need to do for 2 numerical columns

-- scatterplot

select cpu_speed,Price from laptops_backup;

-- copy the generated data and paste it into sheet and generate the scatter plot in googlesheet using insert -> chart
-- it applies for all type of charts so apply same thing for all

-- correlation

select cor(cpu_speed,Price) from laptops_backup;

-- categorical - categorical

-- contigency table

select Company,
sum(Case when touchscreen = 1 then 1 else 0 End) as 'touchscreen_yes',
sum(Case when touchscreen = 0 then 1 else 0 End) as 'touchscreen_no'
from laptops_backup
group by Company;

-- stackbarchart copy the generated data and paste it into sheet and generate the stackbar chart in googlesheet using insert -> chart

-- numerical - categorical

-- compare distribution across categories

select Company,min(Price),max(Price),avg(Price),std(Price) 
from laptops_backup
group by Company;

-- missing vaalue treatment

-- so in this dataset there is no missing values so i have manually gererated null values to understand this missiing value treatment concept

update laptops_backup
set Price = null
where `id` in (5,13,63,76,90,225);

select * from laptops_backup
where Price is null;

-- if you u can drop that rows if you don't know which value can i put in this row
-- or try to fill this value
-- replace missing value with mean  of price

select avg(Price) from laptops_backup;

update laptops_backup
set Price = avg(Price)
where Price is null;

-- replace missing value with mean price of correrspoding comapny

update laptops_backup l1
set Price = (select avg(Price) from laptops_backup l2 where l2.Company = l1.Company )
where Price is null;

-- corresponding company + processor

update laptops_backup as l1
set Price = (select avg(l2.Price) from laptops_backup l2 where
			l2.Company = l1.Company and
            l2.cpu_name = l1.cpu_name)
where l1.Price is null ;

select * from laptops_backup
where Price is null;

-- Create a temporary table to store the average prices
CREATE TEMPORARY TABLE temp_avg_prices AS
SELECT AVG(Price) AS avg_price
FROM laptops_backup
WHERE Price IS NOT NULL;

-- Update laptops_backup with the average price
UPDATE laptops_backup
SET Price = (SELECT avg_price FROM temp_avg_prices)
WHERE Price IS NULL;

-- Drop the temporary table
DROP TEMPORARY TABLE IF EXISTS temp_avg_prices;

-- Feature Engineering

-- let's calculate ppi by using reasolution height, weight and inches and create new column with the name of ppi

alter table laptops_backup
add column ppi integer;

select * from laptops_backup;

select round(sqrt(resolution_height*resolution_height + resolution_width*resolution_width)/Inches) from laptops_backup;

update laptops_backup
set ppi = round(sqrt(resolution_height*resolution_height + resolution_width*resolution_width)/Inches) ;

select * from laptops_backup;

alter table laptops_backup
add column screen_size varchar(255) after Inches;

select *,
case
	when Inches > 14.0 then 'small'
    when Inches <= 14.0 and Inches < 17.0 then 'medium'
    else 'large'
end as 'type'
from laptops_backup;

update atomm.laptops_backup
set screen_size = 
case
	when Inches > 14.0 then 'small'
    when Inches <= 14.0 and Inches < 17.0 then 'medium'
    else 'large'
end;

-- one hot encoding

select distinct gpu_brand from laptops_backup;

-- lets create intel, amd, nvidia, arm column from gpu_brand column

select gpu_brand,
case when gpu_brand = 'Intel' then 1 else 0 end as 'intel',
case when gpu_brand = 'Nvidia' then 1 else 0 end as 'Nvidia',
case when gpu_brand = 'AMD' then 1 else 0 end as 'amd',
case when gpu_brand = 'ARM' then 1 else 0 end as 'arm'
from laptops_backup
