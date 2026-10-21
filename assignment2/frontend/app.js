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
          <span class="badge bg-secondary">Bengaluru 2024</span>
        </div>
        <p class="text-muted fw-bold mb-2">${q.question}</p>
        <div class="p-3 bg-light rounded mb-2 border">
          <strong class="text-dark">Key Findings & Data:</strong>
          <pre class="mb-0 mt-1" style="font-size: 0.85rem;">${JSON.stringify(q.findings, null, 2)}</pre>
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
