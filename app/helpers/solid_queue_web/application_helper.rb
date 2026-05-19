module SolidQueueWeb
  module ApplicationHelper
    def inline_styles
      css = SolidQueueWeb::Engine.root.join("app/assets/stylesheets/solid_queue_web/application.css").read
      content_tag(:style, css.html_safe)
    end

    def inline_scripts
      js = SolidQueueWeb::Engine.root.join("app/assets/javascripts/solid_queue_web/application.js").read
      content_tag(:script, js.html_safe, type: "module")
    end
  end
end
