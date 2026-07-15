require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let!(:user) { create(:user, email: "user@lisa.local", password: "Password@123", active: true) }

  before do
    post session_path, params: { email: user.email, password: "Password@123" }
  end

  describe "GET /" do
    it "renders the dashboard with chart and time stats" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("dashboard.processing_chart.title"))
      expect(response.body).to include(I18n.t("dashboard.time_stats.title"))
    end

    it "renders the empty-state message when no pending works exist" do
      get root_path
      expect(response.body).to include(I18n.t("dashboard.processing_chart.empty"))
    end

    it "renders real categories when pending works exist" do
      exam = create(:examination, name: "CBC", category: "Hematologi")
      specimen = create(:specimen)
      create(:work, specimen: specimen, examination: exam, status: "pending",
                    created_at: 10.minutes.ago)

      get root_path

      expect(response.body).to include("Hematologi")
    end

    it "applies the date range filter" do
      get root_path, params: { start_date: Date.current.iso8601, end_date: Date.current.iso8601 }
      expect(response).to have_http_status(:ok)
    end
  end
end
