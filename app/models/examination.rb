class Examination < ApplicationRecord
  has_many :works, dependent: :restrict_with_error
  has_many :reference_rules, dependent: :destroy

  enum :status, { active: "active", inactive: "inactive" }, validate: true

  RESULT_TYPES = %w[numeric qualitative text].freeze

  validates :name, presence: true
  validates :status, presence: true
  validates :default_result_type, inclusion: { in: RESULT_TYPES, allow_blank: true }

  scope :active, -> { where(status: :active) }
end
