require "rails_helper"

RSpec.describe SolidQueueWeb::ApplicationController, type: :controller do
  controller(SolidQueueWeb::ApplicationController) do
    skip_before_action :authenticate!

    def index
      render plain: "ok"
    end
  end

  after { SolidQueueWeb.connects_to = nil }

  describe "#with_database_connection" do
    context "when connects_to is not configured" do
      it "does not call connected_to" do
        expect(ActiveRecord::Base).not_to receive(:connected_to)
        get :index
        expect(response).to have_http_status(:ok)
      end
    end

    context "when connects_to has a single role" do
      before { SolidQueueWeb.connects_to = { role: :writing } }

      it "calls connected_to with the config" do
        expect(ActiveRecord::Base).to receive(:connected_to).with(role: :writing).and_yield
        get :index
      end
    end

    context "when connects_to has both reading and writing roles" do
      before { SolidQueueWeb.connects_to = { reading: :reading, writing: :writing } }

      it "uses the reading role for GET requests" do
        expect(ActiveRecord::Base).to receive(:connected_to).with(role: :reading).and_yield
        get :index
        expect(response).to have_http_status(:ok)
      end

      it "uses the writing role for non-GET requests" do
        expect(ActiveRecord::Base).to receive(:connected_to).with(role: :writing).and_yield
        post :index
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "#replica_configured?" do
    it "returns false when only role is configured" do
      expect(controller.send(:replica_configured?, { role: :writing })).to be false
    end

    it "returns false when only writing is configured" do
      expect(controller.send(:replica_configured?, { writing: :writing })).to be false
    end

    it "returns true when both reading and writing roles are configured" do
      expect(controller.send(:replica_configured?, { reading: :reading, writing: :writing })).to be true
    end
  end
end
