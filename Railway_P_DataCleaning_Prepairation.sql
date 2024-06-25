
-- Railway Project Analysis

-- This project focuses on the data cleaning of UK Railway Ticketing Dataset,The dataset contained the 
-- detailed information about ticket purchases i.e, Transaction details,Journey specifics and operational
-- performance metrics.

--Objective: This Case study is to conduct an exploratory and interactive dashboard to help stakeholders:
-- This Part of analysis contains the Data prepairation where I will be more focusing on data cleaning.

-----------------------------------------------------------------------------------------------------------------------------------------------------

Create database Railway_Project
Use Railway_Project

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Data Prepairation:

create table Railway_Project
(Transaction_ID varchar(max),Date_of_Purchase varchar(max),Time_of_Purchase varchar(max),Purchase_Type varchar(max),Payment_Method varchar(max),	
Railcard varchar(max),Ticket_Class varchar(max),Ticket_Type varchar(max),Price varchar(max),Departure_Station varchar(max),	
Arrival_Destination varchar(max),Date_of_Journey varchar(max),Departure_Time varchar(max),Arrival_Time varchar(max),	
Actual_Arrival_Time varchar(max),Journey_Status varchar(max),Reason_for_Delay varchar(max),Refund_Request varchar(max))

Select * from Railway_Project

-- Using Bulk Insert into Railway Project Table

BULK INSERT Railway_Project
FROM 'C:\Users\abhis\Desktop\Railway_Project\railway.csv'
WITH (FIELDTERMINATOR = ',',  ROWTERMINATOR = '\n',    FIRSTROW = 2,  MAXERRORS = 40)
go

Select * from Railway_Project

------------------------------------------------------------------------------------------------------------------------------------------------------


-- Performing Data cleaning (Coversion Data Types,Null Values, Eliminate unwanted If it occured)
-- As Instructed, I will create a function to clean the data as most of data to be clean same time of conversion.

-- After importing the data into the sqlserver database, I proceeded with the following data cleaning steps to ensure the dataset 
-- was free from inconsistencies and ready for analysis.

-- Convert Data Types: I converted the columns for date and time and integer to the appropriate types to facilities accurate analysis
---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------

select column_name, data_type 
from information_schema.columns

-- All columns are currently of VARCHAR data type because, during the bulk insertion, I used VARCHAR(MAX) for all columns for the smooth
-- data import so that later I can chage to appropriate type casting to required data.
-- Let's alter all the data types to the required data types based on the data by performing function if it required.


select Date_of_Purchase from Railway_Project
where Date_of_Purchase is null

-- Let's create a function to convert the varchar to date format for all column to date conversion using function to call.
-- Created a function as (mydate) for all varchar date conversion into (Date format)

create function mydate(@inputDate varchar(max))
returns date
as
begin
    declare @cleanDate date

    if patindex('%[^0-9]%', @inputDate) > 0
    begin
       
        set @inputDate = replace(@inputDate, '--', '-')
        set @inputDate = replace(@inputDate, '/', '-')
		set @inputDate = replace(@inputDate, '%', '-')
		set @inputDate = replace(@inputDate, '*', '-') 
    end

 
    set @cleanDate = try_convert(date, @inputDate, 103) 
    if @cleanDate is null
        set @cleanDate = try_convert(date, @inputDate, 121)

    return @cleanDate
end

select dbo.mydate(date_of_purchase) as cleandate
from Railway_Project

update Railway_Project
set date_of_purchase = dbo.mydate(date_of_purchase)
where date_of_purchase is not null


alter table Railway_Project
alter column Date_of_Purchase Date
---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ----------------

select * from Railway_Project

-- Created a function for Time as (mytime) for all varchar time column to (Time) data types.

create function dbo.mytime (@inputTime varchar(max))
returns time
as
begin
    declare @cleanTime time

    set @inputTime = replace(@inputTime, '::', ':')
    set @cleanTime = try_convert(time, @inputTime)
    return @cleanTime
