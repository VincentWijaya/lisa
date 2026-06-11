class Work < ApplicationRecord
  COLLECTION_LAST_MODIFIED_CACHE_KEY = "api/works/collection_last_modified"
  DASHBOARD_CACHE_KEY = "dashboard/stats"

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
  scope :with_details, -> { includes(:specimen, :examination, :examination_results) }
  scope :filter_by_status, ->(value) { value.present? ? where(status: value) : all }
  scope :filter_by_lab_id, ->(value) { value.present? ? joins(:specimen).where(specimens: { lab_id: value.strip }) : all }
  scope :search_term, lambda { |value|
    if value.present?
      term = "%#{sanitize_sql_like(value.strip)}%"
      joins(:specimen).where(
        "works.barcode_id ILIKE :term OR specimens.patient_id ILIKE :term OR specimens.medical_record_id ILIKE :term OR specimens.patient_name ILIKE :term",
        term: term
      )
    else
      all
    end
  }

  after_commit :expire_caches

  def self.collection_last_modified
    Rails.cache.fetch(COLLECTION_LAST_MODIFIED_CACHE_KEY) do
      maximum(:updated_at) || Time.at(0)
    end
  end

  def self.expire_collection_cache
    Rails.cache.delete(COLLECTION_LAST_MODIFIED_CACHE_KEY)
  end

  def latest_result
    if association(:examination_results).loaded?
      examination_results.max_by(&:created_at)
    else
      examination_results.order(created_at: :desc).first
    end
  end

  private

  def expire_caches
    Rails.cache.delete(DASHBOARD_CACHE_KEY)
    self.class.expire_collection_cache
    Specimen.expire_collection_cache
  end

  def status_transition_valid
    return if new_record?

    previous = status_was
    allowed  = TRANSITIONS[previous] || []
    return if allowed.include?(status)

    errors.add(:status, "cannot transition from '#{previous}' to '#{status}'")
  end
end
