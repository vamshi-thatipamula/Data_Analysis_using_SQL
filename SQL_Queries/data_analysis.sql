/* ============================================================
PROJECT: DATA ANALYSIS USING SQL

DESCRIPTION: This SQL script performs exploratory and analytical queries on a movie dataset containing information about movies, actors, financial performance, and languages.
The analysis progresses from basic exploration to advanced analytical techniques using joins, aggregations, Common Table Expressions (CTEs), and window functions.
============================================================ */


/* ============================================================
SECTION 1: DATA EXPLORATION
Purpose: Understand dataset distribution and structure
============================================================ */

/* ------------------------------------------------------------
Query Name: Total Number of Movies
------------------------------------------------------------- */
SELECT COUNT(*) AS total_movies FROM movies;
-- Insight: This query identifies the total number of movies available in the dataset. It provides a starting point for understanding the dataset size.

/* ------------------------------------------------------------
Query Name: Total Number of Actors
------------------------------------------------------------- */
SELECT COUNT(*) AS total_actors FROM actors;
-- Insight: Determines the number of actors present in the dataset, giving an overview of actor coverage in the movie database.

/* ------------------------------------------------------------
Query Name: Movie Distribution by Industry
------------------------------------------------------------- */
SELECT industry, COUNT(*) AS movie_count FROM movies GROUP BY industry;
-- Insight: Shows how movie production is distributed across industries such as Hollywood and Bollywood.

/* ------------------------------------------------------------
Query Name: Movies Released Per Year
------------------------------------------------------------- */
SELECT release_year, COUNT(*) AS movie_count FROM movies GROUP BY release_year ORDER BY release_year;
-- Insight: Helps understand trends in movie production over time. It can reveal growth or decline in yearly movie releases.


/* ============================================================
SECTION 2: LANGUAGE DISTRIBUTION
============================================================ */

/* ------------------------------------------------------------
Query Name: Movie Count by Language
------------------------------------------------------------- */
SELECT l.name AS language, COUNT(*) AS movie_count FROM movies m JOIN languages l ON m.language_id = l.language_id GROUP BY l.name ORDER BY movie_count DESC;
-- Insight: Identifies the most common languages used in movies within the dataset.


/* ============================================================
SECTION 3: IMDB RATING ANALYSIS
============================================================ */

/* ------------------------------------------------------------
Query Name: Top 10 Highest Rated Movies
------------------------------------------------------------- */
SELECT title, imdb_rating FROM movies WHERE imdb_rating IS NOT NULL ORDER BY imdb_rating DESC LIMIT 10;
-- Insight: Lists the highest-rated movies according to IMDb ratings.

/* ------------------------------------------------------------
Query Name: Average IMDb Rating by Industry
------------------------------------------------------------- */
SELECT industry, ROUND(AVG(imdb_rating),2) AS avg_rating FROM movies WHERE imdb_rating IS NOT NULL GROUP BY industry;
-- Insight: Compares the average movie rating across industries, helping identify which industry produces higher-rated films.


/* ============================================================
SECTION 4: STUDIO ANALYSIS
============================================================ */

/* ------------------------------------------------------------
Query Name: Movie Production by Studio
------------------------------------------------------------- */
SELECT studio, COUNT(*) AS movie_count FROM movies WHERE studio <> '' GROUP BY studio ORDER BY movie_count DESC;
-- Insight: Identifies studios that produce the highest number of movies in the dataset.


/* ============================================================
SECTION 5: ACTOR PARTICIPATION
============================================================ */

/* ------------------------------------------------------------
Query Name: Actors Appearing in Each Movie
------------------------------------------------------------- */
SELECT m.title, GROUP_CONCAT(a.name SEPARATOR ', ') AS actors FROM movies m JOIN movie_actor ma ON m.movie_id = ma.movie_id JOIN actors a ON ma.actor_id = a.actor_id GROUP BY m.movie_id, m.title;
-- Insight: Displays all actors appearing in each movie. GROUP_CONCAT ensures that multiple actors are listed in a single row per movie.

