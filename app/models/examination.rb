class Examination < ApplicationRecord
  has_many :works, dependent: :restrict_with_error
  has_many :reference_rules, dependent: :destroy

  enum :status, { active: "active", inactive: "inactive" }, validate: true

  RESULT_TYPES = %w[numeric qualitative text].freeze

  validates :name, presence: true
  validates :status, presence: true
  validates :default_result_type, inclusion: { in: RESULT_TYPES, allow_blank: true }

  scope :active, -> { where(status: :active) }

  # Cache active examinations for 10 minutes — they rarely change.
  def self.cached_active
    Rails.cache.fetch("examinations/active", expires_in: 10.minutes) do
      active.order(:name).to_a
    end
  end

  after_commit :expire_examinations_cache

  private

  def expire_examinations_cache
    Rails.cache.delete("examinations/active")
  end
end
