
--CREATE VIEW for journey issues  
GO 
CREATE VIEW 
    journeyissuesview_ AS 
 SELECT * 
 FROM rail_service_data
 WHERE Journey_Status IN ('Cancelled', 'Delayed');
GO 

--Create VIEW for Routes 
 GO
 CREATE VIEW 
    route_data AS 
  SELECT *,
         CONCAT(Departure_Station, N'⇒' , Arrival_Destination) AS Route
  FROM rail_service_data; 
GO 

 --SUMMARY KPIs 

 --OPERATIONAL METRICS
 --Total journeys
SELECT 
      COUNT(*) AS Total_journeys ---counts attempted journeys 
FROM rail_service_data;

--Completed journeys 
SELECT 
      COUNT(*) AS Total_journeys
FROM rail_service_data
WHERE Journey_Status NOT IN ('Cancelled'); ---does not count cancelled journeys

--Journey completion rate
SELECT
     COUNT(*) AS Total_journeys,
     100* 
       COUNT(CASE WHEN Journey_Status NOT IN ('Cancelled') THEN 1 END )/COUNT(*) AS completion_rate
FROM rail_service_data;

--Average journey price
SELECT
      ROUND(AVG(Price),2)
          AS Avg_ticket_price
FROM rail_service_data;

SELECT
      MAX(Price)
          AS Avg_ticket_price
FROM rail_service_data;


--Total revenue 
SELECT 
      FORMAT(SUM(Price), 'C', 'en-GB') 
         AS Total_Revenue
FROM rail_service_data;

--Peak travel month
SELECT TOP 1 
       DATENAME(Month,Date_of_Journey) AS Month,
       COUNT(*) AS Journeys
FROM rail_service_data
GROUP BY 
      DATENAME(Month,Date_of_Journey)
ORDER  BY Journeys DESC;

--ISSUE METRICS        
--Total delays 
SELECT 
      COUNT(*) AS Total_delays 
FROM delayedjourneys_; 

--Total cancelled journeys 
SELECT 
      COUNT(*) AS Total_cancellations
FROM cancelledjourneys_; 

--Issue (Delays + Cancellations) rate 
SELECT 
      COUNT(rs.Transaction_ID) AS Total_journeys,
      COUNT(j.Transaction_ID) AS Total_issue,    ---counts all delayed and cancelled journeys 
      100* 
       COUNT(j.Transaction_ID) /COUNT(rs.Transaction_ID) AS issue_rate
FROM rail_service_data rs
LEFT JOIN journeyissuesview_  j       ---left join to retain all journeys even if not delayed or cancelled 
ON rs.Transaction_ID = j.Transaction_ID 
ORDER BY issue_rate;

--Punctuality rate 
SELECT 
    COUNT(*) AS Total_Trips,
    SUM(CASE 
           WHEN DATEDIFF(MINUTE, Arrival_Time, Actual_Arrival_Time) <= 5 THEN 1 
           ELSE 0 
           END) AS on_time_trips, 
    100* 
        SUM(CASE 
           WHEN DATEDIFF(MINUTE, arrival_time, actual_arrival_time) <= 5 THEN 1 
           ELSE 0 
           END) / COUNT(*)  AS punctuality_rate
FROM rail_service_data
WHERE 
    Arrival_Time IS NOT NULL
    AND Actual_Arrival_Time IS NOT NULL ;

--Weekly refund volume      
SELECT 
     CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, Date_of_Journey), 0) AS DATE)AS week_start,
     CONCAT(
        DATEPART(YEAR, Date_of_Journey), '-W',
        RIGHT(CAST(DATEPART(WEEK, Date_of_Journey) AS VARCHAR(2)), 2)
            ) AS year_week,
     COUNT(*) AS refund_requests
FROM refundrequests_
GROUP BY 
     CONCAT(
        DATEPART(YEAR, Date_of_Journey), '-W',
        RIGHT(CAST(DATEPART(WEEK, Date_of_Journey) AS VARCHAR(2)), 2)
            ),
     CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, Date_of_Journey), 0) AS DATE)
ORDER BY refund_requests DESC;

--Weekly journey disruptions count
SELECT 
     CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, Date_of_Journey), 0) AS DATE)AS week_start,
     CONCAT(
        DATEPART(YEAR, Date_of_Journey), '-W',
        RIGHT(CAST(DATEPART(WEEK, Date_of_Journey) AS VARCHAR(2)), 2)
            ) AS year_week,
     COUNT(*) AS journey_issue
FROM journeyissuesview_
GROUP BY 
     CONCAT(
        DATEPART(YEAR, Date_of_Journey), '-W',
        RIGHT(CAST(DATEPART(WEEK, Date_of_Journey) AS VARCHAR(2)), 2)
            ),
     CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, Date_of_Journey), 0) AS DATE)
ORDER BY journey_issue DESC;

--Most Affected Route 
SELECT 
       Route,
       ROUND(
          100*
           CAST(COUNT(CASE WHEN Journey_Status IN ('Delayed', 'Cancelled') THEN 1 END )AS FLOAT) / COUNT(*),2
             ) AS Issue_percentage
FROM route_data
GROUP BY Route
ORDER BY Issue_percentage DESC; 

--REFUND AND REVENUE IMPACT 
--Total refund requests 
SELECT 
     COUNT(*) AS Total_refunds 
FROM refundrequests_;

--Percentage of tickets with refund requests 
SELECT  
       COUNT(rs.Transaction_ID) AS Total_Tickets, ---shows how many journeys were evaluated in total
       COUNT(r.Transaction_ID) AS Refund_requests,  ---shows the actual number of refund requests
       ROUND(
         100*
           CAST(COUNT(r.Transaction_ID) AS FLOAT)/ COUNT(rs.Transaction_ID), 2) 
           AS Refund_percentage  ---the refund percentage 
