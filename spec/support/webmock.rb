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

  def webmock(type, method, merge={})
    fixture  = webmock_fixture(type)
    path     = fixture[:path]
    fixture  = Gitcycle::Util.deep_merge(fixture[method], merge)
    request  = fixture[:request]
    response = fixture[:response]
    
    headers  = {
      'Authorization' => "Token token=\"#{Gitcycle::Config.token}\"",
      'Content-Type'  => 'application/x-www-form-urlencoded'
    }

    stub_request(method, "#{Gitcycle::Config.url}#{path}").
      with(:body => request, :headers => headers).
      to_return(:status => 200, :body => response.to_json, :headers => {})
  end
end