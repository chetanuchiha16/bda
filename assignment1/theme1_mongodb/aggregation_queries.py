"""Theme 1: MongoDB Big Data Processing & Analytics
Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
Dataset: NASA POWER Daily Weather - Bengaluru, 2024

Script 2: Aggregation Pipelines using $match, $group, $project, $unwind, $facet
"""

import json
import sys
from pathlib import Path

DATA_JSON = Path(__file__).resolve().parent.parent / "data" / "bengaluru_weather_2024.json"
RESULTS_FILE = Path(__file__).resolve().parent / "aggregation_results.json"

MONGO_URI = "mongodb://localhost:27017"
DB_NAME = "bda_weather_db"
COLLECTION_NAME = "bengaluru_2024"


def run_aggregations_live(client):
    db = client[DB_NAME]
    coll = db[COLLECTION_NAME]

    # Pipeline 1: Monthly Analytics using $match, $group, $project, $sort
    # Analyzes monthly average, min, max temperature and cumulative rainfall
    pipeline_monthly = [
        {"$match": {"year": 2024}},
        {
            "$group": {
                "_id": "$month",
                "month_name": {"$first": "$month_name"},
                "avg_temp": {"$avg": "$temperature_c"},
                "max_temp": {"$max": "$temperature_c"},
                "min_temp": {"$min": "$temperature_c"},
                "total_rainfall_mm": {"$sum": "$precipitation_mm"},
                "avg_humidity": {"$avg": "$relative_humidity_pct"},
                "days_count": {"$sum": 1}
            }
        },
        {
            "$project": {
                "_id": 0,
                "month": "$_id",
                "month_name": 1,
                "avg_temp": {"$round": ["$avg_temp", 2]},
                "max_temp": {"$round": ["$max_temp", 2]},
                "min_temp": {"$round": ["$min_temp", 2]},
                "total_rainfall_mm": {"$round": ["$total_rainfall_mm", 2]},
                "avg_humidity": {"$round": ["$avg_humidity", 2]},
                "days_count": 1
            }
        },
        {"$sort": {"month": 1}}
    ]

    # Pipeline 2: Seasonal Weather Distribution with $project, $unwind, $group
    # Deconstructs weather attributes and categorizes days per season
    pipeline_seasonal = [
        {
            "$project": {
                "season": 1,
                "rain_category": 1,
                "temperature_c": 1,
                "metrics": [
                    {"type": "temp", "val": "$temperature_c"},
                    {"type": "humidity", "val": "$relative_humidity_pct"}
                ]
            }
        },
        {"$unwind": "$metrics"},
        {
            "$group": {
                "_id": {
                    "season": "$season",
                    "metric_type": "$metrics.type"
                },
                "avg_value": {"$avg": "$metrics.val"},
                "max_value": {"$max": "$metrics.val"},
                "min_value": {"$min": "$metrics.val"}
            }
        },
        {
            "$project": {
                "_id": 0,
                "season": "$_id.season",
                "metric_type": "$_id.metric_type",
                "avg_value": {"$round": ["$avg_value", 2]},
                "max_value": {"$round": ["$max_value", 2]},
                "min_value": {"$round": ["$min_value", 2]}
            }
        },
        {"$sort": {"season": 1, "metric_type": 1}}
    ]

    # Pipeline 3: Multi-Faceted Analytics using $facet
    # Computes Top 5 Hottest Days, Top 5 Wettest Days, and Annual Overview simultaneously
    pipeline_facet = [
        {
            "$facet": {
                "hottest_days": [
                    {"$sort": {"temperature_c": -1}},
                    {"$limit": 5},
                    {"$project": {"_id": 0, "date": 1, "temperature_c": 1, "heat_index_c": 1, "season": 1}}
                ],
                "wettest_days": [
                    {"$sort": {"precipitation_mm": -1}},
                    {"$limit": 5},
                    {"$project": {"_id": 0, "date": 1, "precipitation_mm": 1, "rain_category": 1}}
                ],
                "annual_summary": [
                    {
                        "$group": {
                            "_id": None,
                            "overall_avg_temp": {"$avg": "$temperature_c"},
                            "overall_max_temp": {"$max": "$temperature_c"},
                            "overall_min_temp": {"$min": "$temperature_c"},
                            "annual_rainfall_mm": {"$sum": "$precipitation_mm"},
                            "rainy_days_count": {
                                "$sum": {"$cond": [{"$gt": ["$precipitation_mm", 0.1]}, 1, 0]}
                            },
                            "heatwave_days_count": {
                                "$sum": {"$cond": [{"$gte": ["$temperature_c", 35.0]}, 1, 0]}
                            }
                        }
                    },
                    {
                        "$project": {
                            "_id": 0,
                            "overall_avg_temp": {"$round": ["$overall_avg_temp", 2]},
                            "overall_max_temp": 1,
                            "overall_min_temp": 1,
                            "annual_rainfall_mm": {"$round": ["$annual_rainfall_mm", 2]},
                            "rainy_days_count": 1,
                            "heatwave_days_count": 1
                        }
                    }
                ]
            }
        }
    ]

    monthly_res = list(coll.aggregate(pipeline_monthly))
    seasonal_res = list(coll.aggregate(pipeline_seasonal))
    facet_res = list(coll.aggregate(pipeline_facet))

    return {
        "monthly_analytics": monthly_res,
        "seasonal_distribution": seasonal_res,
        "faceted_summary": facet_res[0] if facet_res else {}
    }


