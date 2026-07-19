import { Controller } from "@hotwired/stimulus"

// Range date picker.
// - The trigger button opens a popover with two <input type="date"> fields.
// - Future dates are blocked by the input's `max` attribute and re-clamped in JS.
// - "Terapkan" / "Reset" buttons update the trigger label + refresh the
//   dashboard_stats Turbo Frame.
export default class extends Controller {
  static targets = [ "startInput", "endInput", "trigger", "popover", "applyBtn", "resetBtn", "triggerText" ]
  static values  = { baseUrl: String, max: String }

  connect() {
    this.syncTrigger()
  }

  open(event) {
    event.preventDefault()
    this.popoverTarget.classList.toggle("hidden")
  }

  close(event) {
    if (event && this.element.contains(event.target)) return
    this.popoverTarget.classList.add("hidden")
  }

  // If end < start, swap them. Also clamp both to `max` (today).
  apply(event) {
    if (event) event.preventDefault()
    let s = this.startInputTarget.value
    let e = this.endInputTarget.value
    if (!s && !e) {
      this.popoverTarget.classList.add("hidden")
      return
    }
    if (s && e && s > e) { [ s, e ] = [ e, s ] }
    if (this.hasMaxValue) {
      if (s > this.maxValue) s = this.maxValue
      if (e > this.maxValue) e = this.maxValue
    }
    this.startInputTarget.value = s
    this.endInputTarget.value   = e
    this.syncTrigger()
    this.popoverTarget.classList.add("hidden")
    this.navigate()
  }

  reset(event) {
    if (event) event.preventDefault()
    this.startInputTarget.value = ""
    this.endInputTarget.value   = ""
    this.syncTrigger()
    this.popoverTarget.classList.add("hidden")
    this.navigate()
  }

  navigate() {
    const params = new URLSearchParams()
    const s = this.startInputTarget.value
    const e = this.endInputTarget.value
    if (s) params.set("start_date", s)
    if (e) params.set("end_date", e)
    const url = params.toString() ? `${this.baseUrlValue}?${params}` : this.baseUrlValue
    const frame = document.getElementById("dashboard_stats")
    if (window.Turbo && typeof window.Turbo.visit === "function") {
      window.Turbo.visit(url, { frame: "dashboard_stats" })
    } else if (frame) {
      frame.src = url
    } else {
      window.location.href = url
    }
  }

  syncTrigger() {
    if (!this.hasTriggerTextTarget) return
    const s = this.startInputTarget.value
    const e = this.endInputTarget.value
    if (s || e) {
      this.triggerTextTarget.textContent = `${s || "..."} → ${e || "..."}`
    } else {
      this.triggerTextTarget.textContent = this.triggerTarget.dataset.placeholder || ""
    }
  }
}
