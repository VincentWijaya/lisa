class Specimen < ApplicationRecord
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

  def age_in_years
    return nil unless birth_date

    today = Date.current
    years = today.year - birth_date.year
    years -= 1 if today < birth_date + years.years
    years
  end
end
