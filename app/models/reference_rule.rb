class ReferenceRule < ApplicationRecord
  belongs_to :examination
  has_many :examination_results, dependent: :nullify

  RESULT_TYPES = %w[numeric qualitative text].freeze

  enum :result_type, {
    numeric:     "numeric",
    qualitative: "qualitative",
    text:        "text"
  }, validate: true

  GENDERS = %w[male female].freeze

  enum :gender, {
    male:   "male",
    female: "female"
  }

  validates :name,        presence: true
  validates :result_type, presence: true
  validates :active,      inclusion: { in: [true, false] }

  validates :numeric_low_value,
            numericality: true,
            allow_nil: true,
            if: -> { result_type == "numeric" }

  validates :numeric_high_value,
            numericality: true,
            allow_nil: true,
            if: -> { result_type == "numeric" }

  validate :numeric_range_order, if: -> { result_type == "numeric" && numeric_low_value.present? && numeric_high_value.present? }

  scope :active, -> { where(active: true) }

  # Map free-form specimen gender values to our enum.
  # Returns nil when no match (caller decides: keep all rules, or skip).
  def self.specimen_gender_to_enum(specimen_gender)
    case specimen_gender.to_s.downcase.strip
    when "male", "laki-laki", "laki", "m", "pria" then "male"
    when "female", "perempuan", "wanita", "f", "p", "w" then "female"
    end
  end

  # Rules that apply to the given specimen gender.
  # nil specimen gender → unisex rules only (gender NULL).
  # male/female → matching rules + unisex rules.
  scope :for_specimen_gender, ->(specimen_gender) {
    enum_value = specimen_gender_to_enum(specimen_gender)
    enum_value ? where(gender: [ nil, enum_value ]) : where(gender: nil)
  }

  # Pick the best-matching rule for a specimen from a pre-narrowed candidate set.
  # Prefers a rule whose gender matches the specimen; falls back to the first by id.
  def self.best_for_specimen(rules, specimen_gender)
    enum_value = specimen_gender_to_enum(specimen_gender)
    return rules.min_by(&:id) if enum_value.nil? || rules.empty?

    rules.find { |rule| rule.gender == enum_value } || rules.min_by(&:id)
  end

  def interprets?(value)
    return false if value.blank?

    case result_type
    when "numeric"
      interpret_numeric(value)
    when "qualitative"
      interpret_qualitative(value)
    else
      "normal"
    end
  end

  def interpretation_for(value)
    return nil if value.blank?

    if critical_values.present? && critical_values.include?(value)
      "critical"
    elsif abnormal_values.present? && abnormal_values.include?(value)
      "abnormal"
    elsif normal_values.present? && normal_values.include?(value)
      "normal"
    elsif result_type == "numeric"
      interpret_numeric(value)
    end
  end

  private

  def numeric_range_order
    return unless numeric_low_value > numeric_high_value

    errors.add(:numeric_high_value, "must be greater than or equal to low value")
  end

  def interpret_numeric(value)
    numeric = Float(value)
    if numeric_low_value.present? && numeric < numeric_low_value
      "abnormal"
    elsif numeric_high_value.present? && numeric > numeric_high_value
      "abnormal"
    else
      "normal"
    end
  rescue ArgumentError, TypeError
    nil
  end

  def interpret_qualitative(value)
    if critical_values.include?(value) then "critical"
    elsif abnormal_values.include?(value) then "abnormal"
    elsif normal_values.include?(value) then "normal"
    end
  end
end
