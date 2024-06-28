
-- Railway Project Analysis

-- After Data cleaning will focuses on the data analysis of UK Railway Ticketing Dataset.

--Objective: This Case study is to conduct an exploratory and interactive dashboard to help stakeholders.

-- This Part (Part A of analysis) of analysis contains the Data analysis and finding out of hidden pattern and insight.
-----------------------------------------------------------------------------------------------------------------------------------------------------

Use Railway_Project
 
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- From here on I will start analysing the analysis of insignts and interpretation

select * from Railway_Project

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Identify the peak time and their impact on delay::
-----------------------------------------------------------------------------------------------------------------------------------------------------

-- 1. To identify Peak time analysis 1st I need to understand the Peak purchase hour

select datepart(hour, Time_of_Purchase) as 'Time (in 24 Hr)', 
       count(*) as 'Count of Ticket'
from railway_project
group by datepart(hour, Time_of_Purchase)
order by 'Count of Ticket' desc

-- Interpretation:

-- From the above interpretation, it indicates that ticket purchase times are highest in the morning and evening. This can be assumed 
-- to be due to the following reasons:

-- People are going to work in the morning, so ticket purchasing starts increasing from 6-9 AM, reaching its highest point during this period.
-- Similarly, when people are returning home in the evening, ticket purchases also increase between 5 PM and 8 PM.

-- This increase in ticket purchases during these times can be attributed to people commuting to and from work, making these the peak times 
-- for ticket purchases.

----------  -------------  -------------  -------------  -----------  -----------  ----------  --------------  ------------  ----------  ------
-- To understand the co relation we need to run the query where based on jorney delay impact based on actual arrival and arrival diffrence:

with peak_purchase_impact as 
(select datepart(hour, time_of_purchase) as peak_purchase_hour,
        count(*) as Count_Of_Ticket,
        avg(datediff(minute, departure_time, actual_arrival_time)) as Avg_delay
   from railway_project
   group by datepart(hour, time_of_purchase))

select Top 5
       Peak_purchase_hour,
       Count_Of_Ticket,
     cast(round(avg_delay, 2) as varchar(max)) + ' Min' as Avg_delay,
    case when Avg_delay > 0 then 'Delayed'
         when Avg_delay = 0 then 'On Time'
         else 'Early'
    end as Delay_status
from peak_purchase_impact
order by Count_Of_Ticket desc

-- Interpretation:

-- From the above queries its indicate as I already understand from the previous query that  the highest peak hours occur in the morning around 
-- 7-9 AM and in the evening around 5 PM and 8 PM, when the highest number of tickets are purchased by travelers, but when I tried to understand 
-- the corelation with delay its implies almost most of the peak times are associated with delay But most of Travelers purchasing tickets during 
-- these peak hours experience delays. 


-- In this query, there is an issue with calculating the relationship with delay. Calculating the average delay directly from the departure and actual 
-- arrival times can be incorrect. For example, if a train departs at 9 PM and arrives at 2 PM the next day, the calculation might be wrong due to 
-- crossing midnight. Additionally, cancelled trains might show negative delays high delays (over 700+ min). Therefore, I need to 
-- refine the query to provide accurate results based on the desired output.

----------  -------------  -------------  -------------  -----------  -----------  ----------  --------------  ------------  ----------  ------
-- Refined query for accurate delay calculation

with cte_delay_minutes as 
(select *, case when journey_status <> 'cancelled' then
             case when actual_arrival_time < arrival_time then 
                   round((datediff(minute, arrival_time, actual_arrival_time) + (24*60)), 0) 
                   else
                   round(datediff(minute, arrival_time, actual_arrival_time), 0)
               end
         else 
         null
        end as delay_minutes
    from railway_project),
        
peak_purchase_impact as 
(select datepart(hour, time_of_purchase) as peak_purchase_hour,
        count(*) as count_of_ticket,
        avg(cast(delay_minutes as float)) as avg_delay
    from cte_delay_minutes
    where delay_minutes is not null
    group by datepart(hour, time_of_purchase))

select Top 5
       peak_purchase_hour,
       count_of_ticket,
       cast(round(avg_delay, 2) as varchar(max)) + ' min' as avg_delay,
    case when avg_delay > 0 then 'delayed'
        when avg_delay = 0 then 'on time'
        else 'early'
    end as delay_status
        
