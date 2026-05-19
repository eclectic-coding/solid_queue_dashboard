module SolidQueueWeb
  module ApplicationHelper
    def inline_styles
      dir = SolidQueueWeb::Engine.root.join("app/assets/stylesheets/solid_queue_web")
      css = dir.glob("_*.css").sort.map(&:read).join("\n")
      content_tag(:style, css.html_safe)
    end
  end
end
