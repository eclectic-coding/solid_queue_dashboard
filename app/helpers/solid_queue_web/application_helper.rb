module SolidQueueWeb
  module ApplicationHelper
    def inline_styles
      dir = SolidQueueWeb::Engine.root.join("app/assets/stylesheets/solid_queue_web")
      css = dir.glob("_*.css").sort.map(&:read).join("\n")
      content_tag(:style, css.html_safe)
    end

    def format_duration(seconds)
      s = seconds.to_i
      return "< 1s" if s < 1

      if s < 60
        "#{s}s"
      elsif s < 3600
        "#{s / 60}m #{s % 60}s"
      else
        "#{s / 3600}h #{(s % 3600) / 60}m"
      end
    end
  end
end