def run_aggregations_simulated():
    """Runs exact aggregation logic locally if Mongo service is not running."""
    records = json.loads(DATA_JSON.read_text(encoding="utf-8"))

    # 1. Monthly
    from collections import defaultdict
    months = defaultdict(list)
    for r in records:
        months[r["month"]].append(r)

    monthly_res = []
    for m in sorted(months.keys()):
        group = months[m]
        avg_temp = round(sum(x["temperature_c"] for x in group) / len(group), 2)
        max_temp = max(x["temperature_c"] for x in group)
        min_temp = min(x["temperature_c"] for x in group)
        total_rain = round(sum(x["precipitation_mm"] for x in group), 2)
        avg_rh = round(sum(x["relative_humidity_pct"] for x in group) / len(group), 2)
        monthly_res.append({
            "month": m,
            "month_name": group[0]["month_name"],
            "avg_temp": avg_temp,
            "max_temp": max_temp,
            "min_temp": min_temp,
            "total_rainfall_mm": total_rain,
            "avg_humidity": avg_rh,
            "days_count": len(group)
        })

    # 2. Seasonal
    seasons = defaultdict(lambda: {"temp": [], "humidity": []})
    for r in records:
        seasons[r["season"]]["temp"].append(r["temperature_c"])
        seasons[r["season"]]["humidity"].append(r["relative_humidity_pct"])

    seasonal_res = []
    for s in sorted(seasons.keys()):
        for mtype in ("humidity", "temp"):
            vals = seasons[s][mtype]
            seasonal_res.append({
                "season": s,
                "metric_type": mtype,
                "avg_value": round(sum(vals) / len(vals), 2),
                "max_value": max(vals),
                "min_value": min(vals)
            })

    # 3. Faceted
    hottest = sorted(records, key=lambda x: x["temperature_c"], reverse=True)[:5]
    wettest = sorted(records, key=lambda x: x["precipitation_mm"], reverse=True)[:5]

    annual = {
        "overall_avg_temp": round(sum(x["temperature_c"] for x in records) / len(records), 2),
        "overall_max_temp": max(x["temperature_c"] for x in records),
        "overall_min_temp": min(x["temperature_c"] for x in records),
        "annual_rainfall_mm": round(sum(x["precipitation_mm"] for x in records), 2),
        "rainy_days_count": sum(1 for x in records if x["precipitation_mm"] > 0.1),
        "heatwave_days_count": sum(1 for x in records if x["temperature_c"] >= 35.0)
    }

    return {
        "monthly_analytics": monthly_res,
        "seasonal_distribution": seasonal_res,
        "faceted_summary": {
            "hottest_days": [{"date": x["date"], "temperature_c": x["temperature_c"], "heat_index_c": x["heat_index_c"], "season": x["season"]} for x in hottest],
            "wettest_days": [{"date": x["date"], "precipitation_mm": x["precipitation_mm"], "rain_category": x["rain_category"]} for x in wettest],
            "annual_summary": [annual]
        }
    }


def execute(mongo_uri=MONGO_URI):
    try:
        from pymongo import MongoClient
        client = MongoClient(mongo_uri, serverSelectionTimeoutMS=2000)
        client.admin.command("ping")
        print(f"[OK] Executing aggregation pipelines on live MongoDB at {mongo_uri}...")
        results = run_aggregations_live(client)
        client.close()
    except Exception as e:
        print(f"[INFO] Using standalone pipeline engine ({e}).")
        results = run_aggregations_simulated()

    with open(RESULTS_FILE, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print(f"[OK] Aggregation results successfully written to {RESULTS_FILE}")
    print("\n--- ANNUAL WEATHER SUMMARY (BENGALURU 2024) ---")
    summary = results["faceted_summary"]["annual_summary"][0]
    print(f"Overall Average Temperature : {summary['overall_avg_temp']} °C")
    print(f"Maximum Peak Temperature    : {summary['overall_max_temp']} °C")
    print(f"Minimum Temperature         : {summary['overall_min_temp']} °C")
    print(f"Total Cumulative Rainfall   : {summary['annual_rainfall_mm']} mm")
    print(f"Number of Rainy Days        : {summary['rainy_days_count']} days")
    print(f"Summer Days >= 35°C         : {summary['heatwave_days_count']} days")
    return results


if __name__ == "__main__":
    uri = sys.argv[1] if len(sys.argv) > 1 else MONGO_URI
    execute(uri)
