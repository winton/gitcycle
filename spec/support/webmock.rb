require "webmock/rspec"

RSpec.configure do

  def schema_to_webmock(schema, prefix=[])
    return schema  unless schema.is_a?(Hash)
    
    schema.inject({}) do |memo, (key, value)|
      if !value.is_a?(Hash) || value[:optional]
        # do nothing
      elsif value[:type] == 'string'
        pre = prefix.join(':')
        pre = "#{pre}:"  unless pre.empty? 
        pre = pre.gsub(/^[^:]*:*/, '')
        memo[key] = pre + key.to_s
      elsif value[:type] == 'number'
        memo[key] = Math.floor(Math.random()*1000000)
      elsif value[:type] == 'object'
        pre = prefix.dup
        pre << key
        memo[key] = schema_to_webmock(value[:properties], pre)
      else
        memo[key] = schema_to_webmock(value)
      end

      memo
    end
  end

  def webmock(resource, method, merge={})
    fixture  = schema_to_webmock(schema_fixture(resource))
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