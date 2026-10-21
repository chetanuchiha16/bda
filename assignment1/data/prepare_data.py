"""Data Preparation and Enrichment Script for NASA POWER Weather Dataset.
Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
Dataset: NASA POWER Daily Weather - Bengaluru, 2024
Parameters: T2M (Temperature), PRECTOTCORR (Precipitation), RH2M (Relative Humidity)
"""

import csv
import datetime
import json
import os
import random
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent
ROOT_DIR = DATA_DIR.parent.parent
RAW_FILE = ROOT_DIR / "raw_weather_bengaluru_2024.csv"

CLEAN_CSV = DATA_DIR / "bengaluru_weather_2024.csv"
CLEAN_TSV = DATA_DIR / "bengaluru_weather_2024.tsv"
CLEAN_JSON = DATA_DIR / "bengaluru_weather_2024.json"
SCALED_TSV = DATA_DIR / "bengaluru_weather_scaled.tsv"


def get_season(month: int) -> str:
    if month in (1, 2):
        return "Winter"
    elif month in (3, 4, 5):
        return "Summer"
    elif month in (6, 7, 8, 9):
        return "Monsoon"
    else:
        return "Post-Monsoon"


def get_rain_category(precip: float) -> str:
    if precip <= 0.001:
        return "Dry"
    elif precip <= 7.5:
        return "Light Rain"
    elif precip <= 35.5:
        return "Moderate Rain"
    else:
        return "Heavy Rain"


def compute_heat_index(temp: float, rh: float) -> float:
    # Thom's Discomfort Index (DI) in Celsius
    # DI = T - (0.55 - 0.0055 * RH) * (T - 14.5)
    di = temp - (0.55 - 0.0055 * rh) * (temp - 14.5)
    return round(di, 2)


def process_dataset():
    if not RAW_FILE.exists():
        raise FileNotFoundError(f"Raw file {RAW_FILE} not found. Please ensure it is present.")

    raw_lines = RAW_FILE.read_text(encoding="utf-8").splitlines()

    # Find the header row right after '-END HEADER-'
    header_idx = -1
    for i, line in enumerate(raw_lines):
        if "-END HEADER-" in line:
            header_idx = i + 1
            break

    if header_idx == -1 or header_idx >= len(raw_lines):
        raise ValueError("Could not find '-END HEADER-' in raw CSV.")

    data_lines = raw_lines[header_idx:]
    reader = csv.DictReader(data_lines)

    records = []
    for row in reader:
        year = int(row["YEAR"])
        doy = int(row["DOY"])
        t2m = float(row["T2M"])
        precip = float(row["PRECTOTCORR"])
        rh2m = float(row["RH2M"])

        # Handle missing data (-999 in NASA POWER)
        if t2m <= -900 or rh2m <= -900 or precip <= -900:
            continue

        # Convert DOY to Date
        date_obj = datetime.date(year, 1, 1) + datetime.timedelta(days=doy - 1)
        month = date_obj.month
        month_name = date_obj.strftime("%B")
        day = date_obj.day
        date_str = date_obj.strftime("%Y-%m-%d")
        season = get_season(month)
        rain_cat = get_rain_category(precip)
        heat_idx = compute_heat_index(t2m, rh2m)

        record = {
            "record_id": doy,
            "year": year,
            "doy": doy,
            "date": date_str,
            "month": month,
            "month_name": month_name,
            "day": day,
            "season": season,
            "temperature_c": t2m,
            "precipitation_mm": precip,
            "relative_humidity_pct": rh2m,
            "heat_index_c": heat_idx,
            "rain_category": rain_cat,
            "location": "Bengaluru",
            "latitude": 12.9716,
            "longitude": 77.5946
        }
        records.append(record)

    print(f"[OK] Processed {len(records)} daily weather records for Bengaluru 2024.")

    # 1. Export Clean CSV
    fieldnames = list(records[0].keys())
    with open(CLEAN_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(records)
    print(f"[OK] Saved CSV: {CLEAN_CSV}")

    # 2. Export TSV (for Pig & Hive external tables)
    tsv_fields = [
        "record_id", "date", "year", "month", "day", "season",
        "temperature_c", "precipitation_mm", "relative_humidity_pct",
        "heat_index_c", "rain_category"
    ]
    with open(CLEAN_TSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, delimiter="\t")
        for r in records:
            writer.writerow([r[k] for k in tsv_fields])
    print(f"[OK] Saved TSV: {CLEAN_TSV}")

    # 3. Export JSON (for MongoDB document ingestion)
    with open(CLEAN_JSON, "w", encoding="utf-8") as f:
        json.dump(records, f, indent=2)
    print(f"[OK] Saved JSON: {CLEAN_JSON}")

    # 4. Generate Scaled Dataset (50,000 records for Big Data Cluster Benchmarks)
    generate_scaled_dataset(records, count=50000)


def generate_scaled_dataset(base_records, count=50000):
    """Synthesizes high-frequency / multi-station records for YARN/Hadoop stress tests."""
    print(f"[INFO] Generating scaled dataset with {count:,} records for cluster benchmarking...")
    random.seed(42)
    stations = ["Bengaluru_Central", "Bengaluru_North", "Bengaluru_South", "Bengaluru_East", "Bengaluru_Rural"]

    with open(SCALED_TSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, delimiter="\t")
        for i in range(1, count + 1):
            base = random.choice(base_records)
            station = random.choice(stations)
            # Add micro-variation
            t2m = round(base["temperature_c"] + random.uniform(-1.5, 1.5), 2)
            precip = max(0.0, round(base["precipitation_mm"] + (random.uniform(-0.5, 0.5) if base["precipitation_mm"] > 0 else 0), 2))
            rh = min(100.0, max(15.0, round(base["relative_humidity_pct"] + random.uniform(-3.0, 3.0), 2)))
            heat_idx = compute_heat_index(t2m, rh)
            rain_cat = get_rain_category(precip)

            writer.writerow([
                i, base["date"], base["year"], base["month"], base["day"],
                base["season"], t2m, precip, rh, heat_idx, rain_cat, station
            ])
    size_mb = os.path.getsize(SCALED_TSV) / (1024 * 1024)
    print(f"[OK] Saved Scaled TSV ({size_mb:.2f} MB): {SCALED_TSV}")


if __name__ == "__main__":
    process_dataset()