FROM rail_service_data rs
LEFT JOIN refundrequests_ r   --Left Join ensures we retain all tickets even if not refunded
ON rs.Transaction_ID = r.Transaction_ID

--How much and what percentage of revenue is linked to refunds?
SELECT FORMAT(SUM(r.Price), 'C', 'en-GB') AS Refund_prices, 
       FORMAT(SUM(rs.Price), 'C', 'en-GB') AS Total_revenue, 
       ROUND(
         100* 
            SUM(r.Price)/SUM(rs.Price), 2
            ) AS Revenue_refund_percentage
FROM rail_service_data rs
LEFT JOIN refundrequests_ r   
ON rs.Transaction_ID = r.Transaction_ID;
            

--DELAYS AND CANCELLATIONS, GROUPED BY ROUTES 

--Are there more delays and cancellations combined from certain stations?

--Shows the degree of reliablity of all routes 
SELECT Route,
       COUNT(*) AS Total_journeys,
       COUNT(CASE WHEN Journey_Status = 'Delayed' THEN 1 END) AS Delay_count,
       COUNT(CASE WHEN Journey_Status = 'Cancelled' THEN 1 END) AS no_of_cancellations,
       ROUND(
          100*
           CAST(COUNT(CASE WHEN Journey_Status IN ('Delayed', 'Cancelled') THEN 1 END )AS FLOAT) / COUNT(*),2
             ) AS Issue_percentage
FROM route_data
GROUP BY Route
ORDER BY Issue_percentage; 

--Shows the least reliable routes 
SELECT TOP 15 CONCAT(Departure_Station, N'⇒' , Arrival_Destination) AS Route,
              COUNT(*) AS Total_journeys,
              COUNT(CASE WHEN Journey_Status = 'Delayed' THEN 1 END) AS Delay_count,
              COUNT(CASE WHEN Journey_Status = 'Cancelled' THEN 1 END) AS no_of_cancellations,
              ROUND(
                 100*
                CAST(COUNT(CASE WHEN Journey_Status IN ('Delayed', 'Cancelled') THEN 1 END )AS FLOAT) / COUNT(*),2
                   ) AS Issue_percentage
FROM rail_service_data
GROUP BY Departure_Station, Arrival_Destination
ORDER BY Issue_percentage DESC; 

--What are the top performing routes (by Volume)?
--This query shows the the frequency of all routes 
SELECT Route,
       COUNT(*) AS Total_journeys
FROM route_data
WHERE Journey_Status NOT IN ('Cancelled', 'Delayed')  ---does not count cancelled and delayed journeys 
GROUP BY Route
ORDER BY Total_journeys DESC; 

--Which Routes show improvement in Delay and Cancellations over time? 
SELECT DATENAME(MONTH, Date_of_Journey) AS Month,
       Route,
       COUNT(*) AS Total_journeys,
       COUNT(CASE WHEN Journey_Status = 'Delayed' THEN 1 END) AS Delay_count,
       COUNT(CASE WHEN Journey_Status = 'Cancelled' THEN 1 END) AS no_of_cancellations,
       ROUND(
         100*
           CAST(COUNT(CASE WHEN Journey_Status IN ('Delayed', 'Cancelled') THEN 1 END )AS FLOAT) / COUNT(*),2
           ) AS Issue_percentage
FROM route_data
GROUP BY MONTH(Date_of_Journey),
         DATENAME(MONTH, Date_of_Journey),
         Route
ORDER BY Route, MONTH(Date_of_Journey); 

--Which departure stations are the busiest? 
SELECT TOP 10  Departure_Station, 
               COUNT(*) AS Total_trips 
FROM rail_service_data
GROUP BY Departure_Station
ORDER BY Total_trips DESC;

--Total And Average Revenue by Depature Station 
--Which departure stations generate the most revenue? What's the average revenue generated by each station per trip   
SELECT Departure_Station, 
       COUNT(*) AS Total_trips, 
       FORMAT(SUM(Price), 'C', 'en-GB') AS Total_Revenue, --shows total revenue in Pounds 
       ROUND(
           CAST(SUM(Price) / COUNT(*) AS FLOAT), 2 
            ) AS 'Revenue_per_trip(£)'
FROM rail_service_data
GROUP BY Departure_Station
ORDER BY SUM(price) DESC ;

--Are the top performing routes also the most problematic? 
--Do the routes with the highest traffic also experience the highest rate of delays, cancellations and refunds? 
SELECT CONCAT(Departure_Station, N'⇒' , Arrival_Destination) AS Route,
       COUNT(*) AS Total_journeys,
       COUNT(CASE WHEN Journey_Status = 'Delayed' THEN 1 END) AS Delay_count,
       COUNT(CASE WHEN Journey_Status = 'Cancelled' THEN 1 END) AS no_of_cancellations,
       ROUND(
         100*
           CAST(COUNT(CASE WHEN Journey_Status IN ('Delayed', 'Cancelled') THEN 1 END )AS FLOAT) / COUNT(*),2
           ) AS Issue_percentage,
      FORMAT(SUM(CASE WHEN Refund_Request = 'Yes' THEN Price ELSE 0 END), 'C', 'en-GB') AS Refund_loss, 
      FORMAT(SUM(Price), 'C', 'en-GB') AS Total_Revenue
FROM rail_service_data
GROUP BY Departure_Station,
         Arrival_Destination
ORDER BY Issue_percentage DESC,
         Total_journeys DESC; 
