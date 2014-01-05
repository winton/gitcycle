require "json_schema_spec"
require "webmock/rspec"

RSpec.configure do

  def webmock(resource, method, merge={})
    request, response = json_schema_params(resource, method, merge)

    if method == :get
      query, body = request, nil
    else
      query, body = nil, request
    end
    
    headers  = {
      'Authorization' => "Token token=\"#{Gitcycle::Config.token}\""
    }

    stub_request(method, "#{Gitcycle::Config.url}/#{resource}.json").
      with(:body => body, :headers => headers, :query => query).
      to_return(:status => 200, :body => response.to_json, :headers => {})
  end
end