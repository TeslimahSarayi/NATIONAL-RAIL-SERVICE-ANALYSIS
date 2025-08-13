--Rename tech_table
EXEC sp_rename 'tech_table' , 'rail_service_data'

--Create a backup table 
SELECT *
INTO railservice_databackup 
FROM rail_service_data; 

--Check If date values can be converted 
SELECT Date_of_Journey   --Date of Journey 
FROM rail_service_data
WHERE TRY_CAST(Date_of_Journey AS DATE) IS NULL 
AND Date_of_Journey IS NOT NULL; 

--Preview converted date column 
SELECT Transaction_ID,
       Date_of_Journey, 
       TRY_CAST(Date_of_Journey AS DATE) AS Converted_Date
FROM rail_service_data;

--Change data type 
ALTER TABLE rail_service_data
ALTER COLUMN Date_of_Journey DATE; 

--Check for dupliactes 
--This query confirms that there were no duplicates 
SELECT *
FROM(
     SELECT * ,
          ROW_NUMBER() OVER (PARTITION BY Transaction_ID ORDER BY Date_of_Purchase DESC) AS rn 
     FROM rail_service_data
    ) t
WHERE rn = 1 

--Merge 'Staffing' and 'Staff Shortage' into one delay reason
UPDATE rail_service_data
SET Reason_for_Delay = 'Staffing'
WHERE LOWER(Reason_for_Delay) IN ('Staffing' , 'Staff Shortage');

--Merge 'Weather' and 'Weather Conditions' into one delay reason
UPDATE rail_service_data
SET Reason_for_Delay = 'Weather Conditions'
WHERE LOWER(Reason_for_Delay) IN ('Weather', 'Weather Conditions');

--BASIC STRUCTURE AND OVERVIEW 

--Total number of tickets 
SELECT COUNT(*) AS Total_tickets
FROM rail_service_data; 

--What is the time range of journeys recorded 
SELECT MIN(Date_of_Journey),
       Max(Date_of_Journey) 
FROM rail_service_data;

--What are the unique Values in key columns 
SELECT DISTINCT Ticket_Class  --returns the values in ticket class column 
FROM rail_service_data; 

SELECT DISTINCT Journey_Status   --returns the values in journey status column 
FROM rail_service_data; 

SELECT DISTINCT Railcard   --returns the different railcard types 
FROM rail_service_data; 

SELECT DISTINCT Ticket_Type  --returns the values in ticket types column 
FROM rail_service_data;

SELECT DISTINCT Purchase_Type  --returns the values in purchase type column 
FROM rail_service_data; 

--What is the NULL count per column 
SELECT 
    SUM(CASE WHEN Ticket_Class IS NULL THEN 1 ELSE 0 END) AS null_ticket_class,
    SUM(CASE WHEN Journey_Status IS NULL THEN 1 ELSE 0 END) AS null_journey_status, 
    SUM(CASE WHEN Railcard IS NULL THEN 1 ELSE 0 END) AS null_railcard, 
    SUM(CASE WHEN Ticket_Type IS NULL THEN 1 ELSE 0 END) AS null_ticket_type,
    SUM(CASE WHEN Purchase_Type IS NULL THEN 1 ELSE 0 END) AS null_purchase_type
FROM rail_service_data;

--TICKETS AND REVENUE DISTRIBUTION 

--How many journeys per ticket class? 
SELECT Ticket_Class, 
       COUNT(*) AS Total_tickets, 
       FORMAT(SUM(Price), 'C', 'en-GB') AS Revenue  --How much in Revenue was generated ? 
FROM rail_service_data
GROUP BY Ticket_Class;

--How many journeys per ticket type 
SELECT Ticket_Type, 
       COUNT(*) AS Total_tickets, 
       FORMAT(SUM(Price), 'C', 'en-GB') AS Revenue   --How much in Revenue was generated ?
FROM rail_service_data
GROUP BY Ticket_Type;

--How many journeys per purchase type
SELECT Purchase_Type, 
       COUNT(*) AS Total_tickets, 
       FORMAT(SUM(Price), 'C', 'en-GB') AS Revenue   --How much in Revenue was generated ?
FROM rail_service_data
GROUP BY Purchase_Type;

--How is the journey status distributed 
SELECT Journey_Status, 
       COUNT(*) AS Total_tickets
FROM rail_service_data
GROUP BY Journey_Status;

--How often was each railcard type used
SELECT Railcard, 
      COUNT(*) AS Total_tickets ,
      FORMAT(SUM(Price), 'C', 'en-GB') AS Revenue    --How much in Revenue was generated ?
