/*
===============================================================================
Project      : Job Market Data Warehouse & Data mart
Script Name  : create_company_mart.sql
Schema       : company_mart

PURPOSE
-------------------------------------------------------------------------------
This script creates and populates the Company Mart layer of the Job Market
Data Warehouse.

The Company Mart is an analytical data mart designed to support company
hiring analysis, salary benchmarking, workforce planning, and recruitment
intelligence.

The solution transforms normalized warehouse data into a dimensional model
optimized for reporting and business intelligence workloads.

BUSINESS OBJECTIVES
-------------------------------------------------------------------------------
• Analyze company hiring activity over time
• Monitor hiring demand across countries and job categories
• Track salary distributions and compensation trends
• Measure remote work adoption rates
• Analyze health insurance offerings
• Evaluate degree requirement trends
• Support workforce planning and talent analytics

DATA MODEL
-------------------------------------------------------------------------------

Dimensions
----------
dim_company
    Stores company master data.

dim_location
    Stores standardized country and location information.

dim_date_month
    Stores monthly calendar attributes.

dim_job_title_short
    Stores standardized job role categories.

dim_job_title
    Stores detailed job titles.

Bridge Tables
-------------
bridge_company_location
    Resolves many-to-many relationships between companies and locations.

bridge_job_title
    Resolves relationships between standardized job categories and
    detailed job titles.

Fact Table
----------
fact_company_hiring_monthly

Fact Table Grain
----------------
One row per:
    • Company
    • Job Title Category
    • Country
    • Month

KEY METRICS
-------------------------------------------------------------------------------
• Postings Count
• Median Annual Salary
• Minimum Annual Salary
• Maximum Annual Salary
• Remote Work Share
• Health Insurance Share
• No Degree Requirement Share

SOURCE TABLES
-------------------------------------------------------------------------------
• data_warehouse.job_postings_fact
• data_warehouse.company_dim

TARGET SCHEMA
-------------------------------------------------------------------------------
• company_mart

TECHNICAL SKILLS DEMONSTRATED
-------------------------------------------------------------------------------
✓ Data Warehousing
✓ Dimensional Modeling
✓ Star Schema Concepts
✓ Bridge Table Design
✓ ETL Development
✓ Data Quality Standardization
✓ Window Functions
✓ Median Salary Calculation
✓ KPI Development
✓ Analytical Data Mart Design

ETL WORKFLOW
-------------------------------------------------------------------------------
1. Create analytical dimensions.
2. Create bridge tables.
3. Generate monthly date dimension.
4. Prepare hiring data and business indicators.
5. Calculate salary distributions.
6. Calculate median salary using window functions.
7. Aggregate monthly hiring metrics.
8. Load analytical fact table.
9. Validate results.

===============================================================================
*/


USE data_warehouse;

-- ============================================================================
-- Configure session timeout settings for ETL processing
-- ============================================================================
SET SESSION wait_timeout = 10000;
SET SESSION interactive_timeout = 10000;
SET SESSION net_read_timeout = 10000;
SET SESSION net_write_timeout = 10000;

-- ============================================================================
-- Create Company Mart Schema
--
-- Rebuilds the entire analytical mart from scratch.
-- ============================================================================
DROP SCHEMA IF EXISTS company_mart;
CREATE SCHEMA company_mart;
use company_mart;


-- ============================================================================
-- Dimension: Company
--
-- Purpose:
-- Stores unique companies used throughout the analytical model.
--
-- Grain:
-- One row per company.
-- ============================================================================

DROP TABLE IF EXISTS company_mart.dim_company;

create table company_mart.dim_company (
company_id int primary key,
company_name varchar(500)
);

insert into company_mart.dim_company(company_id, company_name)
select distinct
company_id,
name as company_name
from company_dim;



-- ============================================================================
-- Dimension: Location
--
-- Purpose:
-- Stores standardized country and location combinations.
--
-- Grain:
-- One row per unique country-location combination.
-- ============================================================================

DROP TABLE IF EXISTS company_mart.dim_location;

CREATE TABLE company_mart.dim_location (
    location_id INT PRIMARY KEY,
    job_country VARCHAR(500),
    job_location VARCHAR(500)
);

INSERT INTO company_mart.dim_location (
    location_id,
    job_country,
    job_location
)
SELECT
    ROW_NUMBER() OVER (
        ORDER BY job_country, job_location
    ) AS location_id,
    job_country,
    job_location
FROM (
    SELECT DISTINCT
        case when job_country is null or job_country = "" then "N/A"
        else job_country
        end as job_country,
        
        case when  job_location is null or job_location = "" then "N/A"
        else job_location
        end as job_location
    FROM job_postings_fact
    WHERE job_country IS NOT NULL
      AND job_location IS NOT NULL
) t;



