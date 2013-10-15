require "webmock/rspec"

RSpec.configure do

  def webmock_fixture(type=nil, method=nil)
    fixture = YAML.load(File.read(webmock_fixture_path))
    fixture = Gitcycle::Util.symbolize_keys(fixture)

    if type && method
      fixture[type][method]
    elsif type
      fixture[type]
    else
      fixture
    end
  end

  def webmock_fixture_path
    "#{$root}/spec/fixtures/webmocks.yml"
  end

  def webmock(type, method)
    fixture  = webmock_fixture(type)
    request  = fixture[method][:request]
    response = fixture[method][:response].to_json
    
    headers  = {
      'Authorization' => "Token token=\"#{Gitcycle::Config.token}\"",
      'Content-Type'  => 'application/x-www-form-urlencoded'
    }

    stub_request(method, "#{Gitcycle::Config.url}#{fixture[:path]}").
      with(:body => request, :headers => headers).
      to_return(:status => 200, :body => response, :headers => {})
  end
end