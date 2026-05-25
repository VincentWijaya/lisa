class Work < ApplicationRecord
  belongs_to :specimen
  belongs_to :examination
  has_many :examination_results, dependent: :destroy

  enum :status, {
    pending:   "pending",
    validated: "validated",
    verified:  "verified",
    cancelled: "cancelled"
  }, validate: true

  validates :barcode_id,     presence: true, uniqueness: true
  validates :status,         presence: true
  validates :manual_input,   inclusion: { in: [true, false] }
  validates :label_sequence, presence: true, numericality: { greater_than: 0, only_integer: true }

  # Valid status transitions
  TRANSITIONS = {
    "pending"   => %w[validated cancelled],
    "validated" => %w[verified cancelled],
    "verified"  => [],
    "cancelled" => []
  }.freeze

  validate :status_transition_valid, if: :status_changed?

  scope :pending,   -> { where(status: :pending) }
  scope :validated, -> { where(status: :validated) }
  scope :verified,  -> { where(status: :verified) }
  scope :cancelled, -> { where(status: :cancelled) }

  def latest_result
    examination_results.order(created_at: :desc).first
  end

  private

  def status_transition_valid
    return if new_record?

    previous = status_was
    allowed  = TRANSITIONS[previous] || []
    return if allowed.include?(status)

    errors.add(:status, "cannot transition from '#{previous}' to '#{status}'")
  end
end
