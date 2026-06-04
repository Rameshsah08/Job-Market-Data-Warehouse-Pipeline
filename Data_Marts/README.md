# 📊 Data Marts
 
This document covers all four analytical data marts — what each one does, how it is structured, and how the marts relate to each other and to the Data Warehouse.

<img width="431" height="600" alt="warehouse_marts" src="YOUR_GITHUB_IMAGE_URL_HERE" />

## Overview
 
All four marts are built directly on top of the `data_warehouse` schema using SQL `INSERT...SELECT` transformations. Each mart is a separate MySQL schema designed for a specific analytics purpose — but they all share the same source tables, so their data is always consistent with one another.
 
```
                    data_warehouse
          ┌──────────────┬──────────────┐
          │              │              │
          ▼              ▼              ▼
     flat_mart      skill_mart    priority_mart
                                       
                    company_mart
```
 
### How the Marts Relate
 
| Mart | Grain | Source Tables Used | Primary Use Case |
|---|---|---|---|
| `flat_mart` | One row per job posting | `job_postings_fact`, `company_dim`, `skills_dim`, `skills_job_dim` | BI dashboards, ad-hoc reporting |
| `skill_mart` | One row per skill × month × job category | `job_postings_fact`, `skills_dim`, `skills_job_dim` | Skill demand trend analysis |
| `priority_mart` | One row per priority job posting | `job_postings_fact`, `company_dim` | Recruitment intelligence |
| `company_mart` | One row per company × job category × country × month | `job_postings_fact`, `company_dim` | Company hiring analytics |
 
All marts pull from the same `data_warehouse` source — so running the warehouse load once keeps all marts in sync.
 
---

## Mart 1 — Flat Mart (`flat_mart`)
<img width="250" height="400" alt="Flat_mart" src="YOUR_GITHUB_IMAGE_URL_HERE" />

### What It Does
 
The Flat Mart is the simplest and most accessible mart. It collapses all warehouse tables into a **single denormalized wide table** — one row per job posting, with company name already joined in and all required skills aggregated into a JSON array. No joins needed at query time.
 
It is designed to be the go-to source for BI tools, dashboards, and analysts who need to query job market data without writing complex SQL.
 
### ETL Process
 
```
job_postings_fact
      +                →  NULL/empty string standardization
company_dim            →  company name joined in
      +                →  skills aggregated as JSON array
skills_job_dim
      +
skills_dim
      ↓
flat_mart.flat_mart_job_posting
```
 
### Table: `flat_mart_job_posting`
 
| Column | Description |
|---|---|
| `job_id` | Unique job posting ID |
| `job_title_short` | Standardised role category |
| `job_title` | Full job title (NULL → `N/A`) |
| `job_location` | Location (NULL → `N/A`) |
| `job_via` | Posting platform (NULL → `N/A`) |
| `job_schedule_type` | Schedule type (NULL → `N/A`) |
| `job_work_from_home` | Remote flag |
| `job_posted_date` | Posting date |
| `job_no_degree_mention` | Degree requirement flag |
| `job_health_insurance` | Health insurance flag |
| `job_country` | Country (NULL → `N/A`) |
| `salary_rate` | hourly or yearly (NULL → `N/A`) |
| `salary_year_avg` | Average annual salary |
| `salary_hour_avg` | Average hourly salary |
| `company_name` | Company name joined from `company_dim` |
| `skills_and_type` | JSON array of `{type, name}` objects for all required skills |
 
 
### Key SQL Technique
```sql
JSON_ARRAYAGG(
    JSON_OBJECT('type', sd.type, 'name', sd.skills)
) AS skills_and_type
```
 

## Mart 2 — Skill Mart (`skill_mart`)
<img width="667" height="380" alt="skills_mart" src="YOUR_GITHUB_IMAGE_URL_HERE" />

### What It Does
 
The Skill Mart tracks **how demand for each skill changes over time** across different job categories. It answers questions like:
- Which skills are growing in demand month-over-month?
- Which skills appear most in remote jobs?
- Which skills are most common in jobs that don't require a degree?
- How does skill demand differ between Data Engineers and Data Scientists?
### Data Model
 
The mart follows a **dimensional model** with two dimension tables and one fact table.
 
```
dim_skill ──────────────────────────────────┐
                                             ▼
dim_date ───────────────────────► fact_skill_demand_monthly
```
 
### Tables
 
**`dim_skill`** — Skill dimension
 
| Column | Description |
|---|---|
| `skill_id` | Unique skill ID |
| `skills` | Skill name (e.g. Python, SQL, Spark) |
| `type` | Category (e.g. programming, cloud, databases) |
 
**`dim_date`** — Date dimension
 
| Column | Description |
|---|---|
| `month_start_date` | First day of the month (PK) |
| `year` | Year number |
| `month` | Month number |
| `quarter` | Quarter number |
| `quarter_name` | e.g. Q-1, Q-2 |
| `year_quarter` | e.g. 2023-Q1 |
 
**`fact_skill_demand_monthly`** — Monthly demand fact table
 
Grain: one row per **skill × month × job title category**
 
| Column | Description |
|---|---|
| `skill_id` | FK → `dim_skill` |
| `month_start_date` | FK → `dim_date` |
| `job_title_short` | Job role category |
| `postings_count` | Total job postings requiring this skill |
| `remote_posting_count` | Postings that are remote |
| `health_insurance_postings_count` | Postings offering health insurance |
| `no_degree_mention_count` | Postings with no degree requirement |
 
