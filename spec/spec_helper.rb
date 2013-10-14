$root = File.expand_path('../../', __FILE__)

ENV['ENV']    = "test"
ENV['CONFIG'] = "#{$root}/spec/fixtures/gitcycle.yml"

require "#{$root}/lib/gitcycle"

Gitcycle::Config.config_path = ENV['CONFIG']

Dir["#{$root}/spec/support/**/*.rb"].each { |f| require f }

RSpec.configure do |c|
  
  c.color_enabled = true

  c.around(:each, :capture) do |example|
    capture(:stdout) { example.call }
  end

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end

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