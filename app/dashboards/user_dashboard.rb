require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    email: Field::String,
    password: Field::String.with_options(searchable: false),
    active: Field::Boolean,
    roles: Field::HasMany,
    api_token: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    email
    active
    roles
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    email
    active
    roles
    api_token
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    email
    password
    active
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(user)
    "#{user.name} <#{user.email}>"
  end
end
