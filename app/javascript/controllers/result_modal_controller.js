import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form", "valueInput", "unitInput", "referenceRuleSelect"]

  open(event) {
    const btn = event.currentTarget
    this.valueInputTarget.value           = btn.dataset.resultValue || ""
    this.unitInputTarget.value            = btn.dataset.resultUnit || ""
    this.referenceRuleSelectTarget.value  = btn.dataset.resultReferenceRuleId || ""
    this.formTarget.action                = btn.dataset.updateUrl

    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    this.valueInputTarget.focus()
  }

  close() {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  disconnect() {
    document.body.style.overflow = ""
  }
}
