require "rails_helper"

RSpec.describe SolidQueueWeb::JobPerformanceStats do
  def finished_job(class_name:, duration_seconds:, finished_ago: 1.hour)
    finished = finished_ago.ago
    job = SolidQueue::Job.new(
      queue_name: "default", class_name: class_name,
      arguments: {}.to_json, priority: 0, active_job_id: SecureRandom.uuid
    )
    job.finished_at = finished
    job.created_at  = finished - duration_seconds
    job.updated_at  = finished
    job.save!(validate: false)
    job
  end

  let(:scope) { SolidQueue::Job.where.not(finished_at: nil) }

  describe "#rows" do
    it "returns an empty array when no finished jobs exist" do
      expect(described_class.new(scope).rows).to be_empty
    end

    it "returns one row per distinct job class" do
      finished_job(class_name: "AlphaJob", duration_seconds: 10)
      finished_job(class_name: "BetaJob",  duration_seconds: 20)

      rows = described_class.new(scope).rows
      expect(rows.map(&:class_name)).to match_array(%w[AlphaJob BetaJob])
    end

    it "computes count correctly" do
      3.times { finished_job(class_name: "RepeatedJob", duration_seconds: 10) }

      row = described_class.new(scope).rows.find { |r| r.class_name == "RepeatedJob" }
      expect(row.count).to eq(3)
    end

    it "computes avg, min, and max correctly" do
      finished_job(class_name: "MathJob", duration_seconds: 10)
      finished_job(class_name: "MathJob", duration_seconds: 20)
      finished_job(class_name: "MathJob", duration_seconds: 30)

      row = described_class.new(scope).rows.find { |r| r.class_name == "MathJob" }
      expect(row.avg).to be_within(0.5).of(20)
      expect(row.min).to be_within(0.5).of(10)
      expect(row.max).to be_within(0.5).of(30)
    end

    it "computes p50 as the median" do
      [10, 20, 30, 40, 50].each { |d| finished_job(class_name: "P50Job", duration_seconds: d) }

      row = described_class.new(scope).rows.find { |r| r.class_name == "P50Job" }
      expect(row.p50).to be_within(0.5).of(30)
    end

    it "computes p95 near the high end of the distribution" do
      20.times { |i| finished_job(class_name: "P95Job", duration_seconds: i + 1) }

      row = described_class.new(scope).rows.find { |r| r.class_name == "P95Job" }
      expect(row.p95).to be_within(1).of(19)
    end

    it "sorts rows by p95 descending" do
      finished_job(class_name: "FastJob", duration_seconds: 2)
      finished_job(class_name: "SlowJob", duration_seconds: 120)

      rows = described_class.new(scope).rows
      expect(rows.first.class_name).to eq("SlowJob")
      expect(rows.last.class_name).to  eq("FastJob")
    end

    it "respects a pre-filtered scope" do
      finished_job(class_name: "InScopeJob",  duration_seconds: 10, finished_ago: 30.minutes)
      finished_job(class_name: "OutScopeJob", duration_seconds: 10, finished_ago: 48.hours)

      filtered = scope.where("finished_at >= ?", 1.hour.ago)
      rows = described_class.new(filtered).rows
      expect(rows.map(&:class_name)).to include("InScopeJob")
      expect(rows.map(&:class_name)).not_to include("OutScopeJob")
    end
  end
end
