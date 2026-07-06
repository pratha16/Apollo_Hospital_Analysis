-- ============================================================
--  upGrad Data & AI Hackathon 2026
--  Apollo Hospital No-Show Risk Analysis | Level 3
-- ============================================================
--  Script   : 02_Cleaning.sql
--  Author   : Prathamesh More
--  Date     : March 3, 2026
--  Purpose  : Two things happen in this script.
--             First, we audit apollo_raw to find all data
--             quality issues and document them.
--             Second, we create apollo_cleaned as a separate
--             table with only valid rows and new computed
--             columns ready for analysis.
--
--  Table design:
--  apollo_raw     → original CSV data, never modified
--  apollo_cleaned → clean data used by all other scripts
--
--  Run after  : 01_Loading.sql
--  Run before : 03_Analysis.sql (Sarthak)
-- ============================================================

USE apollo;


-- ============================================================
--  SECTION A : FORENSIC AUDIT
--
--  Nothing is changed in this section.
--  Run each query, read the output, write down the numbers.
--  Every non-zero finding here goes onto PPT Slide 4.
--  A result of zero is also worth noting — it means the
--  data is clean on that dimension, which is honest reporting.
-- ============================================================


-- ------------------------------------------------------------
-- A1 : Total rows in raw table
--
--  This is our starting number. We compare it against
--  apollo_cleaned at the end to show how many rows
--  were excluded and why.
-- ------------------------------------------------------------

SELECT COUNT(*) AS total_raw_rows
FROM apollo_raw;


-- ------------------------------------------------------------
-- A2 : NULL check across all columns
--
--  We check every column for missing values.
--  If scheduled_day or appointment_day return NULLs here,
--  it means the date parsing in Script 01 failed for
--  some rows — those would need to be excluded.
-- ------------------------------------------------------------

SELECT
    SUM(CASE WHEN patient_id      IS NULL THEN 1 ELSE 0 END) AS null_patient_id,
    SUM(CASE WHEN appointment_id  IS NULL THEN 1 ELSE 0 END) AS null_appointment_id,
    SUM(CASE WHEN gender          IS NULL THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN scheduled_day   IS NULL THEN 1 ELSE 0 END) AS null_scheduled_day,
    SUM(CASE WHEN appointment_day IS NULL THEN 1 ELSE 0 END) AS null_appointment_day,
    SUM(CASE WHEN age             IS NULL THEN 1 ELSE 0 END) AS null_age,
    SUM(CASE WHEN neighbourhood   IS NULL THEN 1 ELSE 0 END) AS null_neighbourhood,
    SUM(CASE WHEN scholarship     IS NULL THEN 1 ELSE 0 END) AS null_scholarship,
    SUM(CASE WHEN hypertension    IS NULL THEN 1 ELSE 0 END) AS null_hypertension,
    SUM(CASE WHEN diabetes        IS NULL THEN 1 ELSE 0 END) AS null_diabetes,
    SUM(CASE WHEN alcoholism      IS NULL THEN 1 ELSE 0 END) AS null_alcoholism,
    SUM(CASE WHEN handicap        IS NULL THEN 1 ELSE 0 END) AS null_handicap,
    SUM(CASE WHEN sms_received    IS NULL THEN 1 ELSE 0 END) AS null_sms_received,
    SUM(CASE WHEN no_show         IS NULL THEN 1 ELSE 0 END) AS null_no_show
FROM apollo_raw;


-- ------------------------------------------------------------
-- A3 : Duplicate appointment IDs
--
--  Each row should be one unique appointment.
--  If the same appointment_id appears more than once,
--  that booking was recorded twice in the source system.
--  This inflates our totals and must be documented.
-- ------------------------------------------------------------

-- Show which IDs are duplicated
SELECT
    appointment_id,
    COUNT(*) AS occurrences
FROM apollo_raw
GROUP BY appointment_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 10;

-- Total count of affected rows
SELECT COUNT(*) AS total_duplicate_rows
FROM apollo_raw
WHERE appointment_id IN (
    SELECT appointment_id
    FROM apollo_raw
    GROUP BY appointment_id
    HAVING COUNT(*) > 1
);


-- ------------------------------------------------------------
-- A4 : Age problems
--
--  age < 0   : impossible, clear data entry error
--  age = 0   : could be a valid infant or an error
--              we keep age = 0 but declare it as assumption
--  age > 110 : biologically implausible
-- ------------------------------------------------------------

