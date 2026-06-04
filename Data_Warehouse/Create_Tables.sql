-- =====================================================
-- Purpose : Creates the dimension and fact tables for
--           the Data Warehouse inside the data_warehouse
--           database, ready to load job market CSV data.
-- =====================================================

USE data_warehouse;

-- Allow CSV files to be loaded from the local machine
SET GLOBAL local_infile = 1;


-- =====================================================
-- company_dim
-- Stores company profile data for each hiring employer.
-- Linked to job postings via company_id (FK).
-- =====================================================
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS company_dim;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE company_dim (
    company_id    INT          PRIMARY KEY,
    name          VARCHAR(255),           
    link          TEXT,                   
    link_google   TEXT,                   
    thumbnail     TEXT                    
);


-- =====================================================
-- skills_dim
-- Master list of all skills (e.g. Python, SQL, AWS).
-- Each skill belongs to a type/category (e.g. cloud, programming).
-- =====================================================
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS skills_dim;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE skills_dim (
    skill_id  INT          PRIMARY KEY,
    skills    VARCHAR(255),               
    type      VARCHAR(100)                
);


-- =====================================================
-- job_postings_fact
-- Core fact table — one row per job posting.
-- References company_dim via company_id.
-- Tracks location, salary, schedule, and job benefits.
-- =====================================================
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS job_postings_fact;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE job_postings_fact (
    job_id                 INT  PRIMARY KEY,
    company_id             INT,                     
    job_title_short        VARCHAR(255),            
    job_title              VARCHAR(500),             
    job_location           VARCHAR(255),             
    job_via                VARCHAR(255),             
    job_schedule_type      VARCHAR(100),             
    job_work_from_home     TINYINT(1),               
    search_location        VARCHAR(255),             
    job_posted_date        DATETIME NULL,            
    job_no_degree_mention  TINYINT(1),               
    job_health_insurance   TINYINT(1),               
    job_country            VARCHAR(100),             
    salary_rate            VARCHAR(50),              
    salary_year_avg        DOUBLE,                   
    salary_hour_avg        DOUBLE,                  

    CONSTRAINT fk_job_company
        FOREIGN KEY (company_id)
        REFERENCES company_dim(company_id)
);


-- =====================================================
-- skills_job_dim
-- Bridge table linking job postings to required skills.
-- Resolves the many-to-many relationship:
--   one job can require many skills,
--   one skill can appear in many jobs.
-- =====================================================
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS skills_job_dim;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE skills_job_dim (
    job_id    INT  NOT NULL,    
    skill_id  INT  NOT NULL,    
    PRIMARY KEY (job_id, skill_id),

    CONSTRAINT fk_sjd_job
        FOREIGN KEY (job_id)
        REFERENCES job_postings_fact(job_id),

    CONSTRAINT fk_sjd_skill
        FOREIGN KEY (skill_id)
        REFERENCES skills_dim(skill_id)
);


-- =====================================================
-- Verify all four tables were created successfully
-- =====================================================
SHOW TABLES;
