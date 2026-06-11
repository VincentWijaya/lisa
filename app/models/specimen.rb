class Specimen < ApplicationRecord
  COLLECTION_LAST_MODIFIED_CACHE_KEY = "api/specimens/collection_last_modified"
  DASHBOARD_CACHE_KEY = "dashboard/stats"

  has_many :works, dependent: :restrict_with_error

  enum :status, {
    pending:     "pending",
    in_progress: "in_progress",
    complete:    "complete",
    cancelled:   "cancelled"
  }, validate: true

  validates :patient_id,   presence: true
  validates :patient_name, presence: true
  validates :birth_date,   presence: true
  validates :gender,       presence: true
  validates :lab_id,       presence: true
  validates :order_number, presence: true, uniqueness: true
  validates :status,       presence: true

  scope :today, -> { where(created_at: Time.current.all_day) }
  scope :with_works, -> { includes(works: :examination) }
  scope :filter_by_status, ->(value) { value.present? ? where(status: value) : all }
  scope :filter_by_patient_name, ->(value) { value.present? ? where("patient_name ILIKE ?", "%#{sanitize_sql_like(value.strip)}%") : all }
  scope :filter_by_patient_id, ->(value) { value.present? ? where("patient_id ILIKE ?", "%#{sanitize_sql_like(value.strip)}%") : all }
  scope :filter_by_medical_record_id, ->(value) { value.present? ? where("medical_record_id ILIKE ?", "%#{sanitize_sql_like(value.strip)}%") : all }
  scope :filter_by_order_number, ->(value) { value.present? ? where("order_number ILIKE ?", "%#{sanitize_sql_like(value.strip)}%") : all }

  after_commit :expire_caches

  def self.collection_last_modified
    Rails.cache.fetch(COLLECTION_LAST_MODIFIED_CACHE_KEY) do
      [ maximum(:updated_at), Work.maximum(:updated_at) ].compact.max || Time.at(0)
    end
  end

  def self.expire_collection_cache
    Rails.cache.delete(COLLECTION_LAST_MODIFIED_CACHE_KEY)
  end

  def age_in_years
    return nil unless birth_date

    today = Date.current
    years = today.year - birth_date.year
    years -= 1 if today < birth_date + years.years
    years
  end

  private

  def expire_caches
    Rails.cache.delete(DASHBOARD_CACHE_KEY)
    self.class.expire_collection_cache
  end
end