-- ============================================================================
-- Bridge Table: Company ↔ Location
--
-- Purpose:
-- Resolves many-to-many relationships between companies and
-- locations where jobs are posted.
-- ============================================================================
drop table if exists company_mart.bridge_company_location;

create table company_mart.bridge_company_location(
company_id int,
location_id int,
primary key(company_id, location_id),
foreign key(company_id) references company_mart.dim_company(company_id),
foreign key(location_id) references company_mart.dim_location(location_id)
);

insert into company_mart.bridge_company_location(company_id, location_id)
select distinct
jpf.company_id,
dl.location_id
from job_postings_fact as jpf
inner join company_mart.dim_location as dl
on jpf.job_country = dl.job_country
and 
jpf.job_location = dl.job_location
where jpf.job_country is not null;



-- ============================================================================
-- Dimension: Date_Month
--
-- Purpose:
-- Supports monthly hiring trend analysis.
--
-- Grain:
-- One row per month.
-- ============================================================================
drop table if exists company_mart.dim_date_month;

create table company_mart.dim_date_month(
month_start_date date primary key,
year int,
month int
);

insert into company_mart.dim_date_month(month_start_date, year, month)
SELECT DISTINCT
    DATE_FORMAT(job_posted_date, '%Y-%m-01') AS month_start_date,

    EXTRACT(YEAR FROM job_posted_date) AS year,

    EXTRACT(MONTH FROM job_posted_date) AS month
FROM job_postings_fact
WHERE job_posted_date IS NOT NULL;



-- ============================================================================
-- Dimension: Job Title Category
--
-- Purpose:
-- Stores standardized job role categories used for reporting.
-- ============================================================================

drop table if exists  company_mart.dim_job_title_short;

create table  company_mart.dim_job_title_short(
job_title_short_id int primary key,
job_title_short varchar(500)
);

insert into company_mart.dim_job_title_short(job_title_short_id, job_title_short)
select 
row_number() over(order by job_title_short) as job_title_short_id,
job_title_short
from 
(select distinct
 job_title_short
 from job_postings_fact
 where job_title_short is not null
) t;


-- ============================================================================
-- Dimension: Detailed Job Title
--
-- Purpose:
-- Stores detailed job titles from source job postings.
-- ============================================================================
drop table if exists company_mart.dim_job_title;

create table company_mart.dim_job_title(
job_title_id int primary key,
job_title varchar(500)
);

INSERT INTO company_mart.dim_job_title (
    job_title_id,
    job_title
)
SELECT
    ROW_NUMBER() OVER (ORDER BY job_title) AS job_title_id,
    job_title
FROM (
    SELECT DISTINCT
        CASE
            WHEN job_title IS NULL OR TRIM(job_title) = '' THEN 'N/A'
            ELSE TRIM(job_title)
        END AS job_title
    FROM job_postings_fact
) t;



-- ============================================================================
-- Bridge Table: Job Title Category ↔ Detailed Job Title
--
-- Purpose:
-- Supports reporting hierarchies between standardized job categories
-- and detailed job titles.
-- ============================================================================

drop table if exists company_mart.bridge_job_title;

create table company_mart.bridge_job_title(
job_title_short_id int,
job_title_id int,

primary key(job_title_short_id, job_title_id),
FOREIGN KEY (job_title_short_id) REFERENCES company_mart.dim_job_title_short(job_title_short_id),
    FOREIGN KEY (job_title_id) REFERENCES company_mart.dim_job_title(job_title_id)
);

insert into company_mart.bridge_job_title(job_title_short_id, job_title_id)
SELECT DISTINCT
    djs.job_title_short_id,
    djt.job_title_id
FROM job_postings_fact jpf
INNER JOIN company_mart.dim_job_title_short djs 
    ON jpf.job_title_short = djs.job_title_short
INNER JOIN company_mart.dim_job_title djt
    ON jpf.job_title = djt.job_title
WHERE jpf.job_title_short IS NOT NULL
    AND jpf.job_title IS NOT NULL;




-- ============================================================================
-- Fact Table: Company Hiring Monthly
--
-- Purpose:
-- Stores aggregated monthly hiring metrics by company,
-- job category, country, and month.
--
-- Grain:
-- One row per:
--     Company
--     Job Category
--     Country
--     Month
--
-- Metrics:
--     postings_count
--     median_salary_year
--     min_salary_year
--     max_salary_year
--     remote_share
--     health_insurance_share
--     no_degree_mention_share
-- ============================================================================

DROP TABLE IF EXISTS company_mart.fact_company_hiring_monthly;

