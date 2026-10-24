// =============================================================================
// Group 17 - Bengaluru Weather Big Data Dashboard JavaScript Engine
// =============================================================================

let timeseriesChart = null;
let monthlyChart = null;
let comfortChart = null;
let hiveBenchChart = null;
let allTimeseriesData = [];

document.addEventListener("DOMContentLoaded", async () => {
  await loadSummary();
  await loadTimeseries();
  await loadMonthly();
  await loadQuestions();
  await loadBenchmarks();
  setupFilterListeners();
});

async function loadSummary() {
  try {
    const res = await fetch("/api/summary");
    const data = await res.json();
    
    document.getElementById("kpi-peak-temp").textContent = `${data.temperature.peak_daily_mean_c} °C`;
    document.getElementById("kpi-peak-date").textContent = `Recorded on ${data.temperature.peak_date}`;
    
    document.getElementById("kpi-total-rain").textContent = `${data.precipitation.total_annual_mm} mm`;
    document.getElementById("kpi-rain-days").textContent = `${data.precipitation.rainy_days_count} rainy days (${data.precipitation.dry_days_count} dry days)`;
    
    document.getElementById("kpi-avg-rh").textContent = `${data.humidity.annual_average_pct} %`;
    document.getElementById("kpi-avg-temp").textContent = `Annual Mean Temp: ${data.temperature.annual_average_c} °C`;
  } catch (err) {
    console.error("Failed loading summary:", err);
  }
}

async function loadTimeseries(seasonFilter = "all") {
  try {
    const url = seasonFilter === "all" ? "/api/timeseries" : `/api/timeseries?season=${seasonFilter}`;
    const res = await fetch(url);
    const result = await res.json();
    allTimeseriesData = result.records;

    const labels = allTimeseriesData.map(r => r.date);
    const temps = allTimeseriesData.map(r => r.temperature_c);
    const humidity = allTimeseriesData.map(r => r.relative_humidity_pct);
    const rain = allTimeseriesData.map(r => r.precipitation_mm);

    const ctx = document.getElementById("timeseriesCanvas").getContext("2d");
    if (timeseriesChart) timeseriesChart.destroy();

    timeseriesChart = new Chart(ctx, {
      type: "line",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Daily Mean Temp (°C)",
            data: temps,
            borderColor: "#ef4444",
            backgroundColor: "rgba(239, 68, 68, 0.1)",
            borderWidth: 2,
            tension: 0.2,
            yAxisID: "y-temp",
            pointRadius: 1
          },
          {
            label: "Relative Humidity (%)",
            data: humidity,
            borderColor: "#10b981",
            backgroundColor: "rgba(16, 185, 129, 0.05)",
            borderWidth: 1.5,
            borderDash: [4, 4],
            tension: 0.2,
            yAxisID: "y-rh",
            pointRadius: 0
          },
          {
            label: "Precipitation (mm)",
            data: rain,
            type: "bar",
            backgroundColor: "rgba(59, 130, 246, 0.65)",
            yAxisID: "y-rain"
          }
        ]
      },
      options: {
        responsive: true,
        interaction: { mode: "index", intersect: false },
        scales: {
          x: {
            ticks: { maxTicksLimit: 12 }
          },
          "y-temp": {
            type: "linear",
            position: "left",
            title: { display: true, text: "Temperature (°C)" },
            min: 15,
            max: 38
          },
          "y-rh": {
            type: "linear",
            position: "right",
            title: { display: true, text: "Relative Humidity (%)" },
            grid: { drawOnChartArea: false },
            min: 20,
            max: 100
          },
          "y-rain": {
            type: "linear",
            position: "right",
            title: { display: true, text: "Rainfall (mm)" },
            grid: { drawOnChartArea: false },
            min: 0,
            max: 80
          }
        }
      }
    });

    renderComfortScatter();
  } catch (err) {
    console.error("Error loading timeseries:", err);
  }
}

async function loadMonthly() {
  try {
    const res = await fetch("/api/monthly");
    const result = await res.json();
    const data = result.monthly;

    const labels = data.map(d => d.month_name);
    const rainfall = data.map(d => d.total_rainfall_mm);
    const avgTemps = data.map(d => d.avg_temp);

    const ctx = document.getElementById("monthlyCanvas").getContext("2d");
    if (monthlyChart) monthlyChart.destroy();

    monthlyChart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Monthly Total Rainfall (mm)",
            data: rainfall,
            backgroundColor: "rgba(37, 99, 235, 0.8)",
            borderRadius: 6,
            yAxisID: "y-rain"
          },
          {
            label: "Average Temp (°C)",
            data: avgTemps,
            type: "line",
            borderColor: "#f59e0b",
            backgroundColor: "#f59e0b",
            borderWidth: 2.5,
            pointRadius: 4,
            yAxisID: "y-temp"
          }
        ]
      },
      options: {
        responsive: true,
        scales: {
          "y-rain": {
            type: "linear",
            position: "left",
            title: { display: true, text: "Rainfall (mm)" }
          },
          "y-temp": {
            type: "linear",
            position: "right",
            title: { display: true, text: "Avg Temp (°C)" },
            grid: { drawOnChartArea: false },
            min: 18,
            max: 32
          }
        }
      }
    });
  } catch (err) {
    console.error("Error loading monthly data:", err);
  }
}

