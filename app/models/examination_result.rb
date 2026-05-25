class ExaminationResult < ApplicationRecord
  belongs_to :work
  belongs_to :reference_rule, optional: true

  SOURCES = %w[manual external_api instrument].freeze

  enum :source, {
    manual:       "manual",
    external_api: "external_api",
    instrument:   "instrument"
  }, validate: true

  INTERPRETATIONS = %w[normal abnormal critical].freeze

  validates :result_value,   presence: true
  validates :source,         presence: true
  validates :interpretation, inclusion: { in: INTERPRETATIONS, allow_blank: true }

  validate :allowed_values_respected, if: -> { reference_rule.present? && reference_rule.allowed_values.present? }

  before_save :set_interpretation, if: -> { reference_rule.present? && interpretation.blank? }

  private

  def allowed_values_respected
    allowed = reference_rule.allowed_values
    return if allowed.empty?
    return if allowed.include?(result_value)

    errors.add(:result_value, "must be one of: #{allowed.join(', ')}")
  end

  def set_interpretation
    self.interpretation = reference_rule.interpretation_for(result_value)
  end
end