SELECT
    SUM(CASE WHEN age < 0   THEN 1 ELSE 0 END) AS negative_age,
    SUM(CASE WHEN age = 0   THEN 1 ELSE 0 END) AS zero_age,
    SUM(CASE WHEN age > 110 THEN 1 ELSE 0 END) AS age_over_110,
    MIN(age)                                    AS min_age,
    MAX(age)                                    AS max_age
FROM apollo_raw;


-- ------------------------------------------------------------
-- A5 : Appointment date before booking date
--
--  appointment_day must always be >= scheduled_day.
--  If appointment_day is earlier, the dates are corrupted.
--  These rows produce negative wait_days and must be excluded.
-- ------------------------------------------------------------

SELECT COUNT(*) AS appointment_before_booking
FROM apollo_raw
WHERE DATE(appointment_day) < DATE(scheduled_day);


-- ------------------------------------------------------------
-- A6 : no_show column values
--
--  Should only contain "Yes" or "No".
--  Reminder: "Yes" means patient DID NOT show up.
--  This counterintuitive naming is fixed in Section B
--  where we create a proper 0/1 numeric column.
-- ------------------------------------------------------------

SELECT
    no_show,
    COUNT(*) AS count
FROM apollo_raw
GROUP BY no_show;


-- ------------------------------------------------------------
-- A7 : Gender values
--
--  Should only be 'F' or 'M'.
-- ------------------------------------------------------------

SELECT
    gender,
    COUNT(*) AS count
FROM apollo_raw
GROUP BY gender;


-- ------------------------------------------------------------
-- A8 : Binary columns range check
--
--  All six columns below should only contain 0 or 1.
--  A max value above 1 means bad data came in from the source.
-- ------------------------------------------------------------

SELECT
    MIN(scholarship)  AS min_scholarship,   MAX(scholarship)  AS max_scholarship,
    MIN(hypertension) AS min_hypertension,  MAX(hypertension) AS max_hypertension,
    MIN(diabetes)     AS min_diabetes,      MAX(diabetes)     AS max_diabetes,
    MIN(alcoholism)   AS min_alcoholism,    MAX(alcoholism)   AS max_alcoholism,
    MIN(handicap)     AS min_handicap,      MAX(handicap)     AS max_handicap,
    MIN(sms_received) AS min_sms,           MAX(sms_received) AS max_sms
FROM apollo_raw;


-- ------------------------------------------------------------
-- A9 : Neighbourhood blank or null check
-- ------------------------------------------------------------

SELECT COUNT(*) AS blank_neighbourhood
FROM apollo_raw
WHERE neighbourhood IS NULL
   OR TRIM(neighbourhood) = '';


-- ============================================================
--  PAUSE HERE
--  Read all Section A results before going to Section B.
-- 
-- ============================================================


-- ============================================================
--  SECTION B : CREATE apollo_cleaned
--
--  We create a brand new table here.
--  apollo_raw is never touched.
--
--  What goes into apollo_cleaned:
--  • Only valid rows (no negative age, no corrupted dates)
--  • All original columns carried over as-is
--  • New computed columns added on top:
--    - no_show_flag     : 0/1 version of no_show
--    - wait_days        : days between booking and appointment
--    - wait_bucket      : wait_days grouped into ranges
--    - age_group        : age grouped into demographic buckets
--    - appointment_weekday : day of week of the appointment
-- ============================================================


-- ------------------------------------------------------------
-- B1 : Drop and create apollo_cleaned
-- ------------------------------------------------------------

DROP TABLE IF EXISTS apollo_cleaned;

