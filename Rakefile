require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'json_schema_spec'

root = File.dirname(__FILE__)

require "#{root}/lib/gitcycle/api"
require "#{root}/lib/gitcycle/config"
require "#{root}/lib/gitcycle/util"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "-f d"
end
task :default => :spec

JsonSchemaSpec::Tasks.new("http://127.0.0.1:3000/schema.json")