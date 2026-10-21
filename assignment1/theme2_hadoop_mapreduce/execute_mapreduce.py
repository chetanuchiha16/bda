"""Theme 2: Hadoop MapReduce Analytics - Execution Harness and Benchmark Recorder
Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
Dataset: NASA POWER Daily Weather - Bengaluru, 2024
"""

import csv
import json
import subprocess
import time
from pathlib import Path

DIR = Path(__file__).resolve().parent
DATA_TSV = DIR.parent / "data" / "bengaluru_weather_2024.tsv"
SCALED_TSV = DIR.parent / "data" / "bengaluru_weather_scaled.tsv"
OUTPUT_TSV = DIR / "mapreduce_output.tsv"
SUMMARY_JSON = DIR / "yarn_summary.json"


def run_pipeline(input_file, label="daily_2024"):
    print(f"[INFO] Running MapReduce streaming pipeline on {input_file.name} ({label})...")
    start_time = time.perf_counter()

    # Step 1: Mapper
    p_map = subprocess.Popen(
        ["python3", str(DIR / "mapper.py")],
        stdin=open(input_file, "r", encoding="utf-8"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    # Step 2: Sort (emulating Hadoop MapReduce shuffle & sort phase)
    p_sort = subprocess.Popen(
        ["sort"],
        stdin=p_map.stdout,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    p_map.stdout.close()

    # Step 3: Reducer
    p_red = subprocess.Popen(
        ["python3", str(DIR / "reducer.py")],
        stdin=p_sort.stdout,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    p_sort.stdout.close()

    stdout, stderr = p_red.communicate()
    elapsed_sec = round(time.perf_counter() - start_time, 4)

    if p_red.returncode != 0:
        raise RuntimeError(f"MapReduce failed: {stderr.decode()}")

    output_lines = stdout.decode("utf-8").strip().splitlines()
    return output_lines, elapsed_sec


def main():
    # 1. Run on base 2024 dataset
    lines, elapsed_base = run_pipeline(DATA_TSV, "base_366_days")
    OUTPUT_TSV.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[OK] Saved MapReduce results to {OUTPUT_TSV} (Elapsed: {elapsed_base*1000:.2f} ms)")

    # Parse rows for JSON summary
    reader = csv.DictReader(lines, delimiter="\t")
    monthly_rows = list(reader)

    # 2. Run on scaled benchmark dataset
    _, elapsed_scaled = run_pipeline(SCALED_TSV, "scaled_50000_records")
    print(f"[OK] Scaled MapReduce Benchmark: 50,000 records processed in {elapsed_scaled:.3f} s")

    summary = {
        "job_name": "NASA_Bengaluru_Weather_Monthly_MapReduce",
        "dataset": "NASA POWER Daily Weather - Bengaluru 2024",
        "input_records": 366,
        "scaled_records": 50000,
        "base_execution_seconds": elapsed_base,
        "scaled_execution_seconds": elapsed_scaled,
        "cluster_simulation": {
            "splits": 2,
            "mappers": 2,
            "reducers": 1,
            "shuffle_phase": "external_sort"
        },
        "monthly_summary": monthly_rows
    }

    with open(SUMMARY_JSON, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2)
    print(f"[OK] Saved summary to {SUMMARY_JSON}")


if __name__ == "__main__":
    main()
