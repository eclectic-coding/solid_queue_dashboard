module SolidQueueWeb
  module ApplicationHelper
    def sort_header_th(label, col, url_proc, current_sort:, current_dir:)
      is_active = current_sort == col
      next_dir  = (is_active && current_dir == "desc") ? "asc" : "desc"
      indicator = is_active ? content_tag(:span, current_dir == "desc" ? "↓" : "↑", class: "sqd-sort-indicator") : nil
      tag_opts  = { scope: "col" }
      tag_opts[:"aria-sort"] = current_dir == "asc" ? "ascending" : "descending" if is_active
      content_tag(:th, **tag_opts) do
        link_to(url_proc.call(sort: col, direction: next_dir)) do
          safe_join([label, indicator].compact)
        end
      end
    end

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
