"""Theme 1: MongoDB Big Data Processing & Analytics
Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
Dataset: NASA POWER Daily Weather - Bengaluru, 2024

Script 1: Document Ingestion and Index Setup
"""

import json
import sys
from pathlib import Path

DATA_JSON = Path(__file__).resolve().parent.parent / "data" / "bengaluru_weather_2024.json"

MONGO_URI = "mongodb://localhost:27017"
DB_NAME = "bda_weather_db"
COLLECTION_NAME = "bengaluru_2024"


def ingest_data(mongo_uri=MONGO_URI):
    try:
        from pymongo import MongoClient, ASCENDING, DESCENDING
        client = MongoClient(mongo_uri, serverSelectionTimeoutMS=2000)
        # Test connection
        client.admin.command("ping")
        print(f"[OK] Connected to MongoDB at {mongo_uri}")
    except Exception as e:
        print(f"[WARN] Live MongoDB not reachable at {mongo_uri} ({e}).")
        print("[INFO] Simulating ingestion for development and offline evidence preparation...")
        records = json.loads(DATA_JSON.read_text(encoding="utf-8"))
        print(f"[SIMULATED] Successfully prepared {len(records)} documents for collection '{COLLECTION_NAME}'.")
        return {"status": "simulated", "count": len(records), "db": DB_NAME, "collection": COLLECTION_NAME}

    db = client[DB_NAME]
    collection = db[COLLECTION_NAME]

    # Clean existing records
    collection.delete_many({})

    # Read data
    records = json.loads(DATA_JSON.read_text(encoding="utf-8"))
    
    # Insert documents
    result = collection.insert_many(records)
    print(f"[OK] Inserted {len(result.inserted_ids)} documents into {DB_NAME}.{COLLECTION_NAME}")

    # Create Indexes
    # 1. Single field index on Date
    idx_date = collection.create_index([("date", ASCENDING)], name="idx_date")
    print(f"[OK] Created index: {idx_date}")

    # 2. Single field index on Temperature
    idx_temp = collection.create_index([("temperature_c", DESCENDING)], name="idx_temp")
    print(f"[OK] Created index: {idx_temp}")

    # 3. Compound index on Month and Temperature
    idx_month_temp = collection.create_index(
        [("month", ASCENDING), ("temperature_c", DESCENDING)],
        name="idx_month_temp"
    )
    print(f"[OK] Created compound index: {idx_month_temp}")

    # 4. Index on Precipitation
    idx_precip = collection.create_index([("precipitation_mm", DESCENDING)], name="idx_precip")
    print(f"[OK] Created index: {idx_precip}")

    # Collection statistics
    stats = db.command("collStats", COLLECTION_NAME)
    print(f"[OK] Collection Stats: Count = {stats.get('count')}, Storage Size = {stats.get('storageSize')} bytes")

    client.close()
    return {"status": "success", "count": len(result.inserted_ids)}


if __name__ == "__main__":
    uri = sys.argv[1] if len(sys.argv) > 1 else MONGO_URI
    ingest_data(uri)
