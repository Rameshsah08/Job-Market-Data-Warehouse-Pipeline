"""
===============================================================================
Project      : Job Market Data Warehouse
Script Name  : download_all_csv_files.py

Purpose
-------------------------------------------------------------------------------
This script downloads all required CSV datasets from cloud storage and saves
them into a local data directory.

It replaces multiple individual download scripts with a single reusable
automation step for the ETL pipeline.

Datasets
-------------------------------------------------------------------------------
1. company_dim.csv
2. skills_dim.csv
3. job_postings_fact.csv
4. skills_job_dim.csv

Process
-------------------------------------------------------------------------------
1. Define all source URLs in a dictionary.
2. Define local file output paths.
3. Create target directory if missing.
4. Loop through each dataset and download using streaming mode.
5. Save each file locally.
6. Confirm completion per file.
===============================================================================
"""

import os
import requests

# ============================================================================
# Base local directory
# ============================================================================
BASE_DIR = r"D:\data engineer\Data_warehouse_project_2\data"

os.makedirs(BASE_DIR, exist_ok=True)

# ============================================================================
# Dataset registry (source → destination mapping)
# ============================================================================
DATASETS = {
    "company_dim": {
        "url": "https://storage.googleapis.com/sql_de/company_dim.csv",
        "file": os.path.join(BASE_DIR, "company_dim.csv")
    },
    "skills_dim": {
        "url": "https://storage.googleapis.com/sql_de/skills_dim.csv",
        "file": os.path.join(BASE_DIR, "skills_dim.csv")
    },
    "job_postings_fact": {
        "url": "https://storage.googleapis.com/sql_de/job_postings_fact.csv",
        "file": os.path.join(BASE_DIR, "job_postings_fact.csv")
    },
    "skills_job_dim": {
        "url": "https://storage.googleapis.com/sql_de/skills_job_dim.csv",
        "file": os.path.join(BASE_DIR, "skills_job_dim.csv")
    }
}


def download_file(name, url, output_path):
    print(f"\nDownloading {name}...")

    response = requests.get(url, stream=True)
    response.raise_for_status()

    with open(output_path, "wb") as f:
        for chunk in response.iter_content(chunk_size=1024 * 1024):
            if chunk:
                f.write(chunk)

    print(f"{name} downloaded successfully → {output_path}")


# ============================================================================
# Run all downloads
# ============================================================================
for name, meta in DATASETS.items():
    download_file(name, meta["url"], meta["file"])

print("\nAll downloads completed successfully.")
