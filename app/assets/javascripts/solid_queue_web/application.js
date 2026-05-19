import { Application, Controller } from "@hotwired/stimulus"

const application = Application.start()

class SearchController extends Controller {
  filter({ target }) {
    clearTimeout(this._timer)
    const len = target.value.length
    if (len >= 4 || len === 0) {
      this._timer = setTimeout(() => target.form.requestSubmit(), 300)
    }
  }
}

application.register("sqd-search", SearchController)