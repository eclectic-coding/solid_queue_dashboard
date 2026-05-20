require "rails_helper"

RSpec.describe SolidQueueWeb::ApplicationHelper, type: :helper do
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
