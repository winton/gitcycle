require "webmock/rspec"

RSpec.configure do

  def webmock(resource, method, merge={})
    request, response = json_schema_params(resource, method, merge)
    
    headers  = {
      'Authorization' => "Token token=\"#{Gitcycle::Config.token}\"",
      'Content-Type'  => 'application/x-www-form-urlencoded'
    }

    stub_request(method, "#{Gitcycle::Config.url}/#{resource}.json").
      with(:body => request, :headers => headers).
      to_return(:status => 200, :body => response.to_json, :headers => {})
  end
end