require "rails_helper"

RSpec.describe SolidQueueWeb::ApplicationHelper, type: :helper do
  describe "#format_timestamp" do
    let(:time) { Time.utc(2024, 6, 15, 14, 30, 45) }

    after { SolidQueueWeb.time_zone = nil }

    it "returns '—' for nil" do
      expect(helper.format_timestamp(nil)).to eq("—")
    end

    it "formats in UTC by default" do
      expect(helper.format_timestamp(time)).to eq("2024-06-15 14:30:45")
    end

    it "formats in the configured time zone" do
      SolidQueueWeb.time_zone = "America/New_York"
      expect(helper.format_timestamp(time)).to eq("2024-06-15 10:30:45")
    end

    it "accepts a custom format string" do
      expect(helper.format_timestamp(time, format: "%Y-%m-%d %H:%M")).to eq("2024-06-15 14:30")
    end
  end

  describe "#format_duration" do
    it "returns '< 1s' for sub-second durations" do
      expect(helper.format_duration(0.4)).to eq("< 1s")
    end

    it "formats seconds only" do
      expect(helper.format_duration(45)).to eq("45s")
    end

    it "formats minutes and seconds" do
      expect(helper.format_duration(125)).to eq("2m 5s")
    end

    it "formats hours and minutes" do
      expect(helper.format_duration(3_661)).to eq("1h 1m")
    end
  end
end
