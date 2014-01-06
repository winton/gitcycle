require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'json_schema_spec'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "-f d"
end
task :default => :spec

JsonSchemaSpec::Tasks.new("http://127.0.0.1:3000/schema.json")