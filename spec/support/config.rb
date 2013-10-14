ENV['CONFIG'] = "#{$root}/spec/fixtures/gitcycle.yml"
Gitcycle::Config.config_path = ENV['CONFIG']

RSpec.configure do |c|
  
  def config
    @config ||= YAML.load_file(config_path)
  end

  def config_path
    "#{$root}/spec/config/gitcycle.yml"
  end

  def config_fixture
    @config_fixture ||= YAML.load(File.read(config_fixture_path))
  end

  def config_fixture_path
    ENV['CONFIG']
  end
end