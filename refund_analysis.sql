--Create VIEW for Refund Requests 
GO
CREATE VIEW
    refundrequests_ AS
SELECT *
FROM rail_service_data
WHERE Refund_Request = 'Yes';
GO

--Create VIEW for Price Bands 
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

--REFUND BEHAVIOR BY JOURNEY STATUS
--This query returns refund requests and total tickets of delayed and cancelled journeys. It reveales potential revenue loss 
SELECT Journey_Status,
       COUNT(*) AS Total_Ref_Requests, 
       FORMAT(SUM(Price), 'C', 'en-GB') AS Ticket_Prices
FROM refundrequests_
GROUP BY Journey_Status; 

--REFUND REQUESTS FOR 'On Time' Journeys 
--This query confirms that there were no refund request for 'On time' Journeys 
SELECT Journey_Status, COUNT(*) AS Total_Ref_Requests
FROM rail_service_data
WHERE Refund_Request = 'Yes'
AND Journey_Status = 'On Time'
GROUP BY Journey_Status;

--REFUND REQUESTS ACROSS TICKET CLASSES 
--Which ticket class got the most refund requests? How do refund rates compare across ticket classes 
SELECT 
     rs.Ticket_Class, 
     COUNT(r.Transaction_ID) AS Refund_Requests,
     COUNT(rs.Transaction_ID) AS Ticket_per_class,
     ROUND(
     100.0 *
       CAST(COUNT(r.Transaction_ID) AS FLOAT) / COUNT(rs.Transaction_ID), 1
       )AS Refund_Percentage
FROM rail_service_data rs
LEFT JOIN refundrequests_ r   --Left Join ensures we retain all tickets even if not refunded
     ON rs.Transaction_ID = r.Transaction_ID
GROUP BY rs.Ticket_Class; 

--REFUND REQUESTS ACROSS TICKET TYPES
--Which ticket type got the most refund requests? How do refund rates compare across ticket types 
SELECT 
     rs.Ticket_Type, 
     COUNT(r.Transaction_ID) AS Refund_Requests,
     COUNT(rs.Transaction_ID) AS Ticket_per_type,
     ROUND(
     100.0 *
       CAST(COUNT(r.Transaction_ID) AS FLOAT) / COUNT(rs.Transaction_ID), 1
       )AS Refund_Percentage
FROM rail_service_data rs
LEFT JOIN refundrequests_ r 
     ON rs.Transaction_ID = r.Transaction_ID
GROUP BY rs.Ticket_Type; 

--REFUND AND REVENUE IMPACT

--Number of departure stations 
SELECT COUNT (DISTINCT Departure_Station) AS Total_stations
FROM rail_service_data; 

--Refund requests and potential revenue loss across departure stations
SELECT Departure_Station,
       COUNT(*) AS Refund_Requests,
       FORMAT(SUM(Price), 'C', 'en-GB') AS Ticket_Prices
FROM refundrequests_
GROUP BY Departure_Station 
ORDER BY Refund_Requests DESC; 

--Refund requests and potential revenue loss across Railcard categories 
SELECT rs.Railcard, 
       COUNT(r.Transaction_ID) AS Refund_Requests,
       COUNT(rs.Transaction_ID) as  Tickets_per_railcard,
       FORMAT(SUM(r.Price), 'C', 'en-GB') AS Ticket_Prices,
       ROUND(
       100.0 *
       CAST(COUNT(r.Transaction_ID) AS FLOAT) / COUNT(rs.Transaction_ID), 1
       )AS Refund_Percentage 
FROM rail_service_data rs
LEFT JOIN refundrequests_ r   
     ON rs.Transaction_ID = r.Transaction_ID
GROUP BY rs.Railcard
ORDER  BY Refund_Percentage DESC;

--Is there a pattern of low priced tickets being refunded more often? What's the Revenue Impact across price bands 
--Breakdown of ticket sales and refunds by pricing tier

SELECT 
   t.Price_Band,
   COUNT(t.Transaction_ID) AS Total_Tickets,
   COUNT(r.Transaction_ID) AS Refund_Requests,
   FORMAT(SUM(r.Price), 'C', 'en-GB') AS Ticket_Prices, ---only returns ticket prices of tickets with refund requests 
   ROUND(
       100.0 *
       CAST(COUNT(r.Transaction_ID) AS FLOAT)/ COUNT(t.Transaction_ID), 2
       )AS Refund_Percentage 
FROM  Ticketpricebands_ t
LEFT JOIN refundrequests_ r 
ON t.Transaction_ID = r.Transaction_ID
GROUP BY t.Price_Band
ORDER BY Refund_Percentage DESC; 

--Are refund requests increasing or decreasing over time? 
--Breakdown of refund requests received per month 
SELECT DATENAME(MONTH, Date_of_journey) AS Month, 
       COUNT(*) AS Refund_Requests
FROM refundrequests_
GROUP BY MONTH(Date_of_Journey),
         DATENAME(MONTH, Date_of_journey)
ORDER BY 
         MONTH(Date_of_journey);

--Are there more refund requests during weekdays or weekends? 
--Summary of refund requests for both day types 
SELECT  
    CASE WHEN DATENAME(WEEKDAY, Date_of_Journey) IN ('Saturday', 'Sunday') THEN 'Weekend'
         ELSE 'Weekday' 
     END AS Day_Type,
    COUNT(*) AS Refund_Requests
FROM refundrequests_
GROUP BY CASE WHEN DATENAME(WEEKDAY,Date_of_Journey) IN ('Saturday', 'Sunday') THEN 'Weekend'
         ELSE 'Weekday'
END







