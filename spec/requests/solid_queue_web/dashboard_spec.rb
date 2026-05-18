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

  describe "authentication" do
    after { SolidQueueWeb.instance_variable_set(:@authenticate, nil) }

    it "allows access when the auth block returns truthy" do
      SolidQueueWeb.authenticate { true }
      get "/jobs"
      expect(response).to have_http_status(:ok)
    end

    it "returns 401 when the auth block returns falsy" do
      SolidQueueWeb.authenticate { false }
      get "/jobs"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
