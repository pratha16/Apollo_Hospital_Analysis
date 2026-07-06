-- ============================================================
--  upGrad Data & AI Hackathon 2026
--  Apollo Hospital No-Show Risk Analysis | Level 3
-- ============================================================
--  Script   : 01_Loading.sql
--  Author   : Prathamesh More
--  Date     : March 3, 2026
--  Purpose  : Create the apollo database and load the raw CSV
--             into apollo_raw. No cleaning happens here.
--             All fixes and new columns are in 02_Cleaning.sql
-- ============================================================


-- ------------------------------------------------------------
-- STEP 1 : Create the database
-- ------------------------------------------------------------

DROP DATABASE IF EXISTS apollo;

CREATE DATABASE apollo
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE apollo;


-- ------------------------------------------------------------
-- STEP 2 : Create the raw table
--
--  Column names are cleaned up from the original CSV headers.
--  Example: "Hipertension" (typo in source) becomes hypertension
--  Example: "No-show" (has a dash) becomes no_show
--
--  scheduled_day and appointment_day are stored as DATETIME
--  because we parse the full timestamp during loading below.
--  Everything else comes in as-is from the source file.
-- ------------------------------------------------------------

DROP TABLE IF EXISTS apollo_raw;

CREATE TABLE apollo_raw (
    patient_id        BIGINT,
    appointment_id    BIGINT,
    gender            VARCHAR(1),
    scheduled_day     DATETIME,
    appointment_day   DATETIME,
    age               INT,
    neighbourhood     VARCHAR(100),
    scholarship       TINYINT,
    hypertension      TINYINT,
    diabetes          TINYINT,
    alcoholism        TINYINT,
    handicap          TINYINT,
    sms_received      TINYINT,
    no_show           VARCHAR(3)
);


-- ------------------------------------------------------------
-- STEP 3 : Load the CSV
--
--  DATE FIX EXPLAINED:
--  The CSV stores dates like this: 2016-04-29T18:38:08Z
--  The Z at the end means UTC timezone.
--  MySQL cannot parse the Z directly.
--  Fix: TRIM(TRAILING 'Z' FROM value) removes the Z first,
--  leaving 2016-04-29T18:38:08 which MySQL can parse cleanly.
--
--  We use @raw_ variables to hold the original string values
--  from the CSV, then convert them in the SET block below.
--
--  Update the filename if yours is different.
-- ------------------------------------------------------------

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/apollo_raw.csv'
INTO TABLE apollo_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    patient_id,
    appointment_id,
    gender,
    @raw_scheduled_day,
    @raw_appointment_day,
    age,
    neighbourhood,
    scholarship,
    hypertension,
    diabetes,
    alcoholism,
    handicap,
    sms_received,
    no_show
)
SET
    scheduled_day   = STR_TO_DATE(TRIM(TRAILING 'Z' FROM @raw_scheduled_day),  '%Y-%m-%dT%H:%i:%s'),
    appointment_day = STR_TO_DATE(TRIM(TRAILING 'Z' FROM @raw_appointment_day), '%Y-%m-%dT%H:%i:%s');

-- If you get a line ending error, change '\n' to '\r\n' above.
-- That usually happens with CSV files saved on Windows.


-- ------------------------------------------------------------
-- STEP 4 : Confirm the load worked
--
--  Standard Kaggle dataset has 110,527 rows.
--  If your number is very different, check:
--  • Filename matches exactly what is in the uploads folder
--  • Header row was skipped (IGNORE 1 ROWS)
--  • Try '\r\n' line terminator if count looks wrong
-- ------------------------------------------------------------

-- Total rows loaded
SELECT COUNT(*) AS total_rows_loaded FROM apollo_raw;

-- Visual check — make sure all columns have real data
SELECT * FROM apollo_raw LIMIT 10;

-- Confirm dates parsed correctly — should show proper datetime
-- not NULL. If you see NULL here the Z trim fix needs checking.
SELECT
    scheduled_day,
    appointment_day
FROM apollo_raw
LIMIT 5;


-- ============================================================
--  Done. Check your row count and date columns before moving on.
--  Share the row count with the team, then run 02_Cleaning.sql
-- ============================================================
