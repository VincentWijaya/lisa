class ApplicationSerializer
  def self.serialize(object, **options)
    new(object, **options).as_json
  end

  def self.serialize_collection(collection, **options)
    collection.map { |object| serialize(object, **options) }
  end

  def initialize(object, **options)
    @object = object
    @options = options
  end

  private

  attr_reader :object, :options
end
