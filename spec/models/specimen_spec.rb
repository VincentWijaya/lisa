require "rails_helper"

RSpec.describe Specimen, type: :model do
  subject(:specimen) { build(:specimen) }

  describe "associations" do
    it { is_expected.to have_many(:works).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:patient_id) }
    it { is_expected.to validate_presence_of(:patient_name) }
    it { is_expected.to validate_presence_of(:birth_date) }
    it { is_expected.to validate_presence_of(:gender) }
    it { is_expected.to validate_presence_of(:lab_id) }
    it { is_expected.to validate_presence_of(:order_number) }
    it { is_expected.to define_enum_for(:status).backed_by_column_of_type(:string).with_values(pending: "pending", in_progress: "in_progress", complete: "complete", cancelled: "cancelled") }
  end

  describe "#age_in_years" do
    it "calculates the patient age in full years" do
      travel_to Time.zone.parse("2026-05-25 12:00:00") do
        specimen.birth_date = Date.new(1990, 5, 15)

        expect(specimen.age_in_years).to eq(36)
      end
    end
  end
end
