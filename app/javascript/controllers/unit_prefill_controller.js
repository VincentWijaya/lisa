import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rule", "unit"]

  fill() {
    const selected = this.ruleTarget.selectedOptions[0]
    const unit = selected?.dataset?.unit ?? ""
    if (unit) this.unitTarget.value = unit
  }
}
