import { Controller } from "@hotwired/stimulus"

// Chart.js is loaded as a global via <script> in the layout
// (see app/views/layouts/application.html.erb).
// We poll briefly in case the script tag finishes loading after
// this controller connects.
export default class extends Controller {
  static targets = ["canvas"]
  static values  = {
    labels:       { type: Array, default: [] },
    lt30:         { type: Array, default: [] },
    mid:          { type: Array, default: [] },
    gt60:         { type: Array, default: [] },
    legendLt30:   { type: String, default: "0-30 min" },
    legendMid:    { type: String, default: "31-60 min" },
    legendGt60:   { type: String, default: "> 60 min" },
    unitLabel:    { type: String, default: "minutes" },
    emptyMessage: { type: String, default: "" }
  }

  connect() {
    this.tryRender()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  tryRender(attempt = 0) {
    if (typeof window.Chart === "undefined") {
      if (attempt < 20) {
        setTimeout(() => this.tryRender(attempt + 1), 100)
      }
      return
    }
    this.renderChart()
  }

  renderChart() {
    if (!this.hasCanvasTarget) return
    if (this.labelsValue.length === 0) return

    const labels = this.labelsValue
    const max    = Math.max(
      ...this.lt30Value,
      ...this.midValue,
      ...this.gt60Value,
      1
    )

    this.chart = new window.Chart(this.canvasTarget, {
      type: "bar",
      data: {
        labels,
        datasets: [
          {
            label: this.legendLt30Value,
            data: this.lt30Value,
            backgroundColor: "#00b69b",
            borderRadius: 2,
            barThickness: 40,
            barPercentage: 1.0,
            categoryPercentage: 0.6
          },
          {
            label: this.legendMidValue,
            data: this.midValue,
            backgroundColor: "#f4b400",
            borderRadius: 2,
            barThickness: 40,
            barPercentage: 1.0,
            categoryPercentage: 0.6
          },
          {
            label: this.legendGt60Value,
            data: this.gt60Value,
            backgroundColor: "#f93c65",
            borderRadius: 2,
            barThickness: 40,
            barPercentage: 1.0,
            categoryPercentage: 0.6
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: "#202224",
            titleColor: "#ffffff",
            bodyColor: "#ffffff",
            padding: 8,
            displayColors: true,
            callbacks: {
              label: (ctx) => ` ${ctx.dataset.label}: ${ctx.parsed.y}`
            }
          }
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: {
              font: { family: "Poppins, system-ui, sans-serif", size: 10 },
              color: "#475569"
            }
          },
          y: {
            beginAtZero: true,
            suggestedMax: Math.ceil(max * 1.2),
            grid: { color: "#e2e8f0" },
            ticks: {
              font: { family: "Poppins, system-ui, sans-serif", size: 10 },
              color: "#64748b",
              stepSize: Math.max(1, Math.ceil(max / 5))
            }
          }
        }
      }
    })
  }
}
