import { Application } from "@hotwired/stimulus"
import SearchController from "solid_queue_web/search_controller"

const application = Application.start()
application.register("search", SearchController)
