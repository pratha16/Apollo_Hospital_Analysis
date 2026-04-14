-- ============================================================
--  upGrad Data & AI Hackathon 2026
--  Apollo Hospital No-Show Risk Analysis | Level 3
-- ============================================================
--  Script   : 04_Views.sql
--  Author   : Sarthak (Analytics Engineer)
--  Date     : March 4, 2026
--  Purpose  : Create 3 production views on apollo_cleaned.
--             These are the only tables Prathamesh connects
--             Power BI to. He does not touch apollo_raw or
--             apollo_cleaned directly.
--
--  Views created:
--  vw_noshow_summary          → KPI cards
--  vw_noshow_by_age_wait      → heatmap, bar charts, slicers
--  vw_noshow_by_neighbourhood → geographic bar chart
--
--  Run after  : 03_Analysis.sql
--  Run before : Prathamesh opens Power BI
-- ============================================================

USE apollo;


-- ------------------------------------------------------------
-- VIEW 1 : vw_noshow_summary
--
--  One row summary of the entire clean dataset.
--  Feeds the 3 KPI cards at the top of the dashboard.
--  Total appointments, no-show rate, avg wait days,
--  and SMS coverage all come from this single view.
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW vw_noshow_summary AS
SELECT
    COUNT(*)                                            AS total_appointments,
    SUM(no_show_flag)                                   AS total_no_shows,
    COUNT(*) - SUM(no_show_flag)                        AS total_showed_up,
    ROUND(100.0 * SUM(no_show_flag) / COUNT(*), 2)      AS overall_no_show_pct,
    ROUND(AVG(wait_days), 1)                            AS avg_wait_days,
    SUM(CASE WHEN sms_received = 1 THEN 1 ELSE 0 END)   AS total_sms_sent,
    ROUND(100.0 * SUM(CASE WHEN sms_received = 1
        THEN 1 ELSE 0 END) / COUNT(*), 2)               AS sms_coverage_pct
FROM apollo_cleaned;


-- ------------------------------------------------------------
-- VIEW 2 : vw_noshow_by_age_wait
--
--  This is the most important view in the project.
--  It cross-tabulates age group and wait bucket together
--  which feeds the heatmap matrix — our centrepiece visual.
--
--  It also contains gender, sms_received, hypertension,
--  and diabetes as extra columns so Prathamesh can build
--  slicers and additional breakdowns without needing
--  any other view or table.
--
--  sort_order columns are added for both age and wait so
--  Power BI sorts them in logical order, not alphabetically.
--  Alphabetical would put "30+ Days" before "8-30 Days"
--  which makes no sense in a time-based analysis.
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW vw_noshow_by_age_wait AS
SELECT
    age_group,
    wait_bucket,
    gender,
    sms_received,
    hypertension,
    diabetes,

    -- Sort helpers for Power BI
    CASE age_group
        WHEN 'Child (0-17)'        THEN 1
        WHEN 'Young Adult (18-35)' THEN 2
        WHEN 'Adult (36-60)'       THEN 3
        WHEN 'Senior (60+)'        THEN 4
        ELSE 5
    END                                                 AS age_sort,
    CASE wait_bucket
        WHEN '0 - Same Day' THEN 1
        WHEN '1-7 Days'     THEN 2
        WHEN '8-30 Days'    THEN 3
        WHEN '30+ Days'     THEN 4
        ELSE 5
    END                                                 AS wait_sort,

    COUNT(*)                                            AS total_appointments,
    SUM(no_show_flag)                                   AS no_shows,
    ROUND(100.0 * SUM(no_show_flag) / COUNT(*), 2)      AS no_show_pct

FROM apollo_cleaned
WHERE age_group   != 'Invalid'
  AND wait_bucket != 'Invalid'
GROUP BY
    age_group,
    wait_bucket,
    gender,
    sms_received,
    hypertension,
    diabetes;


-- ------------------------------------------------------------
-- VIEW 3 : vw_noshow_by_neighbourhood
--
--  No-show rate by neighbourhood.
--  Minimum 100 appointments filter is applied here so
--  Power BI never shows misleading rates from tiny samples.
--  A neighbourhood with 5 appointments showing 40% no-show
--  is statistically meaningless and would confuse the jury.
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW vw_noshow_by_neighbourhood AS
SELECT
    neighbourhood,
    COUNT(*)                                            AS total_appointments,
    SUM(no_show_flag)                                   AS no_shows,
    ROUND(100.0 * SUM(no_show_flag) / COUNT(*), 2)      AS no_show_pct
FROM apollo_cleaned
GROUP BY neighbourhood
HAVING COUNT(*) >= 100
ORDER BY no_show_pct DESC;


-- ============================================================
--  VERIFY ALL 3 VIEWS WERE CREATED
-- ============================================================

-- Confirm views exist in the apollo schema
SELECT
    table_name      AS view_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'apollo'
  AND table_type   = 'VIEW'
ORDER BY table_name;

-- Row count check
-- vw_noshow_summary          → must return exactly 1 row
-- vw_noshow_by_age_wait      → should return 32 rows
--                              (4 age × 4 wait × 2 gender = more combinations)
-- vw_noshow_by_neighbourhood → should return all neighbourhoods with 100+ appointments
SELECT 'vw_noshow_summary'          AS view_name, COUNT(*) AS `rows` FROM vw_noshow_summary
UNION ALL
SELECT 'vw_noshow_by_age_wait'      AS view_name, COUNT(*) AS `rows` FROM vw_noshow_by_age_wait
UNION ALL
SELECT 'vw_noshow_by_neighbourhood' AS view_name, COUNT(*) AS `rows` FROM vw_noshow_by_neighbourhood;

-- Quick sanity check on the most important view
-- Numbers must match what Script 03 Query 9 returned
SELECT
    age_group,
    wait_bucket,
    no_show_pct
FROM vw_noshow_by_age_wait
ORDER BY age_sort, wait_sort;

-- ============================================================
--  Script 04 complete.
--
--  Pass to Prathamesh:
--  Database   : apollo
--  Views      : vw_noshow_summary
--               vw_noshow_by_age_wait
--               vw_noshow_by_neighbourhood
--  Connection : MySQL localhost, port 3306
--
--  Next step  : Prathamesh connects Power BI to these 3 views
--               Sarthak writes 05_Bonus.sql independently
-- ============================================================