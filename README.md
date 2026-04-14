# 🏥 Apollo Hospital No-Show Risk Analysis

A complete end-to-end data analysis project focused on understanding and predicting patient no-shows using SQL and Power BI.

This project was built as part of the **upGrad Data & AI Hackathon 2026 (Level 3)** and analyzes over **110,000 medical appointments** to uncover actionable insights.

---

## 📌 Problem Statement

Hospital appointment no-shows lead to:

- Revenue loss 💸  
- Wasted resources 🏥  
- Poor patient care  

👉 **Goal:** Identify patterns and high-risk segments to reduce no-show rates.

---

## 📊 Dataset Overview

- 📍 **Location:** Vitória, Brazil  
- 📅 **Year:** 2016  
- 📈 **Total Records:** 110,527  
- ✅ **Clean Records:** 110,521  
- ❌ **Overall No-Show Rate:** 20.19% (1 in 5 patients)  

### Features:
- Patient demographics (age, gender)  
- Appointment timing  
- Chronic conditions (diabetes, hypertension)  
- SMS reminders  
- Neighborhood data  

---

## 🧠 Key Insights

### ⏳ 1. Wait Time is the Biggest Factor
- Same-day: **4.65% no-show**  
- 30+ days: **33.00% no-show**  

👉 Longer wait = higher chance of skipping appointment  

---

### 👥 2. Young Adults = Highest Risk
- Young Adult + 30+ days → **39.5% no-show**  
- Senior + same day → **2.9%**  

👉 A massive **13x risk difference**

---

### 💊 3. Chronic Patients Are More Responsible
- With conditions: **~17.46% no-show**  
- Without conditions: **~20.92%**  

👉 Health urgency improves attendance  

---

### 📍 4. Location Matters

Some neighborhoods show significantly higher no-show rates  
→ Indicates transport or socioeconomic barriers  

---

## 🏗️ Project Architecture
Raw Data (CSV)
↓
01_Loading.sql
↓
apollo_raw (raw table)
↓
02_Cleaning.sql
↓
apollo_cleaned (clean dataset)
↓
03_Analysis.sql
↓
Insights & Queries
↓
04_Views.sql
↓
Power BI Dashboard (.pbix)


---

## 🗂️ Project Files

| File | Description |
|------|------------|
| `01_Loading.sql` | Creates database and loads raw CSV |
| `02_Cleaning.sql` | Data validation, cleaning, feature engineering |
| `03_Analysis.sql` | Core business insights queries |
| `04_Views.sql` | Production-ready views for dashboard |
| `Apollo_Analysis.pbix` | Power BI dashboard |
| `Presentation.pptx` | Final project presentation |

---

## ⚙️ Tech Stack

- 🐬 MySQL  
- 📊 Power BI  
- 🧮 SQL (Advanced queries, aggregations, CASE logic)  

---

## 🚀 How to Run This Project

### 1️⃣ Setup Database
sql
Run: 01_Loading.sql

2️⃣ Clean Data
Run: 02_Cleaning.sql

3️⃣ Perform Analysis
Run: 03_Analysis.sql

4️⃣ Create Views for Dashboard
Run: 04_Views.sql

5️⃣ Open Dashboard
- Open .pbix file in Power BI
- Connect to MySQL database
- Use views:
  - vw_noshow_summary
  - vw_noshow_by_age_wait
  - vw_noshow_by_neighbourhood

📉 Dashboard Highlights
- KPI Cards (No-show %, Total Appointments)
- Heatmap (Age vs Wait Time)
- Neighborhood Risk Analysis
- SMS Impact Analysis
  
⚠️ Assumptions & Limitations
- Age = 0 treated as valid (infants)
- SMS reminders are not randomly assigned → possible bias
Missing Data:
- Income
- Distance to hospital
- Reason for missing appointments

💡 Business Recommendations
- Reduce wait time (especially for young adults)
- Target SMS reminders for high-risk segments
- Investigate high-risk neighborhoods
