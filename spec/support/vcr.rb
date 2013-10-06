require 'vcr'

VCR.configure do |c|  
  c.cassette_library_dir = 'spec/fixtures/vcr'
  c.hook_into :faraday
  c.default_cassette_options = { :record => :new_episodes }
end