module SolidQueueWeb
  module ApplicationHelper
    def inline_styles
      css = SolidQueueWeb::Engine.root.join("app/assets/stylesheets/solid_queue_web/application.css").read
      content_tag(:style, css.html_safe)
    end
  end
end
