class ServiceResult
  attr_reader :errors

  def self.success(attributes = {})
    new(success: true, **attributes)
  end

  def self.failure(errors:, **attributes)
    new(success: false, errors: Array(errors), **attributes)
  end

  def initialize(success:, errors: [], **attributes)
    @success = success
    @errors = Array(errors)
    attributes.each do |name, value|
      instance_variable_set("@#{name}", value)
      define_singleton_method(name) { value }
    end
  end

  def success?
    @success
  end

  def failure?
    !success?
  end

  def to_h
    instance_values.except("success").symbolize_keys.merge(success: success?, errors: errors)
  end

  private

  def instance_values
    instance_variables.each_with_object({}) do |variable, values|
      values[variable.to_s.delete_prefix("@")] = instance_variable_get(variable)
    end
  end
end
