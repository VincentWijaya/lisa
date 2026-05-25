class Role < ApplicationRecord
  has_and_belongs_to_many :users, join_table: :users_roles

  belongs_to :resource, polymorphic: true, optional: true

  scopify

  validates :name, presence: true,
                   inclusion: { in: User::ROLES, message: "%{value} is not a valid role" }
end
