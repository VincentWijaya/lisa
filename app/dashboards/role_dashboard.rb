require "administrate/base_dashboard"

class RoleDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::Select.with_options(
      searchable: false,
      collection: ->(field) { User::ROLES }
    ),
    users: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    users
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    users
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    users
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(role)
    role.name.to_s.humanize
  end
end
