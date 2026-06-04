/*
===============================================================================
Project      : Job Market Data Warehouse & Data mart
Script Name  : create_flat_mart.sql
Schema       : flat_mart

Purpose:
This script creates and populates the Flat Mart layer of the Job Market
Data Warehouse.

The Flat Mart provides a denormalized, analytics-ready dataset by combining
job postings, company information, salary details, and associated skills
into a single table. This structure simplifies reporting and eliminates
the need for complex joins during business analysis.

Objectives:
- Create a dedicated reporting schema
- Build a flat reporting table
- Clean and standardize source data
- Enrich job postings with company information
- Aggregate job skills into JSON format
- Support BI dashboards and analytical workloads

Source Tables:
- data_warehouse.job_postings_fact
- data_warehouse.company_dim
- data_warehouse.skills_job_dim
- data_warehouse.skills_dim

Target Table:
- flat_mart.flat_mart_job_posting

Business Use Cases:
- Job market analysis
- Salary trend reporting
- Skill demand analysis
- Company hiring insights
- Remote work reporting
===============================================================================
*/

USE data_warehouse;

-- ============================================================================
-- Configure session timeout settings to support long-running ETL operations
-- ============================================================================
SET SESSION wait_timeout = 10000;
SET SESSION interactive_timeout = 10000;
SET SESSION net_read_timeout = 10000;
SET SESSION net_write_timeout = 10000;

-- ============================================================================
-- Recreate Flat Mart schema
-- Existing schema is removed to ensure a clean rebuild
-- ============================================================================
DROP SCHEMA IF EXISTS flat_mart;
CREATE SCHEMA flat_mart;

USE flat_mart;

-- ============================================================================
-- Remove existing reporting table
-- Ensures the ETL process starts from a clean state
-- ============================================================================
DROP TABLE IF EXISTS flat_mart.flat_mart_job_posting;

-- ============================================================================
-- Create denormalized reporting table
--
-- This table combines:
-- - Job information
-- - Company information
-- - Salary metrics
-- - Location attributes
-- - Job characteristics
-- - Aggregated skill data
--
-- The table is optimized for analytics and dashboard reporting.
-- ============================================================================
CREATE TABLE flat_mart.flat_mart_job_posting (
    job_id INT PRIMARY KEY,
    job_title_short VARCHAR(500),
    job_title VARCHAR(500),
    job_location VARCHAR(500),
    job_via VARCHAR(500),
    job_schedule_type VARCHAR(100),

    job_work_from_home TINYINT(1),

    search_location VARCHAR(255),

    job_posted_date DATETIME NULL,

    job_no_degree_mention TINYINT(1),
    job_health_insurance TINYINT(1),

    job_country VARCHAR(100),

    salary_rate VARCHAR(50),

    salary_year_avg DOUBLE,
    salary_hour_avg DOUBLE,

    company_name VARCHAR(500),

    skills_and_type JSON
);

-- ============================================================================
-- Populate Flat Mart table
--
-- ETL Transformations:
-- 1. Extract data from warehouse tables
-- 2. Standardize missing values
-- 3. Join company information
-- 4. Aggregate job skills into JSON arrays
-- 5. Load transformed records into reporting table
-- ============================================================================
INSERT INTO flat_mart.flat_mart_job_posting (
    job_id,
    job_title_short,
    job_title,
    job_location,
    job_via,
    job_schedule_type,
    job_work_from_home,
    search_location,
    job_posted_date,
    job_no_degree_mention,
    job_health_insurance,
    job_country,
    salary_rate,
    salary_year_avg,
    salary_hour_avg,
    company_name,
    skills_and_type
)

SELECT
    jb.job_id,

    jb.job_title_short,

    -- Standardize missing job titles
    CASE
        WHEN job_title IS NULL
          OR TRIM(job_title) = ''
        THEN 'N/A'
        ELSE TRIM(job_title)
    END AS job_title,

    -- Standardize missing job locations
    CASE
        WHEN jb.job_location IS NULL
          OR jb.job_location = ''
        THEN 'N/A'
        ELSE jb.job_location
    END AS job_location,

    -- Standardize missing job source information
    CASE
        WHEN jb.job_via IS NULL
          OR jb.job_via = ''
        THEN 'N/A'
        ELSE jb.job_via
    END AS job_via,

    -- Standardize missing schedule types
    CASE
        WHEN jb.job_schedule_type IS NULL
          OR jb.job_schedule_type = ''
        THEN 'N/A'
        ELSE jb.job_schedule_type
    END AS job_schedule_type,

    jb.job_work_from_home,

    jb.search_location,

    jb.job_posted_date,

    jb.job_no_degree_mention,

    jb.job_health_insurance,

    -- Standardize missing country values
    CASE
        WHEN jb.job_country IS NULL
          OR jb.job_country = ''
        THEN 'N/A'
        ELSE jb.job_country
    END AS job_country,

    -- Standardize salary frequency values
    CASE
        WHEN jb.salary_rate IS NULL
          OR jb.salary_rate = ''
        THEN 'N/A'
        ELSE jb.salary_rate
    END AS salary_rate,

    jb.salary_year_avg,

    jb.salary_hour_avg,

    -- Standardize missing company names
    CASE
        WHEN cd.name IS NULL
          OR cd.name = ''
        THEN 'N/A'
        ELSE cd.name
    END AS company_name,

    sk.skills_and_type

FROM data_warehouse.job_postings_fact jb

-- Join company dimension to enrich job postings
LEFT JOIN data_warehouse.company_dim cd
    ON jb.company_id = cd.company_id

-- Aggregate skills associated with each job posting
LEFT JOIN (
    SELECT
        sjd.job_id,

        JSON_ARRAYAGG(
            JSON_OBJECT(
                'type', sd.type,
                'name', sd.skills
            )
        ) AS skills_and_type

    FROM data_warehouse.skills_job_dim sjd

    -- Join skill details
    LEFT JOIN data_warehouse.skills_dim sd
        ON sjd.skill_id = sd.skill_id

    -- One JSON array per job posting
    GROUP BY sjd.job_id
) sk
    ON jb.job_id = sk.job_id;

-- ============================================================================
-- Validation Checks
-- Verify successful data load into Flat Mart
-- ============================================================================

-- Total number of records loaded
SELECT COUNT(*) AS total_rows
FROM flat_mart.flat_mart_job_posting;

-- Sample output for data quality verification
SELECT *
FROM flat_mart.flat_mart_job_posting;