from peak_purchase_impact
order by count_of_ticket desc
    

-- Interpretation:

-- From the above queries its indicate as I already understand from the previous query that  the highest peak hours occur in the morning around 
-- 8-9 AM and in the evening around 5 PM and 8 PM, when the highest number of tickets are purchased by travelers, but when I tried to understand 
-- the corelation with delay its implies almost most of the peak times are associated with delay But most of Travelers purchasing tickets during these peak hours experience 
-- delays, with average delay times ranging from minimum 23 second to maximum 11.61 minutes. 


-- From the data, it can be assumed that delays are most significant during peak office hours, which include both morning and evening times,
-- especially in the morning at 9 AM and in the evening at 6 PM.This indicates that delays are closely related to the start and end of working or 
-- office hours. Also, there is a noticeable impact during the late morning hours from 10 AM to 12 PM, immediatly after the peak morning period.


-- If I interpret the correlation with peak hours, it generally shows moderate delays of 1 to 4 minutes, except for specific times like 9 AM,
-- which have higher delays. Non-peak hours, particularly late at night, show no delays. We can assume that routes are busy until the end of 
-- the day due to traffic or operational issues.

-- I can assumed from above  peak purchase hours, ticket counts, and delays are interconnected. Travelers buying tickets during peak hours 
-- When ticket counts are high during peak hours, travelers are more likely to experience delays, its because of due with respect to 
-- working hour and returning home.

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.Analyze Journey Patterns of Frequent Travelers
-----------------------------------------------------------------------------------------------------------------------------------------------------

with purchase_counts as 
(select transaction_id,
        count(*) over (partition by transaction_id) as purchase_count
    from railway_project),
	 
frequent_travelers as 
(select distinct
        transaction_id
    from purchase_counts
    where purchase_count > 3),

frequent_journeys as 
(select rp.departure_station,
        rp.arrival_destination,
        count(*) as journey_count
    from railway_project as rp
    inner join 
    frequent_travelers as ft 
	on rp.transaction_id = ft.transaction_id
    group by rp.departure_station,
             rp.arrival_destination)

select departure_station,
       arrival_destination,
       journey_count
from frequent_journeys
order by journey_count desc


-- Interpretation: 

-- The query aimed to understand frequent travelers (those who made more than three purchases) and analyze their common journey
-- patterns, however it appears that there are no such purchases occurring more than three times. 

-- This might be due to missing identification (such as Customer ID or Agent ID or any Unique ID) needed to identify unique travelers. 
-- Since the transaction ID is unique for each transaction, we cannot identify frequent travelers. Hence, there is insufficient 
-- data to analyze this query here. So further analysis I will explicitly create an identifier column to understnd further
-- analysis for freq traveler.

--------- (Approach 2)--------------------------

with frequent_travelers as 
(select concat(payment_method, '-', railcard, '-', ticket_class) as Customer_ID,
        count(transaction_id) as Ticket_Count
      from Railway_Project
	  group by concat(payment_method, '-', railcard, '-', ticket_class)
    having count(transaction_id) > 3)

select ft.Customer_ID,
       rp.departure_station,
       rp.arrival_destination,
       ft.Ticket_Count
from Railway_Project as rp
   inner join frequent_travelers as ft
   on concat(rp.payment_method, '-', rp.railcard, '-', rp.ticket_class) = ft.Customer_ID
group by  
      ft.Customer_ID,
      rp.departure_station,
      rp.arrival_destination,
      ft.Ticket_Count
order by ft.Ticket_Count desc

-- Interpretation: 

-- As in the previous query I have identified due to not having sufficient data execution of analysis will 
-- not be possible for which I have created a cust id by concating some columns to understand frequent travelers.

-- To understanding of frequent travelers and their travel behavior of it can be interprete here: 

-- The requent travellers used routes are Manchester Piccadilly to London Euston, Liverpool Lime Street to Manchester 
-- Piccadilly and routes involving Birmingham New Street are the most frequently traveled and Credit Cards are the 
-- dominant payment  method due to payment comfortablility and followed by Contactless payments and Standard tickets,  
-- especially under without railcard holder category  have the highest ticket counts, reflecting most traveler are frequent
-- with economical journey with credit card, contactless payments method by withoout any railcard and adults catagory.

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.Revenue Loss Due to Delays with Refund Requests
-----------------------------------------------------------------------------------------------------------------------------------------------------
select * from Railway_Project