### Key SQL Technique
Business indicator flags are created in a CTE before aggregation:
```sql
CASE WHEN jpf.job_work_from_home = TRUE THEN 1 ELSE 0 END AS is_remote,
CASE WHEN jpf.job_health_insurance = TRUE THEN 1 ELSE 0 END AS has_health_insurance,
CASE WHEN jpf.job_no_degree_mention = TRUE THEN 1 ELSE 0 END AS no_degree_mentioned
```
Then aggregated with `COUNT(*)` and `SUM()` per skill × month × job category.
 
---

## Mart 3 — Priority Mart (`priority_mart`)
 
<img width="600" height="330" alt="priority_mart" src="YOUR_GITHUB_IMAGE_URL_HERE" />
 
### What It Does
 
The Priority Mart is a **recruitment intelligence layer**. It lets a business define which job roles are strategically important, assign them a priority level, and then monitor all job postings that match those roles — including salary and company information.
 
It is the only mart that has a **writeable reference table** (`priority_roles`) that can be updated as business needs change, without rebuilding the entire mart.
 
### Tables
 
**`priority_roles`** — Business-defined priority reference
 
| Column | Description |
|---|---|
| `role_id` | Unique role ID |
| `role_name` | Job title to monitor (e.g. Senior Data Engineer) |
| `priority_level` | Business ranking — 1 = highest priority |
 
**Current priority roles:**
 
| Role | Priority Level |
|---|---|
| Senior Data Engineer | 1 (highest) |
| Data Engineer | 1 (highest) |
| Software Engineer | 3 |
| Data Scientist | 4 |
 
**`priority_jobs`** — Matching job postings
 
| Column | Description |
|---|---|
| `job_id` | Job posting ID |
| `job_title_short` | Matched role name |
| `company_name` | Hiring company |
| `job_posted_date` | When the role was posted |
| `salary_year_avg` | Annual salary |
| `priority_level` | Inherited from `priority_roles` |
| `updated_at` | Timestamp of the last ETL refresh |
 
### How It Works
 
Job postings are matched to `priority_roles` via an `INNER JOIN` on `job_title_short`. Only postings for monitored roles are loaded — everything else is excluded.
 
```sql
INNER JOIN priority_roles AS r
    ON jpf.job_title_short = r.role_name
```
 
### Business Rule Updates
The mart supports live business rule changes without full rebuilds:
 
```sql
-- Promote Data Engineer to highest priority
UPDATE priority_mart.priority_roles
SET priority_level = 1
WHERE role_id = 1;
 
-- Add a new role to monitor
INSERT INTO priority_mart.priority_roles (role_id, role_name, priority_level)
VALUES (4, 'Data Scientist', 4);
```
 
## Mart 4 — Company Mart (`company_mart`)
 
![Company Mart Schema](Diagram_draw_oi/company_mart.png)
 
### What It Does
 
The Company Mart is the most complex mart in the project. It provides **monthly hiring analytics per company** — covering salary distributions, remote work adoption, health insurance offerings, and degree requirement trends. It is designed for workforce planning, salary benchmarking, and competitive hiring analysis.
 
### Data Model
 
A full dimensional model with five dimensions, two bridge tables, and one fact table.
 
```
dim_company ─────────────────────────────────────────┐
dim_location ────────────────────────────────────────┤
dim_date_month ──────────────────────────────────────► fact_company_hiring_monthly
dim_job_title_short ─────────────────────────────────┘
 
bridge_company_location  (company ↔ location)
bridge_job_title         (job category ↔ detailed title)
```
 
### Dimensions
 
| Table | Grain | Description |
|---|---|---|
| `dim_company` | One row per company | Company ID and name |
| `dim_location` | One row per country + location combination | Standardised job locations with NULL handling |
| `dim_date_month` | One row per month | Year and month attributes |
| `dim_job_title_short` | One row per job category | Standardised role categories (e.g. Data Engineer) |
| `dim_job_title` | One row per unique job title | Full detailed job titles |
 
### Bridge Tables
 
**`bridge_company_location`** — resolves the many-to-many relationship between companies and the locations where they post jobs. One company can hire in many locations.
 
**`bridge_job_title`** — resolves the hierarchy between standardised job categories (`job_title_short`) and the many detailed job titles that fall under each category.
 
### Fact Table: `fact_company_hiring_monthly`
 
Grain: one row per **company × job category × country × month**
 
| Metric | Description |
|---|---|
| `postings_count` | Total job postings in that period |
| `median_salary_year` | Median annual salary |
| `min_salary_year` | Minimum annual salary |
| `max_salary_year` | Maximum annual salary |
| `remote_share` | Share of remote postings (0.0–1.0) |
| `health_insurance_share` | Share of postings offering health insurance |
| `no_degree_mention_share` | Share of postings without degree requirements |
 
### Key SQL Technique — Median Salary
MySQL has no native `MEDIAN()` function. The median is calculated using window functions:
 
```sql
-- Rank salaries within each reporting group
ROW_NUMBER() OVER (
    PARTITION BY company_id, job_title_short_id, job_country, month_start_date
    ORDER BY salary_year_avg
) AS rn,
 
COUNT(*) OVER (
    PARTITION BY company_id, job_title_short_id, job_country, month_start_date
) AS cnt
 
-- Then average the middle value(s)
WHERE rn IN (FLOOR((cnt + 1) / 2), FLOOR((cnt + 2) / 2))
```

 **Requirements:** [MySQL 8+](https://www.mysql.com/) — all mart scripts run entirely in SQL on top of the `data_warehouse` schema.

