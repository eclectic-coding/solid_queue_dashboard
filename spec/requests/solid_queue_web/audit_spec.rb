require "rails_helper"

RSpec.describe "Audit", type: :request do
  describe "GET /jobs/audit" do
    it "returns HTTP success" do
      get "/jobs/audit"
      expect(response).to have_http_status(:ok)
    end

    it "shows empty state when no events exist" do
      get "/jobs/audit"
      expect(response.body).to include("No audit events recorded")
    end

    it "displays the Audit Log heading" do
      get "/jobs/audit"
      expect(response.body).to include("Audit Log")
    end

    it "renders a row for each audit event" do
      SolidQueueWeb::AuditEvent.create!(action: "queue_paused",     queue_name: "default", created_at: 1.minute.ago)
      SolidQueueWeb::AuditEvent.create!(action: "failed_job_retried", created_at: 2.minutes.ago)

      get "/jobs/audit"
      expect(response.body).to include("queue paused")
      expect(response.body).to include("failed job retried")
    end

    it "renders actor as a filter link when present" do
      SolidQueueWeb::AuditEvent.create!(action: "queue_paused", actor: "admin@example.com", created_at: 1.minute.ago)
      get "/jobs/audit"
      expect(response.body).to include("admin@example.com")
    end

    it "filters by action" do
      SolidQueueWeb::AuditEvent.create!(action: "queue_paused",       actor: "pauser",  created_at: 1.minute.ago)
      SolidQueueWeb::AuditEvent.create!(action: "failed_job_retried", actor: "retrier", created_at: 2.minutes.ago)

      get "/jobs/audit", params: { action_filter: "queue_paused" }
      expect(response.body).to include("pauser")
      expect(response.body).not_to include("retrier")
    end

    it "filters by actor" do
      SolidQueueWeb::AuditEvent.create!(action: "queue_paused", actor: "alice", created_at: 1.minute.ago)
      SolidQueueWeb::AuditEvent.create!(action: "queue_paused", actor: "bob",   created_at: 2.minutes.ago)

      get "/jobs/audit", params: { actor: "alice" }
      expect(response.body).to include("alice")
      expect(response.body).not_to include("bob")
    end

    it "filters by queue" do
      SolidQueueWeb::AuditEvent.create!(action: "queue_paused", queue_name: "critical", created_at: 1.minute.ago)
      SolidQueueWeb::AuditEvent.create!(action: "queue_paused", queue_name: "default-only", created_at: 2.minutes.ago)

      get "/jobs/audit", params: { queue: "critical" }
      expect(response.body).to include("critical")
      expect(response.body).not_to include("default-only")
    end

    it "shows a Clear link when filters are active" do
      get "/jobs/audit", params: { action_filter: "queue_paused" }
      expect(response.body).to include("Clear")
    end

    it "ignores invalid action filter values" do
      SolidQueueWeb::AuditEvent.create!(action: "queue_paused", created_at: 1.minute.ago)
      get "/jobs/audit", params: { action_filter: "inject_something_bad" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("queue paused")
    end

    context "CSV export" do
      it "returns a CSV file" do
        get "/jobs/audit.csv"
        expect(response.headers["Content-Type"]).to include("text/csv")
      end

      it "includes CSV headers" do
        get "/jobs/audit.csv"
        expect(response.body).to include("action")
        expect(response.body).to include("actor")
        expect(response.body).to include("item_count")
      end

      it "includes audit event rows" do
        SolidQueueWeb::AuditEvent.create!(action: "queue_paused", queue_name: "default", created_at: 1.minute.ago)
        get "/jobs/audit.csv"
        expect(response.body).to include("queue_paused")
        expect(response.body).to include("default")
      end
    end

    context "authentication" do
      after { SolidQueueWeb.instance_variable_set(:@authenticate, nil) }

      it "allows access when auth block returns truthy" do
        SolidQueueWeb.authenticate { true }
        get "/jobs/audit"
        expect(response).to have_http_status(:ok)
      end

      it "returns 401 when auth block returns falsy" do
        SolidQueueWeb.authenticate { false }
        get "/jobs/audit"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
