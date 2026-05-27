module SolidQueueWeb
  class JobPerformanceStats
    Row = Struct.new(:class_name, :count, :avg, :p50, :p95, :p99, :std_dev, :min, :max, keyword_init: true)

    def initialize(scope)
      @scope = scope
    end

    def rows
      grouped = @scope.pluck(:class_name, :created_at, :finished_at)
        .group_by(&:first)

      grouped.map do |class_name, records|
        durations = records.map { |_, created, finished| (finished - created).to_f }.sort
        Row.new(
          class_name: class_name,
          count:      durations.size,
          avg:        mean(durations),
          p50:        percentile(durations, 50),
          p95:        percentile(durations, 95),
          p99:        percentile(durations, 99),
          std_dev:    std_dev(durations),
          min:        durations.first,
          max:        durations.last
        )
      end.sort_by { |r| -r.p95 }
    end

    private

    def mean(sorted)
      sorted.sum / sorted.size
    end

    def percentile(sorted, pct)
      idx = [(pct / 100.0 * sorted.size).ceil - 1, 0].max
      sorted[idx]
    end

    def std_dev(sorted)
      return 0.0 if sorted.size < 2
      m = mean(sorted)
      Math.sqrt(sorted.sum { |x| (x - m)**2 } / sorted.size)
    end
  end
end
