# 🏛️ Data Warehouse
 
This document covers everything about the Data Warehouse layer — how the source data is downloaded from Google Cloud Storage, loaded into MySQL using Python, and how the warehouse tables are structured.
 
← [Back to Main README](https://github.com/Rameshsah08/job-Market-Data-Warehouse-Analytical-Marts/blob/main/README.md)
 
---
![Data Architecture](https://github.com/user-attachments/assets/ff424160-1c0a-4e6e-8b7a-ab2f3e87a61b)

## Overview
 
The Data Warehouse is a **star schema** built in MySQL. It stores all raw job market data in a clean, normalised structure with full referential integrity. All four analytical marts are built on top of this layer.
 
```
                    ┌─────────────────┐
                    │  company_dim    │
                    │  (dimension)    │
                    └────────┬────────┘
                             │ FK: company_id
┌───────────────┐   ┌────────▼──────────────┐   ┌──────────────────┐
│  skills_dim   │   │  job_postings_fact    │   │  skills_job_dim  │
│  (dimension)  │◄──│  (fact table)         │──►│  (bridge table)  │
└───────────────┘   └───────────────────────┘   └──────────────────┘
```
 
---
 
## Tables
 ### `job_postings_fact` — Fact Table
The central table. One row per job posting.
 
| Column | Type | Description |
|---|---|---|
| `job_id` | INT PK | Unique job posting identifier |
| `company_id` | INT FK | Links to `company_dim` |
| `job_title_short` | VARCHAR | Standardised role category (e.g. Data Engineer) |
| `job_title` | VARCHAR | Full job title as posted |
| `job_location` | VARCHAR | City or region |
| `job_via` | VARCHAR | Platform where the job was posted |
| `job_schedule_type` | VARCHAR | Full-time, Part-time, Contract, etc. |
| `job_work_from_home` | TINYINT | 1 = remote, 0 = on-site |
| `job_posted_date` | DATETIME | Date the posting went live |
| `job_no_degree_mention` | TINYINT | 1 = no degree required |
| `job_health_insurance` | TINYINT | 1 = health insurance offered |
| `job_country` | VARCHAR | Country of the posting |
| `salary_rate` | VARCHAR | hourly or yearly |
| `salary_year_avg` | DOUBLE | Average annual salary |
| `salary_hour_avg` | DOUBLE | Average hourly salary |
 
---
 
### `company_dim` — Company Dimension
One row per company. Linked to job postings via `company_id`.
 
| Column | Type | Description |
|---|---|---|
| `company_id` | INT PK | Unique company identifier |
| `name` | VARCHAR | Company name |
| `link` | TEXT | Company website |
| `link_google` | TEXT | Google search link |
| `thumbnail` | TEXT | Company logo URL |
 
---
 
### `skills_dim` — Skills Dimension
Master list of all skills. One row per skill.
 
| Column | Type | Description |
|---|---|---|
| `skill_id` | INT PK | Unique skill identifier |
| `skills` | VARCHAR | Skill name (e.g. Python, SQL, AWS) |
| `type` | VARCHAR | Skill category (e.g. programming, cloud, databases) |
 
---
 
### `skills_job_dim` — Bridge Table
Resolves the many-to-many relationship between job postings and skills. One job can require many skills; one skill can appear in many jobs.
 
| Column | Type | Description |
|---|---|---|
| `job_id` | INT FK | Links to `job_postings_fact` |
| `skill_id` | INT FK | Links to `skills_dim` |
 
---
 
## Schema Diagram
 
<img width="641" height="475" alt="Tables and relation" src="https://github.com/user-attachments/assets/36f17810-6f09-4708-8d5e-86abe1278438" />


## Prerequisites
 
- [MySQL 8.0+](https://www.mysql.com/) with `local_infile` enabled
- [Python 3.8+](https://www.python.org/)
-  [Visual Studio Code](https://code.visualstudio.com/docs/setup/windows)
```bash
pip install sqlalchemy mysql-connector-python requests
```
 
| Package | Docs |
|---|---|
| `sqlalchemy` | [sqlalchemy.org](https://www.sqlalchemy.org/) |
| `mysql-connector-python` | [dev.mysql.com/doc/connector-python](https://dev.mysql.com/doc/connector-python/en/) |
| `requests` | [requests.readthedocs.io](https://requests.readthedocs.io/en/latest/) |
 
