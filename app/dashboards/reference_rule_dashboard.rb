require "administrate/base_dashboard"

class ReferenceRuleDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    abnormal_values: Field::String.with_options(searchable: false),
    active: Field::Boolean,
    allowed_values: Field::String.with_options(searchable: false),
    critical_values: Field::String.with_options(searchable: false),
    description: Field::Text,
    examination: Field::BelongsTo,
    examination_results: Field::HasMany,
    loinc_code: Field::String,
    name: Field::String,
    normal_values: Field::String.with_options(searchable: false),
    numeric_high_value: Field::String.with_options(searchable: false),
    numeric_low_value: Field::String.with_options(searchable: false),
    reference_value: Field::String,
    result_type: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    unit: Field::String,
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
    loinc_code
    name
    description
    active
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    abnormal_values
    active
    allowed_values
    critical_values
    description
    examination
    loinc_code
    name
    normal_values
    numeric_high_value
    numeric_low_value
    reference_value
    result_type
    unit
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    abnormal_values
    active
    allowed_values
    critical_values
    description
    examination
    loinc_code
    name
    normal_values
    numeric_high_value
    numeric_low_value
    reference_value
    result_type
    unit
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

  # Overwrite this method to customize how reference rules are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(reference_rule)
  #   "ReferenceRule ##{reference_rule.id}"
  # end
  # 

  def display_resource(reference_rule)
    "#{reference_rule.name} (#{reference_rule.loinc_code})"
  end
end
