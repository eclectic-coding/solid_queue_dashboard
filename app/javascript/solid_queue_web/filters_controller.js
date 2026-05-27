import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { page: String }

  connect() {
    const url = new URL(window.location.href)
    const params = url.searchParams
    const page = this.pageValue
    let changed = false

    const keys = page === "jobs" ? ["status", "period"] : ["period"]
    keys.forEach(key => {
      if (!params.has(key)) {
        const saved = localStorage.getItem(`sqd-${page}-${key}`)
        if (saved) { params.set(key, saved); changed = true }
      }
    })

    if (changed) window.location.replace(url.toString())
  }

  saveStatus({ params: { status } }) {
    if (status) localStorage.setItem(`sqd-${this.pageValue}-status`, status)
  }

  savePeriod({ params: { period } }) {
    if (period) {
      localStorage.setItem(`sqd-${this.pageValue}-period`, period)
    } else {
      localStorage.removeItem(`sqd-${this.pageValue}-period`)
    }
  }
}