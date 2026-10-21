#!/usr/bin/env python3
"""Theme 2: Hadoop MapReduce Analytics - Mapper (Python Streaming)
Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
Dataset: NASA POWER Daily Weather - Bengaluru, 2024

Input (TSV):
record_id \t date \t year \t month \t day \t season \t temperature_c \t precipitation_mm \t relative_humidity_pct \t heat_index_c \t rain_category

Output:
Key: Month \t Season
Value: temperature_c \t precipitation_mm \t relative_humidity_pct \t 1
"""

import sys


def map_weather_data(stream):
    for line_num, line in enumerate(stream, 1):
        line = line.strip()
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) < 9:
            continue
        try:
            # Check if this is a header row
            if parts[0] == "record_id":
                continue
            month = int(parts[3])
            season = parts[5]
            temp = float(parts[6])
            precip = float(parts[7])
            rh = float(parts[8])

            # Emit Key: "Month\tSeason", Value: "temp\tprecip\trh\t1"
            print(f"{month:02d}\t{season}\t{temp:.2f}\t{precip:.2f}\t{rh:.2f}\t1")
        except (ValueError, IndexError):
            # Skip invalid/corrupt lines
            continue


if __name__ == "__main__":
    map_weather_data(sys.stdin)
