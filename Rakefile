require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

root = File.dirname(__FILE__)

require "#{root}/lib/gitcycle/api"
require "#{root}/lib/gitcycle/config"

RSpec::Core::RakeTask.new(:spec)
task :default => :spec

namespace :spec do
  desc 'Download schema from gitcycle_api'
  task :schema do
    Gitcycle::Config.config_path = "#{root}/spec/config/gitcycle.yml"
    Gitcycle::Config.load
    puts Gitcycle::Api.branch_schema.inspect
  end
end