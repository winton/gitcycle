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

  # def webmock_hash_to_schema(hash)
  #   new_hash = hash.dup
  #   hash.each do |key, value|
  #     if value.is_a?(String)
  #       new_hash[:properties]    ||= {}
  #       new_hash[:properties][key] = { :type => 'string' }
  #       new_hash.delete(key)
  #     elsif value.is_a?(Integer)
  #       new_hash[:properties]    ||= {}
  #       new_hash[:properties][key] = { :type => 'integer' }
  #       new_hash.delete(key)
  #     elsif value.is_a?(Hash) && key != :type
  #       new_hash[key] = webmock_hash_to_schema(value)
  #     end
  #   end
  #   new_hash
  # end

  def validate_schema(method, schema_type, webmock_type=schema_type, merge={})
    return  if RUBY_VERSION =~ /^1\.8\./

    if webmock_type.is_a?(Hash)
      merge, webmock_type = webmock_type, schema_type
    end

    schema  = schema_fixture(schema_type,   method)
    webmock = webmock_fixture(webmock_type, method)

    # schema_merge = webmock_hash_to_schema(merge)

    # schema  = Gitcycle::Util.deep_merge(schema,  schema_merge)
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