CREATE TABLE company_mart.fact_company_hiring_monthly (
    company_id INT,
    job_title_short_id INT,
    job_country VARCHAR(255),
    month_start_date DATE,
    postings_count INT,
    median_salary_year DOUBLE,
    min_salary_year DOUBLE,
    max_salary_year DOUBLE,
    remote_share DOUBLE,
    health_insurance_share DOUBLE,
    no_degree_mention_share DOUBLE,

    PRIMARY KEY (
        company_id,
        job_title_short_id,
        job_country,
        month_start_date
    ),

    FOREIGN KEY (company_id)
        REFERENCES company_mart.dim_company(company_id),

    FOREIGN KEY (job_title_short_id)
        REFERENCES company_mart.dim_job_title_short(job_title_short_id),

    FOREIGN KEY (month_start_date)
        REFERENCES company_mart.dim_date_month(month_start_date)
);

-- ======== =====inserting data in table EXISTS company_mart.fact_company_hiring_monthly  =============

INSERT INTO company_mart.fact_company_hiring_monthly (
    company_id,
    job_title_short_id,
    job_country,
    month_start_date,
    postings_count,
    median_salary_year,
    min_salary_year,
    max_salary_year,
    remote_share,
    health_insurance_share,
    no_degree_mention_share
)

WITH prepared AS (
    SELECT
        jpf.company_id,
        djs.job_title_short_id,
        jpf.job_country,
        CAST(DATE_FORMAT(jpf.job_posted_date,'%Y-%m-01') AS DATE) AS month_start_date,
        jpf.salary_year_avg,

        CASE WHEN jpf.job_work_from_home = 1 THEN 1 ELSE 0 END AS is_remote,
        CASE WHEN jpf.job_health_insurance = 1 THEN 1 ELSE 0 END AS has_health_insurance,
        CASE WHEN jpf.job_no_degree_mention = 1 THEN 1 ELSE 0 END AS no_degree_required

    FROM job_postings_fact jpf
    INNER JOIN company_mart.dim_job_title_short djs
        ON jpf.job_title_short = djs.job_title_short

    WHERE jpf.company_id IS NOT NULL
      AND jpf.job_country IS NOT NULL
      AND jpf.job_posted_date IS NOT NULL
),

salary_ranked AS (
    SELECT
        p.*,

        ROW_NUMBER() OVER (
            PARTITION BY
                company_id,
                job_title_short_id,
                job_country,
                month_start_date
            ORDER BY salary_year_avg
        ) AS rn,

        COUNT(*) OVER (
            PARTITION BY
                company_id,
                job_title_short_id,
                job_country,
                month_start_date
        ) AS cnt

    FROM prepared p
    WHERE salary_year_avg IS NOT NULL
),

median_salary AS (
    SELECT
        company_id,
        job_title_short_id,
        job_country,
        month_start_date,

        AVG(salary_year_avg) AS median_salary_year

    FROM salary_ranked

    WHERE rn IN (
        FLOOR((cnt + 1) / 2),
        FLOOR((cnt + 2) / 2)
    )

    GROUP BY
        company_id,
        job_title_short_id,
        job_country,
        month_start_date
),

aggregated AS (
    SELECT
        company_id,
        job_title_short_id,
        job_country,
        month_start_date,

        COUNT(*) AS postings_count,

        MIN(salary_year_avg) AS min_salary_year,
        MAX(salary_year_avg) AS max_salary_year,

        AVG(is_remote) AS remote_share,
        AVG(has_health_insurance) AS health_insurance_share,
        AVG(no_degree_required) AS no_degree_mention_share

    FROM prepared

    GROUP BY
        company_id,
        job_title_short_id,
        job_country,
        month_start_date
)

SELECT

    a.company_id,
    a.job_title_short_id,
    a.job_country,
    a.month_start_date,
    a.postings_count,

    m.median_salary_year,

    a.min_salary_year,
    a.max_salary_year,

    a.remote_share,
    a.health_insurance_share,
    a.no_degree_mention_share

FROM aggregated a

LEFT JOIN median_salary m
    ON a.company_id = m.company_id
   AND a.job_title_short_id = m.job_title_short_id
   AND a.job_country = m.job_country
   AND a.month_start_date = m.month_start_date;
   
   
   -- ============================================================================
-- ETL Processing
--
-- prepared:
--     Standardizes source data and generates business indicators.
--
-- salary_ranked:
--     Ranks salary values within each reporting group.
--
-- median_salary:
--     Calculates median salary using window functions.
--
-- aggregated:
--     Generates company hiring KPIs and summary metrics.
-- ============================================================================

   
   -- ============================================================================
-- Validation Query
--
-- Purpose:
-- Verify successful loading of fact_company_hiring_monthly.
-- ============================================================================

   select * from company_mart.fact_company_hiring_monthly
   limit 500;