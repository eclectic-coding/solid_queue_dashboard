require "rails_helper"

RSpec.describe SolidQueueWeb do
  describe ".configure" do
    after do
      SolidQueueWeb.page_size                = nil
      SolidQueueWeb.dashboard_refresh_interval  = nil
      SolidQueueWeb.default_refresh_interval    = nil
      SolidQueueWeb.search_results_limit        = nil
    end

    it "yields self and applies settings" do
      SolidQueueWeb.configure do |c|
        c.page_size                  = 50
        c.dashboard_refresh_interval = 3_000
        c.default_refresh_interval   = 15_000
        c.search_results_limit       = 10
      end

      expect(SolidQueueWeb.page_size).to eq(50)
      expect(SolidQueueWeb.dashboard_refresh_interval).to eq(3_000)
      expect(SolidQueueWeb.default_refresh_interval).to eq(15_000)
      expect(SolidQueueWeb.search_results_limit).to eq(10)
    end

    it "returns defaults when not configured" do
      expect(SolidQueueWeb.page_size).to eq(25)
      expect(SolidQueueWeb.dashboard_refresh_interval).to eq(5_000)
      expect(SolidQueueWeb.default_refresh_interval).to eq(10_000)
      expect(SolidQueueWeb.search_results_limit).to eq(25)
    end
  end
end