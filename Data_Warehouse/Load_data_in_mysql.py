"""
===============================================================================
Project      : Job Market Data Warehouse & Data Mart
Script Name  : load_all_tables.py

Purpose
-------------------------------------------------------------------------------
This script performs full refresh loading for all Data Warehouse tables using
MySQL's LOAD DATA LOCAL INFILE.

It replaces multiple table-specific scripts with a single orchestrated loader
that executes all ingestion steps in a controlled order.

Tables Loaded
-------------------------------------------------------------------------------
1. company_dim
2. skills_dim
3. skills_job_dim
4. job_postings_fact

Process
-------------------------------------------------------------------------------
1. Define database connection
2. Define table-to-file mapping
3. Loop through each dataset
4. Disable FK checks
5. Truncate table
6. Bulk load CSV
7. Re-enable FK checks
8. Commit transaction
===============================================================================
"""

from sqlalchemy import create_engine, text

# ============================================================================
# Database connection
# ============================================================================
DB_URL = (
    "mysql+mysqlconnector://"
    "root:your_pasword@localhost:3306/"
    "data_warehouse?allow_local_infile=true"
)

engine = create_engine(DB_URL)

# ============================================================================
# Table → File mapping (single source of truth)
# ============================================================================
LOAD_JOBS = [
    {
        "table": "company_dim",
        "file": "D:/data engineer/Data_warehouse_project_2/data/company_dim.csv"
    },
    {
        "table": "skills_dim",
        "file": "D:/data engineer/Data_warehouse_project_2/data/skills_dim.csv"
    },
    {
        "table": "skills_job_dim",
        "file": "D:/data engineer/Data_warehouse_project_2/data/skills_job_dim.csv"
    },
    {
        "table": "job_postings_fact",
        "file": "D:/data engineer/Data_warehouse_project_2/data/job_postings_fact.csv"
    }
]


def load_table(conn, table_name, file_path):
    """
    Executes full refresh load for a single table.
    """

    print(f"\nLoading {table_name}...")

    # Disable FK checks
    conn.execute(text("SET FOREIGN_KEY_CHECKS = 0"))

    # Truncate table
    conn.execute(text(f"TRUNCATE TABLE {table_name}"))

    # Bulk load CSV
    conn.execute(text(f"""
        LOAD DATA LOCAL INFILE '{file_path}'
        INTO TABLE {table_name}
        FIELDS TERMINATED BY ','
        ENCLOSED BY '"'
        IGNORE 1 ROWS
    """))

    # Re-enable FK checks
    conn.execute(text("SET FOREIGN_KEY_CHECKS = 1"))

    print(f"{table_name} loaded successfully.")


# ============================================================================
# Run full pipeline
# ============================================================================
with engine.connect() as conn:
    for job in LOAD_JOBS:
        load_table(conn, job["table"], job["file"])

    conn.commit()

print("\nAll tables loaded successfully.")