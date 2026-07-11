import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "category", "list", "checkbox", "summary"]

  connect() {
    this.sync()
  }

  filter() {
    const term = (this.inputTarget.value || "").toLowerCase().trim()
    this.applyFilter(term, this.categoryTarget.value)
  }

  filterCategory() {
    this.applyFilter((this.inputTarget.value || "").toLowerCase().trim(), this.categoryTarget.value)
  }

  applyFilter(term, category) {
    const fieldsets = this.listTarget.querySelectorAll("fieldset[data-examination-category]")
    fieldsets.forEach((fieldset) => {
      const matchesCategory = !category || fieldset.dataset.examinationCategory === category
      let hasVisibleRow = false

      fieldset.querySelectorAll("label").forEach((label) => {
        const name = label.dataset.examinationName || ""
        const matchesTerm = !term || name.includes(term)
        const visible = matchesCategory && matchesTerm
        label.classList.toggle("hidden", !visible)
        if (visible) hasVisibleRow = true
      })

      fieldset.classList.toggle("hidden", !hasVisibleRow)
    })
  }

  toggleGroup(event) {
    const group = event.target.dataset.examinationPickerGroupParam
    if (group !== "all") return

    const checked = event.target.checked
    this.checkboxTargets.forEach((box) => {
      if (box.disabled) return
      box.checked = checked
    })
    this.sync()
  }

  toggleLabelGroups(event) {
    const checked = event.target.checked
    this.checkboxTargets.forEach((box) => {
      if (!box.dataset.labelGroup) return
      box.checked = checked
    })
    this.sync()
  }

  sync() {
    if (!this.hasSummaryTarget) return

    const total    = this.checkboxTargets.length
    const checked  = this.checkboxTargets.filter((box) => box.checked).length
    const groups   = new Set(
      this.checkboxTargets
        .filter((box) => box.checked && box.dataset.labelGroup)
        .map((box) => box.dataset.labelGroup)
    )

    if (checked === 0) {
      this.summaryTarget.textContent = this.summaryValue("selection_empty")
      return
    }

    const parts = [
      this.summaryValue("selection_count", count: checked, total: total)
    ]
    if (groups.size > 0) {
      parts.push(this.summaryValue("selection_groups", count: groups.size))
    }
    this.summaryTarget.textContent = parts.join(" • ")
  }

  summaryValue(key, **vars) {
    const value = this.summaryTarget.dataset[`summary${key.charAt(0).toUpperCase() + key.slice(1)}`]
    if (!value) return ""
    return value.replace(/%\{(\w+)\}/g, (_, name) => vars[name] || "")
  }
}
