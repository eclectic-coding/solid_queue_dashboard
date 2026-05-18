require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /jobs" do
    it "returns HTTP success" do
      get "/jobs"
      expect(response).to have_http_status(:ok), -> { response.body }
    end

    it "displays the dashboard heading" do
      get "/jobs"
      expect(response.body).to include("Dashboard")
    end
  end
end
