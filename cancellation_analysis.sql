--Create VIEW for cancelled journeys
GO
CREATE VIEW
    cancelledjourneys_ AS
SELECT *
FROM rail_service_data
WHERE Journey_Status = 'Cancelled';
GO

--Create VIEW for seasonal data 
GO
CREATE VIEW 
       seasonal_data AS 
SELECT Transaction_ID,
       Departure_Station, 
       Arrival_Destination,
       Journey_Status,
       CASE 
           WHEN MONTH(Date_of_Journey) IN (12, 1, 2) THEN 'Winter'
           WHEN MONTH(Date_of_Journey) IN (3, 4, 5) THEN 'Spring'
           WHEN MONTH(Date_of_Journey) IN (6, 7, 8) THEN 'Summer'
           WHEN MONTH(Date_of_Journey) IN (9, 10, 11) THEN 'Autumn'
         END AS Season
 FROM rail_service_data;
 GO

  --What percentage of journeys were cancelled
 SELECT COUNT(c.Transaction_ID) AS Delays, ---shows the actual number of cancelled journeys
       COUNT(rs.Transaction_ID) AS Total_Trips, ---shows how many journeys were evaluated in total
       ROUND(
         100*
           COUNT(c.Transaction_ID) / COUNT(rs.Transaction_ID), 2) 
           AS cancellation_percentage  ---the cancellation percentage 
FROM rail_service_data rs
LEFT JOIN cancelledjourneys_ c 
ON rs.Transaction_ID = c.Transaction_ID;  --Left Join ensures we retain all journeys even if cancelled

--Cancellation Rate per station 
--Counts the number of cancelled trips per departure station to identify operational bottlenecks 
SELECT rs.Departure_Station, 
       COUNT(rs.Transaction_ID ) AS Total_Trips,
       COUNT(c.Transaction_ID) AS Cancellation_count,
       ROUND(
           100*
            CAST(COUNT(c.Transaction_ID) AS FLOAT) / COUNT(rs.Transaction_ID), 2
       ) AS Cancellation_Rate_Percentage ----calculates cancellation rate percentage 
FROM rail_service_data rs
LEFT JOIN cancelledjourneys_ c  --Left Join ensures we retain all journeys even if not cancelled 
ON rs.Transaction_ID = c.Transaction_ID
GROUP BY rs.Departure_Station
ORDER BY Cancellation_Rate_Percentage DESC; 

--REVENUE IMPACT OF CANCELLED JOURNEYS 
--This query rerturns the total ticket prices of cancelled journeys 
SELECT Journey_Status, 
       FORMAT(SUM(Price), 'C', 'en-GB') AS Ticket_Prices
FROM cancelledjourneys_
GROUP BY Journey_Status; 

-- Are some routes more prone to cancellations during specific seasons? 
 SELECT s.Season, 
        s.Departure_Station, 
        s.Arrival_Destination,
        COUNT(s.Transaction_ID) AS Total_Journeys,
        COUNT(c.Transaction_ID) AS cancellation_Count,
        ROUND(
            100*
                CAST(COUNT(c.Transaction_ID) AS FLOAT) / COUNT(s.Transaction_ID), 2
       ) AS cancellation_Percentage
 FROM seasonal_data s 
 LEFT JOIN cancelledjourneys_ c 
 ON s.Transaction_ID = c.Transaction_ID
 GROUP BY s.Season,
          s.Departure_Station,
          s.Arrival_Destination 
 HAVING COUNT(c.Transaction_ID) >0
 ORDER BY s.Season;
      

--Any Correlation between days of the week (Weekday/wekend) and cancellations
SELECT 
    CASE WHEN DATENAME(WEEKDAY, Date_of_Journey) IN ('Saturday', 'Sunday') THEN 'Weekend'
         ELSE 'Weekday' 
      END AS Day_Type, 
    COUNT(*) AS Cancellation_Count
FROM cancelledjourneys_
GROUP BY CASE WHEN DATENAME(WEEKDAY,Date_of_Journey) IN ('Saturday', 'Sunday') THEN 'Weekend'
         ELSE 'Weekday'
END;

--Are there monthly trends in cancellations?
--Summary of canacellations per month
SELECT DATENAME(MONTH, Date_of_Journey) AS Month, 
       COUNT(*) AS cancellation_Count
FROM cancelledjourneys_
GROUP BY MONTH(Date_of_Journey),
        DATENAME(MONTH, Date_of_Journey)
ORDER BY 
       MONTH(Date_of_Journey) ;

--Any Correlation beteen departure time and cancellations?
--Distribution of cancelled journeys across different times of the day with percentage impact 
SELECT 
    CASE 
       WHEN DATEPART(HOUR, rs.Departure_Time) BETWEEN 5 AND 11 THEN 'Morning' 
       WHEN DATEPART(HOUR, rs.Departure_Time) BETWEEN 12 AND 16 THEN 'Afternoon' 
       WHEN DATEPART(HOUR, rs.Departure_Time) BETWEEN 17 AND 20 THEN 'Evening' 
       ELSE 'Night'
    END AS Time_of_Day, 
    COUNT(rs.Transaction_ID) AS Total_Journeys,
    COUNT(c.Transaction_ID) AS Delay_Count, 
       ROUND(
            100*
                CAST(COUNT(c.Transaction_ID) AS FLOAT) / COUNT(rs.Transaction_ID), 2
       ) AS cancellation_percentage
FROM rail_service_data rs
LEFT JOIN cancelledjourneys_ c
ON rs.Transaction_ID = c.Transaction_ID
GROUP BY CASE 
       WHEN DATEPART(HOUR, rs.Departure_Time) BETWEEN 5 AND 11 THEN 'Morning' 
       WHEN DATEPART(HOUR, rs.Departure_Time) BETWEEN 12 AND 16 THEN 'Afternoon' 
       WHEN DATEPART(HOUR, rs.Departure_Time) BETWEEN 17 AND 20 THEN 'Evening' 
       ELSE 'Night'
    END
ORDER BY cancellation_percentage DESC;
