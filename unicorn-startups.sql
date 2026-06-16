SQL PROJECT: Indian Unicorn Startups Analysis
Description:
This project analyzes Indian Unicorn Startups using SQL.The analysis covers data cleaning, feature engineering,financial performance, growth trends, valuation efficiency,
market share, startup segmentation, and advanced SQL analytics.

-- 1. DATABASE SETUP


CREATE DATABASE IF NOT EXISTS unicorn_analysis;
USE unicorn_analysis;

CREATE TABLE unicorns (
    startup_name VARCHAR(100),
    industry VARCHAR(100),
    founding_year INT,
    unicorn_entry_year INT,
    profit_loss_fy22 VARCHAR(100),
    current_valuation VARCHAR(100),
    acquisitions INT,
    status VARCHAR(100)
);

SELECT * FROM unicorns;

-- 2. DATA CLEANING & FEATURE ENGINEERING

ALTER TABLE unicorns
ADD COLUMN valuation_num DECIMAL(15,2),
ADD COLUMN profit_num_billions DECIMAL(15,4),
ADD COLUMN years_to_unicorn INT,
ADD COLUMN startup_age INT;

-- Clean valuation
UPDATE unicorns
SET valuation_num =
CASE
    WHEN current_valuation IS NULL
    OR TRIM(current_valuation) = ''
    OR current_valuation = 'NA'
    THEN NULL
    ELSE CAST(
        REPLACE(
            REPLACE(
                REPLACE(TRIM(current_valuation),'$',''),
            ' Billion',''),
        ',','')
    AS DECIMAL(15,2))
END;

-- Clean profit/loss

UPDATE unicorns
SET profit_num_billions =
CASE

  -- 1. Handle NULL / empty / junk
  WHEN profit_loss_fy22 IS NULL
    OR TRIM(profit_loss_fy22) = ''
    OR UPPER(TRIM(profit_loss_fy22)) IN ('NA','N/A','NULL')
  THEN NULL

  -- 2. Million values
  WHEN LOWER(profit_loss_fy22) LIKE '%million%' THEN
    ROUND(
      CAST(
        REPLACE(
          REPLACE(
            REPLACE(
              LOWER(TRIM(profit_loss_fy22)),
            '$',''),
          'million',''),
        ' ','')
      AS DECIMAL(15,4)) / 1000
    ,4)

  -- 3. Billion values
  WHEN LOWER(profit_loss_fy22) LIKE '%billion%' THEN
    ROUND(
      CAST(
        REPLACE(
          REPLACE(
            REPLACE(
              LOWER(TRIM(profit_loss_fy22)),
            '$',''),
          'billion',''),
        ' ','')
      AS DECIMAL(15,4))
    ,4)

  -- 4. Pure numeric values (handles -29.5, 37.8 etc.)
  WHEN profit_loss_fy22 REGEXP '^-?[0-9.]+$' THEN
    CAST(profit_loss_fy22 AS DECIMAL(15,4))

  ELSE NULL

END;
-- Years to unicorn
UPDATE unicorns
SET years_to_unicorn =
CASE
    WHEN unicorn_entry_year IS NOT NULL
     AND founding_year IS NOT NULL
     AND unicorn_entry_year >= founding_year
    THEN unicorn_entry_year - founding_year
    ELSE NULL
END;

-- Startup age
UPDATE unicorns
SET startup_age =
CASE
    WHEN founding_year IS NOT NULL
    THEN YEAR(CURDATE()) - founding_year
    ELSE NULL
END;


-- 3. GENERAL MARKET OVERVIEW

SELECT COUNT(*) AS total_unicorns
FROM unicorns;

SELECT
CONCAT('$',ROUND(SUM(valuation_num),2),' Billion')
AS total_market_valuation
FROM unicorns;

SELECT
status,
COUNT(*) AS startup_count
FROM unicorns
GROUP BY status
ORDER BY startup_count DESC;


-- 4. INDUSTRY ANALYSIS


SELECT
industry,
COUNT(*) AS startup_count
FROM unicorns
GROUP BY industry
ORDER BY startup_count DESC;

SELECT
industry,
ROUND(SUM(valuation_num),2) AS total_valuation
FROM unicorns
GROUP BY industry
ORDER BY total_valuation DESC;