with totalrevenue as 

(select sum(price) as total_revenue
from railway_project),

refundrevenue as 
(select sum(price) as refund_revenue
from railway_project
where journey_status = 'delayed' 
and refund_request = 'yes')

select total_revenue as Total_revenue,
       refund_revenue as Refund_revenue,
	   cast(round((refund_revenue * 100.0 / total_revenue), 2) as decimal (4, 2)) as Percentage_of_refund,
       (total_revenue - refund_revenue) as Final_Revenue
from totalrevenue, refundrevenue

-- Interpretation: 

-- From the above query it implies that total revenue of 741,921 from ticket sales. But because of delays its leading to refund requests 
-- due to train cancelled or technical issue or any reason where customer faced the issue they lost 26,165, which is about 3.53% of their 
-- total revenue. So, after refunds, railway collect the  final revenue was 715,756.

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 4. Analysis of Revenue and Average Ticket Price by Ticket Type and Class
-----------------------------------------------------------------------------------------------------------------------------------------------------

select ticket_type, 
    ticket_class, 
    sum(price) as total_revenue, 
    avg(price) as average_price
from Railway_Project
group by ticket_type, 
    ticket_class
order by total_revenue desc 
    
-- Interpretation: 

-- Advance Standard tickets are the most highest no of revenue among travellers categories, contributing the highest total revenue 
-- i.e, 242388 where the ticket price was most lower for Advanc ticket types and standared class one which indicates that a significant number 
-- of travelers plan their trips in advance to take advantage of lower prices of tickets. 

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 5. Analysing the ticket purchase trends
-----------------------------------------------------------------------------------------------------------------------------------------------------

select date_of_purchase, 
       purchase_type, 
       count(*) as number_of_tickets
from Railway_Project
group by date_of_purchase, 
         purchase_type
order by date_of_purchase

-- Interpretation: 

-- From the above analysis, it's evident that since December 8th, 2023, most purchases have been made online rather than at the station 
-- This could be because travellers want to avoid long queue at the station during peak times, which might cause them to miss their train. 
-- To understand this exactly how many are purchasing from Online and station, we should look at online and station purchases separately 
-- and compare them to the total number of purchases.

----------  -------------  -------------  -------------  -----------  -----------  ----------  --------------  ------------  ----------  ------

-- Ticket Purchase Trends specifically Purchase Type Vs Total Purchase

select concat(datepart(year, date_of_purchase), '-', format(datepart(month, date_of_purchase), '00')) as 'month-year',
       sum(case when purchase_type = 'online' then 1 else 0 end) as 'online purchase total',
       sum(case when purchase_type = 'station' then 1 else 0 end) as 'station purchase total',
       sum(case when purchase_type = 'online' then 1 else 0 end) + sum(case when purchase_type = 'station' then 1 else 0 end) as total_purchase
from railway_project
group by concat(datepart(year, date_of_purchase), '-', format(datepart(month, date_of_purchase), '00'))
order by 'month-year'
    
-- Interpretation:

-- Travellers are  purchased more tickets online compared to stations, with peak purchase periods evident from the data. On 2023-12-08
-- maximum tickets were purchased online, each month online purchases are gigher number, the trends seems like advance booking trends.

-----------------------------------------------------------------------------------------------------------------------------------------------------

-- 6. Impact of Railcards on Ticket Prices and Journey Delays:  
-----------------------------------------------------------------------------------------------------------------------------------------------------
select * from Railway_Project


with railcard_impact as 
(select railcard,
        avg(price) as avg_ticket_price,
        avg(case when journey_status = 'delayed' then 1.0 else 0.0 end) as delay_rate
   from railway_project
   group by railcard)

select Railcard,
       round(avg_ticket_price, 2) as Avg_ticket_Cost,
       cast(round((delay_rate * 100), 2) as decimal(5,2)) as Delay_rate_percentage
   from railcard_impact

-- Interpretation:

-- From the above query I can understand the query releted to performance and customer satisfaction related to different railcard categories
-- where Disabled and Senior railcard holders benefit from lower ticket costs and lower delay rates, making their journeys 
-- more economical and reliable and some how punctuallity of their journey.