FROM rail_service_data
GROUP BY Railcard;

--TIME-BASED PATTERNS 

--How many journeys were attempted per month? 
SELECT DATENAME(Month,Date_of_Journey) AS Month,
       COUNT(*) AS Attempted_journeys
FROM rail_service_data
GROUP BY MONTH(Date_of_Journey),
         DATENAME(Month,Date_of_Journey)
ORDER  BY MONTH(Date_of_Journey);

--How many journeys were successfully completed per month? 
SELECT DATENAME(Month,Date_of_Journey) AS Month,
       COUNT(*) AS completed_journeys
FROM rail_service_data
WHERE Journey_Status NOT IN ('Delayed' , 'Cancelled') --does not count cancelled and delayed journeys 
GROUP BY MONTH(Date_of_Journey),
         DATENAME(Month,Date_of_Journey)
ORDER  BY MONTH(Date_of_Journey);

--Are there peak days for travel? 
SELECT DATENAME(WEEKDAY,Date_of_Journey) AS Day_of_week,
       COUNT(*) AS Total_trips
FROM rail_service_data
GROUP BY DATENAME(WEEKDAY,Date_of_Journey),
         DATEPART(WEEKDAY,Date_of_Journey)
ORDER BY DATEPART(WEEKDAY,Date_of_Journey);
       
--PRICE-BASED PATTERNS

--Are there any obvious anomalies in ticket pricing? 
SELECT COUNT(*) AS Zero_price_tickets
FROM rail_service_data
WHERE Price = 0; 

--What is the distribution of ticket prices? 
SELECT FORMAT(MIN(Price), 'C', 'en-GB') AS Min_Price,
       FORMAT(
       ROUND(AVG(Price), 2), 'C' , 'en-GB'
           )AS Avg_price,
       FORMAT(MAX(Price), 'C', 'en-GB') AS Max_Price,
       COUNT(*) AS Total_tickets
FROM rail_service_data;

--Create VIEW for price Bands 
GO 
CREATE VIEW
      Ticketpricebands_ AS 
   SELECT 
       Transaction_ID,
       Price,
       Ticket_Class,
       Ticket_Type,
       Purchase_Type,
       Date_of_Journey,
       CASE 
         WHEN Price BETWEEN 1 AND 50 THEN 'Very low(£1-50)'
         WHEN Price BETWEEN 51 AND 100 THEN 'Low(£51-100)'
         WHEN Price BETWEEN 101 AND 150 THEN 'Mid(£101-150)'
         WHEN Price BETWEEN 151 AND 200 THEN 'High(£151-200)'
         WHEN Price >= 200 THEN 'Very high(£200+)'
       END AS Price_Band
   FROM rail_service_data 
GO 

--Frequenecy distribution of journeys across price bands 
SELECT Price_Band, 
       COUNT(*) AS Total_tickets 
FROM Ticketpricebands_
GROUP BY Price_Band
ORDER BY Total_tickets DESC;

--Pricing patterns by Ticket categories. 

--Pricing patterns by ticket type
SELECT Ticket_Type, 
       Price_Band, 
       COUNT(transaction_ID) AS Total_Tickets
FROM Ticketpricebands_
GROUP BY Ticket_Type,
         Price_Band
ORDER BY Ticket_Type,
         Total_Tickets DESC;

--Pricing patterns by ticket class
SELECT Ticket_Class, 
       Price_Band, 
       COUNT(transaction_ID) AS Total_Tickets
FROM Ticketpricebands_
GROUP BY Ticket_Class,
         Price_Band
ORDER BY Ticket_Class,
         Total_Tickets DESC;

--Pricing patterns by purchase type 
SELECT Purchase_Type, 
       Price_Band, 
       COUNT(transaction_ID) AS Total_Tickets
FROM Ticketpricebands_
GROUP BY Purchase_Type,
         Price_Band
ORDER BY Purchase_Type,
         Total_Tickets DESC;

--Monthly Ticket price trends 
--Displays monthly variation in ticket prices to identify potential seasonal pricing patterns  
SELECT DATENAME(Month,Date_of_Journey) AS Month,
       Price_Band,
       COUNT(*) AS Total_Tickets
FROM Ticketpricebands_
GROUP BY MONTH(Date_of_Journey),
         DATENAME(Month,Date_of_Journey),
         Price_Band
ORDER BY MONTH(Date_of_Journey),
         Total_Tickets DESC;

