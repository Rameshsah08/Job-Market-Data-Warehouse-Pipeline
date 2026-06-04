/*
===============================================================================
Project      : Job Market Data Warehouse & Data mart
Script Name  : create_priority_mart.sql
Schema       : priority_mart

Purpose:
This script creates and populates the Priority Mart layer of the Job Market
Data Warehouse.

The Priority Mart is designed to monitor and prioritize strategically
important job roles by assigning business-defined priority levels and
tracking related job postings.

This mart enables focused analysis on high-value positions and supports
recruitment intelligence, workforce planning, and market monitoring.

Business Objectives:
- Identify critical hiring roles
- Prioritize recruitment monitoring
- Track salary trends for key positions
- Monitor hiring activity by priority level
- Support business-driven talent analytics

Schema Components:

1. priority_roles
   - Stores prioritized job roles
   - Maintains business-defined priority rankings

2. priority_jobs
   - Stores job postings matching priority roles
   - Tracks salary and company information
   - Records refresh timestamps

Source Tables:
- data_warehouse.job_postings_fact
- data_warehouse.company_dim

Target Schema:
- priority_mart

Business Rules:
Priority Level 1 = Highest Priority
Priority Level 2 = High Priority
Priority Level 3 = Medium Priority
Priority Level 4+ = Lower Priority

===============================================================================
*/


-- ============================================================================
-- Enable safe update mode to prevent accidental mass updates
-- ============================================================================
SET SQL_SAFE_UPDATES = 1;

USE data_warehouse;

-- ============================================================================
-- Configure session timeout settings for ETL operations
-- ============================================================================
SET SESSION wait_timeout = 10000;
SET SESSION interactive_timeout = 10000;
SET SESSION net_read_timeout = 10000;
SET SESSION net_write_timeout = 10000;

-- ============================================================================
-- Recreate Priority Mart schema
-- Existing schema is removed to ensure a clean rebuild
-- ============================================================================
DROP SCHEMA IF EXISTS priority_mart;
CREATE SCHEMA priority_mart;

USE priority_mart;

-- ============================================================================
-- Create Priority Roles Reference Table
--
-- Purpose:
-- Stores business-defined job roles and their priority rankings.
--
-- Lower priority_level values indicate higher business importance.
-- ============================================================================
DROP TABLE IF EXISTS priority_roles;

CREATE TABLE priority_roles (
    role_id INT PRIMARY KEY,
    role_name VARCHAR(500),
    priority_level INT
);

-- ============================================================================
-- Seed initial priority role definitions
--
-- Priority Ranking:
-- 1 = Highest Priority
-- 2 = High Priority
-- 3 = Medium Priority
-- ============================================================================
INSERT INTO priority_roles (
    role_id,
    role_name,
    priority_level
)
VALUES
    (1, 'Data Engineer', 2),
    (2, 'Senior Data Engineer', 1),
    (3, 'Software Engineer', 3);

-- ============================================================================
-- Create Priority Jobs Fact Table
--
-- Purpose:
-- Stores job postings that match predefined priority roles.
--
-- Includes:
-- - Job details
-- - Company information
-- - Salary information
-- - Assigned priority level
-- - Data refresh timestamp
-- ============================================================================
DROP TABLE IF EXISTS priority_jobs;

CREATE TABLE priority_jobs (
    job_id INT PRIMARY KEY,
    job_title_short VARCHAR(500),
    company_name VARCHAR(500),
    job_posted_date DATETIME,
    salary_year_avg DOUBLE,
    priority_level INT,
    updated_at DATETIME
);

-- ============================================================================
-- Load Priority Jobs
--
-- ETL Logic:
-- 1. Extract job postings
-- 2. Join company information
-- 3. Match jobs to priority roles
-- 4. Assign priority level
-- 5. Record load timestamp
-- ============================================================================
INSERT INTO priority_jobs (
    job_id,
    job_title_short,
    company_name,
    job_posted_date,
    salary_year_avg,
    priority_level,
    updated_at
)

SELECT
    jpf.job_id,

    jpf.job_title_short,

    COALESCE(cd.name, 'N/A') AS company_name,

    jpf.job_posted_date,

    jpf.salary_year_avg,

    r.priority_level,

    CURRENT_TIMESTAMP() AS updated_at

FROM data_warehouse.job_postings_fact AS jpf

LEFT JOIN data_warehouse.company_dim AS cd
    ON jpf.company_id = cd.company_id

INNER JOIN priority_roles AS r
    ON jpf.job_title_short = r.role_name;

-- ============================================================================
-- Update Priority Levels
--
-- Business Rule Change:
-- Promote Data Engineer role to highest priority level.
-- ============================================================================
UPDATE priority_mart.priority_roles
SET priority_level = 1
WHERE role_id = 1;

-- ============================================================================
-- Add New Priority Role
--
-- Business Rule Extension:
-- Include Data Scientist role in priority monitoring.
-- ============================================================================
INSERT INTO priority_mart.priority_roles (
    role_id,
    role_name,
    priority_level
)
VALUES
    (4, 'Data Scientist', 4);