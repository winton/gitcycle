require "webmock/rspec"

RSpec.configure do

  def webmock_fixture
    @config_fixture ||= YAML.load(File.read(webmock_fixture_path))
  end

  def webmock_fixture_path
    "#{$root}/spec/fixtures/webmocks.yml"
  end

  def webmock(path, type)
    body    = webmock_fixture[path.to_s][type.to_s]
    headers = {
      'Authorization' => "Token token=\"#{Gitcycle::Config.token}\"",
      'Content-Type'  => 'application/x-www-form-urlencoded'
    }
    stub_request(:post, "http://127.0.0.1:3000/#{path}.json").
      with(:body => body, :headers => headers).
      to_return(:status => 200, :body => "{}", :headers => {})
  end
end