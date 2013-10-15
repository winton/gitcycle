ENV['CONFIG'] = "#{$root}/spec/fixtures/gitcycle.yml"
Gitcycle::Config.config_path = ENV['CONFIG']

RSpec.configure do |c|
  
  def config
    fixture = YAML.load_file(config_path)
    Gitcycle::Util.symbolize_keys(fixture)
  end

  def config_path
    "#{$root}/spec/config/gitcycle.yml"
  end

  def config_fixture
    fixture = YAML.load(File.read(config_fixture_path))
    Gitcycle::Util.symbolize_keys(fixture)
  end

  def config_fixture_path
    ENV['CONFIG']
  end
end