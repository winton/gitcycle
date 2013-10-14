ENV['ENV'] = "test"
$root      = File.expand_path('../../', __FILE__)

require "#{$root}/lib/gitcycle"

Dir["#{$root}/spec/support/**/*.rb"].each { |f| require f }

RSpec.configure do |c|
  
  c.color_enabled = true
end