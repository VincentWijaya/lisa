class User < ApplicationRecord
  rolify

  has_secure_password

  ROLES = %w[admin lab_supervisor lab_technician doctor].freeze

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, allow_nil: true

  before_validation :downcase_email
  before_create :generate_api_token

  scope :active, -> { where(active: true) }

  def admin?
    has_role?(:admin)
  end

  def display_roles
    roles.map(&:name).join(", ")
  end

  private

  def downcase_email
    self.email = email&.downcase&.strip
  end

  def generate_api_token
    self.api_token ||= SecureRandom.hex(32)
  end
end
