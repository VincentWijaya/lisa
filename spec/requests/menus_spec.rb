require "rails_helper"

RSpec.describe "Menus", type: :request do
  let!(:user) { create(:user, email: "user@lisa.local", password: "Password@123", active: true) }

  describe "GET menu pages" do
    it "requires authentication" do
      get bank_darah_path

      expect(response).to redirect_to(login_path)
    end

    it "renders blank placeholder pages for the configured menu items" do
      post session_path, params: { email: user.email, password: "Password@123" }

      menu_pages = {
        bank_darah_path => "Bank Darah",
        mikrobiologi_path => "Mikrobiologi",
        patologi_anatomi_path => "Patologi Anatomi",
        inventori_path => "Inventori",
        monitor_qc_path => "Monitor QC",
        laporan_path => "Laporan"
      }

      aggregate_failures do
        menu_pages.each do |path, title|
          get path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(title)
        end
      end
    end
  end
end