SELECT
industry,
ROUND(AVG(acquisitions),2) AS avg_acquisitions
FROM unicorns
GROUP BY industry
ORDER BY avg_acquisitions DESC;


-- 5. FINANCIAL ANALYSIS


SELECT
startup_name,
industry,
valuation_num
FROM unicorns
ORDER BY valuation_num DESC
LIMIT 10;

SELECT
CASE
WHEN profit_num_billions > 0 THEN 'Profitable'
WHEN profit_num_billions < 0 THEN 'Loss Making'
ELSE 'Data Unavailable'
END AS financial_health,
COUNT(*) AS count
FROM unicorns
GROUP BY financial_health;

SELECT
industry,
ROUND(AVG(profit_num_billions),2) AS avg_profitability
FROM unicorns
WHERE profit_num_billions IS NOT NULL
GROUP BY industry
ORDER BY avg_profitability DESC;


-- 6. GROWTH ANALYSIS


SELECT
unicorn_entry_year,
COUNT(*) AS yearly_entries
FROM unicorns
GROUP BY unicorn_entry_year
ORDER BY yearly_entries DESC;

SELECT
startup_name,
industry,
years_to_unicorn
FROM unicorns
ORDER BY years_to_unicorn ASC
LIMIT 10;

SELECT
industry,
ROUND(AVG(years_to_unicorn),2) AS avg_years_to_unicorn
FROM unicorns
GROUP BY industry
HAVING COUNT(*) >= 3
ORDER BY avg_years_to_unicorn ASC;


-- 7. VALUATION EFFICIENCY ANALYSIS


SELECT
startup_name,
industry,
valuation_num,
years_to_unicorn,
ROUND(
valuation_num / NULLIF(years_to_unicorn,0),
2
) AS valuation_efficiency
FROM unicorns
WHERE years_to_unicorn IS NOT NULL
ORDER BY valuation_efficiency DESC;

-- 8. STARTUP MATURITY ANALYSIS


SELECT
startup_name,
industry,
startup_age,
valuation_num
FROM unicorns
ORDER BY startup_age DESC;


-- 9. STARTUP SEGMENTATION

SELECT
startup_name,
valuation_num,
CASE
WHEN valuation_num >= 20 THEN 'Elite Unicorn'
WHEN valuation_num >= 10 THEN 'Decacorn'
WHEN valuation_num >= 5 THEN 'High Growth Unicorn'
WHEN valuation_num >= 1 THEN 'Emerging Unicorn'
ELSE 'Others'
END AS valuation_band
FROM unicorns
ORDER BY valuation_num DESC;

-- 10. ADVANCED SQL ANALYSIS


SELECT *
FROM (
SELECT
startup_name,
industry,
valuation_num,
RANK() OVER(
PARTITION BY industry
ORDER BY valuation_num DESC
) AS industry_rank
FROM unicorns
) ranked
WHERE industry_rank = 1;

SELECT
startup_name,
valuation_num,
DENSE_RANK() OVER(
ORDER BY valuation_num DESC
) AS overall_rank
FROM unicorns;

SELECT *
FROM (
SELECT
startup_name,
unicorn_entry_year,
valuation_num,
ROW_NUMBER() OVER(
PARTITION BY unicorn_entry_year
ORDER BY valuation_num DESC
) AS yearly_rank
FROM unicorns
) ranked
WHERE yearly_rank = 1;


-- 11. MARKET SHARE ANALYSIS

SELECT
industry,
ROUND(SUM(valuation_num),2) AS industry_valuation,
ROUND(
100 * SUM(valuation_num)
/ SUM(SUM(valuation_num)) OVER (),
2
) AS market_share_percentage
FROM unicorns
GROUP BY industry
ORDER BY market_share_percentage DESC;

SELECT
startup_name,
valuation_num,
NTILE(4) OVER(
ORDER BY valuation_num DESC
) AS valuation_quartile
FROM unicorns;


-- 12. UNICORN SUCCESS SCORE ANALYSIS

SELECT
startup_name,
industry,
valuation_num,
years_to_unicorn,
acquisitions,
ROUND(
(valuation_num * 0.6)
+ ((10 - years_to_unicorn) * 0.3)
+ (COALESCE(acquisitions,0) * 0.1),
2
) AS success_score
FROM unicorns
WHERE years_to_unicorn IS NOT NULL
ORDER BY success_score DESC;

