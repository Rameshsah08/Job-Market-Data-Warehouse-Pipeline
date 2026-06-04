
# Job Market Data Warehouse & Analytical Marts
 
An end-to-end data engineering project that ingests real-world job posting data into a structured MySQL Data Warehouse and transforms it into four analytical data marts for business intelligence and reporting.
 
---
 
![Data Architecture](https://github.com/user-attachments/assets/ff424160-1c0a-4e6e-8b7a-ab2f3e87a61b)

---
 
## What Is This Project?
 
This project takes a large real-world dataset of job postings and builds a complete data engineering pipeline on top of it — from raw cloud storage files all the way through to structured, analytics-ready data marts.
 
The dataset contains hundreds of thousands of job listings from companies around the world, covering roles in data, engineering, and technology. Each posting includes information about the company, location, salary, required skills, schedule type, remote eligibility, and more.
 
The goal is to organise this raw data into a form that can answer real business questions about the job market — which skills are in demand, how salaries differ across companies and countries, which companies are hiring the most, and how all of this changes over time.
 
---
 
## How It Works
 
The pipeline has three main stages:
 
**Stage 1 — Data Ingestion**
Raw CSV files are stored on Google Cloud Storage. A Python script downloads them to a local machine using streaming HTTP requests, then a second Python script bulk-loads them into a MySQL Data Warehouse using `LOAD DATA LOCAL INFILE`.
 
**Stage 2 — Data Warehouse**
The warehouse is built as a star schema with one central fact table (`job_postings_fact`) surrounded by three dimension tables (`company_dim`, `skills_dim`, `skills_job_dim`). This normalised structure stores all the raw data cleanly with full referential integrity.
 
**Stage 3 — Data Marts**
Four analytical marts are built on top of the warehouse using SQL `INSERT...SELECT` transformations. Each mart is designed for a specific business use case — flat reporting, skill demand tracking, priority role monitoring, and company hiring analysis.
 
---
 
## Data Architecture
 
```
Google Cloud Storage
        │
        │  Python (requests — streaming download)
        ▼
Local Device  /data/
├── company_dim.csv
├── skills_dim.csv
├── skills_job_dim.csv
└── job_postings_fact.csv
        │
        │  Python (SQLAlchemy — LOAD DATA LOCAL INFILE)
        ▼
MySQL — data_warehouse
├── company_dim        (dimension)
├── skills_dim         (dimension)
├── skills_job_dim     (bridge)
└── job_postings_fact  (fact)
        │
        │  SQL ETL (INSERT...SELECT transforms)
        ▼
Analytical Marts
├── flat_mart          → denormalized reporting table
├── skill_mart         → monthly skill demand trends
├── priority_mart      → high-priority role monitoring
└── company_mart       → company hiring KPIs
```
 
---
 
## Project Layers
 
| Layer | What It Is | Detail |
|---|---|---|
| **Data Warehouse** | Star schema storing all raw job market data | [→ View Data Warehouse README](DATA_WAREHOUSE.md) |
| **Flat Mart** | Denormalized wide table — jobs, companies, skills in one row | [→ View Data Marts README](DATA_MARTS.md) |
| **Skill Mart** | Monthly demand metrics for each skill by job category | [→ View Data Marts README](DATA_MARTS.md) |
| **Priority Mart** | Job postings filtered and ranked by business-defined priority | [→ View Data Marts README](DATA_MARTS.md) |
| **Company Mart** | Monthly hiring KPIs — salary, remote share, degree trends | [→ View Data Marts README](DATA_MARTS.md) |
 
---
 
## Repository Structure
 
### 1. 🗃️ Dataset
All source data is hosted publicly on **Google Cloud Storage**.
 
| File | Description | Size | Download |
|---|---|---|---|
| `job_postings_fact.csv` | One row per job posting — salary, location, schedule, remote, degree flags | ~268 MB | [Download ↓](https://storage.googleapis.com/sql_de/job_postings_fact.csv) |
| `company_dim.csv` | Company profiles — name, links, thumbnail | ~44 MB | [Download ↓](https://storage.googleapis.com/sql_de/company_dim.csv) |
| `skills_job_dim.csv` | Many-to-many mapping of job postings to required skills | ~74 MB | [Download ↓](https://storage.googleapis.com/sql_de/skills_job_dim.csv) |
| `skills_dim.csv` | Master list of 250+ skills and their categories | ~5 KB | [Download ↓](https://storage.googleapis.com/sql_de/skills_dim.csv) |
 
---
 
### 2. 🏛️ Data Warehouse
→ Full detail in [DATA_WAREHOUSE.md](DATA_WAREHOUSE.md)
 
| File | Description |
|---|---|
| `create_data_warehouse.sql` | Creates the `data_warehouse` MySQL database |
| `data_download.py` | Downloads all four CSVs from Google Cloud Storage |
| `create_tables.sql` | Defines dimension and fact tables (star schema) |
| `Load_data_in_mysql.py` | Bulk loads CSVs into MySQL via SQLAlchemy |
| `warehouse_validation_queries.sql` | Data quality checks on warehouse tables |
 
---
 
### 3. 📊 Data Marts
→ Full detail in [DATA_MARTS.md](DATA_MARTS.md)
 
| File | Description |
|---|---|
| `create_flat_mart.sql` | Denormalized reporting table combining all job, company, and skill data |
| `create_priority_mart.sql` | Priority role monitoring mart with business-defined rankings |
| `create_skill_mart.sql` | Dimensional model for monthly skill demand analysis |
| `create_company_mart.sql` | Company hiring KPIs with salary distributions and workforce metrics |
| `mart_validation_queries.sql` | Data quality checks across all four mart schemas |
 
---
 
## Key Numbers
 
- **Job postings:** hundreds of thousands of real listings
- **Companies:** tens of thousands of unique employers
- **Skills tracked:** 250+ across programming, cloud, databases, and analyst tools
- **Countries covered:** global dataset
- **Time range:** monthly data enabling trend analysis over time
---
 
## Tech Stack
 
| Tool | Purpose |
|---|---|
| **MySQL 8+** | Data warehouse and all mart schemas |
| **Python 3** | Data download and ETL loading |
| **SQLAlchemy** | Database connection and query execution |
| **mysql-connector-python** | MySQL driver |
| **requests** | Streaming CSV downloads from GCS |
| **draw.io** | Architecture and schema diagrams |
 
---
 
## Technical Skills Demonstrated
 
- ✅ Data Warehouse Design & Star Schema Modeling
- ✅ Dimensional Modeling (facts, dimensions, bridge tables)
- ✅ ETL Pipeline Development
- ✅ MySQL Window Functions (`ROW_NUMBER`, `COUNT OVER`, `AVG OVER`)
- ✅ JSON Aggregation (`JSON_ARRAYAGG`, `JSON_OBJECT`)
- ✅ Common Table Expressions (CTEs)
- ✅ Bulk Data Loading (`LOAD DATA LOCAL INFILE`)
- ✅ Python–MySQL integration via SQLAlchemy
- ✅ Data Quality Standardization
- ✅ Median Salary Calculation (no native MEDIAN in MySQL)
- ✅ KPI Development for business analytics
---
 
## License
 
This project is for portfolio and educational purposes.




