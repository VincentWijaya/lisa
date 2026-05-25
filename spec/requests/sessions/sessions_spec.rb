require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user, email: "user@lisa.local", password: "Password@123", active: true) }

  describe "GET /login" do
    it "renders the login form" do
      get login_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects authenticated users to root" do
      post session_path, params: { email: user.email, password: "Password@123" }
      get login_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /session" do
    context "with valid credentials" do
      it "logs in and redirects to root" do
        post session_path, params: { email: user.email, password: "Password@123" }
        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid credentials" do
      it "re-renders the login form with 422" do
        post session_path, params: { email: user.email, password: "wrong" }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with inactive account" do
      let!(:inactive_user) { create(:user, :inactive, email: "inactive@lisa.local", password: "Password@123") }

      it "re-renders the login form" do
        post session_path, params: { email: inactive_user.email, password: "Password@123" }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /logout" do
    it "logs out and redirects to login" do
      post session_path, params: { email: user.email, password: "Password@123" }
      delete session_path
      expect(response).to redirect_to(login_path)
    end
  end
end
