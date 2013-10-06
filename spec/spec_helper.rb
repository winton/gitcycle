ENV['ENV'] = 'test'

$root = File.expand_path('../../', __FILE__)
require "#{$root}/lib/gitcycle"

def config
  path = "#{File.dirname(__FILE__)}/config/gitcycle.yml"
  @config ||= YAML.load_file(path)
end