require "rails_helper"

RSpec.describe Auth::LoginService do
  let!(:user) { create(:user, email: "test@lisa.local", password: "Password@123", active: true) }

  describe ".call" do
    context "with valid credentials" do
      it "returns a successful result with the user" do
        result = described_class.call(email: "test@lisa.local", password: "Password@123")
        expect(result).to be_success
        expect(result.user).to eq(user)
      end

      it "is case-insensitive for email" do
        result = described_class.call(email: "TEST@LISA.LOCAL", password: "Password@123")
        expect(result).to be_success
      end
    end

    context "with incorrect password" do
      it "returns a failure result" do
        result = described_class.call(email: "test@lisa.local", password: "WrongPassword")
        expect(result).to be_failure
        expect(result.errors.first).to be_present
      end
    end

    context "with unknown email" do
      it "returns a failure result" do
        result = described_class.call(email: "nobody@lisa.local", password: "Password@123")
        expect(result).to be_failure
        expect(result.errors.first).to be_present
      end
    end

    context "when account is inactive" do
      let!(:inactive_user) { create(:user, :inactive, email: "inactive@lisa.local", password: "Password@123") }

      it "returns a failure result" do
        result = described_class.call(email: "inactive@lisa.local", password: "Password@123")
        expect(result).to be_failure
        expect(result.errors.first).to be_present
      end
    end
  end
end
