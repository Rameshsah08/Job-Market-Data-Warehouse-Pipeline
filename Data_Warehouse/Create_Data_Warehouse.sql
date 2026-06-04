
-- ============================================================
-- Purpose : Sets up a Data Warehouse database in MySQL with
--           three logical schemas — company, job, and skill —
--           to organise and analyse job market data.
-- ============================================================

-- Drop and recreate the 'Warehouse' database
DROP DATABASE IF EXISTS Data_Warehouse;

-- Create the 'Warehouse' database
CREATE DATABASE Data_Warehouse;
USE Data_Warehouse;