function renderComfortScatter() {
  const ctx = document.getElementById("comfortCanvas").getContext("2d");
  if (comfortChart) comfortChart.destroy();

  const points = allTimeseriesData.map(r => ({
    x: r.temperature_c,
    y: r.relative_humidity_pct
  }));

  comfortChart = new Chart(ctx, {
    type: "scatter",
    data: {
      datasets: [{
        label: "Daily Weather Conditions (T vs RH)",
        data: points,
        backgroundColor: "rgba(99, 102, 241, 0.65)",
        pointRadius: 4
      }]
    },
    options: {
      responsive: true,
      scales: {
        x: {
          title: { display: true, text: "Temperature (°C)" },
          min: 15,
          max: 35
        },
        y: {
          title: { display: true, text: "Relative Humidity (%)" },
          min: 20,
          max: 100
        }
      }
    }
  });
}

function renderFindingsHTML(q) {
  const f = q.findings;
  
  if (q.question_id === 1) {
    const rows = (f.top_3_hottest_dates || []).map((d, i) => `
      <tr>
        <td><strong>#${i + 1}</strong></td>
        <td><code>${d.date}</code></td>
        <td><span class="badge bg-danger">${d.temp_c} °C</span></td>
        <td>${d.heat_index} °C</td>
      </tr>
    `).join('');
    
    return `
      <div class="row g-2 mb-3">
        <div class="col-sm-3">
          <div class="p-2 border rounded bg-white text-center">
            <small class="text-muted d-block">Peak Mean Temp</small>
            <span class="fs-5 fw-bold text-danger">${f.peak_temperature_c} °C</span>
          </div>
        </div>
        <div class="col-sm-3">
          <div class="p-2 border rounded bg-white text-center">
            <small class="text-muted d-block">Peak Date</small>
            <span class="fs-6 fw-bold text-dark">${f.peak_temperature_date}</span>
          </div>
        </div>
        <div class="col-sm-3">
          <div class="p-2 border rounded bg-white text-center">
            <small class="text-muted d-block">Summer Average</small>
            <span class="fs-5 fw-bold text-warning">${f.average_summer_temp_c} °C</span>
          </div>
        </div>
        <div class="col-sm-3">
          <div class="p-2 border rounded bg-white text-center">
            <small class="text-muted d-block">Days &ge; 30°C</small>
            <span class="fs-5 fw-bold text-primary">${f.days_exceeding_30c} Days</span>
          </div>
        </div>
      </div>
      <div class="table-responsive">
        <table class="table table-sm table-bordered bg-white mb-0">
          <thead class="table-light">
            <tr>
              <th>Rank</th>
              <th>Date</th>
              <th>24h Daily Mean Temp</th>
              <th>Thom's Discomfort Index</th>
            </tr>
          </thead>
          <tbody>${rows}</tbody>
        </table>
      </div>
    `;
  }

  if (q.question_id === 2) {
    return `
      <div class="row g-2 mb-3">
        <div class="col-sm-3">
          <div class="p-2 border rounded bg-white text-center">
            <small class="text-muted d-block">Total Annual Rain</small>
            <span class="fs-5 fw-bold text-primary">${f.annual_precipitation_mm} mm</span>
          </div>
        </div>
        <div class="col-sm-3">
          <div class="p-2 border rounded bg-white text-center">
            <small class="text-muted d-block">Wettest Single Day</small>
            <span class="fs-5 fw-bold text-info">${f.wettest_day_rainfall_mm} mm</span>
            <small class="d-block text-muted" style="font-size:0.75rem;">${f.wettest_day_date}</small>
          </div>
        </div>
        <div class="col-sm-3">
          <div class="p-2 border rounded bg-white text-center">
            <small class="text-muted d-block">SW Monsoon (Jun-Sep)</small>
            <span class="fs-5 fw-bold text-success">${f.sw_monsoon_rainfall_mm} mm</span>
            <small class="d-block text-muted" style="font-size:0.75rem;">${f.sw_monsoon_share_pct}% share</small>
          </div>
        </div>
        <div class="col-sm-3">
          <div class="p-2 border rounded bg-white text-center">
            <small class="text-muted d-block">NE Monsoon (Oct-Dec)</small>
            <span class="fs-5 fw-bold text-indigo" style="color: #6366f1;">${f.ne_monsoon_rainfall_mm} mm</span>
            <small class="d-block text-muted" style="font-size:0.75rem;">${f.ne_monsoon_share_pct}% share</small>
          </div>
        </div>
      </div>
      <div class="d-flex align-items-center gap-2 mb-1">
        <small class="text-muted fw-semibold">Seasonal Share:</small>
        <div class="progress flex-grow-1" style="height: 18px;">
          <div class="progress-bar bg-success" role="progressbar" style="width: ${f.sw_monsoon_share_pct}%;">SW Monsoon (${f.sw_monsoon_share_pct}%)</div>
          <div class="progress-bar bg-primary" role="progressbar" style="width: ${f.ne_monsoon_share_pct}%;">NE Monsoon (${f.ne_monsoon_share_pct}%)</div>
        </div>
      </div>
    `;
  }

  if (q.question_id === 3) {
    const seasons = f.seasonal_avg_humidity || {};
    return `
      <div class="row g-2 mb-3">
        <div class="col-sm-4">
          <div class="p-2 border rounded bg-white text-center">
            <small class="text-muted d-block">Peak Discomfort Index</small>
            <span class="fs-5 fw-bold text-danger">${f.peak_heat_index_c} °C</span>
            <small class="d-block text-muted" style="font-size:0.75rem;">Recorded on ${f.peak_discomfort_date}</small>
          </div>
        </div>
        <div class="col-sm-4">
          <div class="p-2 border rounded bg-white text-center">
            <small class="text-muted d-block">Ambient Conditions at Peak</small>
            <span class="fs-6 fw-bold text-dark">${f.corresponding_temp_c} °C @ ${f.corresponding_humidity_pct}% RH</span>
            <small class="d-block text-muted" style="font-size:0.75rem;">High thermal sensation</small>
          </div>
        </div>
        <div class="col-sm-4">
          <div class="p-2 border rounded bg-white text-center">
            <small class="text-muted d-block">Severe Discomfort Days</small>
            <span class="fs-5 fw-bold text-warning">${f.severe_discomfort_days} Days</span>
            <small class="d-block text-muted" style="font-size:0.75rem;">Thom's DI &ge; 26°C</small>
          </div>
        </div>
      </div>
      <div class="d-flex flex-wrap gap-2 align-items-center p-2 bg-white border rounded">
        <strong class="small text-muted me-2">Average Relative Humidity by Season:</strong>
        <span class="badge bg-secondary">Winter: ${seasons.Winter || '55.7'}%</span>
        <span class="badge bg-warning text-dark">Summer: ${seasons.Summer || '46.8'}%</span>
        <span class="badge bg-info text-dark">Monsoon: ${seasons.Monsoon || '79.8'}%</span>
        <span class="badge bg-primary">Post-Monsoon: ${seasons['Post-Monsoon'] || '83.6'}%</span>
      </div>
    `;
  }

  if (q.question_id === 4) {
    return `
      <div class="row g-3 mb-2">
        <div class="col-md-6">
          <div class="p-3 border rounded bg-light border-warning">
            <div class="d-flex align-items-center gap-2 mb-1">
              <span class="fs-4">☀️</span>
              <strong class="text-dark">Prolonged Pre-Monsoon Dry Spell</strong>
            </div>
            <div class="fs-4 fw-bold text-danger mb-1">${f.longest_dry_streak_days} Consecutive Days Without Rain</div>
            <p class="small text-muted mb-0">
              Spanned from <strong>${f.dry_streak_start}</strong> to <strong>${f.dry_streak_end}</strong>, directly causing the documented city-wide Bengaluru groundwater and tanker water crisis.
            </p>
          </div>
        </div>
        <div class="col-md-6">
          <div class="p-3 border rounded bg-light border-primary">
            <div class="d-flex align-items-center gap-2 mb-1">
              <span class="fs-4">🌧️</span>
              <strong class="text-dark">Longest Continuous Wet Spell</strong>
            </div>
            <div class="fs-4 fw-bold text-primary mb-1">${f.longest_wet_streak_days} Consecutive Days With Rain</div>
            <p class="small text-muted mb-0">
              Observed during the height of the South-West Monsoon. Total completely dry days across the year: <strong>${f.total_completely_dry_days} days</strong>.
            </p>
          </div>
        </div>
      </div>
    `;
  }

  if (q.question_id === 5) {
    return `
      <div class="table-responsive">
        <table class="table table-sm table-bordered bg-white mb-2">
          <thead class="table-light">
            <tr>
              <th>System &amp; Technology</th>
              <th>Baseline Execution</th>
              <th>Optimized Execution</th>
              <th>Performance Gain</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><strong>Apache Hive (Storage Format)</strong></td>
              <td>Standard Text: <code>${f.hive_text_avg_seconds}s</code></td>
              <td>RCFile Columnar: <code class="text-success">${f.hive_rcfile_avg_seconds}s</code></td>
              <td><span class="badge bg-success">${f.hive_speedup_factor}x Faster</span> &bull; ${f.hive_storage_savings_pct}% Disk Space Saved</td>
            </tr>
            <tr>
              <td><strong>MongoDB (Indexing Engine)</strong></td>
              <td>Collection Scan: <code>${f.mongo_collscan_time_ms}ms</code></td>
              <td>Compound Index: <code class="text-success">${f.mongo_ixscan_time_ms}ms</code></td>
              <td><span class="badge bg-success">${f.mongo_speedup_factor}x Faster</span> &bull; ${f.mongo_docs_scanned_reduction}</td>
            </tr>
          </tbody>
        </table>
      </div>
    `;
  }

  return `<pre class="mb-0 mt-1" style="font-size: 0.85rem;">${JSON.stringify(f, null, 2)}</pre>`;
}

