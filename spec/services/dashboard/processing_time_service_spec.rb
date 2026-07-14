require "rails_helper"

RSpec.describe Dashboard::ProcessingTimeService do
  let(:start_date) { Date.current - 6 }
  let(:end_date)   { Date.current }
  let(:specimen)   { create(:specimen) }

  def make_examination(name:, category: nil)
    create(:examination, name: name, category: category)
  end

  def make_pending_work(examination:, age_minutes:)
    examination = make_examination(name: examination[:name], category: examination[:category]) if examination.is_a?(Hash)
    create(:work,
           specimen: specimen,
           examination: examination,
           status: "pending",
           created_at: Time.current - age_minutes.minutes)
  end

  def make_verified_work(examination:, tat_minutes:)
    examination = make_examination(name: examination[:name], category: examination[:category]) if examination.is_a?(Hash)
    work = create(:work, specimen: specimen, examination: examination, status: "pending")
    work.update_columns(status: "verified",
                        created_at: Time.current - tat_minutes.minutes,
                        verified_at: Time.current)
    work
  end

  describe ".call" do
    it "returns a hash with chart and stats" do
      result = described_class.call(start_date: start_date, end_date: end_date)
      expect(result).to be_a(Hash)
      expect(result[:chart]).to be_a(Hash)
      expect(result[:stats]).to be_a(Hash)
    end

    context "chart bucketing (pending works by age)" do
      let(:hematology) { make_examination(name: "Hematology", category: "Hematologi") }
      let(:kimia)      { make_examination(name: "Kimia",      category: "Kimia Klinik") }

      it "places a 10-minute-old pending work in the 0-30 bucket" do
        make_pending_work(examination: hematology, age_minutes: 10)
        result = described_class.call(start_date: start_date, end_date: end_date)

        idx = result[:chart][:labels].index("Hematologi")
        expect(idx).not_to be_nil
        expect(result[:chart][:series][:lt_30][idx]).to eq(1)
        expect(result[:chart][:series][:mid][idx]).to eq(0)
        expect(result[:chart][:series][:gt_60][idx]).to eq(0)
      end

      it "places a 45-minute-old pending work in the 31-60 bucket" do
        make_pending_work(examination: kimia, age_minutes: 45)
        result = described_class.call(start_date: start_date, end_date: end_date)

        idx = result[:chart][:labels].index("Kimia Klinik")
        expect(result[:chart][:series][:lt_30][idx]).to eq(0)
        expect(result[:chart][:series][:mid][idx]).to eq(1)
        expect(result[:chart][:series][:gt_60][idx]).to eq(0)
      end

      it "places a 120-minute-old pending work in the >60 bucket" do
        make_pending_work(examination: hematology, age_minutes: 120)
        result = described_class.call(start_date: start_date, end_date: end_date)

        idx = result[:chart][:labels].index("Hematologi")
        expect(result[:chart][:series][:gt_60][idx]).to eq(1)
      end

      it "groups uncategorized examinations under 'Lainnya'" do
        uncat = make_examination(name: "Misc", category: nil)
        make_pending_work(examination: uncat, age_minutes: 5)
        result = described_class.call(start_date: start_date, end_date: end_date)

        expect(result[:chart][:labels]).to include(Dashboard::ProcessingTimeService::UNCATEGORIZED_LABEL)
      end

      it "excludes non-pending works" do
        work = create(:work, specimen: specimen, examination: hematology, status: "pending",
                            created_at: 10.minutes.ago)
        work.update_columns(status: "validated", validated_at: Time.current)
        result = described_class.call(start_date: start_date, end_date: end_date)
        expect(result[:chart][:labels]).not_to include("Hematologi")
      end

      it "excludes works outside the date range" do
        old = make_examination(name: "Old", category: "Lama")
        make_pending_work(examination: old, age_minutes: 10)
        Work.where(examination: old).update_all(created_at: 30.days.ago)
        result = described_class.call(start_date: start_date, end_date: end_date)
        expect(result[:chart][:labels]).not_to include("Lama")
      end

      it "returns empty labels/series when no pending works exist" do
        result = described_class.call(start_date: start_date, end_date: end_date)
        expect(result[:chart][:labels]).to eq([])
        expect(result[:chart][:series][:lt_30]).to eq([])
        expect(result[:chart][:series][:mid]).to eq([])
        expect(result[:chart][:series][:gt_60]).to eq([])
      end
    end

    context "stats (verified works TAT)" do
      let(:exam) { make_examination(name: "Test", category: "Cat") }

      it "computes average TAT in minutes" do
        make_verified_work(examination: exam, tat_minutes: 30)
        make_verified_work(examination: exam, tat_minutes: 60)
        result = described_class.call(start_date: start_date, end_date: end_date)
        expect(result[:stats][:avg_tat_minutes]).to eq(45)
      end

      it "computes percent of verified works completed under 60 minutes" do
        make_verified_work(examination: exam, tat_minutes: 20)
        make_verified_work(examination: exam, tat_minutes: 40)
        make_verified_work(examination: exam, tat_minutes: 90)
        make_verified_work(examination: exam, tat_minutes: 120)
        result = described_class.call(start_date: start_date, end_date: end_date)
        expect(result[:stats][:pct_under_60]).to eq(50)
        expect(result[:stats][:verified_count]).to eq(4)
      end

      it "returns nil averages when no verified works exist" do
        result = described_class.call(start_date: start_date, end_date: end_date)
        expect(result[:stats][:avg_tat_minutes]).to be_nil
        expect(result[:stats][:pct_under_60]).to be_nil
        expect(result[:stats][:verified_count]).to eq(0)
      end

      it "exposes the target SLA constant" do
        result = described_class.call(start_date: start_date, end_date: end_date)
        expect(result[:stats][:target_minutes]).to eq(61)
      end

      it "ignores verified works with nil verified_at" do
        work = create(:work, specimen: specimen, examination: exam, status: "pending")
        work.update_columns(status: "verified", verified_at: nil, created_at: 10.minutes.ago)
        result = described_class.call(start_date: start_date, end_date: end_date)
        expect(result[:stats][:verified_count]).to eq(0)
      end
    end
  end
end
