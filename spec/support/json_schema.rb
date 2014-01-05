require "json_schema_spec"

module JsonSchemaSpecOverwrite
  def validate_json_schema(resource, method, params)
    return  if RUBY_VERSION =~ /^1\.8\./

    schema = json_schema(resource, method)

    [ :request, :response ].each do |direction|
      puts "\n#{"-"*10} #{resource} #{method} #{direction} schema"
      puts schema[direction].inspect
      puts "\n#{"-"*10} #{resource} #{method} #{direction} schema"
      puts params[direction].inspect
      
      validates = JSON::Validator.fully_validate(
        schema[direction],
        params[direction],
        :validate_schema => true
      )
      expect(validates).to eq([])
    end
  end
end

RSpec.configure do |c|
  c.include JsonSchemaSpec
  c.include JsonSchemaSpecOverwrite
end