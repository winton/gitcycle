# -*- encoding: utf-8 -*-
root = File.expand_path('../', __FILE__)
lib = "#{root}/lib"

$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = "gitcycle"
  s.version     = '0.2.17'
  s.platform    = Gem::Platform::RUBY
  s.authors     = [ 'Winton Welsh' ]
  s.email       = [ 'mail@wintoni.us' ]
  s.homepage    = "https://github.com/winton/gitcycle"
  s.summary     = %q{Tame your development cycle}
  s.description = %q{Tame your development cycle.}

  s.executables = `cd #{root} && git ls-files bin/*`.split("\n").collect { |f| File.basename(f) }
  s.files = `cd #{root} && git ls-files`.split("\n")
  s.require_paths = %w(lib)
  s.test_files = `cd #{root} && git ls-files -- {features,test,spec}/*`.split("\n")

  s.add_development_dependency "cucumber"
  s.add_development_dependency "lighthouse"
  s.add_development_dependency "redis"
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "yajl-ruby"

  s.add_dependency "launchy", "= 2.0.5"
  s.add_dependency "yajl-ruby", "= 1.1.0"
  s.add_dependency "httpclient", "= 2.1.5"
  s.add_dependency "httpi", "= 0.9.6"
end
