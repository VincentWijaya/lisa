import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "video", "status", "input", "scanForm"]

  open() {
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    this.startCamera()
  }

  close() {
    this.stopCamera()
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  async startCamera() {
    this.scanning = false
    this.setStatus("starting")

    try {
      this.stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: { ideal: "environment" }, width: { ideal: 1280 } }
      })
      this.videoTarget.srcObject = this.stream
      await this.videoTarget.play()
      this.scanning = true

      if ("BarcodeDetector" in window) {
        this.setStatus("scanning")
        this.detectLoop()
      } else {
        this.setStatus("no_detector")
      }
    } catch (_err) {
      this.setStatus("camera_error")
    }
  }

  async detectLoop() {
    if (!this.scanning) return

    try {
      const detector = this._detector ||= new BarcodeDetector({
        formats: ["code_128", "code_39", "qr_code", "ean_13", "ean_8"]
      })
      const codes = await detector.detect(this.videoTarget)
      if (codes.length > 0) {
        this.onDetected(codes[0].rawValue)
        return
      }
    } catch (_) {}

    if (this.scanning) requestAnimationFrame(() => this.detectLoop())
  }

  onDetected(value) {
    this.stopCamera()
    this.inputTarget.value = value
    this.setStatus("detected")
    this.scanFormTarget.requestSubmit()
  }

  submitManual() {
    if (this.inputTarget.value.trim()) {
      this.scanFormTarget.requestSubmit()
    } else {
      this.inputTarget.focus()
    }
  }

  stopCamera() {
    this.scanning = false
    if (this.stream) {
      this.stream.getTracks().forEach(t => t.stop())
      this.stream = null
    }
  }

  setStatus(key) {
    const messages = {
      starting:    "Starting camera…",
      scanning:    "Point camera at barcode…",
      no_detector: "Camera active — scan or type barcode below.",
      camera_error:"Cannot access camera. Type the barcode below.",
      detected:    "Barcode detected! Submitting…"
    }
    if (this.hasStatusTarget) this.statusTarget.textContent = messages[key] || ""
  }

  disconnect() {
    this.stopCamera()
    document.body.style.overflow = ""
  }
}
