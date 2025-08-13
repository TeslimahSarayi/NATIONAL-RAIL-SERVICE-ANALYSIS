# NATIONAL-RAIL-SERVICE-ANALYSIS
This repository contains a set of structured SQL scripts and a Power BI dashboard developed to analyse the operational performance of the National Rail service from January to April,2024. The analysis focuses on key service metrics such as delays, cancellations, refunds, and other performance indicators. 

## Overview


This project analyzes the UK Railway opeartions for National Rail, transforming transactional data from January to April,2024 into strategic insights. It examines passenger travel patterns, financial performance across ticket categories, and service reliability metrics to support operational excellence. 
## Business Value 
The findings contribute directly to improvements in the following aspects of the rail service: 
#### Revenue & Pricing 
* Quantify the financial impact of operational lapses through analysis of refund-linked revenue loss.
* Support informed pricing strategies by identifying underperforming ticket classes or premium offerings. 
#### Customer Experience & Retention
* Identify patterns in refund behavior across demographics to tailor communications, improve services , and reduce churn. 
#### Resource deployment & optimisation
* Improve forecasting of disruption-prone periods to enable improvement in staffing, train allocation, and operational planning.
## TOOLS USED 
#### SQL 
* Data Extraction and loading 
* Data Cleaning 
* Data Normalisation

#### Power BI
* Data Analysis Expression(DAX)
* Data Visualisation 
* Dashboard Design 
## REPOSITORY CONTENTS
#### SQL Scripts 
Each SQL script addresses different aspects of the rail service performance: 
| Script | Content |
|-------------|------------|
data_exploration_and_cleaning.sql | Initial data inspection, integrity checks, duplicates handling, and preparation for analysis 
delay_analysis.sql | Analysis of train delays, delay frequency, average delay durations, and delay reasons across routes 
refund_analysis.sql | Examination of refund trends, identifying refund triggers(delays,cancellations), and their financial impact. 
cancellation_analysis.sql | Insights into service cancellations, cancellation rates by routes, and associated reasons
operational_performance(Summary_KPIs).sql | Aggregated performance metrics, summary KPIs, journey disruptions grouped by routes , route reliability
#### Power BI Dashboard 
The interactive dashboard consolidates key operational metrics across all departure stations, and includes filters to view performance data for individual stations. 
This dashboard provides a high-level overview of all rail service performance across all departure stations, enabling stakeholders to: 
* Monitor overall journey disruptions 
* Compare refund and punctuality rates by station
* Track monthly revenue alongside potential loss from refunds 
* Review core KPIs (tickets sold, average ticket price, total revenue, total refund value)
* Analyse ticket sales distribution by purchase channel and class 




