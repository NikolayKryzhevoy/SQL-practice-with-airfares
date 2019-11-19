/*
Objective

Given an airfare data 
(https://docs.google.com/spreadsheets/d/1JOQ5bnInxX9Mpf_3xtsX38cw-G1uctiu5jTrjzkJoh0/edit#gid=809136041)
covering the top 1,000 contiguous state city-pair markets. Help a company analyze this data and identify trends.
*/

-- What range of years is represented in the data?
SELECT DISTINCT Year
FROM airfare_data
ORDER BY Year;
-- There are entries for 23 years: 1996-2018

-- What are the shortest and longest-distanced flights, and between which 2 cities are they?
SELECT city1, city2, MAX(nsmiles)
FROM airfare_data;
-- The longest-distance flight is Miami-Seattle: 2724 miles 
--
SELECT city1, city2, MIN(nsmiles)
FROM airfare_data;
-- The shortest-distance flight is Los Angeles-San Diego: 109 miles 

-- How many distinct cities are represented in the data?
SELECT citymarketid_1, city1
FROM airfare_data
UNION 
SELECT citymarketid_2, city2
FROM airfare_data;
-- There are 163 distinct cities (regardless of whether a city is the source or destination)

-- How many distinct airport pairs are there in the database? 
SELECT citymarketid_1, citymarketid_2, city1, city2
FROM airfare_data
GROUP BY 1, 2;
-- There are 1610 distinct pairs (flight routes) 

--How many passengers were transported for the whole period?
SELECT SUM(passengers)
FROM airfare_data;
-- 72,244,723,  more than 72,2Mio

--How many passengers were transported by year?
SELECT Year, SUM(passengers)/1000000. as 'Tot_Passengers (Mio)'
FROM airfare_data
GROUP BY 1
HAVING CAST(Year as INTEGER) < 2018;
/* As seen from figure 'TotPass_vs_Year.png', the total amount of passengers has grown 
from 2.39 Mio in 1996 to 3.90 Mio in 2017 (63%). There were two recessions: one in 
2001-2002 and 2008-2009 likely caused by the terror acts and the financial crisis, respectively
*/  

--What were the busiest directions?
SELECT citymarketid_1, citymarketid_2, city1, city2, SUM(passengers) as Total_Passengers
FROM airfare_data
GROUP BY 1, 2
ORDER BY 5 DESC;
-- LA - SF  1,738,196 passengers
-- Miami - NYC  1,225,916 passengers  
-- LA - NYC 893,802 passengers

-- Which flights were the most(least) cost effective for passengers?
SELECT Year, quarter, city1, city2, fare/nsmiles, nsmiles/fare, fare, nsmiles, passengers
FROM airfare_data
ORDER BY 5 DESC;
/* The flight Atlanta--Nashvill (2nd quarter, 2008, 214 miles, 182 passengers) was the least cost effective:
each mile cost 1.73$ for a passenger, or a passenger could fly only 0.58 miles for a 1$ paid
The flight Columbus--Las Vegas (1st quarter, 1996, 1772 miles, 766 passengers) was the most cost effective:
each mile cost 4.7Ct for a passenger, or a passenger could fly 21 miles(!) for a 1$ paid
*/

-- Which flights were the most(least) cost effective for airlines?
SELECT Year, quarter, city1, city2, fare*passengers/nsmiles, fare, nsmiles, passengers
FROM airfare_data
ORDER BY 5 DESC;
/* The flight Los Angeles--San Francisco (2nd quarter, 2016, 372 miles, 21242 passengers) was the most cost 
effective for a company: the airline earned $8542.0 for each mile. The least cost effective was the flight 
Buffalo--San Diego (4th quater, 2001, 2196 miles, 142 passengers): the company earned $8.91 per mile
*/

-- Which airline appear most frequently as the carrier with the lowest fare? 
SELECT carrier_low, COUNT(*)
FROM airfare_data
GROUP BY 1
ORDER BY 2 DESC;
-- WN: 29,652 times

-- How about the airline with the largest market share?
SELECT carrier_lg, COUNT(*)
FROM airfare_data
GROUP BY 1
ORDER BY 2 DESC;
-- WN: 23,659 times

-- How would you describe the overall trend in airfares from 1997 to 2017
-- What are the percent changes in average fare by flight for these years?
WITH tmp 
AS	(
	SELECT Year, AVG(fare) as 'Fare'
	FROM airfare_data
	GROUP BY 1
	)
