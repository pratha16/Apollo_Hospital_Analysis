-- ============================================================
--  upGrad Data & AI Hackathon 2026
--  Apollo Hospital No-Show Risk Analysis | Level 3
-- ============================================================
--  Script   : 03_Analysis.sql
--  Author   : Sarthak (Analytics Engineer)
--  Date     : March 4, 2026
--  Purpose  : Exploratory analysis on apollo_cleaned.
--             Eight focused queries that answer the most
--             decision-relevant questions for Apollo Hospital.
--             Every query has a comment explaining why we
--             chose to look at that dimension — judges read
--             these comments, so keep them clear.
--
--  Baseline numbers from Script 02 (do not recalculate):
--  Total appointments : 110,521
--  Total no-shows     : 22,314
--  Overall no-show %  : 20.19%
--
--  Run after  : 02_Cleaning.sql (Nitishkumar)
--  Run before : 04_Views.sql
-- ============================================================

USE apollo;


-- ============================================================
--  QUERY 1 : Baseline confirmation
--
--  We re-confirm the baseline here so we know Script 03
--  is reading from apollo_cleaned correctly before anything
--  else runs. Numbers must match Script 02 Section C exactly.
-- ============================================================

SELECT
    COUNT(*)                                        AS total_appointments,
    SUM(no_show_flag)                               AS total_no_shows,
    ROUND(100.0 * SUM(no_show_flag) / COUNT(*), 2)  AS no_show_pct
FROM apollo_cleaned;

-- Expected: 110521 | 22314 | 20.19
-- If these do not match, stop and check apollo_cleaned.


-- ============================================================
--  QUERY 2 : No-show rate by wait_bucket
--
--  WHY THIS MATTERS:
--  Wait time is our primary hypothesis. We believe patients
--  who wait longer between booking and appointment are more
--  likely to forget, change plans, or lose motivation.
--  This query either confirms or challenges that hypothesis.
--  It is the most important single query in this script.
-- ============================================================

SELECT
    wait_bucket,
    COUNT(*)                                        AS total_appointments,
    SUM(no_show_flag)                               AS no_shows,
    ROUND(100.0 * SUM(no_show_flag) / COUNT(*), 2)  AS no_show_pct
FROM apollo_cleaned
GROUP BY wait_bucket
ORDER BY FIELD(wait_bucket,
    '0 - Same Day',
    '1-7 Days',
    '8-30 Days',
    '30+ Days',
    'Invalid');


-- ============================================================
--  QUERY 3 : No-show rate by age_group
--
--  WHY THIS MATTERS:
--  Different age groups have different relationships with
--  healthcare. Young adults may deprioritise appointments
--  due to work or lifestyle. Seniors may be more compliant
--  because they depend on regular medical care.
--  This query helps us identify which demographic needs
--  the most intervention.
-- ============================================================

SELECT
    age_group,
    COUNT(*)                                        AS total_appointments,
    SUM(no_show_flag)                               AS no_shows,
    ROUND(100.0 * SUM(no_show_flag) / COUNT(*), 2)  AS no_show_pct
FROM apollo_cleaned
GROUP BY age_group
ORDER BY no_show_pct DESC;


-- ============================================================
--  QUERY 4 : No-show rate by gender
--
--  WHY THIS MATTERS:
--  Gender-based differences in healthcare engagement are
--  well documented. If one gender shows significantly higher
--  no-show rates, reminder strategies can be targeted.
--  Note: this dataset only records M/F — we declare this
--  as a limitation in the PPT.
-- ============================================================

SELECT
    gender,
    COUNT(*)                                        AS total_appointments,
    SUM(no_show_flag)                               AS no_shows,
    ROUND(100.0 * SUM(no_show_flag) / COUNT(*), 2)  AS no_show_pct
FROM apollo_cleaned
GROUP BY gender
ORDER BY no_show_pct DESC;


-- ============================================================
--  QUERY 5 : No-show rate by SMS received
--
--  WHY THIS MATTERS:
--  SMS reminders are Apollo's most actionable intervention.
--  However, this analysis has a known risk: patients who
--  received SMS may have been pre-selected as high-risk.
--  If that is the case, higher no-show rates among SMS
--  recipients does not mean SMS causes no-shows — it means
--  the selection was biased. We document this in the PPT
--  as a limitation and do not make a causal claim.
-- ============================================================