CREATE TABLE apollo_cleaned AS
SELECT
    -- Original columns carried over exactly as loaded
    patient_id,
    appointment_id,
    gender,
    scheduled_day,
    appointment_day,
    age,
    neighbourhood,
    scholarship,
    hypertension,
    diabetes,
    alcoholism,
    handicap,
    sms_received,
    no_show,

    -- no_show_flag
    -- Converts the confusing "Yes"/"No" text into 0 and 1.
    -- "Yes" = patient did NOT show up = 1 (no-show happened)
    -- "No"  = patient showed up       = 0 (no-show did not happen)
    CASE
        WHEN no_show = 'Yes' THEN 1
        WHEN no_show = 'No'  THEN 0
        ELSE NULL
    END AS no_show_flag,

    -- wait_days
    -- How many days passed between booking and appointment.
    -- This is the most important variable in our analysis.
    DATEDIFF(
        DATE(appointment_day),
        DATE(scheduled_day)
    ) AS wait_days,

    -- wait_bucket
    -- Groups wait_days into ranges for charts and aggregations.
    -- These exact labels are used in Script 03, 04 and Power BI
    -- so all numbers stay consistent across the whole project.
    CASE
        WHEN DATEDIFF(DATE(appointment_day), DATE(scheduled_day)) < 0
             THEN 'Invalid'
        WHEN DATEDIFF(DATE(appointment_day), DATE(scheduled_day)) = 0
             THEN '0 - Same Day'
        WHEN DATEDIFF(DATE(appointment_day), DATE(scheduled_day)) BETWEEN 1 AND 7
             THEN '1-7 Days'
        WHEN DATEDIFF(DATE(appointment_day), DATE(scheduled_day)) BETWEEN 8 AND 30
             THEN '8-30 Days'
        WHEN DATEDIFF(DATE(appointment_day), DATE(scheduled_day)) > 30
             THEN '30+ Days'
    END AS wait_bucket,

    -- age_group
    -- Standard demographic buckets used in healthcare analysis.
    CASE
        WHEN age < 0                 THEN 'Invalid'
        WHEN age BETWEEN 0  AND 17   THEN 'Child (0-17)'
        WHEN age BETWEEN 18 AND 35   THEN 'Young Adult (18-35)'
        WHEN age BETWEEN 36 AND 60   THEN 'Adult (36-60)'
        WHEN age > 60                THEN 'Senior (60+)'
    END AS age_group,

    -- appointment_weekday
    -- Day of week the appointment was scheduled on.
    -- Used in day-of-week no-show pattern analysis.
    DAYNAME(DATE(appointment_day)) AS appointment_weekday

FROM apollo_raw

-- Exclusion rules — rows that fail these checks are left
-- in apollo_raw but do not make it into apollo_cleaned.
-- We document the excluded count at the end of this script.
WHERE age >= 0
  AND DATE(appointment_day) >= DATE(scheduled_day)
  AND no_show IN ('Yes', 'No');


-- ============================================================
--  SECTION C : VERIFY apollo_cleaned
--
--  Run all of these after the table is created.
--  Share the final numbers with the full team.
-- ============================================================

-- Row counts — raw vs clean vs excluded
SELECT
    (SELECT COUNT(*) FROM apollo_raw)     AS raw_rows,
    (SELECT COUNT(*) FROM apollo_cleaned) AS clean_rows,
    (SELECT COUNT(*) FROM apollo_raw)
    - (SELECT COUNT(*) FROM apollo_cleaned) AS excluded_rows;

-- Confirm no bad data made it into apollo_cleaned
SELECT
    SUM(CASE WHEN wait_days < 0        THEN 1 ELSE 0 END) AS negative_wait_days,
    SUM(CASE WHEN age < 0              THEN 1 ELSE 0 END) AS negative_age,
    SUM(CASE WHEN no_show_flag IS NULL THEN 1 ELSE 0 END) AS null_no_show_flag
FROM apollo_cleaned;
-- All three should be 0. If not, check the WHERE clause above.

-- Overall no-show rate on clean data
-- This is the project baseline KPI — share this with everyone
SELECT
    COUNT(*)                                          AS total_appointments,
    SUM(no_show_flag)                                 AS total_no_shows,
    ROUND(100.0 * SUM(no_show_flag) / COUNT(*), 2)    AS overall_no_show_pct
FROM apollo_cleaned;

-- Distribution of new computed columns
SELECT wait_bucket,  COUNT(*) AS count FROM apollo_cleaned GROUP BY wait_bucket  ORDER BY count DESC;
SELECT age_group,    COUNT(*) AS count FROM apollo_cleaned GROUP BY age_group    ORDER BY count DESC;
SELECT appointment_weekday, COUNT(*) AS count FROM apollo_cleaned
GROUP BY appointment_weekday
ORDER BY FIELD(appointment_weekday,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

-- Final structure check
DESCRIBE apollo_cleaned;

-- ============================================================
--  Script 02 complete.
--
--  Document from Section A for PPT Slide 4:
--  • Duplicate appointment IDs found
--  • Negative age rows found
--  • Corrupted date rows found (appointment before booking)
--  • Any binary columns outside 0-1 range
--  • Total excluded_rows and the reason for exclusion
--
--  Share with the full team:
--  • clean_rows count
--  • overall_no_show_pct  ← this is the project baseline KPI
--
-- ============================================================
