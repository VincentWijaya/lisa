require "administrate/base_dashboard"

class ExaminationDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    code: Field::String,
    name: Field::String,
    category: Field::String,
    description: Field::Text,
    label_group: Field::String,
    specimen_type: Field::String,
    default_result_type: Field::Select.with_options(searchable: false, collection: %w[numeric qualitative text]),
    default_unit: Field::String,
    status: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    reference_rules: Field::HasMany,
    works: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    code
    name
    description
    default_result_type
    default_unit
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    code
    name
    category
    description
    label_group
    specimen_type
    default_result_type
    default_unit
    status
    reference_rules
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    code
    name
    category
    description
    label_group
    specimen_type
    default_result_type
    default_unit
    status
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how examinations are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(examination)
  #   "Examination ##{examination.id}"
  # end
  #

  def display_resource(examination)
    "#{examination.code} - #{examination.name}"
  end
end