/* ------------------------------------------------------------
Query Name: Actors with Most Movie Appearances
------------------------------------------------------------- */
SELECT a.name, COUNT(ma.movie_id) AS movie_count FROM actors a JOIN movie_actor ma ON a.actor_id = ma.actor_id GROUP BY a.name ORDER BY movie_count DESC LIMIT 10;
-- Insight: Identifies the most frequently appearing actors in the dataset.

/* ------------------------------------------------------------
Query Name: Actors with Highest Average Movie Rating
------------------------------------------------------------- */
SELECT a.name, ROUND(AVG(m.imdb_rating),2) AS avg_rating FROM actors a JOIN movie_actor ma ON a.actor_id = ma.actor_id JOIN movies m ON ma.movie_id = m.movie_id WHERE imdb_rating IS NOT NULL
GROUP BY a.name ORDER BY avg_rating DESC LIMIT 10;
-- Insight: Highlights actors who consistently appear in highly rated movies.


/* ============================================================
SECTION 6: FINANCIAL DATA NORMALIZATION
Convert units to millions and normalize currency
============================================================ */

/* ------------------------------------------------------------
Query Name: Financial Data Converted to Millions
------------------------------------------------------------- */
SELECT movie_id, budget, revenue, unit, currency, 
ROUND((CASE WHEN unit = 'billions' THEN budget * 1000 WHEN unit = 'thousands' THEN budget / 1000 ELSE budget END) * (CASE WHEN currency = 'USD' THEN 90 ELSE 1 END), 2) AS budget_miilions,
ROUND((CASE WHEN unit = 'billions' THEN revenue * 1000 WHEN unit = 'thousands' THEN revenue / 1000 ELSE revenue END) * (CASE WHEN currency = 'USD' THEN 90 ELSE 1 END), 2)  AS revenue_millions FROM financials;
-- Insight: Financial values are standardized to millions and converted to INR equivalents when currency is USD.


/* ============================================================
SECTION 7: FINANCIAL PERFORMANCE
============================================================ */

/* ------------------------------------------------------------
Query Name: Top 10 Movies by Budget
------------------------------------------------------------- */

WITH financial_clean AS (SELECT movie_id,
ROUND((CASE WHEN unit='billions' THEN budget*1000 WHEN unit='thousands' THEN budget/1000 ELSE budget END) * (CASE WHEN currency='USD' THEN 90 ELSE 1 END), 2)  AS budget_millions,
ROUND((CASE WHEN unit='billions' THEN revenue*1000 WHEN unit='thousands' THEN revenue/1000 ELSE revenue END) * (CASE WHEN currency='USD' THEN 90 ELSE 1 END), 2) AS revenue_millions FROM financials) 
SELECT m.title, fc.budget_millions FROM movies m JOIN financial_clean fc ON m.movie_id = fc.movie_id ORDER BY fc.budget_millions DESC LIMIT 10;
-- Insight: Identifies the movies with the largest production budgets.

/* ------------------------------------------------------------
Query Name: Top 10 Movies by Revenue
------------------------------------------------------------- */

WITH financial_clean AS (SELECT movie_id,
ROUND((CASE WHEN unit='billions' THEN revenue*1000 WHEN unit='thousands' THEN revenue/1000 ELSE revenue END) * (CASE WHEN currency='USD' THEN 90 ELSE 1 END), 2) AS revenue_millions FROM financials)
SELECT m.title, fc.revenue_millions FROM movies m JOIN financial_clean fc ON m.movie_id = fc.movie_id ORDER BY fc.revenue_millions DESC LIMIT 10;
-- Insight: Highlights movies that generated the highest revenue.

