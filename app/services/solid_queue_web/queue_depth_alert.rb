require "net/http"
require "json"
require "uri"

module SolidQueueWeb
  class QueueDepthAlert
    MUTEX = Mutex.new

    class << self
      def call
        return unless configured?

        queue_depths = SolidQueue::ReadyExecution
          .joins(:job)
          .group("solid_queue_jobs.queue_name")
          .count

        queue_depths.each do |queue_name, depth|
          threshold = SolidQueueWeb.alert_queue_thresholds[queue_name.to_s]
          next unless threshold && depth >= threshold
          next unless should_fire?(queue_name)

          urls = webhook_urls
          Thread.new { urls.each { |url| post(url, queue_name, depth, threshold) } }
        end
      end

      def reset!
        MUTEX.synchronize { @last_fired_at = {} }
      end

      private

      def configured?
        SolidQueueWeb.alert_queue_thresholds.any? && webhook_urls.any?
      end

      def webhook_urls
        Array(SolidQueueWeb.alert_webhook_url).flatten.compact.select(&:present?)
      end

      def should_fire?(queue_name)
        MUTEX.synchronize do
          @last_fired_at ||= {}
          cooldown = SolidQueueWeb.alert_webhook_cooldown
          return false if @last_fired_at[queue_name] && Time.current - @last_fired_at[queue_name] < cooldown

          @last_fired_at[queue_name] = Time.current
          true
        end
      end

      def post(url_string, queue_name, depth, threshold)
        uri = URI.parse(url_string)
        payload = JSON.generate(
          event:      "queue_depth_threshold_exceeded",
          queue_name: queue_name,
          depth:      depth,
          threshold:  threshold,
          fired_at:   Time.current.iso8601
        )
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = 5
        http.read_timeout = 10
        request = Net::HTTP::Post.new(uri.path.presence || "/", "Content-Type" => "application/json")
        request.body = payload
        http.request(request)
      rescue => e
        Rails.logger.error("[SolidQueueWeb] Queue depth alert webhook failed: #{e.message}")
      end
    end
  end
end