end


select dbo.mytime(time_of_purchase) as converted_time
from Railway_Project

update Railway_Project
set time_of_purchase = dbo.mytime(time_of_purchase)
where time_of_purchase is not null

alter table Railway_Project
alter column Time_of_Purchase Time

---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ----------------
-- Using Function (myDate) will update and alter the data types of Date_of_Journey column

select dbo.mydate(Date_of_Journey) as cleandate
from Railway_Project

update Railway_Project
set Date_of_Journey = dbo.mydate(Date_of_Journey)
where Date_of_Journey is not null

alter table Railway_Project
alter column Date_of_Journey date
---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ----------------
-- Using (myTime) Function will update and alter the types of departure_time column as already I have created the function previously.

select * from Railway_Project

select dbo.mytime(departure_time) as converted_time
from Railway_Project

update Railway_Project
set departure_time = dbo.mytime(departure_time)
where departure_time is not null

alter table Railway_Project
alter column departure_time time
---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ----------------
-- Using (myTime) Function will update and alter the types of arrival_time column as already I have created the function previously.

select * from Railway_Project

select dbo.mytime(arrival_time) as converted_time
from Railway_Project

update Railway_Project
set arrival_time = dbo.mytime(arrival_time)
where arrival_time is not null

alter table Railway_Project
alter column arrival_time time

---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ----------------
-- Using (myTime) Function will update and alter the types of actual_arrival_time column as already I have created the function previously.

select * from Railway_Project

select dbo.mytime(actual_arrival_time) as converted_time
from Railway_Project

update Railway_Project
set actual_arrival_time = dbo.mytime(actual_arrival_time)
where actual_arrival_time is not null

alter table Railway_Project
alter column arrival_time time

---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ----------------
-- As Price column have only one column or only one integer column required so no need of function to create so I have cleaned the 
-- Data using manual observation.

select * from Railway_Project

-- will check is there any non numeric values are there:
select price from Railway_Project
where ISNUMERIC(price)=0

select Price from Railway_Project 
where Price like '%[!@#$%^&*()_+:";<>.,^£]%' or price like '%[--]%'

update railway_project
set price = replace(replace(replace(replace(price, '&^', ''), '$', ''), '--', ''), '%', '')
where price like '%&^%' or price like '%$%' or price like '%--%'

select price 
from railway_project 
where patindex('%[^0-9]%', Price) > 0

update railway_project
set price = replace(replace(replace(replace(replace(replace
               (price, '&^', ''), '$', ''), '--', ''), '%', ''), 'ú', ''), 'A', '')
where price like '%&^%' or price like '%$%' or price like '%--%' 
         or price like '%ú%' or price like '%A%'

alter table railway_project
alter column price int

---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ----------------
-- Transaction_ID having mix of AlphaNumeric charecter may or may not required to Type casting but for future uses i will type caste
-- to Nvarchar()

alter table railway_project
alter column Transaction_ID nvarchar(max)

---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ----------------
-- Lets check the final data types whether I have successfully converted or not:

select column_name, data_type 
from information_schema.columns

select * from Railway_Project

---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ----------------
-- Lets Check any duplicate data occured or not for the unique indentifier column 

select Transaction_ID from Railway_Project
select count(distinct Transaction_ID) as uniq_id from Railway_Project 

-- Semms like no data duplicates as per transaction Id.
-- Let's recheck using row no if any data duplicates occured or not.

with Duplrows as
(select *, row_number() over(partition by 
Transaction_ID order by date_of_purchase asc ) as row_num
from Railway_Project)
select * from Duplrows
where row_num>=2

-- No Transaction_ID column have duplicates value, all data cleaned now 

---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ----------------
-- By following these steps, I ensured that the dataset was clean, consistent, and ready for detailed analysis.
-- I was curious as to what story the data can tell me, if I carried out further exploratory analysis using MsSQL Server.

-- Let's move to next part of data analysis and will interprete the analysis  in-deepth.


                                           ------------------- * * * ------------------