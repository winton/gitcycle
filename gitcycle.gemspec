# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "gitcycle"
  spec.version       = "0.4.0"
  spec.authors       = ["Winton Welsh", "Matt Pruitt"]
  spec.email         = ["mail@wintoni.us", "matt@guitsaru.com"]
  spec.description   = %q{Automated development cycle}
  spec.summary       = %q{Gitcycle automates your development cycle.}
  spec.homepage      = "http://gitcycle.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "vcr"

  spec.add_dependency "excon"
  spec.add_dependency "faraday"
  spec.add_dependency "launchy"
  spec.add_dependency "rainbow"
  spec.add_dependency "system_timer"
  spec.add_dependency "thor"
  spec.add_dependency "yajl-ruby"
end