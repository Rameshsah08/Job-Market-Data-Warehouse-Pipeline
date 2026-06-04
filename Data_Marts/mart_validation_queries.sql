/*
===============================================================================
Project      : Job Market Data Warehouse
File Name    : mart_validation_queries.sql

PURPOSE
-------------------------------------------------------------------------------
This file contains validation and quality assurance queries used after
building analytical marts.

The queries verify ETL execution, inspect dimension and fact tables,
validate bridge tables, and confirm successful data loading.

TARGET SCHEMAS
-------------------------------------------------------------------------------
• flat_mart
• skill_mart
• priority_mart
• company_mart

VALIDATION OBJECTIVES
-------------------------------------------------------------------------------
✓ Flat Mart Validation
✓ Skill Mart Validation
✓ Priority Mart Validation
✓ Company Mart Validation
✓ ETL Verification
✓ Fact Table Validation
✓ Dimension Validation

===============================================================================
*/

-- ============================================================================
-- Flat Mart Validation
--
-- Purpose:
-- Verify flat mart creation and denormalized output.
-- ============================================================================

USE flat_mart;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS flat_mart_job_posting;

SET FOREIGN_KEY_CHECKS = 1;

SELECT
    jb.job_id,
    cd.name,
    sk.skills_and_type
FROM data_warehouse.job_postings_fact jb

LEFT JOIN data_warehouse.company_dim cd
    ON jb.company_id = cd.company_id

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

    LEFT JOIN data_warehouse.skills_dim sd
        ON sjd.skill_id = sd.skill_id

    GROUP BY sjd.job_id
) sk
    ON jb.job_id = sk.job_id

LIMIT 10;

SELECT COUNT(*)
FROM flat_mart_job_posting;

SELECT COUNT(*) AS total_rows
FROM flat_mart_job_posting;

SELECT *
FROM data_warehouse.job_postings_fact
LIMIT 10;

SELECT *
FROM data_warehouse.flat_mart_job_posting
LIMIT 100;

SELECT COUNT(*)
FROM flat_mart_job_posting;

-- ============================================================================
-- Skill Mart Validation
--
-- Purpose:
-- Verify skill dimensions and monthly demand fact table.
-- ============================================================================

SELECT COUNT(*)
FROM dim_skill;

SELECT *
FROM dim_skill
LIMIT 10;

SELECT *
FROM dim_skill
WHERE skill_id = '';

SELECT *
FROM dim_date
WHERE month = '';

SELECT *
FROM fact_skill_demand_monthly
LIMIT 100;

-- ============================================================================
-- Priority Mart Validation
--
-- Purpose:
-- Verify priority job monitoring tables.
-- ============================================================================

SELECT *
FROM priority_jobs
LIMIT 20;

SELECT
    job_title_short,
    COUNT(*) AS job_count,
    MIN(priority_level) AS priority_level,
    MIN(updated_at) AS updated_at
FROM priority_mart.priority_jobs
GROUP BY job_title_short
ORDER BY job_count DESC;

SELECT *
FROM priority_roles;

-- ============================================================================
-- Company Mart Validation
--
-- Purpose:
-- Verify company mart dimensions, bridge tables, and fact tables.
-- ============================================================================

SELECT *
FROM company_mart.dim_company
WHERE company_id IS NULL
   OR company_id = '';

SELECT *
FROM company_mart.dim_company
LIMIT 500;

SELECT *
FROM company_mart.dim_job_title_short;

SELECT *
FROM company_mart.dim_location
WHERE job_country IS NULL
   OR job_country = '';

SELECT *
FROM company_mart.dim_location
WHERE job_country = 'N/A'
   OR job_location = 'N/A';

SELECT *
FROM company_mart.bridge_company_location;

SELECT *
FROM company_mart.dim_date_month
WHERE month_start_date = '';

SELECT *
FROM company_mart.dim_job_title_short;

SELECT *
FROM company_mart.dim_job_title
WHERE job_title IS NULL
   OR job_title = 'n/a';

SELECT *
FROM company_mart.bridge_job_title
LIMIT 500;

-- ============================================================================
-- Company Hiring Fact Validation
--
-- Purpose:
-- Inspect final company hiring metrics.
-- ============================================================================

SELECT *
FROM company_mart.fact_company_hiring_monthly
LIMIT 500;