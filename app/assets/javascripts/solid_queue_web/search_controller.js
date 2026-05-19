import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  filter({ target }) {
    clearTimeout(this._timer)
    const len = target.value.length
    if (len >= 4 || len === 0) {
      this._timer = setTimeout(() => target.form.requestSubmit(), 300)
    }
  }
}