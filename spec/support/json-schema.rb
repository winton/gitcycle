require "json-schema"

RSpec.configure do

  def schema_fixture(type=nil, method=nil)
    fixture = File.read(schema_fixture_path(type))
    fixture = YAML.load(fixture)
    fixture = Gitcycle::Util.symbolize_keys(fixture)
    
    if method
      fixture[method]
    else
      fixture
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