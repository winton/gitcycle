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

  def validate_schema(method, schema_type, webmock_type=schema_type, merge={})
    return  if RUBY_VERSION =~ /^1\.8\./

    if webmock_type.is_a?(Hash)
      merge, webmock_type = webmock_type, schema_type
    end

    schema  = schema_fixture(schema_type,   method)
    webmock = webmock_fixture(webmock_type, method)
    webmock = Gitcycle::Util.deep_merge(webmock, merge)

    [ :request, :response ].each do |direction|
      validates = JSON::Validator.fully_validate(
        schema[direction],
        webmock[direction],
        :validate_schema => true
      )
      expect(validates).to eq([])
    end
  end
end