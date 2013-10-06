ENV['ENV'] = 'test'

$root = File.expand_path('../../', __FILE__)
require "#{$root}/lib/gitcycle"

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
end

def config
  path = "#{File.dirname(__FILE__)}/config/gitcycle.yml"
  @config ||= YAML.load_file(path)
end