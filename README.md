# 🏭 Job Market Data Warehouse & Analytical Marts
 
A full end-to-end data engineering project that ingests real-world job market data into a structured MySQL Data Warehouse and builds four purpose-built analytical data marts for business intelligence and reporting.
 
---
 
## 📌 Project Overview
 
This project models and analyzes a large-scale job postings dataset (~390 MB of raw CSV data) covering hundreds of thousands of job listings worldwide. Raw CSV files are hosted on **Google Cloud Storage**, downloaded to a local machine using Python, bulk-loaded into MySQL, and then transformed into four analytical data marts — each targeting a specific analytics domain.
 
The pipeline covers everything from raw data ingestion to multi-layered analytical mart construction, with a focus on clean dimensional modeling, ETL best practices, and production-ready SQL.
 
**Key questions this project answers:**
- Which skills are most in demand across data roles?
- How do salaries vary by company, country, and job category?
- Which companies are hiring the most and where?
- How has hiring activity trended month-over-month?
- Which priority roles (e.g. Senior Data Engineer) have the highest demand?
---


## 🏗️ Architecture 
```
Google Cloud Storage (public bucket)
          │
          │  HTTP streaming  (data_download.py)
          ▼
  Local machine  /data/
  ├── company_dim.csv        (~44 MB)
  ├── skills_dim.csv         (~5 KB)
  ├── skills_job_dim.csv     (~74 MB)
  └── job_postings_fact.csv  (~268 MB)
          │
          │  LOAD DATA LOCAL INFILE  (Load_data_in_mysql.py)
          ▼
  MySQL — data_warehouse
  ├── company_dim
  ├── skills_dim
  ├── skills_job_dim
  └── job_postings_fact
          │
          │  SQL INSERT...SELECT  (ETL transforms)
          ▼
  Analytical Marts
  ├── flat_mart
  ├── skill_mart
  ├── priority_mart
  └── company_mart
```

![Data Architecture](https://github.com/user-attachments/assets/ff424160-1c0a-4e6e-8b7a-ab2f3e87a61b)

