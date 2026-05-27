import "@hotwired/turbo"
import { Application } from "@hotwired/stimulus"
import SearchController from "solid_queue_web/search_controller"
import RefreshController from "solid_queue_web/refresh_controller"
import SelectionController from "solid_queue_web/selection_controller"
import ThemeController from "solid_queue_web/theme_controller"
import FiltersController from "solid_queue_web/filters_controller"

const application = Application.start()
application.register("search", SearchController)
application.register("refresh", RefreshController)
application.register("selection", SelectionController)
application.register("theme", ThemeController)
application.register("filters", FiltersController)