SELECT A.Year, ROUND(A.Fare,2) as 'FareCurr', ROUND(B.Fare,2) as 'FarePrev', ROUND((A.Fare-B.Fare)/B.Fare*100.,2) as 'Percent_Change_Mean_Fare (%)'
FROM tmp A, tmp B
WHERE A.Year = B.Year+1;
/* 1996--2008 The fares were relatively modest, on average $181. The prices increased from $171 in 
1996 to $191 in 2000 but then droped in 2001 by almost 7.8% (terror acts and low number of passengers).
The period of low prices lasted 5 years till 2005. The prices started to grow only in 2006. 
In 2009 the fares droped again, now by almost 10% compared to year 2008 because of the financial crisis.
2009-2014 is a period of rapidly growing fares (31%). The prices bounced back in 2014 and stabilized 
around $218 in 2016-2018.    
*/

/*
What is the average fare for each quarter? Which quarter of the year has the highest overall average fare? lowest?
Not all flights have data from all 4 quarters. To avoid skewing the data I consider only flights that have 
data available for all 4 quarters.
*/
WITH tmp 
AS	(
	SELECT A.citymarketid_1 as IDc1, A.citymarketid_2 as IDc2, A.Year as Year, A.quarter as Q1, A.fare as FareQ1, B.quarter as Q2, B.fare as FareQ2, C.quarter as Q3, C.fare as FareQ3, D.quarter as Q4, D.fare as FareQ4 
	FROM airfare_data A
		INNER JOIN airfare_data B ON A.Year = B.Year AND B.quarter = 2 AND A.citymarketid_1 = B.citymarketid_1 AND A.citymarketid_2 = B.citymarketid_2
		INNER JOIN airfare_data C ON A.Year = C.Year AND C.quarter = 3 AND A.citymarketid_1 = C.citymarketid_1 AND A.citymarketid_2 = C.citymarketid_2
		INNER JOIN airfare_data D ON A.Year = D.Year AND D.quarter = 4 AND A.citymarketid_1 = D.citymarketid_1 AND A.citymarketid_2 = D.citymarketid_2 
	WHERE A.quarter = 1 
	)
SELECT Year, AVG(FareQ1) as AvgFareQ1, AVG(FareQ2) as AvgFareQ2, AVG(FareQ3) as AvgFareQ3, AVG(FareQ4) as AvgFareQ4
FROM tmp
GROUP BY 1
ORDER BY 1;
/* As seen from figure 'AvgFares_by_Quarter_over_Years.png' the prices in the first quarter (red)
were consistently larger between 1996 and 2004. Any quarter dependence of fares is absent after 2004.*/ 

-- Is there any dependence of the total amount of passengers on quarter?
WITH tmp 
AS	(
	SELECT A.citymarketid_1 as IDc1, A.citymarketid_2 as IDc2, A.Year as Year, A.quarter as Q1, A.passengers as PassQ1, B.quarter as Q2, B.passengers as PassQ2, C.quarter as Q3, C.passengers as PassQ3, D.quarter as Q4, D.passengers as PassQ4 
	FROM airfare_data A
		INNER JOIN airfare_data B ON A.Year = B.Year AND B.quarter = 2 AND A.citymarketid_1 = B.citymarketid_1 AND A.citymarketid_2 = B.citymarketid_2
		INNER JOIN airfare_data C ON A.Year = C.Year AND C.quarter = 3 AND A.citymarketid_1 = C.citymarketid_1 AND A.citymarketid_2 = C.citymarketid_2
		INNER JOIN airfare_data D ON A.Year = D.Year AND D.quarter = 4 AND A.citymarketid_1 = D.citymarketid_1 AND A.citymarketid_2 = D.citymarketid_2 
	WHERE A.quarter = 1 
	)
SELECT Year, SUM(PassQ1) as Pass_Q1, SUM(PassQ2) as Pass_Q2, SUM(PassQ3) as Pass_Q3, SUM(PassQ4) as Pass_Q4
FROM tmp
GROUP BY 1
ORDER BY 1;
/* Yes.  As seen from figure 'TotPass_by_Quarter_over_Years.png' the passengers prefer to
travel in the year's second quarter (green) and stay at home in the first quarter (red)*/ 

