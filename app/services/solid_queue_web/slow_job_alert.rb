require "net/http"
require "json"
require "uri"

module SolidQueueWeb
  class SlowJobAlert
    MUTEX = Mutex.new

    class << self
      def call
        return unless configured?

        slow_count = SolidQueue::ClaimedExecution
          .where("created_at <= ?", SolidQueueWeb.slow_job_threshold.ago)
          .count

        return if slow_count < SolidQueueWeb.alert_slow_job_count_threshold
        return unless should_fire?

        urls = webhook_urls
        Thread.new { urls.each { |url| post(url, slow_count) } }
      end

      def reset!
        MUTEX.synchronize { @last_fired_at = nil }
      end

      private

      def configured?
        SolidQueueWeb.slow_job_threshold.present? &&
          SolidQueueWeb.alert_slow_job_count_threshold.present? &&
          webhook_urls.any?
      end

      def webhook_urls
        Array(SolidQueueWeb.alert_webhook_url).flatten.compact.select(&:present?)
      end

      def should_fire?
        MUTEX.synchronize do
          cooldown = SolidQueueWeb.alert_webhook_cooldown
          return false if @last_fired_at && Time.current - @last_fired_at < cooldown

          @last_fired_at = Time.current
          true
        end
      end

      def post(url_string, slow_count)
        uri = URI.parse(url_string)
        payload = JSON.generate(
          event:          "slow_job_threshold_exceeded",
          slow_job_count: slow_count,
          threshold:      SolidQueueWeb.alert_slow_job_count_threshold,
          fired_at:       Time.current.iso8601
        )
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = 5
        http.read_timeout = 10
        request = Net::HTTP::Post.new(uri.path.presence || "/", "Content-Type" => "application/json")
        request.body = payload
        http.request(request)
      rescue => e
        Rails.logger.error("[SolidQueueWeb] Slow job alert webhook failed: #{e.message}")
      end
    end
  end
end
