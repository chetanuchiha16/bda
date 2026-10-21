#!/usr/bin/env python3
"""Theme 2: Hadoop MapReduce Analytics - Reducer (Python Streaming)
Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
Dataset: NASA POWER Daily Weather - Bengaluru, 2024

Input: Sorted lines of:
Month \t Season \t temp \t precip \t rh \t 1

Output:
Month \t MonthName \t Season \t DaysCount \t AvgTemp \t MaxTemp \t MinTemp \t TotalRain \t RainyDays \t AvgRH
"""

import sys
import calendar


def reduce_weather_data(stream):
    current_key = None
    days_count = 0
    temp_sum = 0.0
    temp_max = -999.0
    temp_min = 999.0
    precip_sum = 0.0
    rainy_days = 0
    rh_sum = 0.0

    # Header for standard output
    header = "Month\tMonthName\tSeason\tDaysCount\tAvgTemp_C\tMaxTemp_C\tMinTemp_C\tTotalRain_mm\tRainyDays\tAvgRH_pct"
    print(header)

    for line in stream:
        line = line.strip()
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) != 6:
            continue

        month_str, season, temp_str, precip_str, rh_str, count_str = parts
        key = (month_str, season)

        try:
            temp = float(temp_str)
            precip = float(precip_str)
            rh = float(rh_str)
            cnt = int(count_str)
        except ValueError:
            continue

        if current_key == key:
            days_count += cnt
            temp_sum += temp
            if temp > temp_max:
                temp_max = temp
            if temp < temp_min:
                temp_min = temp
            precip_sum += precip
            if precip > 0.1:
                rainy_days += 1
            rh_sum += rh
        else:
            if current_key is not None:
                m_int = int(current_key[0])
                m_name = calendar.month_name[m_int]
                avg_t = temp_sum / days_count
                avg_rh = rh_sum / days_count
                print(f"{current_key[0]}\t{m_name}\t{current_key[1]}\t{days_count}\t{avg_t:.2f}\t{temp_max:.2f}\t{temp_min:.2f}\t{precip_sum:.2f}\t{rainy_days}\t{avg_rh:.2f}")

            current_key = key
            days_count = cnt
            temp_sum = temp
            temp_max = temp
            temp_min = temp
            precip_sum = precip
            rainy_days = 1 if precip > 0.1 else 0
            rh_sum = rh

    # Output last key
    if current_key is not None and days_count > 0:
        m_int = int(current_key[0])
        m_name = calendar.month_name[m_int]
        avg_t = temp_sum / days_count
        avg_rh = rh_sum / days_count
        print(f"{current_key[0]}\t{m_name}\t{current_key[1]}\t{days_count}\t{avg_t:.2f}\t{temp_max:.2f}\t{temp_min:.2f}\t{precip_sum:.2f}\t{rainy_days}\t{avg_rh:.2f}")


if __name__ == "__main__":
    reduce_weather_data(sys.stdin)