SELECT
    sms_received,
    COUNT(*)                                        AS total_appointments,
    SUM(no_show_flag)                               AS no_shows,
    ROUND(100.0 * SUM(no_show_flag) / COUNT(*), 2)  AS no_show_pct
FROM apollo_cleaned
GROUP BY sms_received
ORDER BY sms_received;


-- ============================================================
--  QUERY 6 : No-show rate by appointment day of week
--
--  WHY THIS MATTERS:
--  Day of week affects patient behaviour and clinic capacity.
--  Monday appointments may have higher no-shows because
--  patients book on Friday and change plans over the weekend.
--  Saturday appointments are rare — likely special clinics.
--  Understanding this pattern helps Apollo distribute
--  reminder efforts across the week more effectively.
-- ============================================================

SELECT
    appointment_weekday,
    COUNT(*)                                        AS total_appointments,
    SUM(no_show_flag)                               AS no_shows,
    ROUND(100.0 * SUM(no_show_flag) / COUNT(*), 2)  AS no_show_pct
FROM apollo_cleaned
GROUP BY appointment_weekday
ORDER BY FIELD(appointment_weekday,
    'Monday','Tuesday','Wednesday',
    'Thursday','Friday','Saturday','Sunday');


-- ============================================================
--  QUERY 7 : No-show rate by chronic condition
--
--  WHY THIS MATTERS:
--  Patients with chronic conditions like hypertension or
--  diabetes depend on regular appointments for disease
--  management. Our hypothesis is they show lower no-show
--  rates because missing an appointment has direct health
--  consequences for them. This query tests that hypothesis.
--  If the data shows the opposite, that is an even more
--  interesting finding worth highlighting.
-- ============================================================

SELECT
    hypertension,
    diabetes,
    COUNT(*)                                        AS total_appointments,
    SUM(no_show_flag)                               AS no_shows,
    ROUND(100.0 * SUM(no_show_flag) / COUNT(*), 2)  AS no_show_pct
FROM apollo_cleaned
GROUP BY hypertension, diabetes
ORDER BY no_show_pct DESC;


-- ============================================================
--  QUERY 8 : Top 10 neighbourhoods by no-show rate
--
--  WHY THIS MATTERS:
--  Geographic location is a proxy for access barriers.
--  Neighbourhoods with poor transport links, lower income,
--  or fewer nearby clinics may show higher no-show rates
--  for structural reasons, not just individual behaviour.
--  We only include neighbourhoods with at least 100
--  appointments to avoid misleading rates from tiny samples.
-- ============================================================

SELECT
    neighbourhood,
    COUNT(*)                                        AS total_appointments,
    SUM(no_show_flag)                               AS no_shows,
    ROUND(100.0 * SUM(no_show_flag) / COUNT(*), 2)  AS no_show_pct
FROM apollo_cleaned
GROUP BY neighbourhood
HAVING COUNT(*) >= 100
ORDER BY no_show_pct DESC
LIMIT 10;


-- ============================================================
--  QUERY 9 : Combined risk — wait time + age group
--
--  WHY THIS MATTERS:
--  A young adult waiting 30+ days is very different from
--  a senior waiting 30+ days. This cross-tabulation finds
--  the highest risk combinations of age and wait time.
--  These are the patient segments Apollo should prioritise
--  for targeted SMS reminders and overbooking strategies.
--  This query also feeds directly into the Power BI heatmap.
-- ============================================================

SELECT
    age_group,
    wait_bucket,
    COUNT(*)                                        AS total_appointments,
    SUM(no_show_flag)                               AS no_shows,
    ROUND(100.0 * SUM(no_show_flag) / COUNT(*), 2)  AS no_show_pct
FROM apollo_cleaned
WHERE wait_bucket != 'Invalid'
  AND age_group   != 'Invalid'
GROUP BY age_group, wait_bucket
ORDER BY no_show_pct DESC;


-- ============================================================
--  Script 03 complete.
--
--  Key findings to pull out for PPT Slide 6 (Core Insights):
--  • Query 2 : Which wait bucket has the highest no-show rate?
--  • Query 3 : Which age group is highest risk?
--  • Query 5 : What is the SMS paradox showing?
--  • Query 9 : Which age + wait combination is highest risk?
--
--
--
--  Next step : Write 04_Views.sql
-- ============================================================