-- Simillarly, in case of Adult holders are despite of paying moderately lower ticket prices compared to those without railcards
-- experience the highest delay rates, it can be leads due to high no adults traveller and high rush.

-- None category railcard holder are pay the highest average ticket price but the delay percentage is 6.74%, indicating a moderate 
-- frequency of delays and I can assumed its quite satisfaction to their jouney as compared to Adults holder.

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 7. Analysis of Payment Method Trends: 
-----------------------------------------------------------------------------------------------------------------------------------------------------
select * from Railway_Project


select payment_method,
       count(*) as count
from railway_project 
group by payment_method

-- Interpretation:

-- From above query its indicating that Credit Card payments are the most popular method, followed by contactless methods, also I can assumed 
-- indicating that due to train delay or cancelled they can cancelled priorly for convenience and security purpose.

-----------------------------------------------------------------------------------------------------------------------------------------------------

-- 8. Journey Performance by Departure and Arrival Stations: 
-----------------------------------------------------------------------------------------------------------------------------------------------------
select * from Railway_Project

with with_cte_journey_performance_by_dep_arr as 
(select departure_station,
        arrival_destination,
        avg(case when journey_status <> 'cancelled' then
             case when actual_arrival_time < arrival_time then 
                   round((datediff(minute, arrival_time, actual_arrival_time) + (24*60)), 0) 
                   else
                   round(datediff(minute, arrival_time, actual_arrival_time), 0)
               end
         else 
         null
        end) as Avg_delay
    from railway_project
    group by departure_station,
             arrival_destination)

select Departure_station,
       Arrival_destination,
       cast(Avg_delay as varchar (max))+ ' Min' as Avg_delay
   from with_cte_journey_performance_by_dep_arr
   order by Avg_delay desc   

-- Interpretation:

-- High Delay, Moderate Delay,Low Delay and 0 Delay Punctual Routes Analysis::

-- From the analysis of various train journeys, I have identified some routes with significant delays that need immediate attention
-- The route from Manchester Piccadilly to Leeds, for instance, experiences an average delay of 65 minutes. This route faces the most of time 
-- delays, indicating that there may be critical issues affecting punctuality. Similarly, the route from London Euston to York has an average delay 
-- of 36 minutes, indicating frequent operational issues. The journey from Liverpool Lime Street to London Euston also shows 
-- moderate delays with an average of 28 minutes, pointing to areas where improvements can be made. Even the York to Doncaster route, with a 9-minute 
-- delay, highlights the need for better schedule management.

-- This analysis associated with moderate delays, the journey from Edinburgh Waverley to London Kings Cross averages 15 minutes of delay, 
-- indicating minor  adjustments could enhance punctuality. The Manchester Piccadilly to London Euston route, with a 16-minute delay, similarly suggests room for 
-- operational improvements. The journey from Liverpool Lime Street to London Paddington, averaging an 18-minute delay,  
-- shows there are efficiency gains to be made.

-- Some routes,performing much better. The London Euston to Birmingham New Street route, with only a 3-minute delay, demonstrates good 
-- operational efficiency. The York to Durham and Oxford to Bristol Temple Meads routes, both averaging just 2minute delays, are indicate of 
-- highly efficient travel routes with minimal delays.

-- Many routes journeys like from Liverpool Lime Street to Birmingham New Street , Reading to Liverpool Lime Street, Manchester Piccadilly to London Kings Cross.
-- These routes set a benchmark for punctuality and good operational efficiency.

-- To improve the overall journey performance, it's crucial to focus on the routes with the highest delays, the Manchester 
-- Piccadilly to Leeds and London Euston to York routes should be a priority. For routes with moderate delays, like those from Edinburgh Waverley to
-- London Kings Cross, optimizing processes and schedules could enhance punctuality. It's also essential to maintain the high standards on the routes
-- with zero delays, using them as models for best practices.

-----------------------------------------------------------------------------------------------------------------------------------------------------

-- 9. Revenue and Delay Analysis by Railcard and Station
-----------------------------------------------------------------------------------------------------------------------------------------------------
select * from Railway_Project


with CTE_revenue_delayan_alysis as 
(select railcard,
        departure_station,
        arrival_destination,
        sum(price) as totalrevenue,
        cast(avg(case when journey_status = 'delayed' then 1.0 else 0.0 end)*100 as decimal(10,2)) as delay_rate_percentage
   from  railway_project
   group by railcard,
            departure_station,
            arrival_destination)
