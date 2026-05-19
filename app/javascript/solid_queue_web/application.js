import "@hotwired/turbo"
import { Application } from "@hotwired/stimulus"
import SearchController from "solid_queue_web/search_controller"
import RefreshController from "solid_queue_web/refresh_controller"

const application = Application.start()
application.register("search", SearchController)
application.register("refresh", RefreshController)
