ENV['CONFIG'] = "#{$root}/spec/fixtures/gitcycle.yml"
Gitcycle::Config.config_path = ENV['CONFIG']

RSpec.configure do |c|
  
  def config
    unless @config
      @config = YAML.load_file(config_path)
      @config = Gitcycle::Util.symbolize_keys(@config)
    end
    @config
  end

  def config_path
    "#{$root}/spec/config/gitcycle.yml"
  end

  def config_fixture
    unless @config_fixture
      @config_fixture = YAML.load(File.read(config_fixture_path))
      @config_fixture = Gitcycle::Util.symbolize_keys(@config_fixture)
    end
    @config_fixture
  end

  def config_fixture_path
    ENV['CONFIG']
  end
end