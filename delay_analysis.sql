--Create VIEW for delayed journeys
GO
CREATE VIEW
    delayedjourneys_ AS
SELECT *
FROM rail_service_data
WHERE Journey_Status = 'Delayed';
GO 

--Create VIEW for seasonal data 
GO
CREATE VIEW 
       seasonaldata_ AS 
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
 FROM rail_service_data
 GO

 --What percentage of journeys were delayed
 SELECT COUNT(d.Transaction_ID) AS Delays, ---shows the actual number of delayed journeys
       COUNT(rs.Transaction_ID) AS Total_Trips, ---shows how many journeys were evaluated in total
       ROUND(
         100*
           COUNT(d.Transaction_ID) / COUNT(rs.Transaction_ID), 2) 
           AS delay_percentage  ---the delay percentage 
FROM rail_service_data rs
LEFT JOIN delayedjourneys_ d  --Left Join ensures we retain all journeys even if delayed
ON rs.Transaction_ID = d.Transaction_ID

--Frequency distribution of delay reasons  
SELECT Reason_for_Delay, 
        COUNT(*) AS Trips 
FROM delayedjourneys_
GROUP BY Reason_for_Delay;

 --Delay rate per station 
 --Counts the number of delayed trips per departure station to identify operational bottlenecks 
SELECT rs.Departure_Station, 
       COUNT(rs.Transaction_ID ) AS Total_Trips,
       COUNT(d.Transaction_ID) AS Delay_count,
       ROUND(
           100*
            CAST(COUNT(d.Transaction_ID) AS FLOAT) / COUNT(rs.Transaction_ID), 2
       ) AS Delay_Rate_Percentage
FROM rail_service_data rs
LEFT JOIN delayedjourneys_ d  --Left Join ensures we retain all journeys even if not delayed
ON rs.Transaction_ID = d.Transaction_ID
GROUP BY rs.Departure_Station
ORDER BY Delay_Rate_Percentage DESC; 

--REVENUE IMPACT OF DELAYED JOURNEYS 
--This query rerturns the total ticket prices of delayed journeys 
SELECT Journey_Status, 
       FORMAT(SUM(Price), 'C', 'en-GB') AS Ticket_Prices
FROM delayedjourneys_
GROUP BY Journey_Status; 

-- Are some routes more prone to delay during specific seasons? 
 SELECT s.Season, 
        s.Departure_Station, 
        s.Arrival_Destination,
        COUNT(s.Transaction_ID) AS Total_Journeys,
        COUNT(d.Transaction_ID) AS Delay_Count,
        ROUND(
            100*
                CAST(COUNT(d.Transaction_ID) AS FLOAT) / COUNT(s.Transaction_ID), 2
       ) AS Delay_Percentage
 FROM seasonaldata_ s 
 LEFT JOIN delayedjourneys_ d 
 ON s.Transaction_ID = d.Transaction_ID
 GROUP BY s.Departure_Station, s.Arrival_Destination, s.Season
 HAVING COUNT(d.Transaction_ID) >0
 ORDER BY s.Season;     

--Any Correlation between days of the week (Weekday/wekend) and delays?
SELECT 
    CASE WHEN DATENAME(WEEKDAY, Date_of_Journey) IN ('Saturday', 'Sunday') THEN 'Weekend'
         ELSE 'Weekday' 
     END AS Day_Type, 
    COUNT(*) AS Delay_Count
FROM delayedjourneys_
GROUP BY CASE WHEN DATENAME(WEEKDAY,Date_of_Journey) IN ('Saturday', 'Sunday') THEN 'Weekend'
         ELSE 'Weekday'
END;

--Are there monthly trends in delays?
--Summary of delays per month
SELECT DATENAME(MONTH, Date_of_Journey) AS Month, 
       COUNT(*) AS Delay_Count
FROM delayedjourneys_
GROUP BY MONTH(Date_of_Journey),
        DATENAME(MONTH, Date_of_Journey)
ORDER BY 
       MONTH(Date_of_Journey) ;

--Any Correlation beteen departure time and delays?
--Distribution of delayed journeys across different times of the day with percentage impact 
SELECT 
    CASE 
       WHEN DATEPART(HOUR, rs.Departure_Time) BETWEEN 5 AND 11 THEN 'Morning' 
       WHEN DATEPART(HOUR, rs.Departure_Time) BETWEEN 12 AND 16 THEN 'Afternoon' 
       WHEN DATEPART(HOUR, rs.Departure_Time) BETWEEN 17 AND 20 THEN 'Evening' 
       ELSE 'Night'
    END AS Time_of_Day, 
    COUNT(rs.Transaction_ID) AS Total_Journeys,
    COUNT(d.Transaction_ID) AS Delay_Count, 
       ROUND(
            100*
                CAST(COUNT(d.Transaction_ID) AS FLOAT) / COUNT(rs.Transaction_ID), 2
       ) AS Delay_Percentage
FROM rail_service_data rs
LEFT JOIN delayedjourneys_ d
ON rs.Transaction_ID = d.Transaction_ID
GROUP BY CASE 
       WHEN DATEPART(HOUR, rs.Departure_Time) BETWEEN 5 AND 11 THEN 'Morning' 
       WHEN DATEPART(HOUR, rs.Departure_Time) BETWEEN 12 AND 16 THEN 'Afternoon' 
       WHEN DATEPART(HOUR, rs.Departure_Time) BETWEEN 17 AND 20 THEN 'Evening' 
       ELSE 'Night'
    END
ORDER BY Delay_Percentage DESC;

   
