$root = File.expand_path('../../', __FILE__)

ENV['ENV']    = "test"
ENV['CONFIG'] = "#{$root}/spec/fixtures/gitcycle.yml"

require "#{$root}/lib/gitcycle"

Gitcycle::Config.config_path = ENV['CONFIG']
Dir["#{$root}/spec/support/**/*.rb"].each { |f| require f }

RSpec.configure do |c|
  
  c.treat_symbols_as_metadata_keys_with_true_values = true

  c.around(:each, :vcr) do |example|
    name = example.metadata[:full_description]
    name = name.downcase
    name = name.split(/\s+/, 2)
    name = name.join("/")
    name = name.gsub(/[^\w\/]+/, "_")

    VCR.use_cassette(name) { example.call }
  end

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
    path = "#{File.dirname(__FILE__)}/config/gitcycle.yml"
    @config ||= YAML.load_file(path)
  end

  def config_fixture
    @config_fixture ||= YAML.load(File.read(Gitcycle::Config.config_path))
  end
end