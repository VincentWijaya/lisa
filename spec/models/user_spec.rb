require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "associations" do
    it { is_expected.to have_and_belong_to_many(:roles) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to have_secure_password }
  end

  describe "#downcase_email" do
    it "normalises email to lowercase before validation" do
      user.email = "Admin@LISA.LOCAL"
      user.valid?
      expect(user.email).to eq("admin@lisa.local")
    end
  end

  describe "#generate_api_token" do
    it "assigns a 64-character hex api_token before create" do
      user.save!
      expect(user.api_token).to match(/\A[0-9a-f]{64}\z/)
    end

    it "does not overwrite an existing token" do
      user.api_token = "existing_token"
      user.save!
      expect(user.api_token).to eq("existing_token")
    end
  end

  describe "#admin?" do
    it "returns true when user has admin role" do
      user.save!
      user.add_role(:admin)
      expect(user).to be_admin
    end

    it "returns false when user has no admin role" do
      user.save!
      expect(user).not_to be_admin
    end
  end

  describe "#display_roles" do
    it "returns comma-separated role names" do
      user.save!
      user.add_role(:lab_technician)
      expect(user.display_roles).to include("lab_technician")
    end
  end

  describe "active scope" do
    it "returns only active users" do
      active   = create(:user, active: true)
      inactive = create(:user, :inactive)
      expect(User.active).to include(active)
      expect(User.active).not_to include(inactive)
    end
  end
end
