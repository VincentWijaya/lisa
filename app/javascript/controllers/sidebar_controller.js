import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static classes = ["collapsed"]
  static targets = ["label", "hideable"]

  connect() {
    this.collapsed = localStorage.getItem("sidebar-collapsed") === "true"
    this._applyState()
  }

  toggle() {
    this.collapsed = !this.collapsed
    localStorage.setItem("sidebar-collapsed", this.collapsed)
    this._applyState()
  }

  _applyState() {
    this.element.classList.toggle(this.collapsedClass, this.collapsed)
  }
}
