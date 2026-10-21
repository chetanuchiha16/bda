"""Assignment 2: Practical Extension - FastAPI Analytics & Visualization Service
Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
Dataset: NASA POWER Daily Weather - Bengaluru, 2024
Course: BCS714D - Big Data Analytics
"""

import json
from pathlib import Path
from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, JSONResponse

BASE_DIR = Path(__file__).resolve().parent.parent.parent
DATA_DIR = BASE_DIR / "assignment1" / "data"
THEME1_DIR = BASE_DIR / "assignment1" / "theme1_mongodb"
THEME2_DIR = BASE_DIR / "assignment1" / "theme2_hadoop_mapreduce"
THEME3_DIR = BASE_DIR / "assignment1" / "theme3_pig_hive"
ANALYTICS_FILE = BASE_DIR / "assignment1" / "analytical_questions.json"
FRONTEND_DIR = Path(__file__).resolve().parent.parent / "frontend"

app = FastAPI(
    title="Bengaluru 2024 Climatological Big Data Analytics",
    description="Track B Assignment 2 Practical Extension - Group 17 (Chetan Kishor & Hongiran D)",
    version="1.0.0"
)

# Enable CORS for local dev
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def load_json(filepath: Path, fallback=None):
    if filepath.exists():
        try:
            return json.loads(filepath.read_text(encoding="utf-8"))
        except Exception:
            return fallback or {}
    return fallback or {}


@app.get("/api/summary")
def get_summary():
    """Returns top-level KPIs for Bengaluru 2024 weather and dataset statistics."""
    records = load_json(DATA_DIR / "bengaluru_weather_2024.json", [])
    if not records:
        return JSONResponse(status_code=404, content={"error": "Dataset not found"})

    total_records = len(records)
    avg_temp = round(sum(r["temperature_c"] for r in records) / total_records, 2)
    max_temp_rec = max(records, key=lambda x: x["temperature_c"])
    min_temp_rec = min(records, key=lambda x: x["temperature_c"])
    total_rain = round(sum(r["precipitation_mm"] for r in records), 2)
    max_rain_rec = max(records, key=lambda x: x["precipitation_mm"])
    avg_humidity = round(sum(r["relative_humidity_pct"] for r in records) / total_records, 2)
    rainy_days = sum(1 for r in records if r["precipitation_mm"] > 0.1)

    return {
        "dataset_name": "NASA POWER Daily Weather - Bengaluru 2024",
        "station_coordinates": {"latitude": 12.9716, "longitude": 77.5946},
        "total_days_observed": total_records,
        "temperature": {
            "annual_average_c": avg_temp,
            "peak_daily_mean_c": max_temp_rec["temperature_c"],
            "peak_date": max_temp_rec["date"],
            "lowest_daily_mean_c": min_temp_rec["temperature_c"],
            "lowest_date": min_temp_rec["date"]
        },
        "precipitation": {
            "total_annual_mm": total_rain,
            "wettest_day_mm": max_rain_rec["precipitation_mm"],
            "wettest_date": max_rain_rec["date"],
            "rainy_days_count": rainy_days,
            "dry_days_count": total_records - rainy_days
        },
        "humidity": {
            "annual_average_pct": avg_humidity
        },
        "group_info": {
            "group_number": 17,
            "students": ["Chetan Kishor C G (1JS23CS032)", "Hongiran D (1JS23CS062)"],
            "institution": "JSSATE Bengaluru"
        }
    }


@app.get("/api/timeseries")
def get_timeseries(
    season: str | None = None,
    min_temp: float | None = None,
    max_temp: float | None = None
):
    """Returns daily timeseries observations with optional filters."""
    records = load_json(DATA_DIR / "bengaluru_weather_2024.json", [])
    filtered = records

    if season and isinstance(season, str):
        filtered = [r for r in filtered if r["season"].lower() == season.lower()]
    if min_temp is not None and isinstance(min_temp, (int, float)):
        filtered = [r for r in filtered if r["temperature_c"] >= min_temp]
    if max_temp is not None and isinstance(max_temp, (int, float)):
        filtered = [r for r in filtered if r["temperature_c"] <= max_temp]

    return {
        "count": len(filtered),
        "records": filtered
    }


@app.get("/api/monthly")
def get_monthly_breakdown():
    """Returns monthly aggregates computed via MapReduce and MongoDB pipelines."""
    # Read Theme 1 MongoDB aggregation results
    mongo_agg = load_json(THEME1_DIR / "aggregation_results.json", {})
    monthly_data = mongo_agg.get("monthly_analytics", [])
    return {
        "source": "MongoDB & MapReduce Verified Aggregations",
        "monthly": monthly_data
    }


@app.get("/api/questions")
def get_analytical_questions():
    """Returns the 5 distinct analytical inquiries and conclusions."""
    questions = load_json(ANALYTICS_FILE, [])
    return questions


@app.get("/api/benchmarks")
def get_benchmarks():
    """Returns comprehensive big data system benchmarks across all themes."""
    mongo_profile = load_json(THEME1_DIR / "profile.json", {})
    yarn_summary = load_json(THEME2_DIR / "yarn_summary.json", {})
    hive_bench = load_json(THEME3_DIR / "benchmark.json", {})

    return {
        "theme1_mongodb": mongo_profile,
        "theme2_hadoop_yarn": yarn_summary,
        "theme3_hive_formats": hive_bench
    }


# Serve Static Frontend Files
if FRONTEND_DIR.exists():
    app.mount("/static", StaticFiles(directory=FRONTEND_DIR), name="static")


@app.get("/")
def serve_index():
    index_file = FRONTEND_DIR / "index.html"
    if index_file.exists():
        return FileResponse(index_file)
    return {"message": "FastAPI Big Data API is active. Frontend index.html not yet placed in /frontend"}