select Railcard,
       Departure_station,
       Arrival_destination,
       Totalrevenue,
       delay_rate_percentage
   from CTE_revenue_delayan_alysis
   Order By railcard, totalrevenue desc


-- Interpretation:

-- From this interpretation I can comes to some insights into how different railcards impact revenue and journey delays across various stations.

-- From Adult railcard:  revenue contributions High revenue routes include Liverpool Lime Street to London Euston 13,819, London Euston to
-- Birmingham New Street 10,137, and London Kings Cross to York 10,461, but some routes are high revenue but moderate delays on routes 
-- like Manchester Piccadilly to London Euston having 7,939 revenue with 44.86% delay rate.But In case of delay interpretation of adult railcard
-- category severe delays on routes such as Birmingham new street to Manchester Piccadilly with (42.86%) and Liverpool Lime Street to london 
-- euston with (63.35%) of delay rate but if I check Complete delays on routes like Liverpool Lime Street to London Paddington with (100%) 
-- of delay rate and Manchester Piccadilly to Nottingham (100%) of delay.

-- From disabled railcard: The High revenue routes include London Euston to Manchester Piccadilly with 10,829 of revenue and london kings 
-- Cross to Edinburgh Waverley 6,084 and the moderate revenue from routes like Liverpool Lime Street to Manchester Piccadilly with of 
-- 1,397 revenue but But In case of delay interpretation normally delay rates of this category are very low delay rates but spefically the 
-- routes from York to Wakefield with 100% of delay, rest of routes are trying to maintain the as possible low rates of delay which indicates
--  efficient service for disabled railcard holders to be reliable and some how punctuallity for them.

-- From None railcard: For no holdings of any kinds of railcard contributing most highest revenue from London Kings Cross to York of 164,790
-- and Liverpool Lime Street to London Euston 97,376 of revenue but high revenue routes with significant delays include Liverpool Lime 
-- Street to London Euston of 71.74% of delay and Manchester Piccadilly to London Euston of 85.51% of delay.But interpretation of delay insights
-- comes to the picture there is severe delays on certain high revenue routes such as London Euston to York with 100% and Manchester Piccadilly
-- to London Euston of 85.51% delay, but some routes like London Paddington to Reading having minimal delays with 1.12% which is considerable.

-- From Senior railcard: The Senior category contributes the high revenue with no delays on routes like London St Pancras to Leicester with 
-- a revenue of 5,991 but in other hand the Moderate revenue from routes like Liverpool Lime Street to Crewe 1,563 and London Kings Cross to 
-- York 3,657. Now lets dive into the delay insights where significant delays on routes like Oxford to Bristol Temple Meads and Liverpool 
-- Lime Street to London Euston both are with 100% of delay, but most routes are Low delays which indicating good management for the senior
-- railcard holder to be reliable and punctuallity and commitment for them for them.


-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 10. Journey Delay Impact Analysis by Hour of Day
-----------------------------------------------------------------------------------------------------------------------------------------------------

--
with cte_delay_minutes as 
(select *, case when journey_status <> 'cancelled' then
             case when actual_arrival_time < arrival_time then 
                   round((datediff(minute, arrival_time, actual_arrival_time) + (24*60)), 0) 
                   else
                   round(datediff(minute, arrival_time, actual_arrival_time), 0)
               end
         else 
         null
        end as delay_minutes
    from railway_project),
        
peak_purchase_impact as 
(select datepart(hour, time_of_purchase) as peak_purchase_hour,
        count(*) as count_of_ticket,
        avg(cast(delay_minutes as float)) as avg_delay
    from cte_delay_minutes
    where delay_minutes is not null
    group by datepart(hour, time_of_purchase))

select 
       peak_purchase_hour,
       count_of_ticket,
       cast(round(avg_delay, 2) as varchar(max)) + ' min' as avg_delay,
    case when avg_delay > 0 then 'delayed'
        when avg_delay = 0 then 'on time'
        else 'early'
    end as delay_status 
        
from peak_purchase_impact
order by count_of_ticket desc

-- -- Interpretation:

-- Same query Q2 already done with the interpretation

-----------------------------------------------------------------------------------------------------------------------------------------------------






