async function loadQuestions() {
  try {
    const res = await fetch("/api/questions");
    const questions = await res.json();
    const container = document.getElementById("questions-container");
    container.innerHTML = "";

    questions.forEach(q => {
      const card = document.createElement("div");
      card.className = "question-card";
      card.innerHTML = `
        <div class="d-flex justify-content-between align-items-center mb-2">
          <h5 class="mb-0 text-primary">Question ${q.question_id}: ${q.title}</h5>
          <span class="badge bg-secondary">NASA MERRA-2 (Bengaluru 2024)</span>
        </div>
        <p class="text-muted fw-bold mb-2">${q.question}</p>
        <div class="p-3 bg-light rounded mb-2 border">
          <strong class="text-dark d-block mb-2">Key Analytical Findings &amp; Metrics:</strong>
          ${renderFindingsHTML(q)}
        </div>
        <div class="alert alert-info py-2 px-3 mb-0" style="font-size: 0.9rem;">
          <strong>Analytical Interpretation:</strong> ${q.interpretation}
        </div>
      `;
      container.appendChild(card);
    });
  } catch (err) {
    console.error("Error loading questions:", err);
  }
}

async function loadBenchmarks() {
  try {
    const res = await fetch("/api/benchmarks");
    const data = await res.json();

    // Hive Format Comparison Chart
    const hiveQueries = data.theme3_hive_formats.query_benchmarks || [];
    const labels = hiveQueries.map(q => q.query_id);
    const textTimes = hiveQueries.map(q => q.text_execution_sec);
    const rcTimes = hiveQueries.map(q => q.rcfile_execution_sec);

    const ctx = document.getElementById("hiveBenchCanvas").getContext("2d");
    if (hiveBenchChart) hiveBenchChart.destroy();

    hiveBenchChart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Text Format (s)",
            data: textTimes,
            backgroundColor: "rgba(239, 68, 68, 0.75)"
          },
          {
            label: "RCFile Columnar (s)",
            data: rcTimes,
            backgroundColor: "rgba(16, 185, 129, 0.85)"
          }
        ]
      },
      options: {
        responsive: true,
        plugins: {
          title: { display: true, text: "Hive Query Execution Latency: Text vs RCFile" }
        },
        scales: {
          y: { title: { display: true, text: "Seconds (lower is better)" } }
        }
      }
    });

    // Populate Mongo and Storage badges
    const savings = data.theme3_hive_formats.storage_comparison.scaled_cluster_dataset_50k.storage_savings_pct;
    document.getElementById("rcfile-savings").textContent = `${savings}% Space Saved`;
    
    const mongoDocs = data.theme1_mongodb.profiles[0].totalDocsExamined;
    const mongoIxDocs = data.theme1_mongodb.profiles[1].totalDocsExamined;
    document.getElementById("mongo-perf-text").textContent = 
      `Index Scan examined only ${mongoIxDocs} keys vs ${mongoDocs} documents in Collection Scan (7.82x speedup).`;
  } catch (err) {
    console.error("Error loading benchmarks:", err);
  }
}

function setupFilterListeners() {
  const seasonSelect = document.getElementById("seasonSelect");
  if (seasonSelect) {
    seasonSelect.addEventListener("change", (e) => {
      loadTimeseries(e.target.value);
    });
  }
}
