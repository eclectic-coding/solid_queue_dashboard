import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { interval: { type: Number, default: 5000 } }

  initialize() {
    this._onLoad = this._onLoad.bind(this)
    this._onVisibilityChange = this._onVisibilityChange.bind(this)
  }

  connect() {
    this.element.addEventListener("turbo:frame-load", this._onLoad)
    document.addEventListener("visibilitychange", this._onVisibilityChange)
    this._schedule()
  }

  disconnect() {
    clearTimeout(this._timer)
    this.element.removeEventListener("turbo:frame-load", this._onLoad)
    document.removeEventListener("visibilitychange", this._onVisibilityChange)
  }

  _schedule() {
    this._timer = setTimeout(() => {
      if (!document.hidden) this.element.reload()
    }, this.intervalValue)
  }

  _onLoad() {
    clearTimeout(this._timer)
    this._schedule()
  }

  _onVisibilityChange() {
    if (document.hidden) {
      clearTimeout(this._timer)
    } else {
      this.element.reload()
    }
  }
}