/* ------------------------------------------------------------
Query Name: Most Profitable Movies
------------------------------------------------------------- */
WITH financial_clean AS (SELECT movie_id,
ROUND((CASE WHEN unit='billions' THEN budget*1000 WHEN unit='thousands' THEN budget/1000 ELSE budget END) * (CASE WHEN currency='USD' THEN 90 ELSE 1 END), 2) AS budget_millions,
ROUND((CASE WHEN unit='billions' THEN revenue*1000 WHEN unit='thousands' THEN revenue/1000 ELSE revenue END) * (CASE WHEN currency='USD' THEN 90 ELSE 1 END),2 ) AS revenue_millions FROM financials)
SELECT m.title, revenue_millions - budget_millions AS profit_millions FROM movies m JOIN financial_clean fc ON m.movie_id = fc.movie_id ORDER BY profit_millions DESC;
-- Insight: Calculates profit to determine which movies were the most financially successful.


/* ============================================================
SECTION 8: COMMON TABLE EXPRESSIONS (CTE)
============================================================ */

/* ------------------------------------------------------------
Query Name: Movie Profit Using CTE
------------------------------------------------------------- */
WITH financial_clean AS (SELECT movie_id,
ROUND((CASE WHEN unit='billions' THEN revenue*1000 WHEN unit='thousands' THEN revenue/1000 ELSE revenue END) *
(CASE WHEN currency='USD' THEN 90 ELSE 1 END) - (CASE WHEN unit='billions' THEN budget*1000 WHEN unit='thousands' THEN budget/1000 ELSE budget END) * (CASE WHEN currency='USD' THEN 90 ELSE 1 END), 2)
AS profit_millions FROM financials)
SELECT m.title, fc.profit_millions FROM financial_clean fc JOIN movies m ON fc.movie_id = m.movie_id ORDER BY profit_millions DESC;
-- Insight: Uses a CTE to simplify profit calculation and identify the most profitable movies.


/* ============================================================
SECTION 9: WINDOW FUNCTIONS
============================================================ */

/* ------------------------------------------------------------
Query Name: Revenue Ranking of Movies
------------------------------------------------------------- */
WITH financial_clean AS (SELECT movie_id, ROUND((CASE WHEN unit='billions' THEN revenue*1000 WHEN unit='thousands' THEN revenue/1000 ELSE revenue END) *
(CASE WHEN currency='USD' THEN 90 ELSE 1 END), 2) AS revenue_millions FROM financials)
SELECT m.title, fc.revenue_millions, RANK() OVER (ORDER BY revenue_millions DESC) AS revenue_rank FROM movies m JOIN financial_clean fc ON m.movie_id = fc.movie_id;
-- Insight: Ranks movies based on revenue performance.

/* ------------------------------------------------------------
Query Name: Movie Ranking by IMDb Rating
------------------------------------------------------------- */
SELECT title, imdb_rating, DENSE_RANK() OVER (ORDER BY imdb_rating DESC) AS rating_rank FROM movies WHERE imdb_rating IS NOT NULL;
-- Insight: Assigns rankings to movies based on IMDb ratings.

/* ------------------------------------------------------------
Query Name: Top Rated Movies Per Industry
------------------------------------------------------------- */
SELECT * FROM (SELECT title, industry, imdb_rating, RANK() OVER (PARTITION BY industry ORDER BY imdb_rating DESC) AS industry_rank FROM movies WHERE imdb_rating IS NOT NULL) ranked_movies WHERE industry_rank = 1;
-- Insight: Identifies the highest-rated movie within each industry.

/* ------------------------------------------------------------
Query Name: Cumulative Movie Releases Over Time
------------------------------------------------------------- */
SELECT release_year, COUNT(*) AS movies_released, SUM(COUNT(*)) OVER (ORDER BY release_year) AS cumulative_movies FROM movies GROUP BY release_year;
-- Insight: Shows how the total number of movies grows over time, indicating industry expansion trends.


/* ============================================================
FINAL INSIGHTS:
1. Hollywood movies generally have larger budgets compared to Bollywood movies.
2. A small number of actors appear in many movies, indicating concentration of star actors.
3. Higher budgets do not always guarantee higher IMDb ratings.
4. Certain studios dominate movie production.
5. Financial success varies significantly across industries.
============================================================ */


