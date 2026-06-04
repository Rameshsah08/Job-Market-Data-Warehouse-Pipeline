/*
===============================================================================
Project      : Job Market Data Warehouse
File Name    : warehouse_validation_queries.sql

PURPOSE
-------------------------------------------------------------------------------
This file contains validation, profiling, and quality assurance queries used
during Data Warehouse development.

The queries help verify source table integrity, identify duplicate records,
validate relationships between dimensions and facts, and inspect source
data quality before building analytical marts.

SOURCE TABLES
-------------------------------------------------------------------------------
• company_dim
• job_postings_fact
• skills_dim
• skills_job_dim

VALIDATION OBJECTIVES
-------------------------------------------------------------------------------
✓ Duplicate Detection
✓ Data Quality Assessment
✓ Relationship Validation
✓ Record Count Verification
✓ Fact Table Inspection
✓ Dimension Table Inspection

===============================================================================
*/

USE data_warehouse;

-- ============================================================================
-- Company Dimension Validation
--
-- Purpose:
-- Identify duplicate company names and review company records.
-- ============================================================================

SELECT company_id, name, COUNT(name) OVER (PARTITION BY name) AS occurrence
FROM company_dim
WHERE name IN (
    SELECT name
    FROM company_dim
    GROUP BY name
    HAVING COUNT(name) > 1
);

SELECT *
FROM company_dim
LIMIT 20;

SELECT *
FROM company_dim
GROUP BY company_id;

-- ============================================================================
-- Warehouse Join Validation
--
-- Purpose:
-- Verify relationships between job postings, companies, and skills.
-- ============================================================================

SELECT COUNT(*)
FROM (
    SELECT
        jb.job_id,
        jb.job_title_short,

        CASE
            WHEN jb.job_title = '' THEN 'N/A'
            ELSE jb.job_title
        END AS job_title,

        CASE
            WHEN jb.job_location = '' THEN 'N/A'
            ELSE jb.job_location
        END AS job_location,

        CASE
            WHEN jb.job_via = '' THEN 'N/A'
            ELSE jb.job_via
        END AS job_via,

        CASE
            WHEN jb.job_schedule_type = '' THEN 'N/A'
            ELSE jb.job_schedule_type
        END AS job_schedule_type,

        jb.job_work_from_home,
        jb.search_location,
        jb.job_posted_date,
        jb.job_no_degree_mention,
        jb.job_health_insurance,

        CASE
            WHEN jb.job_country = '' THEN 'N/A'
            ELSE jb.job_country
        END AS job_country,

        CASE
            WHEN jb.salary_rate = '' THEN 'N/A'
            ELSE jb.salary_rate
        END AS salary_rate,

        jb.salary_year_avg,
        jb.salary_hour_avg,

        cd.company_id,

        CASE
            WHEN cd.name = '' THEN 'N/A'
            ELSE cd.name
        END AS company_name,

        sd.skills,
        sd.type

    FROM job_postings_fact AS jb

    LEFT JOIN company_dim AS cd
        ON jb.company_id = cd.company_id

    LEFT JOIN skills_job_dim AS sjd
        ON sjd.job_id = jb.job_id

    LEFT JOIN skills_dim AS sd
        ON sd.skill_id = sjd.skill_id
) t;

-- ============================================================================
-- Skills Dimension Validation
--
-- Purpose:
-- Inspect skills and identify duplicate skill names.
-- ============================================================================

SELECT COUNT(*)
FROM skills_dim;

SELECT *
FROM skills_dim
LIMIT 20;

SELECT skills, COUNT(skills)
FROM skills_dim
GROUP BY skills
HAVING COUNT(skills) > 1;

SELECT *
FROM skills_dim
LIMIT 10;

SELECT skill_id, skills, type
FROM skills_dim;

-- ============================================================================
-- Job Postings Fact Validation
--
-- Purpose:
-- Inspect warehouse fact table records.
-- ============================================================================

SELECT COUNT(*)
FROM job_postings_fact;

SELECT *
FROM job_postings_fact
LIMIT 200;

SELECT *
FROM job_postings_fact
WHERE job_work_from_home = 1;

-- ============================================================================
-- Company Posting Analysis
--
-- Purpose:
-- Identify companies with multiple job postings.
-- ============================================================================

SELECT
    company_id,
    COUNT(company_id) AS occurrence
FROM job_postings_fact
GROUP BY company_id
HAVING COUNT(company_id) > 1;

-- ============================================================================
-- Skills-to-Job Relationship Validation
--
-- Purpose:
-- Verify many-to-many mappings between jobs and skills.
-- ============================================================================

SELECT COUNT(*)
FROM skills_job_dim;

SELECT
    job_id,
    COUNT(job_id) AS occurrence
FROM skills_job_dim
GROUP BY job_id
HAVING COUNT(job_id) > 1;

-- ============================================================================
-- Source Data Quality Checks
--
-- Purpose:
-- Additional warehouse validation.
-- ============================================================================

SELECT job_title
FROM job_postings_fact;

SELECT
    TRIM(job_title) AS clean_title
FROM job_postings_fact
WHERE job_title IS NULL
   OR job_title = '';