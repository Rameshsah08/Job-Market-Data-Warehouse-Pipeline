/*
===============================================================================
Project      : Job Market Data Warehouse & Data mart
Script Name  : create_skill_mart.sql
Schema       : skill_mart

Purpose:
This script creates and populates the Skill Mart layer of the Job Market
Data Warehouse.

The Skill Mart is designed to analyze skill demand trends across time
and job categories by transforming normalized warehouse data into a
dimensional model optimized for reporting and business intelligence.

Business Questions Answered:
- Which skills are most in demand?
- How does skill demand change over time?
- Which skills are most common in remote jobs?
- Which skills are associated with jobs offering health insurance?
- Which skills appear most frequently in jobs that do not require degrees?

Data Model:
1. dim_skill
   - Stores skill attributes and categories.

2. dim_date
   - Stores monthly calendar information for trend analysis.

3. fact_skill_demand_monthly
   - Stores aggregated monthly demand metrics for each skill.

Source Tables:
- data_warehouse.skills_dim
- data_warehouse.skills_job_dim
- data_warehouse.job_postings_fact

Target Schema:
- skill_mart

Granularity:
One record per:
- Skill
- Month
- Job Title Category

===============================================================================
*/

USE data_warehouse;

-- ============================================================================
-- Configure session timeout settings for long-running ETL operations
-- ============================================================================
SET SESSION wait_timeout = 10000;
SET SESSION interactive_timeout = 10000;
SET SESSION net_read_timeout = 10000;
SET SESSION net_write_timeout = 10000;

-- ============================================================================
-- Recreate Skill Mart schema
-- Existing schema is removed to ensure a clean rebuild
-- ============================================================================
DROP SCHEMA IF EXISTS skill_mart;
CREATE SCHEMA skill_mart;

USE skill_mart;

-- ============================================================================
-- Create Skill Dimension
--
-- Purpose:
-- Stores unique skills and their corresponding categories.
--
-- Example:
-- Skill      : Python
-- Category   : Programming
-- ============================================================================
DROP TABLE IF EXISTS skill_mart.dim_skill;

CREATE TABLE skill_mart.dim_skill (
    skill_id INT PRIMARY KEY,
    skills VARCHAR(100),
    type VARCHAR(100)
);

-- ============================================================================
-- Load Skill Dimension from warehouse source table
-- ============================================================================
INSERT INTO dim_skill (
    skill_id,
    skills,
    type
)
SELECT
    skill_id,
    skills,
    type
FROM data_warehouse.skills_dim;

-- ============================================================================
-- Create Date Dimension
--
-- Purpose:
-- Provides monthly, quarterly, and yearly attributes for trend analysis.
--
-- Example:
-- Month Start Date : 2023-01-01
-- Quarter          : Q1
-- Year Quarter     : 2023-Q1
-- ============================================================================
DROP TABLE IF EXISTS skill_mart.dim_date;

CREATE TABLE skill_mart.dim_date (
    month_start_date DATE PRIMARY KEY,
    year INT,
    month INT,
    quarter VARCHAR(50),
    quarter_name VARCHAR(50),
    year_quarter VARCHAR(50)
);

-- ============================================================================
-- Populate Date Dimension
--
-- Generates one record per month found in job posting data.
-- ============================================================================
INSERT INTO skill_mart.dim_date (
    month_start_date,
    year,
    month,
    quarter,
    quarter_name,
    year_quarter
)

SELECT DISTINCT
    DATE_FORMAT(
        job_posted_date,
        '%Y-%m-01'
    ) AS month_start_date,

    EXTRACT(YEAR FROM job_posted_date) AS year,

    EXTRACT(MONTH FROM job_posted_date) AS month,

    EXTRACT(QUARTER FROM job_posted_date) AS quarter,

    CONCAT(
        'Q-',
        EXTRACT(QUARTER FROM job_posted_date)
    ) AS quarter_name,

    CONCAT(
        EXTRACT(YEAR FROM job_posted_date),
        '-Q',
        EXTRACT(QUARTER FROM job_posted_date)
    ) AS year_quarter

FROM data_warehouse.job_postings_fact;

-- ============================================================================
-- Create Fact Table
--
-- Purpose:
-- Stores aggregated monthly skill demand metrics.
--
-- Granularity:
-- One record per:
--   Skill
--   Month
--   Job Title Category
--
-- Metrics:
-- - Total Job Postings
-- - Remote Job Postings
-- - Health Insurance Job Postings
-- - No Degree Requirement Job Postings
-- ============================================================================
DROP TABLE IF EXISTS fskill_mart.act_skill_demand_monthly;

CREATE TABLE skill_mart.fact_skill_demand_monthly (
    skill_id INT,
    month_start_date DATE,
    job_title_short VARCHAR(50),

    postings_count INT,
    remote_posting_count INT,
    health_insurance_postings_count INT,
    no_degree_mention_count INT,

    PRIMARY KEY (
        skill_id,
        month_start_date,
        job_title_short
    ),

    FOREIGN KEY (skill_id)
        REFERENCES dim_skill(skill_id),

    FOREIGN KEY (month_start_date)
        REFERENCES dim_date(month_start_date)
);

-- ============================================================================
-- Populate Fact Table
--
-- ETL Process:
-- 1. Join job postings to associated skills
-- 2. Generate analytical indicator flags
-- 3. Aggregate metrics at the monthly skill level
-- 4. Load results into the fact table
-- ============================================================================
INSERT INTO skill_mart.fact_skill_demand_monthly (
    skill_id,
    month_start_date,
    job_title_short,
    postings_count,
    remote_posting_count,
    health_insurance_postings_count,
    no_degree_mention_count
)

-- ============================================================================
-- Build intermediate dataset
--
-- Creates one record for every job-skill relationship while adding
-- business indicators used for aggregation.
-- ============================================================================
WITH job_postings AS (
    SELECT
        sjd.skill_id,

        DATE_FORMAT(
            jpf.job_posted_date,
            '%Y-%m-01'
        ) AS month_start_date,

        jpf.job_title_short,

        -- Remote work indicator
        CASE
            WHEN jpf.job_work_from_home = TRUE THEN 1
            ELSE 0
        END AS is_remote,

        -- Health insurance indicator
        CASE
            WHEN jpf.job_health_insurance = TRUE THEN 1
            ELSE 0
        END AS has_health_insurance,

        -- No degree requirement indicator
        CASE
            WHEN jpf.job_no_degree_mention = TRUE THEN 1
            ELSE 0
        END AS no_degree_mentioned

    FROM data_warehouse.job_postings_fact AS jpf

    INNER JOIN data_warehouse.skills_job_dim AS sjd
        ON jpf.job_id = sjd.job_id
)

-- ============================================================================
-- Aggregate monthly skill demand metrics
--
-- Output:
-- One row per skill, month, and job category.
-- ============================================================================
SELECT
    skill_id,
    month_start_date,
    job_title_short,

    -- Total postings requiring the skill
    COUNT(*) AS postings_count,

    -- Remote job postings requiring the skill
    SUM(is_remote) AS remote_posting_count,

    -- Jobs offering health insurance requiring the skill
    SUM(has_health_insurance) AS health_insurance_postings_count,

    -- Jobs without degree requirements requiring the skill
    SUM(no_degree_mentioned) AS no_degree_mention_count

FROM job_postings

GROUP BY
    skill_id,
    month_start_date,
    job_title_short

ORDER BY
    skill_id,
    month_start_date,
    job_title_short;

-- ============================================================================
-- Validation Queries
--
-- Used to verify successful fact table population and review results.
-- ============================================================================

SELECT *
FROM fact_skill_demand_monthly;