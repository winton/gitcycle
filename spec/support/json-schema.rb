require "json-schema"

RSpec.configure do

  def schema_fixture(type=nil, method=nil)
    @schema_fixture ||= {}

    unless @schema_fixture[type]
      @schema_fixture[type] = File.read(schema_fixture_path(type))
      @schema_fixture[type] = YAML.load(@schema_fixture[type])
      @schema_fixture[type] = Gitcycle::Util.symbolize_keys(@schema_fixture[type])
    end
    
    if type && method
      @schema_fixture[type][method]
    elsif type
      @schema_fixture[type]
    else
      @schema_fixture
    end
  end

  def schema_fixture_path(type)
    "#{$root}/spec/fixtures/schema/#{type}.yml"
  end

  def validate_schema(method, schema_type, webmock_type=schema_type)
    return  if RUBY_VERSION =~ /^1\.8\./
    [ :request, :response ].each do |direction|
      JSON::Validator.validate(
        schema_fixture(schema_type, method)[direction],
        webmock_fixture(webmock_type, method)[direction]
      )
    end
  end
end