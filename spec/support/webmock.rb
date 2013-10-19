require "webmock/rspec"

RSpec.configure do

  def schema_to_webmock(schema, prefix=[])
    return schema  unless schema.is_a?(Hash)
    
    schema.inject({}) do |memo, (key, value)|
      memo[key] = webmock_value(key, value, prefix.dup)
      memo.delete(key)  unless memo[key]
      memo
    end
  end

  def webmock_fixture(resource)
    $webmock_fixture           ||= {}
    $webmock_fixture[resource] ||= schema_to_webmock(schema_fixture(resource))
    Gitcycle::Util.deep_dup($webmock_fixture[resource])
  end

  def webmock_value(key, value, prefix)
    if !value.is_a?(Hash) || value[:optional]
      nil
    elsif value[:type] == 'string'
      webmock_value_prefix(prefix) + key.to_s
    elsif value[:type] == 'number'
      Math.floor(Math.random()*1000000)
    elsif value[:type] == 'object'
      schema_to_webmock(value[:properties], prefix << key)
    else
      schema_to_webmock(value)
    end
  end

  def webmock_value_prefix(prefix)
    prefix = prefix.join(':')
    prefix = "#{prefix}:"  unless prefix.empty? 
    prefix.gsub(/^[^:]*:*/, '')
  end

  def webmock(resource, method, merge={})
    fixture  = webmock_fixture(resource)
    fixture  = Gitcycle::Util.deep_merge(fixture[method], merge)
    request  = fixture[:request]
    response = fixture[:response]
    
    headers  = {
      'Authorization' => "Token token=\"#{Gitcycle::Config.token}\"",
      'Content-Type'  => 'application/x-www-form-urlencoded'
    }

    stub_request(method, "#{Gitcycle::Config.url}/#{resource}.json").
      with(:body => request, :headers => headers).
      to_return(:status => 200, :body => response.to_json, :headers => {})
  end
end