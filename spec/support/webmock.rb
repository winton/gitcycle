require "webmock/rspec"

RSpec.configure do

  def webmock_fixture
    @config_fixture ||= YAML.load(File.read(webmock_fixture_path))
  end

  def webmock_fixture_path
    "#{$root}/spec/fixtures/webmocks.yml"
  end

  def webmock(path, type)
    fixture  = webmock_fixture[path.to_s][type.to_s]
    request  = fixture['request']
    response = fixture['response'].to_json
    
    headers  = {
      'Authorization' => "Token token=\"#{Gitcycle::Config.token}\"",
      'Content-Type'  => 'application/x-www-form-urlencoded'
    }

    stub_request(type, "#{Gitcycle::Config.url}/#{path}.json").
      with(:body => request, :headers => headers).
      to_return(:status => 200, :body => response, :headers => {})
  end
end