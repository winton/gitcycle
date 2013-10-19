require "json-schema"

RSpec.configure do

  def schema_fixture(resource=nil, method=nil)
    fixture = File.read(schema_fixture_path(resource))
    fixture = YAML.load(fixture)
    fixture = Gitcycle::Util.symbolize_keys(fixture)
    
    method ? fixture[method] : fixture
  end

  def schema_fixture_path(resource)
    "#{$root}/spec/fixtures/schema/#{resource}.yml"
  end

  def validate_schema(resource, method, merge={})
    return  if RUBY_VERSION =~ /^1\.8\./

    webmock = webmock_fixture(resource)[method]
    schema  = schema_fixture(resource)[method]
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